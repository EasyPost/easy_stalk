# frozen_string_literal: true

# require 'easy_stalk/tasks'
# will give you the rake tasks

namespace :easy_stalk do
  # rake easy_stalk:work
  # rake easy_stalk:work[tubename1,tubename2]
  desc 'Start EasyStalk workers on the passed in tubes'
  task :work, [:tubes] => :environment do |_task, args|
    ::Rails.application.eager_load! if defined?(::Rails)

    EasyStalk::Dispatcher.dispatch(
      client: EasyStalk::Client.new(
        consumer: EasyStalk::ConsumerPool.new(tubes: args[:tubes])
      )
    )
  end
end
