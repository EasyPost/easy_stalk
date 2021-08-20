# frozen_string_literal: true

EasyStalk::Consumer = Struct.new(:job) do
  class << self
    def tubes
      @tubes ||= Set.new
    end

    def assign(*assignments)
      assignments.each do |tube|
        existing_consumer = EasyStalk.tube_consumers[tube]
        raise ArgumentError, "#{existing_consumer} already assigned to #{tube}" if existing_consumer

        EasyStalk.tube_consumers[tube] = self
        tubes << tube
      end
    end

    # @return [Integer] 0..2**32. 0 is highest
    def priority
      @priority ||= EasyStalk.default_job_priority
    end
    attr_writer :priority

    # integer seconds to run this job
    def time_to_run
      @time_to_run ||= EasyStalk.default_job_time_to_run
    end
    attr_writer :time_to_run

    # @return [Integer] seconds before job is in ready queue
    def delay
      @delay ||= EasyStalk.default_job_delay
    end
    attr_writer :delay

    # @return [Integer] max number of times to retry job before burying
    def retry_limit
      @retry_limit ||= EasyStalk.default_job_retry_limit
    end
    attr_writer :retry_limit

    def enqueue(
      data,
      client: EasyStalk::Client.default,
      priority: self.class.priority,
      time_to_run: self.class.time_to_run,
      delay: self.class.delay,
      delay_until: nil,
      tube: self.class.default_tube
    )
      if delay_until
        raise ArgumentError, 'cannot specify delay and delay_until' if delay

        delay = delay_until - Time.now
      end

      payload = serialize(data)

      client.push(
        payload,
        tube: tube,
        priority: priority,
        time_to_run: time_to_run,
        delay: delay
      )
    end

    def serialize(data)
      EasyStalk::MethodDelegator.serialize(data, specification: method(:call))
    end

    def consume(job)
      job_consumer = new(job)
      job_consumer.consume

      job.complete unless job.finished?
    rescue StandardError => e
      job_consumer&.on_error(e)
      return if job.finished?
      job.retries < self.retry_limit ? job_consumer&.retry_job : job_consumer&.bury_job
    end
  end

  def consume
    EasyStalk::MethodDelegator.delegate(job.body, to: method(:call))
  end

  def call(**)
    raise NotImplementedError
  end

  def on_error(exception, logger: EasyStalk.logger)
    logger.error { exception.inspect }
  end

  def retry_job
    job.delayed_release
  end

  def bury_job
    job.bury
  end
end
