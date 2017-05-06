# require 'easy_stalk/tasks'
# will give you the rake tasks

namespace :easy_stalk do
  # rake easy_stalk:work
  # rake easy_stalk:work[tubename1,tubename2]
  desc "Start EasyStalk workers on the passed in tubes"
  task :work => :environment do |task, args|
    ::Rails.application.eager_load! if defined?(::Rails)

    job_classes     = EasyStalk::Job.descendants
    all_tubes       = job_classes.map{ |cls| cls.tube_name }
    selected_tubes  = arg.extras

    selected_tubes.each do |tube|
      raise "Invalid tube: #{tube}" unless all_tubes.include?(tube)
    end

    tubes = if selected_tubes.size > 0
              job_classes.select { |job| args.extras.include?(job.tube_name) }
            end

    EasyStalk::Worker.new().work(tubes)
  end

  task :work_jobs do |task, args|
    EasyStalk.logger.info("work_jobs is deprecated, please use work instead")
    Rake::Task["easy_stalk:work"].invoke
  end
end
