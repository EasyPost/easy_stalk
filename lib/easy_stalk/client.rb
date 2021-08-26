# frozen_string_literal: true

EasyStalk::Client = Struct.new(:producer, :consumer) do
  include Enumerable

  class << self
    def default
      @default ||= new
    end
  end

  def initialize(
    producer: EasyStalk::ProducerPool.default,
    consumer: EasyStalk::ConsumerPool.default
  )
    super(producer, consumer)
  end

  def tubes
    consumer.tubes
  end

  def push(
    data = nil,
    tube:,
    delay: EasyStalk.default_job_delay,
    priority: EasyStalk.default_job_priority,
    time_to_run: EasyStalk.default_job_time_to_run
  )
    producer.with do |beaneater|
      beaneater
        .tubes[tube]
        .put(
          EasyStalk::Job.encode(data),
          pri: priority,
          ttr: time_to_run,
          delay: [delay, 0].compact.max
        )
    end

    true
  end

  def each(timeout:)
    return to_enum(:each, timeout: timeout) unless block_given?

    loop do
      consumer.with do |beaneater|
        # This Timeout block is to catch the case where the beanstalkd
        # may zone out and forget to reserve a job for us. We intentionally
        # don't catch Timeout::Error; if that fires, then beanstalkd is
        # messed up, and our best bet is probably to exit noisily
        job = Timeout.timeout(timeout * 4) { beaneater.tubes.reserve(timeout) }

        if job.nil?
          EasyStalk.logger.debug { 'no jobs available' }
          yield nil
          next
        end

        EasyStalk.logger.info do
          "reserved beanstalkd://#{beaneater.connection.host}:#{beaneater.connection.port}/"\
          "#{job.tube}/#{job.id}"
        end

        yield EasyStalk::Job.new(job, client: self)
      end
    rescue Beaneater::TimedOutError
      # Failed to reserve a job, tube is likely empty
      EasyStalk.logger.debug { "failed to reserve jobs within #{timeout} seconds" }
      yield nil
    end
  end

  def releases(job)
    job.stats.releases
  end

  def release(job, delay: nil, priority: nil)
    options = {}
    options[:delay] = delay if delay
    options[:pri] = priority if priority
    job.release(options)
  end

  def bury(job)
    job.bury
  end

  def complete(job)
    job.delete
  end
end
