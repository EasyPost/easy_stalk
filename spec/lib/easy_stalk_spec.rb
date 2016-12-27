require 'spec_helper'

describe "EasyStalk" do
  describe "#configure" do
    specify "properly sets things" do
      doublog = double
      EasyStalk.configure do |config|
        config.logger = doublog
      end
      expect(doublog).to be EasyStalk.logger
      EasyStalk.configure
    end
  end
end
