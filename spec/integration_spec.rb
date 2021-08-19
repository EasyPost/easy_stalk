# frozen_string_literal: true

RSpec.describe 'produce and consume', :integration, :slow do
  let!(:consumer) do
    Class.new(EasyStalk::Consumer) do
      assign 'foo'

      def self.jobs
        @jobs ||= []
      end

      def call(bar:, foo: 'bar')
        self.class.jobs << [
          job,
          args: { bar: bar, foo: foo },
          releases: job.releases
        ]
      end

      def on_error(exception)
        raise exception
      end
    end
  end

  let!(:tubes) { ['foo'] }
  let(:dispatcher) do
    EasyStalk::Dispatcher.new(
      client: EasyStalk::Client.new(
        consumer: EasyStalk::ConsumerPool.new(tubes: ['foo'])
      )
    )
  end

  specify do
    worker = Thread.new { dispatcher.run }

    EasyStalk::Client.default.push({ bar: 'baz', extra: 'extra' }, tube: 'foo')
    Timeout.timeout(3) { worker.value }
    dispatcher.shutdown!

    expect(consumer.jobs).to contain_exactly([an_instance_of(EasyStalk::Job), 'baz'])
    job, = consumer.jobs.first
  end
end
