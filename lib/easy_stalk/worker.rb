require 'json'
require 'interactor'
require_relative 'client'
require_relative 'job'

module EasyStalk
  class Worker
    RETRY_TIMES = 5
    RESERVE_TIMEOUT = 3

    def work_jobs(job_classes = nil, on_fail: nil)
      job_classes = EasyStalk::Job.descendants unless job_classes
      job_classes = [job_classes] unless job_classes.instance_of?(Array)

      job_classes.each do |job_class|
        raise ArgumentError, "#{job_class} is not a valid EasyStalk::Job subclass" unless Class === job_class && job_class < EasyStalk::Job
      end

      if on_fail && !on_fail.respond_to?(:call)
        raise ArgumentError, "on_fail handler does not respond to call"
      elsif !on_fail
        on_fail = Proc.new { |job_class, job_body, ex|
          EasyStalk.logger.error "Worker for #{job_class} on tube[#{job_class.tube_name}] failed #{ex.message}"
          EasyStalk.logger.error ex.backtrace.join("\n")
        }
      end

      register_signal_handlers!
      @cancelled = false

      tube_class_hash = {}

      EasyStalk::Client.instance.with do |beanstalk|
        job_classes.each do |job_class|
          beanstalk.tubes.watch!(job_class.tube_name)
          tube_class_hash[job_class.tube_name] = job_class
        end
        EasyStalk.logger.info "Watching tube #{beanstalk.tubes.watched} for jobs"

        # TODO: we can likely do without this cancelled protection
        # Worse case scenario, we call the interactor, but the job gets re-enqueued when
        # ttr expires.
        while !@cancelled
          # wait until next job available
          begin
            job = beanstalk.tubes.reserve(RESERVE_TIMEOUT)
            begin
              job_class = tube_class_hash[job.tube]
              result = job_class.call!(JSON.parse(job.body))
            rescue => ex
              # Job issued a failed context or raised an unhandled exception
              if job.stats.releases < RETRY_TIMES
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
          rescue Beaneater::TimedOutError => e
            # Failed to reserve a job, tube is likely empty
          end
        end
      end

      jobs_list = job_classes.map { |job_class| "#{job_class} on tube #{job_class.tube_name}" }.join(", ")
      EasyStalk.logger.info "Worker running #{jobs_list} has been stopped"
    end

    private

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
