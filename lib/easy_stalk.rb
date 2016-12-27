require 'logger'

module EasyStalk
  class << self
    attr_writer :logger

    def logger
      configuration.logger
    end

    def configuration
      @configuration ||= configure
    end

    def configure
      @configuration = EasyStalk::Configuration.new
      yield(@configuration) if block_given?
    end
  end
end

require_relative 'easy_stalk/configuration'
require_relative 'easy_stalk/descendant_tracking'
require_relative 'easy_stalk/job'
require_relative 'easy_stalk/client'
require_relative 'easy_stalk/worker'
