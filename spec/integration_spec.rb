# frozen_string_literal: true

RSpec.describe 'produce and consumer', :integration do
  specify do
    consumer = Class.new(EasyStalk::Consumer) do
      assign 'foo'

      def self.jobs
        @jobs ||= []
      end

      def call(bar:)
        self.class.jobs << [job, bar]
      end

      def on_error(exception)
        raise exception
      end
    end

    dispatcher = EasyStalk::Dispatcher.new(
      client: EasyStalk::Client.new(
        consumer: EasyStalk::ConsumerPool.new(tubes: ['foo'])
      )
    )

    worker = Thread.new { dispatcher.run }

    EasyStalk::Client.default.push({ bar: 'baz' }, tube: 'foo')
    Timeout.timeout(3) { worker.value }
    dispatcher.shutdown!

    expect(consumer.jobs).to contain_exactly([an_instance_of(EasyStalk::Job), 'baz'])
  end
end
