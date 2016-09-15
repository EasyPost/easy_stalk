require 'spec_helper'


describe EasyStalk::Job do

  class EasyStalk::MockJob < EasyStalk::Job
  end
  describe EasyStalk::MockJob do
    describe 'self << class' do
      subject { described_class }

      describe '.tube_name' do
        it 'defaults to class name' do
          stub_const "ENV", {"BEANSTALKD_TUBE_PREFIX" => "rating.test."}
          expect(subject.tube_name).to eq "rating.test.MockJob"
        end
        it 'can be set manually' do
          class MockJobWithName < subject
            tube_name "bar"
          end
          stub_const "ENV", {"BEANSTALKD_TUBE_PREFIX" => "rating.test."}
          expect(MockJobWithName.new.class.tube_name).to eq "rating.test.bar"
        end
        it 'properly uses a prefix' do
          class MockJobWithNameAndPrefix < subject
            tube_name "bar"
            tube_prefix "foo."
          end
          expect(MockJobWithNameAndPrefix.new.class.tube_name).to eq "foo.bar"
        end
      end

      describe '.tube_prefix' do
        it 'can be set manually' do
          class MockJobWithPrefix < subject
            tube_prefix "bar."
          end
          expect(MockJobWithPrefix.new().class.tube_prefix).to eq "bar."
        end
        it 'uses the env if present' do
          stub_const "ENV", {'BEANSTALKD_TUBE_PREFIX' => "foo."}
          expect(subject.tube_prefix).to eq "foo."
        end
        it 'uses blank if no env' do
          stub_const "ENV", {}
          expect(subject.tube_prefix).to eq ""
        end
      end

      describe '.priority' do
        it 'can be set manually' do
          class MockJobWithPri < subject
            priority 25
          end
          expect(MockJobWithPri.new().class.priority).to eq 25
        end
        it 'uses default if not set' do
          expect(subject.priority).to eq EasyStalk::Job::DEFAULT_PRI
        end
      end

      describe '.time_to_run' do
        it 'can be set manually' do
          class MockJobWithTtr < subject
            time_to_run 90
          end
          expect(MockJobWithTtr.new().class.time_to_run).to eq 90
        end
        it 'uses default if not set' do
          expect(subject.time_to_run).to eq EasyStalk::Job::DEFAULT_TTR
        end
      end

      describe '.delay' do
        it 'can be set manually' do
          class MockJobWithDelay < subject
            delay 5
          end
          expect(MockJobWithDelay.new().class.delay).to eq 5
        end
        it 'uses default if not set' do
          expect(subject.delay).to eq EasyStalk::Job::DEFAULT_DELAY
        end
      end

      describe '.serializable_context_keys' do
        it 'can be set manually' do
          class MockJobWithKeys < subject
            serializable_context_keys :cat, :dog
          end
          expect(MockJobWithKeys.new().class.serializable_context_keys).to eq [:cat, :dog]
        end
        it 'uses default if not set' do
          expect(subject.serializable_context_keys).to eq EasyStalk::Job::DEFAULT_SERIALIZABLE_KEYS
        end
      end
    end

    describe '.enqueue' do
      it 'properly enquques with defaults' do
        stub_const "ENV", {"BEANSTALKD_TUBE_PREFIX" => "rating.test."}
        conn = double
        tube = double
        job_data = "{}"
        pri = EasyStalk::Job::DEFAULT_PRI
        ttr = EasyStalk::Job::DEFAULT_TTR
        delay = EasyStalk::Job::DEFAULT_DELAY
        expect(conn).to receive(:tubes) { {"rating.test.MockJob" => tube } }
        expect(tube).to receive(:put).with(job_data, pri: pri, ttr: ttr, delay: delay) { {:status=>"INSERTED", :id=>"1234"} }
        subject.enqueue(conn)
      end
      it 'allows overriding pri, ttr and delay' do
        stub_const "ENV", {}
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
        stub_const "ENV", {}
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
        stub_const "ENV", {}
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
        stub_const "ENV", {}
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
      end
    end

    describe '.job_data' do
      it 'only_uses_serlizable_keys' do
        class MockJobWithKeys < described_class
          serializable_context_keys :cat, :dog
        end
        context = { :cat => "mew", "dog" => "wuf", :fish => "blu" }
        expect(MockJobWithKeys.new(context).job_data).to eq "{\"cat\":\"mew\",\"dog\":\"wuf\"}"
      end
    end

    describe '.call' do
      class ImplementedJob < described_class
        def call; end
      end
      it { expect { described_class.call }.to raise_error(NotImplementedError) }
      it { expect { ImplementedJob.call }.to_not raise_error }
    end
  end
end
