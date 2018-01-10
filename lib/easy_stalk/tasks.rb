# require 'easy_stalk/tasks'
# will give you the rake tasks

namespace :easy_stalk do
  # rake easy_stalk:work
  # rake easy_stalk:work[tubename1,tubename2]
  desc "Start EasyStalk workers on the passed in tubes"
  task :work, [:tubes] => :environment do |task, args|
    ::Rails.application.eager_load! if defined?(::Rails)

    name_to_class = Hash[EasyStalk::Job.descendants.map { |cls| [cls.tube_name, cls] }]

    # there are three ways to invoke this task:
    #
    #   - no arguments (run all tubes)
    #   - some tube names (run just those tubes)
    #   - some tube names prefixed with "-" (run all tubes except those)
    requested_tubes = args[:tubes].nil? ? [] : args[:tubes].split

    included_tubes = requested_tubes.select { |c| !c.starts_with? '-' }
    excluded_tubes = requested_tubes.select { |c| c.starts_with? '-' }.map { |c| c[1..-1] }

    # build a set of candidate tubes to consume from.
    tubes = if included_tubes.empty?
              Set.new(name_to_class.keys)
            else
              Set.new(included_tubes)
            end

    # remove the excluded tubes
    tubes -= Set.new(excluded_tubes)

    # confirm that all requested tubes are defined
    Set.new([*tubes, *included_tubes, *excluded_tubes]).each do |tube|
      unless name_to_class.include?(tube.gsub(/$-/, ""))
        raise StandardError.new("Invalid tube: #{tube}")
      end
    end

    EasyStalk::Worker.new().work(tubes.map { |tube| name_to_class[tube] })
  end
end
