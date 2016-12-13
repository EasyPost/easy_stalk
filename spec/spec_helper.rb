ENV['RAKE_ENV'] = 'test'

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "easy_stalk"

require 'support/mock_beaneater'
require 'support/immediate_job_runner'
require 'support/job'

RSpec.configure do |config|
  config.color = true
  config.tty = true
  config.order = "random"
end
