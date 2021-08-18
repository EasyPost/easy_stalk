# frozen_string_literal: true

# stdlib
require 'json'
require 'logger'
require 'timeout'
require 'set'
require 'delegate'

# deps
require 'beaneater'
require 'ezpool'

module EasyStalk
  MAX_PRIORITY = 2**32

  class << self
    def tube_consumers
      @tube_consumers ||= {}
    end

    def consumers
      tube_consumers.values.uniq
    end

    def tubes
      tube_consumers.keys
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

    def nonzero_integer!(numeric)
      integer = Integer(numeric)
      raise ArgumentError, "#{integer} is not greater than 0" unless integer.positive?

      integer
    end
  end
end

EasyStalk.connection_max_age = 300
EasyStalk.default_job_delay = 0
EasyStalk.default_job_priority = 500
EasyStalk.default_job_retry_limit = 5
EasyStalk.default_job_time_to_run = 120
EasyStalk.pool_size = 5
EasyStalk.timeout_seconds = 10

require_relative 'easy_stalk/producer_pool'
require_relative 'easy_stalk/consumer_pool'
require_relative 'easy_stalk/client'
require_relative 'easy_stalk/consumer'
require_relative 'easy_stalk/dispatcher'
require_relative 'easy_stalk/job'
require_relative 'easy_stalk/method_delegator'
