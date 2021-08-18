# frozen_string_literal: true

class EasyStalk::Configuration
  MAX_PRIORITY = 2**32

  def initialize(connection_max_age: 300, default_job_delay: 0, default_job_priority: 500,
                 default_job_retry_limit: 5, default_job_time_to_run: 120, timeout_seconds: 10,
                 servers: nil, pool_size: 5)
    self.servers = servers
    self.connection_max_age = connection_max_age
    self.default_job_delay = default_job_delay
    self.default_job_priority = default_job_priority
    self.default_job_retry_limit = default_job_retry_limit
    self.default_job_time_to_run = default_job_time_to_run
    self.pool_size = pool_size
    self.timeout_seconds = timeout_seconds
  end

  def logger
    @logger ||= Logger.new(STDOUT).tap do |logger|
      logger.progname = Module.nesting.last.name
    end
  end
  attr_writer :logger

  attr_reader :default_job_priority
  def default_job_priority=(default_job_priority)
    integer = Integer(default_job_priority)
    unless integer < MAX_PRIORITY
      raise ArgumentError, "#{default_job_priority} is greater than #{MAX_PRIORITY}"
    end

    @default_job_priority = nonzero_integer!(default_job_priority)
  end

  attr_reader :default_job_time_to_run
  def default_job_time_to_run=(default_job_time_to_run)
    @default_job_time_to_run = nonzero_integer!(default_job_time_to_run)
  end

  attr_reader :default_job_delay
  def default_job_delay=(default_job_delay)
    integer = Integer(default_job_delay)
    raise ArgumentError, "#{integer} is not greater than or equal to 0" unless integer >= 0

    @default_job_delay = integer
  end

  attr_reader :default_job_retry_limit
  def default_job_retry_limit=(default_job_retry_limit)
    @default_job_retry_limit = nonzero_integer!(default_job_retry_limit)
  end

  # @return [String] default: ENV['BEANSTALKD_URLS'] as comma separated urls
  def servers
    @servers ||= ENV.fetch('BEANSTALKD_URLS', 'localhost:11300').split(',').map(&:strip)
  end
  attr_writer :servers

  attr_reader :pool_size
  def pool_size=(pool_size)
    @pool_size = nonzero_integer!(pool_size)
  end

  attr_reader :timeout_seconds
  def timeout_seconds=(timeout_seconds)
    @timeout_seconds = nonzero_integer!(timeout_seconds)
  end

  attr_reader :connection_max_age
  def connection_max_age=(connection_max_age)
    @connection_max_age = nonzero_integer!(connection_max_age)
  end

  private

  def nonzero_integer!(numeric)
    integer = Integer(numeric)
    raise ArgumentError, "#{integer} is not greater than 0" unless integer.positive?

    integer
  end
end
