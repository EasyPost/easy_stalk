# frozen_string_literal: true

EasyStalk::ConsumerPool = Class.new(SimpleDelegator) do
  def self.default
    @default ||= new
  end

  attr_reader :servers
  attr_reader :timeout
  attr_reader :max_age
  attr_reader :tubes

  # @param tubes [Array] List of tubes to connection to
  # @param servers [Enumerable] Enumerator that produces the next host to connection to.
  # @param max_age [Array] Duration of connection to a given host
  def initialize(
    tubes: EasyStalk.tubes,
    servers: EasyStalk.servers.shuffle.to_enum.cycle,
    timeout: 5, # seconds
    max_age: EasyStalk.connection_max_age
  )
    servers = servers.to_enum unless servers.is_a?(Enumerable)

    @servers = servers
    @timeout = timeout
    @max_age = max_age
    @tubes = tubes

    super(create_pool(
      servers: servers, timeout: timeout, max_age: max_age, tubes: tubes
    ))
  end

  protected

  # workers should only ever run a single thread to talk to beanstalk;
  # set the pool size to "1" and the timeout low to ensure that we don't
  # ever violate that
  def create_pool(tubes:, timeout:, max_age:, servers:)
    EzPool.new(
      size: 1,
      timeout: timeout,
      max_age: max_age,
      disconnect_with: lambda(&:close)
    ) do
      Beaneater.new(servers.next).tap do |connection|
        connection.tubes.watch!(*tubes)
      end
    end
  end
end
