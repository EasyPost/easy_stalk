# frozen_string_literal: true

class EasyStalk::ProducerPool
  def self.default
    @default ||= create
  end

  def self.create(servers: EasyStalk.configuration.beanstalkd_urls,
                  size: EasyStalk.configuration.pool_size,
                  timeout: EasyStalk.configuration.timeout_seconds)

    EzPool.new(size: size, timeout: timeout) do
      EasyStalk::Client.new(Beaneater.new(servers.sample))
    end
  end
end
