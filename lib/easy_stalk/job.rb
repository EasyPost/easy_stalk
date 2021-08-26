# frozen_string_literal: true

class EasyStalk::Job < Struct.new(:client, :job, :tube, :body, :finished, :buried)
  AlreadyFinished = Class.new(StandardError)

  ExponentialBackoff = Struct.new(:base, :factor, :jitter) do
    def call(releases:)
      backoff = factor * base**(releases + 1)

      backoff + rand(0..(backoff * jitter))
    end
  end

  DEFAULT_DELAY = ExponentialBackoff.new(3, 3, 0.5)

  def self.encode(body)
    raise TypeError, "cannot serialize #{body.class} to a Hash" unless body.respond_to?(:to_h)

    JSON.dump(body.to_h)
  end

  def self.decode(body)
    body.nil? ? nil : JSON.parse(body)
  end

  def initialize(job, client: EasyStalk::Client.default)
    super(
      client,
      job,
      job.tube,
      self.class.decode(job.body),
      false,
      false,
    )
  end

  def delayed_release(delay: DEFAULT_DELAY)
    delay_seconds = delay.respond_to?(:call) ? delay.call(releases: releases) : delay
    finish { client.release(job, delay: delay_seconds) }
  end
  alias delayed_retry delayed_release

  def releases
    client.releases(job) || 0
  end
  alias retries releases

  def release
    finish { client.release(job) }
  end

  def bury
    finish { client.bury(job) }
    self.buried = true
  end
  alias dead bury

  def complete
    finish { client.complete(job) }
  end

  attr_reader :finished, :buried
  alias finished? finished
  alias dead? buried
  alias buried? buried

  protected

  attr_writer :finished, :buried

  def finish
    raise AlreadyFinished if finished

    yield
    self.finished = true
  end
end
