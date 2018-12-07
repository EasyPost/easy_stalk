require 'logger'

module EasyStalk
  VERSION = '0.1.3'

  class << self
    attr_writer :logger

    def logger
      configuration.logger
    end

    def configuration
      @configuration ||= configure
    end

    def configure
      config = EasyStalk::Configuration.new
      yield(config) if block_given?
      @configuration = config
    end
  end
end

require_relative 'easy_stalk/configuration'
require_relative 'easy_stalk/job'
require_relative 'easy_stalk/client'
require_relative 'easy_stalk/worker'
