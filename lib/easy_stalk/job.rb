require 'interactor'
require_relative 'descendant_tracking'

module EasyStalk
  class Job
    include Interactor
    include EasyStalk::DescendantTracking

    SECONDS_IN_DAY = 24 * 60 * 60
    DEFAULT_SERIALIZABLE_CONTEXT_KEYS = []

    def self.tube_name(tube=nil)
      @tube_name = tube
    end
    def self.get_tube_name
      get_tube_prefix + (@tube_name || name.split('::').last)
    end

    def self.tube_prefix(prefix=nil)
      define_singleton_method :get_tube_prefix do
        prefix
      end
    end
    def self.get_tube_prefix
      EasyStalk.configuration.default_tube_prefix
    end

    def self.priority(pri=nil)
      # integer < 2**32. 0 is highest
      define_singleton_method :get_priority do
        pri
      end
    end
    def self.get_priority
      EasyStalk.configuration.default_priority
    end

    def self.time_to_run(seconds=nil)
      # integer seconds to run this job
      define_singleton_method :get_time_to_run do
        seconds
      end
    end
    def self.get_time_to_run
      EasyStalk.configuration.default_time_to_run
    end

    def self.delay(seconds=nil)
      # integer seconds before job is in ready queue
      define_singleton_method :get_delay do
        seconds
      end
    end
    def self.get_delay
      EasyStalk.configuration.default_delay
    end

    def self.retry_times(attempts=nil)
      # max number of times to retry job before burying
      define_singleton_method :get_retry_times do
        attempts
      end
    end
    def self.get_retry_times
      EasyStalk.configuration.default_retry_times
    end

    def self.serializable_context_keys(*keys)
      define_singleton_method :get_serializable_context_keys do
        keys
      end
    end
    def self.get_serializable_context_keys
      DEFAULT_SERIALIZABLE_CONTEXT_KEYS
    end

    def enqueue(beanstalk_connection, priority: nil, time_to_run: nil, delay: nil, delay_until: nil)
      tube = beanstalk_connection.tubes[self.class.get_tube_name]
      pri = priority || self.class.get_priority
      ttr = time_to_run || self.class.get_time_to_run
      delay = delay || self.class.get_delay

      if delay_until && DateTime === delay_until
        days = delay_until - DateTime.now
        delay = (days * SECONDS_IN_DAY).to_i
      end

      tube.put job_data, pri: pri, ttr: ttr, delay: [delay, 0].max
    end

    def job_data
      data = context.to_h.select { |key, value| self.class.get_serializable_context_keys.include? key }
      JSON.dump(data)
    end

    def call
      raise NotImplementedError
    end
  end
end

