# require 'easy_stalk/tasks'
# will give you the rake tasks

namespace :easy_stalk do
  # rake jobs:work[tubename]
  desc "Start EasyStalk workers on the passed in tubes"
  task :work_jobs => :environment do |task, args|
    tubes = args.extras
    EasyStalk::Job.descendants.each do |job|
      if tubes.include?(job.tube_name)
        EasyStalk::Worker.new().work_jobs(job)
      end
    end
  end
end
