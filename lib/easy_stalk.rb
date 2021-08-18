# frozen_string_literal: true

# stdlib
require 'json'
require 'logger'
require 'timeout'
require 'set'
require 'delegate'

# deps
require 'beaneater'
require 'ezpool'

module EasyStalk
  class << self
    def logger
      configuration.logger
    end

    def tube_consumers
      @tube_consumers ||= {}
    end

    def consumers
      tube_consumers.values.uniq
    end

    def tubes
      tube_consumers.keys
    end

    def configuration
      @configuration ||= configure
    end

    def configure
      config = EasyStalk::Configuration.new
      yield(config) if block_given?
      @configuration = config
    end

    def respond_to_missing?(name, include_private = false)
      configuration.respond_to?(name, include_private)
    end

    def method_missing(method, *args, &block)
      if configuration.respond_to?(method)
        configuration.public_send(method, *args, &block)
      else
        super
      end
    end
  end
end

require_relative 'easy_stalk/producer_pool'
require_relative 'easy_stalk/consumer_pool'
require_relative 'easy_stalk/client'
require_relative 'easy_stalk/configuration'
require_relative 'easy_stalk/consumer'
require_relative 'easy_stalk/dispatcher'
require_relative 'easy_stalk/job'
require_relative 'easy_stalk/method_delegator'
