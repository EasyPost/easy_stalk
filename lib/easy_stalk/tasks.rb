# require 'easy_stalk/tasks'
# will give you the rake tasks

namespace :easy_stalk do
  # rake easy_stalk:work
  # rake easy_stalk:work[tubename1,tubename2]
  desc "Start EasyStalk workers on the passed in tubes"
  task :work, [:tubes] => :environment do |task, args|
    ::Rails.application.eager_load! if defined?(::Rails)

	def parse_tube_args_to_re(wildcard_arg)
	  matching_parts = wildcard_arg.split('*', -1).collect { |part| Regexp.escape(part) }
	  /\A#{matching_parts.join(".*")}\z/
	end

    name_to_class = Hash[EasyStalk::Job.descendants.map { |cls| [cls.tube_name, cls] }]

    # there are three ways to invoke this task:
    #
    #   - no arguments (run all tubes)
    #   - some tube names (run just those tubes)
    #   - some tube names prefixed with "-" (run all tubes except those)
    requested_tubes = args[:tubes].nil? ? [] : args[:tubes].split

    included_tubes_re, excluded_tubes_re = [], []

    requested_tubes.map do |c|
      if c.start_with? '-'
        excluded_tubes_re << parse_tube_args_to_re(c[1..-1])
      else
        included_tubes_re << parse_tube_args_to_re(c)
      end
    end

    if excluded_tubes_re.present? && included_tubes_re.present?
      raise StandardError.new("Can't use both exclude and include arguments")
    end

    tubes = if included_tubes_re.present?
              temp_tubes = []
              included_tubes_re.map do |re|
                temp_tubes += name_to_class.keys.select { |e| re.match(e) }
              end
              temp_tubes.uniq
            else
              Set.new(name_to_class.keys)
            end

    # remove the excluded tubes
    excluded_tubes_re.map do |re|
      tubes -= tubes.select { |e| re.match(e) }
    end

    # confirm that all requested tubes are defined
    Set.new([*included_tubes_re, *excluded_tubes_re]).each do |tube_re|
      unless name_to_class.keys.find{ |e| tube_re =~ e }
        raise StandardError.new("Invalid tube: #{tube_re}")
      end
    end

    EasyStalk::Worker.new().work(tubes.map { |tube| name_to_class[tube] })
  end
end
