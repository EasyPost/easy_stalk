# frozen_string_literal: true

EasyStalk::ProducerPool = Class.new(SimpleDelegator) do
  def self.default
    @default ||= new
  end

  def initialize(
    servers: EasyStalk.servers.shuffle.to_enum.cycle,
    size: EasyStalk.pool_size,
    timeout: EasyStalk.timeout_seconds
  )
    super(EzPool.new(size: size, timeout: timeout) { Beaneater.new(servers.next) })
  end
end
