require 'spec_helper'

describe EasyStalk::Worker do
  describe "self.work" do
    before do
      EasyStalk.configure do |config|
        config.pool_size = 12
        config.timeout_seconds = 21
        config.beanstalkd_urls = "::mocked::"
      end
    end
    after do
      EasyStalk.configure
    end

    context "with an invalid job class" do
      it { expect { subject.work(Hash) }.to raise_error ArgumentError, "Hash is not a valid EasyStalk::Job subclass" }
    end

    context "with a valid job class" do
      before do
        class ValidJob < EasyStalk::Job
          def self.tube_name
            "job_tube"
          end

          def call
          end
        end
      end
      after do
        Object.send(:remove_const, :ValidJob)
      end

      let(:job_instance) { ValidJob.new }

      it { expect { subject.work(job_instance) }.to raise_error ArgumentError, "#{job_instance} is not a valid EasyStalk::Job subclass" }

      specify do
        expect(EasyStalk.logger).to receive(:info).at_least(1).times
        beanstalk = EasyStalk::MockBeaneater.new
        tubes = EasyStalk::MockBeaneater::Tubes.new
        tubes.watch!(ValidJob)
        expect(Beaneater).to receive(:new).and_return beanstalk
        expect(beanstalk).to receive(:tubes).and_return(tubes).at_least(1).times
        expect(tubes).to receive(:watch!).with("job_tube")
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
        expect { subject.work(job_instance.class) }.to_not raise_error
      end

      specify "raising exception will trigger a failure" do
        expect(EasyStalk.logger).to receive(:info).at_least(1).times
        beanstalk = EasyStalk::MockBeaneater.new
        mocked_client = EzPool.new(size: 2, timeout: 30) { beanstalk }
        tubes = EasyStalk::MockBeaneater::Tubes.new
        expect(EzPool).to receive(:new).and_return mocked_client
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
        expect(job_instance.class).to receive(:call!).exactly(3).times { raise "Boom" }
        expect(EasyStalk.logger).to receive(:error).exactly(6).times
        expect { subject.work(job_instance.class) }.to_not raise_error
      end

      specify "raises if on_fail doesn't respond to call" do
        expect { subject.work(job_instance.class, on_fail: "Nop") }.to raise_error ArgumentError, "on_fail handler does not respond to call"
      end

      specify "fail will call on_fail handler if provided" do
        expect(EasyStalk.logger).to receive(:info).at_least(1).times
        beanstalk = EasyStalk::MockBeaneater.new
        mocked_client = EzPool.new(size: 2, timeout: 30) { beanstalk }
        tubes = EasyStalk::MockBeaneater::Tubes.new
        expect(EzPool).to receive(:new).and_return mocked_client
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
        expect(job_instance.class).to receive(:call!).exactly(3).times { raise "Boom" }
        expect(EasyStalk.logger).to receive(:error).exactly(0).times
        expect(EasyStalk.logger).to receive(:warn).exactly(3).times
        fail_proc = Proc.new { |job, ex| EasyStalk.logger.warn "warn!" }
        expect { subject.work(job_instance.class, on_fail: fail_proc) }.to_not raise_error
      end
    end

    context "with no job class" do
      before do
        class ValidJob < EasyStalk::Job
          def call
          end
        end
      end
      after do
        Object.send(:remove_const, :ValidJob)
      end

      let(:job_instance) { ValidJob.new }

      specify do
        expect(EasyStalk.logger).to receive(:info).at_least(1).times
        beanstalk = EasyStalk::MockBeaneater.new
        mocked_client = EzPool.new(size: 2, timeout: 30) { beanstalk }
        tubes = EasyStalk::MockBeaneater::Tubes.new
        tubes.watch!(ValidJob)
        expect(EzPool).to receive(:new).and_return mocked_client
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
        expect { subject.work }.to_not raise_error
      end
    end

    context "with a custom retry times" do
      before do
        class ValidJob < EasyStalk::Job
          retry_times 2
          def call
            raise "boom"
          end
        end
      end
      after do
        Object.send(:remove_const, :ValidJob)
      end

      specify "buries the job after retry_times +1 attempt" do
        EasyStalk.configuration.default_worker_on_fail = Proc.new {}
        expect(EasyStalk.logger).to receive(:info).at_least(2).times {}
        beanstalk = EasyStalk::MockBeaneater.new
        mocked_client = EzPool.new(size: 2, timeout: 30) { beanstalk }
        tubes = EasyStalk::MockBeaneater::Tubes.new
        tubes.watch!(ValidJob)
        expect(EzPool).to receive(:new).and_return mocked_client
        expect(beanstalk).to receive(:tubes).and_return(tubes).at_least(1).times
        expect(tubes).to receive(:reserve) {
          @count = (@count || 0) + 1
          if @count > 3
            # all done. simulate empty queue
            subject.send :cleanup
            nil
          else
            job = EasyStalk::MockBeaneater::TubeItem.new("{}", nil, nil, nil, ValidJob.tube_name, @count)
            expect(job).to receive(:bury) if @count == 3
            job
          end
        }.exactly(4).times
        expect { subject.work }.to_not raise_error
      end
    end
  end
end
