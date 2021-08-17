# frozen_string_literal: true

EasyStalk::Client = Struct.new(:producer, :consumer) do
  include Enumerable

  class << self
    def default
      @default ||= new
    end
  end

  TubeEmpty = Class.new(StandardError)

  def initialize(producer: EasyStalk::ProducerPool.default,
                 consumer: EasyStalk::ConsumerPool.default)
    super(producer, consumer)
  end

  def push(data, tube:, priority: EasyStalk.default_job_priority,
           delay: EasyStalk.default_job_delay, time_to_run: EasyStalk.default_job_time_to_run)
    producer.with do |connection|
      connection.tubes
                .fetch(EasyStalk.tube_name(tube))
                .put(EasyStalk::Job.encode(data),
                     pri: priority,
                     ttr: time_to_run,
                     delay: [delay, 0].max)
    end

    true
  end

  def each(timeout:)
    return to_enum(:each, timeout: timeout) unless block_given?

    # This Timeout block is to catch the case where the beanstalkd
    # may zone out and forget to reserve a job for us. We intentionally
    # don't catch Timeout::Error; if that fires, then beanstalkd is
    # messed up, and our best bet is probably to exit noisily

    consumer.with do |connection|
      job = Timeout.timeout(timeout * 4) { connection.tubes.reserve(timeout) }
      raise TubeEmpty unless job

      yield EasyStalk::Job.new(job)
    end
  rescue TubeEmpty
    retry
  rescue Beaneater::TimedOutError
    # Failed to reserve a job, tube is likely empty
    EasyStalk.logger.debug do
      "#{connection} failed to reserve jobs within #{reserve_timeout} seconds"
    end
    retry
  end

  def releases(job)
    job.stats.release
  end

  def release(job, delay:)
    job.release delay: delay
  end

  def bury(job)
    job.dead
  end

  def complete(job)
    job.delete
  end
end
