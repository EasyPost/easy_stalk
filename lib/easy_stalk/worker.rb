require 'json'
require 'interactor'
require 'timeout'
require_relative 'client'
require_relative 'job'

module EasyStalk
  class Worker
    RESERVE_TIMEOUT = 3

    def work(job_classes = nil, on_fail: nil)
      job_classes = EasyStalk::Job.descendants unless job_classes
      job_classes = [job_classes] unless job_classes.instance_of?(Array)

      job_classes.each do |job_class|
        raise ArgumentError, "#{job_class} is not a valid EasyStalk::Job subclass" unless Class === job_class && job_class < EasyStalk::Job
      end

      on_fail = EasyStalk.configuration.default_worker_on_fail unless on_fail
      raise ArgumentError, "on_fail handler does not respond to call" unless on_fail.respond_to?(:call)

      register_signal_handlers!
      @cancelled = false

      tube_class_hash = Hash[
        job_classes.map { |cls| [cls.tube_name, cls] }
      ]

      pool = EasyStalk::Client.create_worker_pool(tube_class_hash.keys)

      while !@cancelled
        pool.with do |beanstalk|
          job = get_one_job(beanstalk)
          # continue around the loop if we got a timeout reserving a job
          # (that is to say, if there's nothing in this tube)
          next unless job
          begin
            job_class = tube_class_hash[job.tube]
            job_class.call!(JSON.parse(job.body))
          rescue => ex
            # Job issued a failed context or raised an unhandled exception
            job_class = tube_class_hash[job.tube]
            if job.stats.releases <= job_class.retry_times
              # Re-enqueue with stepped delay
              release_with_delay(job)
            else
              job.bury
            end
            on_fail.call(job_class, job.body, ex)
          else
            # Job Succeeded!
            job.delete
          end
        end
      end

      jobs_list = job_classes.map { |job_class| "#{job_class} on tube #{job_class.tube_name}" }.join(", ")
      EasyStalk.logger.info "Worker running #{jobs_list} has been stopped"
    end

    private

    def get_one_job(beanstalk_client)
      begin
        # This Timeout block is to catch the case where the beanstalkd
        # may zone out and forget to reserve a job for us. We intentionally
        # don't catch Timeout::Error; if that fires, then beanstalkd is
        # messed up, and our best bet is probably to exit noisily
        Timeout.timeout(RESERVE_TIMEOUT * 4) {
          beanstalk_client.tubes.reserve(RESERVE_TIMEOUT)
        }
      rescue Beaneater::TimedOutError
        # Failed to reserve a job, tube is likely empty
      end
    end

    def release_with_delay(job)
      # Compute a cubed backoff with a randomizer, skipping the first gen
      # [4,13,40,121,364,,,] mins + up to 1/3 of the time (randomly)
      minutes_to_delay = ((3**(job.stats.releases + 1))/2)
      seconds_to_delay = minutes_to_delay * 60
      randomizer = rand(0..seconds_to_delay/3)
      job.release :delay => seconds_to_delay + randomizer
    end

    def cleanup
      EasyStalk.logger.info "Cancelling"
      @cancelled = true
    end

    def register_signal_handlers!
      trap("QUIT") { cleanup }
      trap("TERM") { cleanup }
      trap('INT')  { cleanup }
    end

  end
end
