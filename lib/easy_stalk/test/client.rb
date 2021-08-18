# frozen_string_literal: true

class EasyStalk::Test::Client
  include Enumerable

  Job = Struct.new(:body, :priority, :tube, :time_to_run, :delay, :releases)

  attr_reader :buried
  attr_reader :reserved
  attr_reader :completed
  attr_reader :delayed
  attr_reader :ready

  def initialize(ready: [], delayed: {}, buried: [], completed: [], reserved: [])
    @ready = ready
    @delayed = delayed
    @buried = buried
    @completed = completed
    @reserved = reserved
  end

  def push(data, tube:, priority: EasyStalk.default_job_priority,
           delay: EasyStalk.default_job_delay, time_to_run: EasyStalk.default_job_time_to_run)

    payload = Job.new(
      EasyStalk::Job.encode(data), priority, tube, time_to_run, delay, 0
    )
    ready << payload

    payload
  end

  def each(timeout:)
    return to_enum(:each, timeout: timeout) unless block_given?

    next_job = ready.shift
    return unless next_job

    reserved << next_job

    yield next_job
  end

  def releases(job)
    job.releases
  end

  def release(job, delay:)
    job.releases += 1
    delayed[job] = delay

    reserved.delete(job)
  end

  def bury(job)
    buried << job

    reserved.delete(job)
  end

  def complete(job)
    completed << job

    reserved.delete(job)
  end
end
