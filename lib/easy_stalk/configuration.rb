module EasyStalk
  class Configuration
    attr_accessor :logger,
                  :worker_on_fail

    attr_reader :default_tube_prefix,
                :default_priority,
                :default_time_to_run,
                :default_delay,
                :default_serializable_context_keys,
                :beanstalkd_urls,
                :pool_size,
                :timeout_seconds

    DEFAULT_POOL_SIZE = 30
    DEFAULT_TIMEOUT_SECONDS = 10

    DEFAULT_TUBE_PREFIX = ""
    DEFAULT_PRI = 500 # 0 is highest
    DEFAULT_TTR = 120 # seconds
    DEFAULT_DELAY = 0 # seconds
    DEFAULT_SERIALIZABLE_KEYS = []

    def initialize
      @logger = Logger.new($stdout).tap do |log|
        log.progname = Module.nesting.last.name
      end
      @worker_on_fail = Proc.new { |job_class, job_body, ex|
        EasyStalk.logger.error "Worker for #{job_class} on tube[#{job_class.tube_name}] failed #{ex.message}"
        EasyStalk.logger.error ex.backtrace.join("\n")
      }

      # FROM JOB
      self.default_tube_prefix = ENV['BEANSTALKD_TUBE_PREFIX']
      self.default_priority = DEFAULT_PRI
      self.default_time_to_run = DEFAULT_TTR
      self.default_delay = DEFAULT_DELAY
      self.default_serializable_context_keys = DEFAULT_SERIALIZABLE_KEYS
      # FROM CLIENT
      self.beanstalkd_urls = ENV['BEANSTALKD_URLS']
      self.pool_size = ENV['BEANSTALKD_POOL_SIZE']
      self.timeout_seconds = ENV['BEANSTALKD_TIMEOUT_SECONDS']
    end

    def default_tube_prefix=(tube_prefix)
      @default_tube_prefix = String === tube_prefix ? tube_prefix : DEFAULT_TUBE_PREFIX
    end
    def default_priority=(pri)
      @default_priority = (pri.to_i > 0 && pri.to_i < 2**32) ? pri.to_i : DEFAULT_PRI
    end
    def default_time_to_run=(ttr)
      @default_time_to_run = ttr.to_i > 0 ? ttr.to_i : DEFAULT_TTR
     end
    def default_delay=(delay)
      @default_delay = delay.to_i > 0 ? delay.to_i : DEFAULT_DELAY
    end
    def default_serializable_context_keys=(serializable_keys)
      @default_serializable_context_keys = DEFAULT_SERIALIZABLE_KEYS
    end

    def beanstalkd_urls=(urls)
      @beanstalkd_urls = urls.split(",") if String === urls
      @beanstalkd_urls = urls if Array === urls
      @beanstalkd_urls.each { |url| url.strip! } if @beanstalkd_urls
    end

    def pool_size=(size)
      @pool_size = size.to_i > 0 ? size.to_i : DEFAULT_POOL_SIZE
    end

    def timeout_seconds=(seconds)
      @timeout_seconds = seconds.to_i > 0 ? seconds.to_i : DEFAULT_TIMEOUT_SECONDS
    end

  end
end
