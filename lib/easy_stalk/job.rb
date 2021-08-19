# frozen_string_literal: true

class EasyStalk::Job < Struct.new(
  :client, :job, :tube, :body, :finished, :buried, keyword_init: true
)
  AlreadyFinished = Class.new(StandardError)

  ExponentialBackoff = lambda { |releases:|
    backoff = ((3**(releases + 1)) / 2) * 60
    jitter = rand(0..backoff / 3)

    backoff + jitter
  }

  def self.encode(body)
    raise TypeError, "cannot serialize #{body.class} to a Hash" unless body.respond_to?(:to_h)

    JSON.dump(body.to_h)
  end

  def initialize(job, client: EasyStalk::Client.default)
    body = job.body.nil? ? nil : JSON.parse(job.body)

    super(
      job: job,
      buried: false,
      finished: false,
      body: body,
      client: client,
      tube: job.tube
    )
  end

  def delayed_release(delay: ExponentialBackoff)
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

  attr_reader :finished
  alias finished? finished
  attr_reader :buried
  alias dead? buried
  alias buried? buried

  protected

  attr_writer :finished
  attr_writer :buried

  def finish
    raise AlreadyFinished if finished

    yield
    self.finished = true
  end
end
