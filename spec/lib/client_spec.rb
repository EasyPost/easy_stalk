require 'spec_helper'

describe EasyStalk::Client do

  describe "class << self" do
    subject { described_class }
    before(:each) do
      EasyStalk::Client.instance_variable_set :@pool, nil
      EasyStalk::Client.instance_variable_set :@urls, nil
    end
    after(:all) do
      EasyStalk::Client.instance_variable_set :@pool, nil
      EasyStalk::Client.instance_variable_set :@urls, nil
    end

    it 'uses the env specified values instead of default' do
      urls = "test1.com:11300,test2.com:11300,test3.com:11300"
      stub_const "ENV", { "BEANSTALKD_POOL_SIZE" => "12", "BEANSTALKD_TIMEOUT_SECONDS" => "21",
                          "BEANSTALKD_URLS" => urls}
      expect(subject.instance.instance_variable_get(:@size)).to eq 12
      expect(subject.instance.instance_variable_get(:@timeout)).to eq 21
      expect(subject.beanstalkd_urls).to eq urls.split(",")
      expect(subject.beanstalkd_urls).to include(subject.random_beanstalkd_url)
    end

    it 'enqueues only EasyStalk Jobs' do
      stub_const "ENV", { "BEANSTALKD_POOL_SIZE" => "12", "BEANSTALKD_TIMEOUT_SECONDS" => "21",
                          "BEANSTALKD_URLS" => "::mocked::"}
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
