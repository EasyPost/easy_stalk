# frozen_string_literal: true

RSpec.describe EasyStalk::Consumer do
  let(:consumer) do
    Class.new(EasyStalk::Consumer) do
      class << self
        def to_s
          'consumer'
        end

        alias_method :inspect, :to_s

        def consume(job)
          new(job).consume
        end
      end
    end
  end

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
    let(:payload) { client.push(body, tube: 'foo') }
    let(:client) { EasyStalk::Test::Client.new }
    let(:body) { { 'foo' => 'bar' } }

    subject(:consume) { consumer.consume(EasyStalk::Job.new(payload, client: client)) }

    specify { expect { consume }.to raise_error(NotImplementedError) }

    context 'on error' do
      let(:consumer) do
        Class.new(EasyStalk::Consumer) do
          class << self
            def to_s
              'consumer'
            end

            alias_method :inspect, :to_s
          end

          def call
            raise 'retry me'
          end
        end
      end

      specify { expect { consume }.to change(client, :delayed).to(payload => a_value > 0) }
    end

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

      specify { expect { consume }.to raise_error(ArgumentError) }
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
