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

    private

    def self.create_pool(config = EasyStalk.configuration)
      raise "beanstalkd_urls not specified in config" unless config.beanstalkd_urls
      Beaneater.configure do |konfig|
      end
      instance = EzPool.new(size: config.pool_size, timeout: config.timeout_seconds) do
        Beaneater.new(config.beanstalkd_urls.sample)
      end
      instance
    end

    def self.create_worker_pool(tubes, config=EasyStalk.configuration)
      raise "beanstalkd_urls not specified in config" unless config.beanstalkd_urls
      Beaneater.configure do |konfig|
      end
      conns = config.beanstalkd_urls.shuffle
      i = 0
      instance = EzPool.new(size: config.pool_size, timeout: config.timeout_seconds, max_age: config.worker_reconnect_seconds) do
        # rotate through the connections fairly
        client = Beaneater.new(conns[i])
        i = (i + 1) % conns.length
        client.tubes.watch!(*tube_class_hash.keys)
        EasyStalk.logger.info "Watching tube #{beanstalk.tubes.watched} for jobs"
        client
      end
      instance
    end

  end
end
