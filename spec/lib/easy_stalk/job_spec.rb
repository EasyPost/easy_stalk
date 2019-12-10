# frozen_string_literal: true

require 'spec_helper'

describe EasyStalk::Job do
  subject(:job) do
    Class.new(EasyStalk::Job) do
      def self.name
        'MockJob'
      end
    end
  end

  describe '.tube_name' do
    subject(:tube_name) { job.tube_name }

    context 'with a default prefix' do
      before { EasyStalk.configure { |config| config.default_tube_prefix = 'prefix.' } }

      it { is_expected.to eq('prefix.MockJob') }

      context 'and custom tube_name' do
        before { job.tube_name 'bar' }

        it { is_expected.to eq('prefix.bar') }
      end
    end

    context 'with a custom prefix and tube_name' do
      before do
        job.tube_name 'bar'
        job.tube_prefix 'foo.'
      end

      it { is_expected.to eq('foo.bar') }
    end
  end

  describe '.tube_prefix' do
    subject(:tube_prefix) { job.tube_prefix }

    before { EasyStalk.configure  }

    it { is_expected.to eq(EasyStalk::Configuration::DEFAULT_TUBE_PREFIX) }

    context 'with a custom prefix' do
      before { EasyStalk.configure { |config| config.default_tube_prefix = 'prefix.' } }

      it { is_expected.to eq('prefix.') }
    end
  end

  describe '.priority' do
    subject(:priority) { job.priority }

    it { is_expected.to eq(EasyStalk::Configuration::DEFAULT_PRI) }

    context 'with a custom priority' do
      before { EasyStalk.configure { |config| config.default_priority = 25 } }

      it { is_expected.to eq(25) }
    end
  end

  describe '.time_to_run' do
    subject(:time_to_run) { job.time_to_run }

    it { is_expected.to eq(EasyStalk::Configuration::DEFAULT_TTR) }

    context 'with a custom time_to_run' do
      before { EasyStalk.configure { |config| config.default_time_to_run = 90 } }

      it { is_expected.to eq(90) }
    end
  end

  describe '.delay' do
    subject(:delay) { job.delay }

    it { is_expected.to eq(EasyStalk::Configuration::DEFAULT_DELAY) }

    context 'with a custom delay' do
      before { EasyStalk.configure { |config| config.default_delay = 5 } }

      it { is_expected.to eq(5) }
    end
  end

  describe '.retry_times' do
    subject(:retry_times) { job.retry_times }

    it { is_expected.to eq(EasyStalk::Configuration::DEFAULT_RETRY_TIMES) }

    context 'with a custom retry_times' do
      before { EasyStalk.configure { |config| config.default_retry_times = 5 } }

      it { is_expected.to eq(5) }
    end
  end

  describe '.serializable_context_keys' do
    subject(:serializable_context_keys) { job.serializable_context_keys }

    it { is_expected.to be_empty }

    context 'with custom context keys' do
      before { job.serializable_context_keys :foo, :bar }

      it { is_expected.to contain_exactly(:foo, :bar) }

      context 'when subclassed' do
        let(:subclass) { Class.new(job) }

        subject(:serializable_context_keys) { subclass.serializable_context_keys }

        it { is_expected.to contain_exactly(:foo, :bar) }

        context 'with custom context keys' do
          before { subclass.serializable_context_keys :baz }

          it { is_expected.to contain_exactly(:foo, :bar, :baz) }
        end
      end
    end
  end

  describe '#enqueue' do
    subject(:enqueue) { instance.enqueue(connection, **options) }

    let(:connection) { spy(Beaneater::Connection, tubes: tubes) }
    let(:tube) { spy(Beaneater::Tube) }
    let(:tubes) { { job.tube_name => tube } }
    let(:options) { {} }
    let(:instance) { job.new }

    specify do
      enqueue

      expect(tube).to have_received(:put)
        .with(instance.job_data, pri: job.priority, ttr: job.time_to_run, delay: job.delay)
    end

    context 'with custom priority, time_to_run, delay' do
      before { options.merge!(priority: 10, time_to_run: 30, delay: 1) }

      specify do
        enqueue

        expect(tube).to have_received(:put).with(instance.job_data, pri: 10, ttr: 30, delay: 1)
      end
    end

    context 'with delay_until' do
      before do
        options.merge!(delay_until: now + 3)
        allow(Time).to receive(:now).and_return(now)
      end

      let(:now) { Time.now }

      specify do
        enqueue

        expect(tube).to have_received(:put).with(instance.job_data,
                                                 pri: job.priority,
                                                 ttr: job.time_to_run,
                                                 delay: 3 * 24 * 60 * 60)
      end
    end

    context 'with a negative delay' do
      before { options.merge!(delay: -10) }

      specify do
        enqueue

        expect(tube).to have_received(:put).with(instance.job_data,
                                                 pri: job.priority,
                                                 ttr: job.time_to_run,
                                                 delay: 0)
      end
    end

    context 'with non-serializable context keys' do
      before { job.serializable_context_keys :foo, :bar }

      let(:instance) { job.new(foo: 1, bar: 2, baz: 3) }

      specify do
        enqueue

        expect(tube).to have_received(:put).with(JSON.dump(foo: 1, bar: 2),
                                                 pri: job.priority,
                                                 ttr: job.time_to_run,
                                                 delay: job.delay)
      end
    end
  end

  describe '#call' do
    subject(:call) { job.new.call }

    it { expect { call }.to raise_error(NotImplementedError) }

    context 'when ImmediateJobRunner is active' do
      before { EasyStalk::Extensions::ImmediateJobRunner.activate! }
      after { EasyStalk::Extensions::ImmediateJobRunner.deactivate! }

      specify { expect { described_class.call }.to raise_error(NotImplementedError) }
    end
  end
end
