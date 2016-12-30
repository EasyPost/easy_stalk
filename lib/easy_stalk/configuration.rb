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
      self.default_tube_prefix = ENV['BEANSTALKD_TUBE_PREFIX'] || DEFAULT_TUBE_PREFIX
      self.default_priority = DEFAULT_PRI
      self.default_time_to_run = DEFAULT_TTR
      self.default_delay = DEFAULT_DELAY
      self.default_serializable_context_keys = DEFAULT_SERIALIZABLE_KEYS
      # FROM CLIENT
      self.beanstalkd_urls = ENV['BEANSTALKD_URLS']
      self.pool_size = ENV['BEANSTALKD_POOL_SIZE'] || DEFAULT_POOL_SIZE
      self.timeout_seconds = ENV['BEANSTALKD_TIMEOUT_SECONDS'] || DEFAULT_TIMEOUT_SECONDS
    end

    def default_tube_prefix=(tube_prefix)
      if String === tube_prefix
        @default_tube_prefix = tube_prefix
      else
        logger.warn "Invalid default_tube_prefix #{tube_prefix}. Using default."
        @default_tube_prefix = DEFAULT_TUBE_PREFIX
      end
    end
    def default_priority=(pri)
      if pri.respond_to?(:to_i) && pri.to_i >= 0 && pri.to_i < 2**32
        @default_priority = pri.to_i
      else
        logger.warn "Invalid default_priority #{pri}. Using default."
        @default_priority = DEFAULT_PRI
      end
    end
    def default_time_to_run=(ttr)
      if ttr.respond_to?(:to_i) && ttr.to_i > 0
        @default_time_to_run = ttr.to_i
      else
        logger.warn "Invalid default_time_to_run #{ttr}. Using default."
        @default_time_to_run = DEFAULT_TTR
      end
    end
    def default_delay=(delay)
      if delay.respond_to?(:to_i) && delay.to_i >= 0
        @default_delay = delay.to_i
      else
        logger.warn "Invalid default_delay #{delay}. Using default."
        @default_delay = DEFAULT_DELAY
      end
    end
    def default_serializable_context_keys=(serializable_keys)
      if Array === serializable_keys
        @default_serializable_context_keys = serializable_keys
      else
        logger.warn "Invalid default_serializable_context_keys #{serializable_keys}. Using default."
        @default_serializable_context_keys = DEFAULT_SERIALIZABLE_KEYS
      end
    end

    def beanstalkd_urls=(urls)
      @beanstalkd_urls = urls.split(",") if String === urls
      @beanstalkd_urls = urls if Array === urls
      @beanstalkd_urls.each { |url| url.strip! } if @beanstalkd_urls
    end

    def pool_size=(size)
      if size.respond_to?(:to_i) && size.to_i > 0
        @pool_size = size.to_i
      else
        logger.warn "Invalid pool_size #{size}. Using default."
        @pool_size = DEFAULT_POOL_SIZE
      end
    end

    def timeout_seconds=(seconds)
      if seconds.respond_to?(:to_i) && seconds.to_i > 0
        @timeout_seconds = seconds.to_i
      else
        logger.warn "Invalid timeout_seconds #{seconds}. Using default."
        @timeout_seconds = DEFAULT_TIMEOUT_SECONDS
      end
    end

  end
end
