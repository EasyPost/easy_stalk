require 'beaneater'
require 'ezpool'
require_relative 'job'

module EasyStalk
  class Client
    def self.instance
      @pool ||= create_pool
    end

    def self.enqueue(job, priority: nil, time_to_run: nil, delay: nil, delay_until: nil)
      instance.with do |conn|
        raise ArgumentError, "Unable to enqueue non-EasyStalk Job" unless job.class < EasyStalk::Job
        job.enqueue conn, priority: priority, time_to_run: time_to_run, delay: delay, delay_until: delay_until
      end
    end

    def self.create_pool(config = EasyStalk.configuration)
      raise "beanstalkd_urls not specified in config" unless config.beanstalkd_urls
      Beaneater.configure do |config|
        # config.default_put_delay   = 0
        # config.default_put_pri     = 65536
        # config.default_put_ttr     = 120
        # config.job_parser          = lambda { |body| body }
        # config.job_serializer      = lambda { |body| body }
        # config.beanstalkd_url      = 'localhost:11300'
      end
      instance = EzPool.new(size: config.pool_size, timeout: config.timeout_seconds) do
        Beaneater.new(config.beanstalkd_urls.sample)
      end
      instance
    end

  end
end
