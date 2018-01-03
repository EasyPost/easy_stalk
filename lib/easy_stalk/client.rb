require 'beaneater'
require 'ezpool'
require_relative 'job'

module EasyStalk
  class Client
    def self.instance
      @pool ||= create_pool
    end

    def self.enqueue(
      job,
      priority: nil,
      time_to_run: nil,
      delay: nil,
      delay_until: nil,
      tube_name: nil,
      **kwargs
    )
      instance.with do |conn|
        unless job.class < EasyStalk::Job
          raise ArgumentError, "Unable to enqueue non-EasyStalk Job"
        end

        job.enqueue(
          conn,
          priority: priority,
          time_to_run: time_to_run,
          delay: delay,
          delay_until: delay_until,
          tube_name: tube_name
        )
      end
    end

    def self.create_worker_pool(tubes, config=EasyStalk.configuration)
      raise "beanstalkd_urls not specified in config" unless config.beanstalkd_urls
      conns = config.beanstalkd_urls.shuffle
      i = 0
      # workers should only ever run a single thread to talk to beanstalk;
      # set the pool size t "1" and the timeout low to ensure that we don't
      # ever violate that
      instance = EzPool.new(size: 1, timeout: 1, max_age: config.worker_reconnect_seconds) do
        # rotate through the connections fairly
        client = Beaneater.new(conns[i])
        i = (i + 1) % conns.length
        client.tubes.watch!(*tubes)
        EasyStalk.logger.info "Watching tubes #{tubes} for jobs"
        client
      end
      instance
    end

    def self.create_pool(config = EasyStalk.configuration)
      raise "beanstalkd_urls not specified in config" unless config.beanstalkd_urls
      instance = EzPool.new(size: config.pool_size, timeout: config.timeout_seconds) do
        Beaneater.new(config.beanstalkd_urls.sample)
      end
      instance
    end

    private_class_method :create_pool
  end
end
