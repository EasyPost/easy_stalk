# frozen_string_literal: true

class EasyStalk::Test::Client
  Job = Struct.new(:body, :priority, :tube, :delay, :time_to_run, :releases, :buried)

  attr_reader :jobs

  def initialize(jobs: [])
    @jobs = jobs
  end

  def push(data, tube:, priority: EasyStalk.default_job_priority,
           delay: EasyStalk.default_job_delay, time_to_run: EasyStalk.default_job_time_to_run)
    jobs << Job.new(JSON.parse(JSON.dump(data)), priority, tube, delay, time_to_run, 0)
  end

  def pop(timeout:)
    next_job = jobs.shift
    return unless next_job

    yield next_job
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
