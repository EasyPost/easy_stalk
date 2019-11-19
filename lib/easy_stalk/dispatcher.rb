# frozen_string_literal: true

class EasyStalk::Dispatcher
  attr_reader :shutdown

  def self.dispatch(client: EasyStalk::Client.default, reserve_timeout: 3)
    worker = new(tubes, reserve_timeout: reserve_timeout, client: client)
    worker.register_signal_handlers
    worker.start
  end

  def initialize(reserve_timeout:, client:)
    @client = client
    @reserve_timeout = reserve_timeout
    @shutdown = false
  end

  def register_signal_handlers
    trap('QUIT', &method(:shutdown!))
    trap('TERM', &method(:shutdown!))
    trap('INT', &method(:shutdown!))
  end

  def shutdown!
    EasyStalk.logger.info { 'Shutting Down...' }
    self.shutdown = true
  end

  def start
    EasyStalk.logger.info { "Watching tubes #{tubes.inspect} for jobs" }

    until shutdown
      client.pop(timeout: reserve_timeout) do |job|
        EasyStalk.consumers.fetch(job.tube).dispatch(job)
      end
    end

    EasyStalk.logger.info { "Dispatcher assigned to #{tubes.inspect} has been stopped" }
  end

  private

  attr_writer :shutdown
end
