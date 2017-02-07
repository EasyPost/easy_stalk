require 'spec_helper'
require 'ezpool'

describe EasyStalk::Client do

  describe "class << self" do
    subject { described_class }
    before do
      EasyStalk.configure do |config|
        config.pool_size = 12
        config.timeout_seconds = 21
        config.beanstalkd_urls = "::mocked::"
      end
    end
    after do
      EasyStalk.configure
      EasyStalk::Client.instance_variable_set :@pool, nil
    end

    it 'enqueues only EasyStalk Jobs' do
      mocked_client = EzPool.new(size: 2, timeout: 30) { EasyStalk::MockBeaneater.new }
      expect(EzPool).to receive(:new).and_return mocked_client
      class NonEasyStalkJob; end
      expect { subject.enqueue(NonEasyStalkJob.new) }.to raise_error ArgumentError
      class TestBeanstalkJob < EasyStalk::Job; end
      job = TestBeanstalkJob.new
      expect(job).to receive(:enqueue)
      expect { subject.enqueue(job) }.to_not raise_error
    end

  end
end
