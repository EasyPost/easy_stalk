# require 'easy_stalk/tasks'
# will give you the rake tasks

namespace :easy_stalk do
  # rake easy_stalk:work
  # rake easy_stalk:work[tubename1,tubename2]
  desc "Start EasyStalk workers on the passed in tubes"
  task :work => :environment do |task, args|
    ::Rails.application.eager_load! if defined?(::Rails)

    name_to_class = Hash[EasyStalk::Job.descendants.map { |cls| [cls.tube_name, cls] }]
    tubes = args.extras.map do |tube_name|
      raise "Invalid tube: #{tube_name}" unless name_to_class.include?(tube_name)
      name_to_class[tube_name]
    end

    EasyStalk::Worker.new().work(tubes)
  end

  task :work_jobs do |task, args|
    EasyStalk.logger.info("work_jobs is deprecated, please use work instead")
    Rake::Task["easy_stalk:work"].invoke
  end
end
