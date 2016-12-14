require 'logger'

module EasyStalk
  class << self
    attr_writer :logger

    def logger
      @logger ||= Logger.new($stdout).tap do |log|
        log.progname = self.name
      end
    end
  end
end

require_relative 'easy_stalk/descendant_tracking'
require_relative 'easy_stalk/job'
require_relative 'easy_stalk/client'
require_relative 'easy_stalk/worker'
require_relative 'easy_stalk/test'
