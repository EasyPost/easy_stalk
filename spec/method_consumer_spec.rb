# frozen_string_literal: true

require 'easy_stalk/method_consumer'

RSpec.describe EasyStalk::MethodConsumer do
  let(:consumer) do
    Class.new(EasyStalk::Consumer) do
      include EasyStalk::MethodConsumer

      class << self
        def to_s
          'consumer'
        end

        def on_error(exception)
          raise exception
        end

        alias_method :inspect, :to_s
      end
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

      specify { expect(consume).to eq(false) }
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
