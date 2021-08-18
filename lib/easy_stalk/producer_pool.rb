# frozen_string_literal: true

EasyStalk::ProducerPool = Class.new(SimpleDelegator) do
  def self.default
    @default ||= new
  end

  def initialize(
    servers: EasyStalk.servers.shuffle.to_enum.cycle,
    size: EasyStalk.pool_size,
    timeout: EasyStalk.timeout_seconds,
    max_age: EasyStalk.connection_max_age
  )
    servers = servers.to_enum unless servers.is_a?(Enumerable)

    @servers = servers
    @timeout = timeout
    @max_age = max_age
    @size = size

    super(create_pool(size: size, timeout: timeout, max_age: max_age, servers: servers))
  end

  protected

  def create_pool(size:, timeout:, max_age:, servers:)
    EzPool.new(size: size, max_age: max_age, timeout: timeout) do
      Beaneater.new(servers.next)
    end
  end
end
