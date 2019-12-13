# frozen_string_literal: true

class EasyStalk::Test::InlineClient < EasyStalk::Test::Client
  def push(data, **)
    job = super

    EasyStalk.tube_consumers.fetch(job.tube).consume(
      EasyStalk::Job.new(job, client: client)
    )
  end
end
