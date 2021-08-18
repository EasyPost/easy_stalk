# frozen_string_literal: true

EasyStalk::Job = Class.new(SimpleDelegator) do
  AlreadyFinished = Class.new(StandardError)

  def self.encode(body)
    raise TypeError, "cannot serialize #{body.class} to a Hash" unless body.respond_to?(:to_h)

    JSON.dump(body.to_h)
  end

  attr_reader :client
  attr_reader :job
  attr_reader :body

  def initialize(job, client: EasyStalk::Client.default)
    @client = client
    @finished = false
    @buried = false
    @job = job
    @body ||= job.body.nil? ? nil : JSON.parse(job.body)
    super(job)
  end

  def delayed_release
    finish do
      backoff = ((3**(releases + 1)) / 2) * 60
      jitter = rand(0..backoff / 3)

      delay = backoff + jitter

      client.release(job, delay: delay)
    end
  end
  alias_method :delayed_retry, :delayed_release

  def releases
    client.releases(job) || 0
  end
  alias_method :retries, :releases

  def bury
    finish { client.bury(job) }
    self.buried = true
  end
  alias_method :dead, :bury

  def complete
    finish { client.complete(job) }
  end

  attr_reader :finished
  alias_method :finished?, :finished
  attr_reader :buried

  protected

  attr_writer :finished
  attr_writer :buried

  def finish
    raise AlreadyFinished if finished

    yield
    self.finished = true
  end
end
