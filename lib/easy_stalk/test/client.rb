# frozen_string_literal: true

class EasyStalk::Test::Client
  Job = Struct.new(:body, :priority, :tube, :delay, :time_to_run, :releases, :buried)

  def initialize(jobs: [])
    @jobs = jobs
  end

  def push(body, priority:, tube:, delay:, time_to_run:)
    jobs << Job.new(body, priority, tube, delay, time_to_run, 0)
  end

  def pop
    jobs.shift
  end

  def releases(job)
    job.releases
  end

  def release(job, delay:)
    job.releases += 1
    job.delay = delay
  end

  def bury(job)
    job.buried = true
  end
end
