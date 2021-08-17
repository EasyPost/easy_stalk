# frozen_string_literal: true

class EasyStalk::ProducerPool
  def self.default
    @default ||= create
  end

  def self.create(
    servers: EasyStalk.servers.shuffle.to_enum.cycle,
    size: EasyStalk.pool_size,
    timeout: EasyStalk.timeout_seconds
  )
    EzPool.new(size: size, timeout: timeout) do
      EasyStalk::Client.new(Beaneater.new(servers.next))
    end
  end
end
