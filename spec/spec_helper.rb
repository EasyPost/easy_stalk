# frozen_string_literal: true

if ENV.key?('COVERAGE')
  require 'simplecov'
  SimpleCov.start
end

require_relative '../lib/easy_stalk'
require_relative '../lib/easy_stalk/test'

EasyStalk.logger = ENV.key?('DEBUG') ? Logger.new(STDOUT) : Logger.new(nil)

Bundler.require(:test)
require 'securerandom'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true
  config.default_formatter = 'doc' if config.files_to_run.one?
  config.order = :random
  config.before { EasyStalk.tube_consumers.clear }
  config.around do |e|
    skip('no beanstalk configured') if e.metadata[:integration] && !ENV.key?('BEANSTALKD_URLS')
    e.run
  end

  Kernel.srand config.seed
end
