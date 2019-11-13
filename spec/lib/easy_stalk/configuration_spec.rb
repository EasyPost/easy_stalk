require 'spec_helper'

describe EasyStalk::Configuration do
  describe "#logger" do
    specify "gets the default logger" do
      expect(subject.logger).to be_a Logger
      expect(subject.logger.progname).to eq EasyStalk.name
    end
  end
  describe "#logger=" do
    specify "sets the default logger" do
      subject.logger = "cat"
      expect(subject.logger).to eq "cat"
    end
  end

  describe "#default_worker_on_fail" do
    specify "gets the default logger" do
      expect(subject.default_worker_on_fail).to be_a Proc
    end
  end
  describe "#default_worker_on_fail=" do
    specify "sets the default on_fail proc" do
      subject.default_worker_on_fail = "cat"
      expect(subject.default_worker_on_fail).to eq "cat"
    end
  end

  describe "#default_tube_prefix" do
    specify "gets default if not provided" do
      expect(subject.default_tube_prefix).to eq described_class::DEFAULT_TUBE_PREFIX
    end
    specify "gets env if set" do
      stub_const "ENV", { "BEANSTALKD_TUBE_PREFIX" => "foo."}
      expect(subject.default_tube_prefix).to eq "foo."
    end
  end
  describe "#default_tube_prefix=" do
    specify "overrides default" do
      subject.default_tube_prefix = "bar.baz."
      expect(subject.default_tube_prefix).to eq "bar.baz."
    end
  end

  describe "#default_priority" do
    specify "gets default if not provided" do
      expect(subject.default_priority).to eq described_class::DEFAULT_PRI
    end
  end
  describe "#default_priority=" do
    specify "only accepts valid priorities" do
      # integer < 2**32. 0 is highest
      subject.default_priority = 1
      expect(subject.default_priority).to eq 1
      expect(subject.logger).to receive(:warn) { }
      subject.default_priority = -1
      expect(subject.default_priority).to eq described_class::DEFAULT_PRI
      expect(subject.logger).to receive(:warn) { }
      subject.default_priority = 2**32 + 1 # 2**32 is beanstalk max
      expect(subject.default_priority).to eq described_class::DEFAULT_PRI
    end
  end

  describe "#default_time_to_run" do
    specify "gets default if not provided" do
      expect(subject.default_time_to_run).to eq described_class::DEFAULT_TTR
    end
  end
  describe "#default_time_to_run=" do
    specify "only accepts positive numbers" do
      subject.default_time_to_run = 1
      expect(subject.default_time_to_run).to eq 1
      expect(subject.logger).to receive(:warn) { }
      subject.default_time_to_run = 0
      expect(subject.default_time_to_run).to eq described_class::DEFAULT_TTR
      expect(subject.logger).to receive(:warn) { }
      subject.default_time_to_run = nil
      expect(subject.default_time_to_run).to eq described_class::DEFAULT_TTR
      expect(subject.logger).to receive(:warn) { }
      subject.default_time_to_run = -5
      expect(subject.default_time_to_run).to eq described_class::DEFAULT_TTR
      expect(subject.logger).to receive(:warn) { }
      subject.default_time_to_run = "non numeric string"
      expect(subject.default_time_to_run).to eq described_class::DEFAULT_TTR
    end
  end

  describe "#default_delay" do
    specify "gets default if not provided" do
      expect(subject.default_delay).to eq described_class::DEFAULT_DELAY
    end
  end
  describe "#default_delay=" do
    specify "only accepts positive numbers" do
      subject.default_delay = 1
      expect(subject.default_delay).to eq 1
      subject.default_delay = 0
      expect(subject.default_delay).to eq 0
      subject.default_delay = nil
      expect(subject.default_delay).to eq nil.to_i
      expect(subject.logger).to receive(:warn) { }
      subject.default_delay = -5
      expect(subject.default_delay).to eq described_class::DEFAULT_DELAY
      subject.default_delay = "non numeric string"
      expect(subject.default_delay).to eq "non numeric string".to_i
    end
  end

  describe "#default_retry_times" do
    specify "gets default if not provided" do
      expect(subject.default_retry_times).to eq described_class::DEFAULT_RETRY_TIMES
    end
  end
  describe "#default_retry_times=" do
    specify "only accepts positive numbers" do
      subject.default_retry_times = 1
      expect(subject.default_retry_times).to eq 1
      subject.default_retry_times = 0
      expect(subject.default_retry_times).to eq 0
      subject.default_retry_times = nil
      expect(subject.default_retry_times).to eq nil.to_i
      expect(subject.logger).to receive(:warn) { }
      subject.default_retry_times = -5
      expect(subject.default_retry_times).to eq described_class::DEFAULT_RETRY_TIMES
      subject.default_retry_times = "non numeric string"
      expect(subject.default_retry_times).to eq "non numeric string".to_i
    end
  end

  describe "#beanstalkd_urls" do
    specify "defaults to ENV['BEANSTALKD_URLS']" do
      urls = "test1.com:11300,test2.com:11300,test3.com:11300"
      stub_const "ENV", { "BEANSTALKD_URLS" => urls }
      expect(subject.beanstalkd_urls).to eq urls.split(",")
    end
    specify "returns nil if env var not set" do
      expect(subject.beanstalkd_urls).to eq nil
    end
  end
  describe "#beanstalkd_urls=" do
    specify "accepts comma separated string" do
      urls = "test1.com:11300,  test2.com:11300  ,test3.com:11300"
      subject.beanstalkd_urls = urls
      expect(subject.beanstalkd_urls).to eq urls.split(",").collect {|url| url.strip }
    end
    specify "accepts array of strings" do
      urls = ["test1.com:11300", "test2.com:11300", "test3.com:11300"]
      subject.beanstalkd_urls = urls
      expect(subject.beanstalkd_urls).to eq urls
    end
  end

  describe "#pool_size" do
    specify "gets default if not provided" do
      expect(subject.pool_size).to eq described_class::DEFAULT_POOL_SIZE
    end
    specify "gets env if set" do
      stub_const "ENV", { "BEANSTALKD_POOL_SIZE" => "12"}
      expect(subject.pool_size).to eq 12
    end
  end
  describe "#pool_size=" do
    specify "only accepts positive numbers" do
      subject.pool_size = 1
      expect(subject.pool_size).to eq 1
      expect(subject.logger).to receive(:warn) { }
      subject.pool_size = 0
      expect(subject.pool_size).to eq described_class::DEFAULT_POOL_SIZE
      expect(subject.logger).to receive(:warn) { }
      subject.pool_size = nil
      expect(subject.pool_size).to eq described_class::DEFAULT_POOL_SIZE
      expect(subject.logger).to receive(:warn) { }
      subject.pool_size = -5
      expect(subject.pool_size).to eq described_class::DEFAULT_POOL_SIZE
      expect(subject.logger).to receive(:warn) { }
      subject.pool_size = "non numeric string"
      expect(subject.pool_size).to eq described_class::DEFAULT_POOL_SIZE
    end
  end

  describe "#timeout_seconds" do
    specify "gets default if not provided" do
      expect(subject.timeout_seconds).to eq described_class::DEFAULT_TIMEOUT_SECONDS
    end
    specify "gets env if set" do
      stub_const "ENV", { "BEANSTALKD_TIMEOUT_SECONDS" => "21"}
      expect(subject.timeout_seconds).to eq 21
    end
  end
  describe "#timeout_seconds=" do
    specify "only accepts positive numbers" do
      subject.timeout_seconds = 1
      expect(subject.timeout_seconds).to eq 1
      expect(subject.logger).to receive(:warn) { }
      subject.timeout_seconds = 0
      expect(subject.timeout_seconds).to eq described_class::DEFAULT_TIMEOUT_SECONDS
      expect(subject.logger).to receive(:warn) { }
      subject.timeout_seconds = nil
      expect(subject.timeout_seconds).to eq described_class::DEFAULT_TIMEOUT_SECONDS
      expect(subject.logger).to receive(:warn) { }
      subject.timeout_seconds = -5
      expect(subject.timeout_seconds).to eq described_class::DEFAULT_TIMEOUT_SECONDS
      expect(subject.logger).to receive(:warn) { }
      subject.timeout_seconds = "non numeric string"
      expect(subject.timeout_seconds).to eq described_class::DEFAULT_TIMEOUT_SECONDS
    end
  end

  describe "#worker_rate_controller" do
    specify "gets default if not provided" do
      expect(subject.worker_rate_controller).to be_nil
    end
  end
  describe "#worker_rate_controller=" do
    before do
      class TestRateController
        def self.poll
        end
        def self.do_work?
        end
      end

      class NotARateController
      end
    end

    specify "only accepts class that responds to `poll` and `do_work?`" do
      subject.worker_rate_controller = TestRateController
      expect(subject.worker_rate_controller).to eq TestRateController

      expect(subject.logger).to receive(:warn).with("Invalid worker_rate_controller NotARateController. Using none.")
      subject.worker_rate_controller = NotARateController
      expect(subject.worker_rate_controller).to be_nil

      # log nothing if we are setting it to nil, since that's also a valid value
      subject.worker_rate_controller = nil
      expect(subject.worker_rate_controller).to be_nil

      expect(subject.logger).to receive(:warn).with("Invalid worker_rate_controller -5. Using none.")
      subject.worker_rate_controller = -5
      expect(subject.worker_rate_controller).to be_nil

      expect(subject.logger).to receive(:warn).with("Invalid worker_rate_controller non numeric string. Using none.")
      subject.worker_rate_controller = "non numeric string"
      expect(subject.worker_rate_controller).to be_nil
    end
  end
end
=begin

worker RESERVE_TIMEOUT

worker backoff_proc
=end
