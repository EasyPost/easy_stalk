ENV['RAKE_ENV'] = 'test'

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "easy_stalk"

require 'support/mock_beaneater'
require 'easy_stalk/test'

RSpec.configure do |config|
  config.color = true
  config.tty = true
  config.order = "random"
end
