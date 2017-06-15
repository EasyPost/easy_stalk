require 'spec_helper'


describe EasyStalk::Job do

  class EasyStalk::MockJob < EasyStalk::Job
  end

  after(:all) do
    EasyStalk.send(:remove_const, :MockJob)
  end

  describe EasyStalk::MockJob do
    after do
      EasyStalk.configure
    end

    describe 'self << class' do
      subject { described_class }

      describe '.tube_name' do
        it 'defaults to class name' do
          EasyStalk.configure { |config| config.default_tube_prefix = "rating.test." }
          expect(subject.tube_name).to eq "rating.test.MockJob"
        end
        it 'can be set manually' do
          class MockJobWithName < subject
            tube_name "bar"
          end
          EasyStalk.configure { |config| config.default_tube_prefix = "rating.test." }
          expect(MockJobWithName.new.class.tube_name).to eq "rating.test.bar"
          Object.send(:remove_const, :MockJobWithName)
        end
        it 'properly uses a prefix' do
          class MockJobWithNameAndPrefix < subject
            tube_name "bar"
            tube_prefix "foo."
          end
          expect(MockJobWithNameAndPrefix.new.class.tube_name).to eq "foo.bar"
          Object.send(:remove_const, :MockJobWithNameAndPrefix)
        end
      end

      describe '.tube_prefix' do
        it 'can be set manually' do
          class MockJobWithPrefix < subject
            tube_prefix "bar."
          end
          expect(MockJobWithPrefix.new().class.tube_prefix).to eq "bar."
          Object.send(:remove_const, :MockJobWithPrefix)
        end
        it 'uses the env if present' do
          EasyStalk.configure { |config| config.default_tube_prefix = "foo." }
          expect(subject.tube_prefix).to eq "foo."
        end
        it 'uses blank if no env' do
          expect(subject.tube_prefix).to eq ""
        end
      end

      describe '.priority' do
        it 'can be set manually' do
          class MockJobWithPri < subject
            priority 25
          end
          expect(MockJobWithPri.new().class.priority).to eq 25
          Object.send(:remove_const, :MockJobWithPri)
        end
        it 'uses default if not set' do
          expect(subject.priority).to eq EasyStalk::Configuration::DEFAULT_PRI
        end
      end

      describe '.time_to_run' do
        it 'can be set manually' do
          class MockJobWithTtr < subject
            time_to_run 90
          end
          expect(MockJobWithTtr.new().class.time_to_run).to eq 90
          Object.send(:remove_const, :MockJobWithTtr)
        end
        it 'uses default if not set' do
          expect(subject.time_to_run).to eq EasyStalk::Configuration::DEFAULT_TTR
        end
      end

      describe '.delay' do
        it 'can be set manually' do
          class MockJobWithDelay < subject
            delay 5
          end
          expect(MockJobWithDelay.new().class.delay).to eq 5
          Object.send(:remove_const, :MockJobWithDelay)
        end
        it 'uses default if not set' do
          expect(subject.delay).to eq EasyStalk::Configuration::DEFAULT_DELAY
        end
      end

      describe '.retry_times' do
        it 'can be set manually' do
          class MockJobWithRetryTimes < subject
            retry_times 5
          end
          expect(MockJobWithRetryTimes.new().class.retry_times).to eq 5
          Object.send(:remove_const, :MockJobWithRetryTimes)
        end
        it 'uses default if not set' do
          expect(subject.retry_times).to eq EasyStalk::Configuration::DEFAULT_RETRY_TIMES
        end
      end

      describe '.serializable_context_keys' do
        it 'can be set manually' do
          class MockJobWithKeys < subject
            serializable_context_keys :cat, :dog
          end
          expect(MockJobWithKeys.new().class.serializable_context_keys).to eq [:cat, :dog]
          Object.send(:remove_const, :MockJobWithKeys)
        end
        it 'uses default if not set' do
          expect(subject.serializable_context_keys).to eq described_class::DEFAULT_SERIALIZABLE_CONTEXT_KEYS
        end
      end
    end

    describe '.enqueue' do

      it 'properly enquques with defaults' do
        EasyStalk.configure { |config| config.default_tube_prefix = "rating.test." }
        conn = double
        tube = double
        job_data = "{}"
        pri = EasyStalk::Configuration::DEFAULT_PRI
        ttr = EasyStalk::Configuration::DEFAULT_TTR
        delay = EasyStalk::Configuration::DEFAULT_DELAY
        expect(conn).to receive(:tubes) { {"rating.test.MockJob" => tube } }
        expect(tube).to receive(:put).with(job_data, pri: pri, ttr: ttr, delay: delay) { {:status=>"INSERTED", :id=>"1234"} }
        subject.enqueue(conn)
      end
      it 'allows overriding pri, ttr and delay' do
        conn = double
        tube = double
        job_data = "{}"
        pri = 10
        ttr = 30
        delay = 1
        expect(conn).to receive(:tubes) { {"MockJob" => tube } }
        expect(tube).to receive(:put).with(job_data, pri: pri, ttr: ttr, delay: delay) { {:status=>"INSERTED", :id=>"1234"} }
        subject.enqueue(conn, priority: pri, time_to_run: ttr, delay: delay)
      end
      it 'properly uses delay_until over delay' do
        conn = double
        tube = double
        now = DateTime.now
        delay_until = now + 3
        expect(DateTime).to receive(:now).and_return(now)
        expect(conn).to receive(:tubes) { {"MockJob" => tube } }
        expect(tube).to receive(:put).with("{}", pri: 1, ttr: 1, delay: 3 * 24*60*60) { {:status=>"INSERTED", :id=>"1234"} }
        subject.enqueue(conn, priority: 1, time_to_run: 1, delay: 24*60*60, delay_until: delay_until)
      end
      it 'does not allow a delay less than 0' do
        conn = double
        tube = double
        expect(conn).to receive(:tubes) { {"MockJob" => tube } }
        expect(tube).to receive(:put).with("{}", pri: 1, ttr: 1, delay: 0) { {:status=>"INSERTED", :id=>"1234"} }
        subject.enqueue(conn, priority: 1, time_to_run: 1, delay: -10)
      end
      it 'only enqueues serializable_context_keys' do
        class MockJobWithKeys < described_class
          serializable_context_keys :cat, :dog
        end
        conn = double
        tube = double
        job_data = "{\"cat\":\"mew\",\"dog\":\"wuf\"}"
        pri = 10
        ttr = 30
        delay = 1
        expect(conn).to receive(:tubes) { {"MockJobWithKeys" => tube } }
        expect(tube).to receive(:put).with(job_data, pri: pri, ttr: ttr, delay: delay) {
          {:status=>"INSERTED", :id=>"1234"}
        }
        MockJobWithKeys.new(:cat => "mew", "dog" => "wuf", :fish => "blu").
          enqueue(conn, priority: pri, time_to_run: ttr, delay: delay)
        Object.send(:remove_const, :MockJobWithKeys)
      end
    end

    describe '.enqueue' do
      context 'when ImmediateJobRunner is active' do
        before do
          EasyStalk::Extensions::ImmediateJobRunner.activate!
        end

        it 'raises NotImplementedError' do
          expect { described_class.call }.to raise_error(NotImplementedError)
        end

        after do
          EasyStalk::Extensions::ImmediateJobRunner.deactivate!
        end
      end
    end

    describe '.job_data' do
      it 'only_uses_serlizable_keys' do
        class MockJobWithKeys < described_class
          serializable_context_keys :cat, :dog
        end
        context = { :cat => "mew", "dog" => "wuf", :fish => "blu" }
        expect(MockJobWithKeys.new(context).job_data).to eq "{\"cat\":\"mew\",\"dog\":\"wuf\"}"
        Object.send(:remove_const, :MockJobWithKeys)
      end
    end

    describe '.call' do
      before do
        class ImplementedJob < described_class
          def call; end
        end
      end
      after do
        Object.send(:remove_const, :ImplementedJob)
      end
      it { expect { described_class.call }.to raise_error(NotImplementedError) }
      it { expect { ImplementedJob.call }.to_not raise_error }
    end
  end
end
