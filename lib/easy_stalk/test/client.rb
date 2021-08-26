# frozen_string_literal: true

EasyStalk::Test::Client = Struct.new(:ready, :delayed, :buried, :completed, :reserved) do
  include Enumerable

  Job = Struct.new(
    :body,
    :priority,
    :tube,
    :time_to_run,
    :delay,
    :releases,
    :client,
    :buried,
    :finished
  ) do
    alias_method :retries, :releases
    alias_method :finished?, :finished
    alias_method :buried?, :buried
    alias_method :dead?, :buried

    def release(delay: 0)
      self.releases += 1

      client.delayed[self] = delay
      client.reserved.delete(self)
      client.ready << self
    end

    def bury
      client.buried << self
      self.buried = true

      client.reserved.delete(self)
    end
    alias_method :dead, :bury

    def complete
      client.completed << self
      self.finished = true

      client.reserved.delete(self)
    end
  end

  def initialize(ready: [], delayed: {}, buried: [], completed: [], reserved: [])
    super(ready, delayed, buried, completed, reserved)
  end

  def tubes
    EasyStalk.tubes
  end

  def push(data, tube:, priority: EasyStalk.default_job_priority,
           delay: EasyStalk.default_job_delay, time_to_run: EasyStalk.default_job_time_to_run)

    payload = Job.new(
      EasyStalk::Job.encode(data),
      priority,
      tube,
      time_to_run,
      delay,
      0,
      self,
      false,
      false
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

  def release(job, delay: 0)
    job.release(delay: delay)
  end

  def bury(job)
    job.bury
  end

  def complete(job)
    job.complete
  end
end
