# frozen_string_literal: true

RSpec.describe EasyStalk::Consumer do
  let(:consumer) do
    Class.new(EasyStalk::Consumer) do
      class << self
        def to_s
          'consumer'
        end

        alias_method :inspect, :to_s
      end

      def on_error(exception)
        raise exception
      end
    end
  end

  before { EasyStalk.tube_consumers.clear }

  describe '.priority' do
    specify do
      expect { consumer.priority = 30 }
        .to change(consumer, :priority).from(EasyStalk.default_job_priority).to(30)
    end
  end

  describe '.time_to_run' do
    specify do
      expect { consumer.time_to_run = 30 }
        .to change(consumer, :time_to_run).from(EasyStalk.default_job_time_to_run).to(30)
    end
  end

  describe '.delay' do
    specify do
      expect { consumer.delay = 30 }
        .to change(consumer, :delay).from(EasyStalk.default_job_delay).to(30)
    end
  end

  describe '.retry_limit' do
    specify do
      expect { consumer.retry_limit = 30 }
        .to change(consumer, :retry_limit).from(EasyStalk.default_job_retry_limit).to(30)
    end
  end

  describe '.assign' do
    specify do
      expect { consumer.assign('foo') }
        .to change { consumer.tubes }
        .from([]).to(['foo'])
        .and change { EasyStalk.consumers }
        .by([consumer])
        .and change { EasyStalk.tube_consumers }.to('foo' => consumer)
    end

    specify do
      expect { consumer.assign('foo', 'bar') }
        .to change { consumer.tubes }
        .from([]).to(%w[foo bar])
        .and change { EasyStalk.consumers }
        .by([consumer])
        .and change { EasyStalk.tube_consumers }.to('foo' => consumer, 'bar' => consumer)
    end
  end

  describe '.consume' do
    let(:job) { instance_double(EasyStalk::Job, complete: true, body: body) }
    let(:body) { { 'foo' => 'bar' } }

    subject(:consume) { consumer.consume(job) }

    specify { expect { consume }.to raise_error(NotImplementedError) }

    context '#call()' do
      before do
        consumer.class_eval do
          def call
            'called'
          end
        end
      end

      specify { expect(consume).to eq('called') }
    end

    context '#call(:keyreq)' do
      before do
        consumer.class_eval do
          def call(foo:)
            foo
          end
        end
      end

      specify { expect(consume).to eq('bar') }
    end

    context '#call(:key)' do
      before do
        consumer.class_eval do
          def call(bar: true)
            bar
          end
        end
      end

      specify { expect(consume).to eq(true) }
    end

    context '#call(:req)' do
      before do
        consumer.class_eval do
          def call(bar)
            bar || false
          end
        end
      end

      specify { expect { consume }.to raise_error(EasyStalk::MethodDelegator::InvalidArgument) }
    end

    context '#call(:key,:keyrest)' do
      before do
        consumer.class_eval do
          def call(_bar: nil, **args)
            args
          end
        end
      end

      specify { expect(consume).to eq(foo: 'bar') }
    end
  end
end