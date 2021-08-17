# frozen_string_literal: true

EasyStalk::Consumer = Struct.new(:job) do
  SECONDS_IN_DAY = 24 * 60 * 60

  class << self
    def tubes
      @tubes ||= Set.new
    end

    def assign(*assignments, prefix: EasyStalk.tube_prefix)
      assignments.each do |tube|
        tube_name = prefix + tube
        existing_consumer = EasyStalk.tube_consumers[tube_name]
        raise ArgumentError, "#{existing_consumer} already assigned to #{tube}" if existing_consumer

        EasyStalk.tube_consumers[tube_name] = self
        tubes << tube_name
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

    def push(client: EasyStalk::Client.default, priority: self.class.priority,
             time_to_run: self.class.time_to_run, delay: self.class.delay, delay_until: nil,
             tube: self.class.default_tube, data:)
      if delay_until
        raise ArgumentError, 'cannot specify delay and delay_until' if delay

        days = delay_until - Time.now
        delay = (days * SECONDS_IN_DAY).to_i
      end

      payload = serialize(data)

      client.push(payload, tube: tube, priority: priority, time_to_run: time_to_run, delay: delay)
    end

    def serialize(data)
      EasyStalk::MethodDelegator.serialize(data, specification: method(:call))
    end

    def consume(job)
      job_consumer = new(job)
      job_consumer.consume

      job.complete
    rescue StandardError => e
      job_consumer&.on_error(e)
    end
  end

  def consume
    EasyStalk::MethodDelegator.delegate(job.body, to: method(:call))
  end

  def call(*, **)
    raise NotImplementedError
  end

  def on_error(exception, logger: EasyStalk.logger)
    logger.error { exception.inspect }

    return if job.finished?

    job.retries < self.class.retry_limit ? job.delayed_release : job.dead
  end
end
