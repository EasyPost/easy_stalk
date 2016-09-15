require 'interactor'
require_relative 'descendant_tracking'

module EasyStalk
  class Job
    include Interactor
    include EasyStalk::DescendantTracking

    SECONDS_IN_DAY = 24 * 60 * 60
    DEFAULT_PRI = 500 # 0 is highest
    DEFAULT_TTR = 120 # seconds
    DEFAULT_DELAY = 0 # seconds
    DEFAULT_SERIALIZABLE_KEYS = []

    def self.tube_name(tube=nil)
      if tube
        @tube_name = tube
      else
        tube_prefix + (@tube_name || name.split('::').last)
      end
    end

    def self.tube_prefix(prefix=nil)
      if prefix
        @tube_prefix = prefix
      else
        @tube_prefix || ENV['BEANSTALKD_TUBE_PREFIX'] || ""
      end
    end

    def self.priority(pri=nil)
      # integer < 2**32. 0 is highest
      if pri
        @priority = pri
      else
        @priority || DEFAULT_PRI
      end
    end

    def self.time_to_run(seconds=nil)
      # integer seconds to run this job
      if seconds
        @time_to_run = seconds
      else
        @time_to_run || DEFAULT_TTR
      end
    end

    def self.delay(seconds=nil)
      # integer seconds before job is in ready queue
      if seconds
        @delay = seconds
      else
        @delay || DEFAULT_DELAY
      end
    end

    def self.serializable_context_keys(*keys)
      if keys.size > 0
        @serializable_context_keys = keys
      else
        @serializable_context_keys || DEFAULT_SERIALIZABLE_KEYS
      end
    end

    def enqueue(beanstalk_connection, priority: nil, time_to_run: nil, delay: nil, delay_until: nil)
      tube = beanstalk_connection.tubes[self.class.tube_name]
      pri = priority || self.class.priority
      ttr = time_to_run || self.class.time_to_run
      delay = delay || self.class.delay

      if delay_until && DateTime === delay_until
        days = delay_until - DateTime.now
        delay = (days * SECONDS_IN_DAY).to_i
      end

      tube.put job_data, pri: pri, ttr: ttr, delay: [delay, 0].max
    end

    def job_data
      data = context.to_h.select { |key, value| self.class.serializable_context_keys.include? key }
      JSON.dump(data)
    end

    def call
      raise NotImplementedError
    end
  end
end

