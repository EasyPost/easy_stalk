class EasyStalk::Client
  class << self
    def default
      @default ||= new(EasyStalk::ProducerPool.default, EasyStalk::ConsumerPool.default)
    end

    attr_writer :default
  end

  TubeEmpty = Class.new(StandardError)

  attr_reader :consumer
  attr_reader :producer

  def initialize(producer: EasyStalk::ProducerPool.default,
                 consumer: EasyStalk::ConsumerPool.default)
    @producer = producer
    @consumer = consumer
  end

  def push(data, priority:, tube:, delay:, time_to_run:)
    producer_pool.with do |connection|
      connection
        .tubes
        .fetch(EasyStalk.tube_name(tube))
        .put(EasyStalk::Job.encode(data), pri: priority, ttr: time_to_run, delay: [delay, 0].max)
    end
  end

  def pop
    # This Timeout block is to catch the case where the beanstalkd
    # may zone out and forget to reserve a job for us. We intentionally
    # don't catch Timeout::Error; if that fires, then beanstalkd is
    # messed up, and our best bet is probably to exit noisily

    consumer_pool.with do |connection|
      job = Timeout.timeout(reserve_timeout * 4) { connection.tubes.reserve(reserve_timeout) }
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
  end
end
