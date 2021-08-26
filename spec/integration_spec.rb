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

  let(:test_consumer) do
    Class.new(EasyStalk::Consumer) do
      def self.jobs
        @jobs ||= []
      end

      def on_error(exception)
        raise exception
      end

      def retry_job
        job.release
      end
    end
  end

  context 'with a consumer that releases once' do
    let!(:consumer) do
      Class.new(test_consumer) do
        assign 'foo'

        def call(bar:, foo: 'bar')
          self.class.jobs << [
            job.body,
            { args: { bar: bar, foo: foo },
              releases: job.releases }
          ]
          raise 'too many releases' if self.class.jobs.size > 5

          job.release if job.releases == 0
        end
      end
    end

    specify do
      EasyStalk::Client.default.push({ bar: 'baz', extra: 'extra' }, tube: 'foo')
      begin
        Timeout.timeout(1) { worker.value }
      rescue StandardError
        Timeout::Error
      end
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
        ]
      )
    end
  end

  context 'with a consumer that errors' do
    let!(:consumer) do
      Class.new(EasyStalk::Consumer) do
        assign 'foo'
        self.retry_limit = 3

        def call
          raise 'try again'
        end

        def retry_job
          job.release
        end
      end
    end

    specify 'retries the specified amount and then buries' do
      body = { id: SecureRandom.hex(5) }
      EasyStalk::Client.default.push(body, tube: 'foo')
      begin
        Timeout.timeout(1) { worker.value }
      rescue Timeout::Error
      end
      dispatcher.shutdown!

      EasyStalk::Client.default.consumer.with do |conn|
        expect(conn.tubes['foo'].peek(:buried)).to have_attributes(
          body: JSON.dump(body),
          stats: having_attributes(releases: 3)
        )
      end
    end
  end

  context 'with a consumer that finishes without exception' do
    let!(:consumer) do
      Class.new(EasyStalk::Consumer) do
        assign 'foo'
        self.retry_limit = 3

        def call
          self.class.jobs << [job.body, { releases: job.releases }]
        end
      end
    end

    specify 'retries the specified amount and then buries' do
      EasyStalk::Client.default.push(nil, tube: 'foo')
      begin
        Timeout.timeout(1) { worker.value }
      rescue Timeout::Error
      end
      dispatcher.shutdown!

      EasyStalk::Client.default.consumer.with do |conn|
        expect(conn.tubes['foo'].peek(:buried)).to be_nil
      end
    end
  end

  context 'enqueues itself' do
    let!(:consumer) do
      Class.new(EasyStalk::Consumer) do
        assign 'foo'
        self.retry_limit = 3

        def call
          self.class.jobs << [job.body, { releases: job.releases }]
        end
      end
    end

    specify 'retries the specified amount and then buries' do
      consumer.enqueue
      begin
        Timeout.timeout(1) { worker.value }
      rescue Timeout::Error
      end
      dispatcher.shutdown!

      EasyStalk::Client.default.consumer.with do |conn|
        expect(conn.tubes['foo'].peek(:buried)).to be_nil
      end
    end
  end
end
