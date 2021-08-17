# frozen_string_literal: true

class EasyStalk::ConsumerPool
  def self.default
    @default ||= new
  end

  attr_reader :max_age
  attr_reader :servers
  attr_reader :tubes
  attr_reader :pool

  # @param tubes [Array] List of tubes to connection to
  # @param servers [Enumerable] Enumerator that produces the next host to connection to.
  # @param max_age [Array] Duration of connection to a given host
  def initialize(tubes: EasyStalk.tubes,
                 servers: EasyStalk.servers.shuffle.to_enum.cycle,
                 max_age: EasyStalk.host_connection_max_age)
    @tubes = tubes.map { |tube| EasyStalk.tube_name(tube) }
    @max_age = max_age
    @servers = servers
    @pool = set_pool
  end

  protected

  # workers should only ever run a single thread to talk to beanstalk;
  # set the pool size to "1" and the timeout low to ensure that we don't
  # ever violate that
  def set_pool
    EzPool.new(size: 1, timeout: 1, max_age: max_age, disconnect_with: lambda(&:close)) do
      Beaneater.new(servers.next).tap do |connection|
        connection.tubes.watch!(*connection_tubes)
      end
    end
  end
end
