require 'spec_helper'

describe EasyStalk::Worker do

  describe "self.work_jobs" do
    before(:each) do
      EasyStalk::Client.instance_variable_set :@pool, nil
      EasyStalk::Client.instance_variable_set :@urls, nil
    end
    after(:all) do
      EasyStalk::Client.instance_variable_set :@pool, nil
      EasyStalk::Client.instance_variable_set :@urls, nil
    end

    context "with an invalid job class" do
      it { expect { subject.work_jobs(Hash) }.to raise_error ArgumentError, "Hash is not a valid EasyStalk::Job subclass" }
    end

    context "with a valid job class" do
      before do
        class ValidJob < EasyStalk::Job
          def call
          end
        end
      end
      let(:job_instance) { ValidJob.new }

      it { expect { subject.work_jobs(job_instance) }.to raise_error ArgumentError, "#{job_instance} is not a valid EasyStalk::Job subclass" }

      specify do
        stub_const "ENV", { "BEANSTALKD_POOL_SIZE" => "12", "BEANSTALKD_TIMEOUT_SECONDS" => "21",
                            "BEANSTALKD_URLS" => "::mocked::"}

        expect(EasyStalk.logger).to receive(:info).at_least(1).times
        EasyStalk::Client.instance_variable_set :@pool, nil
        beanstalk = EasyStalk::MockBeaneater.new
        mocked_client = ConnectionPool.new(size: 2, timeout: 30) { beanstalk }
        tubes = EasyStalk::MockBeaneater::Tubes.new
        tubes.watch!(ValidJob)
        expect(ConnectionPool).to receive(:new).and_return mocked_client
        expect(beanstalk).to receive(:tubes).and_return(tubes).at_least(1).times
        expect(tubes).to receive(:watch!).with(job_instance.class.tube_name)
        sample_job = EasyStalk::MockBeaneater::TubeItem.new("{}", nil, nil, nil, job_instance.class.tube_name)
        expect(tubes).to receive(:reserve) {
          @count ||= 0
          if @count < 2
            @count = @count + 1
          else
            subject.send :cleanup
          end
          sample_job
        }.exactly(3).times
        expect { subject.work_jobs(job_instance.class) }.to_not raise_error
      end

      specify "raising exception will trigger a failure" do
        stub_const "ENV", { "BEANSTALKD_POOL_SIZE" => "12", "BEANSTALKD_TIMEOUT_SECONDS" => "21",
                            "BEANSTALKD_URLS" => "::mocked::"}

        expect(EasyStalk.logger).to receive(:info).at_least(1).times
        EasyStalk::Client.instance_variable_set :@pool, nil
        beanstalk = EasyStalk::MockBeaneater.new
        mocked_client = ConnectionPool.new(size: 2, timeout: 30) { beanstalk }
        tubes = EasyStalk::MockBeaneater::Tubes.new
        expect(ConnectionPool).to receive(:new).and_return mocked_client
        expect(beanstalk).to receive(:tubes).and_return(tubes).at_least(1).times
        expect(tubes).to receive(:watch!).with(job_instance.class.tube_name)
        sample_job = EasyStalk::MockBeaneater::TubeItem.new("{}", nil, nil, nil, job_instance.class.tube_name)
        expect(tubes).to receive(:reserve) {
          @count ||= 0
          if @count < 2
            @count = @count + 1
          else
            subject.send :cleanup
          end
          sample_job
        }.exactly(3).times
        expect(job_instance.class).to receive(:call!).exactly(3).times { raise "Boom" }
        expect(EasyStalk.logger).to receive(:error).exactly(6).times
        expect { subject.work_jobs(job_instance.class) }.to_not raise_error
      end

      specify "raises if on_fail doesn't respond to call" do
        expect { subject.work_jobs(job_instance.class, on_fail: "Nop") }.to raise_error ArgumentError, "on_fail handler does not respond to call"
      end

      specify "fail will call on_fail handler if provided" do
        stub_const "ENV", { "BEANSTALKD_POOL_SIZE" => "12", "BEANSTALKD_TIMEOUT_SECONDS" => "21",
                            "BEANSTALKD_URLS" => "::mocked::"}

        expect(EasyStalk.logger).to receive(:info).at_least(1).times
        EasyStalk::Client.instance_variable_set :@pool, nil
        beanstalk = EasyStalk::MockBeaneater.new
        mocked_client = ConnectionPool.new(size: 2, timeout: 30) { beanstalk }
        tubes = EasyStalk::MockBeaneater::Tubes.new
        expect(ConnectionPool).to receive(:new).and_return mocked_client
        expect(beanstalk).to receive(:tubes).and_return(tubes).at_least(1).times
        expect(tubes).to receive(:watch!).with(job_instance.class.tube_name)
        sample_job = EasyStalk::MockBeaneater::TubeItem.new("{}", nil, nil, nil, job_instance.class.tube_name)
        expect(tubes).to receive(:reserve) {
          @count ||= 0
          if @count < 2
            @count = @count + 1
          else
            subject.send :cleanup
          end
          sample_job
        }.exactly(3).times
        expect(job_instance.class).to receive(:call!).exactly(3).times { raise "Boom" }
        expect(EasyStalk.logger).to receive(:error).exactly(0).times
        expect(EasyStalk.logger).to receive(:warn).exactly(3).times
        fail_proc = Proc.new { |job, ex| EasyStalk.logger.warn "warn!" }
        expect { subject.work_jobs(job_instance.class, on_fail: fail_proc) }.to_not raise_error
      end
    end

    context "with  no job class" do
      before do
        class ValidJob < EasyStalk::Job
          def call
          end
        end
      end

      let(:job_instance) { ValidJob.new }

      specify do
        stub_const "ENV", { "BEANSTALKD_POOL_SIZE" => "12", "BEANSTALKD_TIMEOUT_SECONDS" => "21",
                            "BEANSTALKD_URLS" => "::mocked::"}

        expect(EasyStalk.logger).to receive(:info).at_least(1).times
        EasyStalk::Client.instance_variable_set :@pool, nil
        beanstalk = EasyStalk::MockBeaneater.new
        mocked_client = ConnectionPool.new(size: 2, timeout: 30) { beanstalk }
        tubes = EasyStalk::MockBeaneater::Tubes.new
        tubes.watch!(ValidJob)
        expect(ConnectionPool).to receive(:new).and_return mocked_client
        expect(beanstalk).to receive(:tubes).and_return(tubes).at_least(1).times
        sample_job = EasyStalk::MockBeaneater::TubeItem.new("{}", nil, nil, nil, job_instance.class.tube_name)
        expect(tubes).to receive(:reserve) {
          @count ||= 0
          if @count < 2
            @count = @count + 1
          else
            subject.send :cleanup
          end
          sample_job
        }.exactly(3).times
        expect { subject.work_jobs() }.to_not raise_error
      end
    end
  end
end
