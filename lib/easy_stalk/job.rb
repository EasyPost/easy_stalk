# frozen_string_literal: true

class EasyStalk::Job
  AlreadyFinished = Class.new(StandardError)

  def self.encode(body)
    raise ArgumentError, "body must be a Hash, not #{body.class}" unless body.respond_to?(:to_h)

    JSON.dump(body)
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
      # Compute a cubed backoff with a randomizer, skipping the first gen
      # [4,13,40,121,364,,,] mins + up to 1/3 of the time (randomly)
      minutes_to_delay = ((3**(job.stats.releases + 1)) / 2)
      seconds_to_delay = minutes_to_delay * 60
      randomizer = rand(0..seconds_to_delay / 3)

      client.release(job, delay: seconds_to_delay + randomizer)
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
    finish { job.delete }
  end

  attr_reader :finished
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
