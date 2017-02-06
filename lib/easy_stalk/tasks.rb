# require 'easy_stalk/tasks'
# will give you the rake tasks

namespace :easy_stalk do
  # rake easy_stalk:work
  # rake easy_stalk:work[tubename1,tubename2]
  desc "Start EasyStalk workers on the passed in tubes"
  task :work => :environment do |task, args|
    ::Rails.application.eager_load! if defined?(::Rails)

    tubes = if args.extras.size > 0
              EasyStalk::Job.descendants.select do |job|
                tubs.include?(job.tube_name)
              end
            end

    EasyStalk::Worker.new().work(tubes)
  end

  task :work_jobs do |task, args|
    EasyStalk.logger.info("work_jobs is deprecated, please use work instead")
    Rake::Task["easy_stalk:work"].invoke
  end
end
