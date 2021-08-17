# frozen_string_literal: true

class EasyStalk::Job
  AlreadyFinished = Class.new(StandardError)

  def self.encode(body)
    raise TypeError, "cannot serialize #{body.class} to a Hash" unless body.respond_to?(:to_h)

    JSON.dump(body.to_h)
  end

  attr_reader :client

  def initialize(job, client: EasyStalk::Client.default)
    @job = job
    @client = client
    @finished = false
    @buried = false
  end

  def body
    @body ||= JSON.parse(job.body)
  end

  def delayed_release
    finish do
      backoff = ((3**(releases + 1)) / 2) * 60
      jitter = rand(0..backoff / 3)

      delay = backoff + jitter

      client.release(job, delay: delay)
    end
  end
  alias delayed_retry delayed_release

  def releases
    client.releases(job)
  end
  alias retries releases

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

  private

  attr_reader :job
  attr_writer :finished
  attr_writer :buried

  def finish
    raise AlreadyFinished if finished

    yield
    self.finished = true
  end
end
