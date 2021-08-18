# frozen_string_literal: true

RSpec.describe 'produce and consumer', :integration do
  specify do
    Class.new(EasyStalk::Consumer) do
      assign 'foo'

      def call(bar:)
        puts bar
      end
    end

    dispatcher = EasyStalk::Dispatcher.new(
      client: EasyStalk::Client.new(
        consumer: EasyStalk::ConsumerPool.new(tubes: ['foo'])
      )
    )

    worker = Thread.new { dispatcher.run }

    EasyStalk::Client.default.push({ bar: 'baz' }, tube: 'foo')

    sleep(3)
    dispatcher.shutdown!
    worker.value
  end
end
