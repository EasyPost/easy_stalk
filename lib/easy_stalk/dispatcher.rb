# frozen_string_literal: true

EasyStalk::Dispatcher = Struct.new(:client, :reserve_timeout) do
  DEFAULT_SIGNALS = %w[QUIT TERM INT].freeze
  DEFAULT_RESERVE_TIMEOUT = 3 # seconds

  attr_reader :shutdown

  def self.call(
    client: EasyStalk::Client.default,
    reserve_timeout: DEFAULT_RESERVE_TIMEOUT,
    shutdown_signals: DEFAULT_SIGNALS
  )
    dispatcher = new(reserve_timeout: reserve_timeout, client: client)
    dispatcher.shutdown_on(signals: shutdown_signals).run
  end

  def initialize(reserve_timeout: DEFAULT_RESERVE_TIMEOUT, client: EasyStalk::Client.default)
    super(client, reserve_timeout)
  end

  def shutdown_on(signals:)
    signals.each { |signal| trap(signal, &method(:shutdown!)) }

    self
  end

  def shutdown!
    EasyStalk.logger.info { 'Shutting Down...' }
    self.shutdown = true
  end

  def run
    EasyStalk.logger.info { "Watching tubes #{client.tubes.inspect} for jobs" }

    jobs = client.each(timeout: reserve_timeout)

    until shutdown
      job = jobs.next

      next if job.nil?

      EasyStalk
        .tube_consumers
        .fetch(job.tube)
        .consume(job)
    end
  rescue StopIteration
    EasyStalk.logger.warn { 'Ran out of work' }
  ensure
    EasyStalk.logger.info do
      "Dispatcher assigned to #{client.tubes.inspect} has been stopped"
    end
  end

  private

  attr_writer :shutdown
end
