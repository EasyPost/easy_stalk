require 'beaneater'
require 'ezpool'
require_relative 'job'

module EasyStalk
  class Client
    DEFAULT_POOL_SIZE = 30
    DEFAULT_TIMEOUT_SECONDS = 10

    def self.instance
      @pool ||= create_pool
    end

    def self.enqueue(job, priority: nil, time_to_run: nil, delay: nil, delay_until: nil)
      instance.with do |conn|
        raise ArgumentError, "Unable to enqueue non-EasyStalk Job" unless job.class < EasyStalk::Job
        job.enqueue conn, priority: priority, time_to_run: time_to_run, delay: delay, delay_until: delay_until
      end
    end

    def self.create_pool
      raise "ENV['BEANSTALKD_URLS'] not specified" unless String === ENV['BEANSTALKD_URLS']
      Beaneater.configure do |config|
        # config.default_put_delay   = 0
        # config.default_put_pri     = 65536
        # config.default_put_ttr     = 120
        # config.job_parser          = lambda { |body| body }
        # config.job_serializer      = lambda { |body| body }
        # config.beanstalkd_url      = 'localhost:11300'
      end
      beanstalkd = nil
      pool_size = DEFAULT_POOL_SIZE
      if ENV['BEANSTALKD_POOL_SIZE'].to_i > 0
        pool_size = ENV['BEANSTALKD_POOL_SIZE'].to_i
      end
      timeout_seconds = DEFAULT_TIMEOUT_SECONDS
      if ENV['BEANSTALKD_TIMEOUT_SECONDS'].to_i > 0
        timeout_seconds = ENV['BEANSTALKD_TIMEOUT_SECONDS'].to_i
      end
      instance = EzPool.new(size: pool_size, timeout: timeout_seconds) do
        Beaneater.new(random_beanstalkd_url)
      end
      instance
    end

    def self.beanstalkd_urls
      @urls ||= ENV['BEANSTALKD_URLS'].split(",")
    end

    def self.random_beanstalkd_url
      beanstalkd_urls.sample.strip
    end

  end
end
