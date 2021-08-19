# frozen_string_literal: true

RSpec.describe 'produce and consume', :integration, :slow do
  let!(:tubes) { ['foo'] }
  let(:dispatcher) do
    EasyStalk::Dispatcher.new(
      client: EasyStalk::Client.new(
        consumer: EasyStalk::ConsumerPool.new(tubes: ['foo'])
      )
    )
  end

  before { dispatcher.client.consumer.with { |connection| connection.tubes['foo'].clear } }
  let(:worker) { Thread.new { dispatcher.run } }

  context 'with a consumer that releases once' do
    let!(:consumer) do
      Class.new(EasyStalk::Consumer) do
        assign 'foo'

        def self.jobs
          @jobs ||= []
        end

        def call(bar:, foo: 'bar')
          self.class.jobs << [
            job.body,
            args: { bar: bar, foo: foo },
            releases: job.releases
          ]
          raise 'too many releases' if self.class.jobs.size > 5

          job.release if job.releases == 0
        end

        def on_error(exception)
          raise exception
        end
      end
    end

    specify do
      EasyStalk::Client.default.push({ bar: 'baz', extra: 'extra' }, tube: 'foo')
      Timeout.timeout(1) { worker.value } rescue Timeout::Error
      dispatcher.shutdown!

      expect(consumer.jobs).to contain_exactly(
        [
          { 'bar' => 'baz', 'extra' => 'extra' },
          args: { bar: 'baz', foo: 'bar' },
          releases: 0
        ],
        [
          { 'bar' => 'baz', 'extra' => 'extra' },
          args: { bar: 'baz', foo: 'bar' },
          releases: 1
        ],
      )
    end
  end
end
