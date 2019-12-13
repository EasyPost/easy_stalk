# frozen_string_literal: true

RSpec.describe EasyStalk::Dispatcher do
  let(:dispatcher) { described_class.new(reserve_timeout: 1, client: client) }
  let(:client) { EasyStalk::Test::Client.new }

  describe '#shutdown!' do
    subject(:shutdown!) { dispatcher.shutdown! }

    specify { expect { shutdown! }.to change(dispatcher, :shutdown).from(false).to(true) }
  end

  describe '#start' do
    subject(:start) { dispatcher.start }

    before do
      Thread.new do
        sleep 0.5
        dispatcher.shutdown!
      end
    end

    specify do
      expect(dispatcher).to receive(:run).at_least(:once)

      start
    end
  end

  describe '#run' do
    subject(:run) { dispatcher.run }

    specify { expect(run).to eq(nil) }

    context 'with a job' do
      before { client.push({}, tube: 'foo') }

      context 'with no consumer' do
        specify { expect { run }.to raise_error(KeyError) }
      end

      context 'with a consumer' do
        let!(:consumer) { Class.new(EasyStalk::Consumer) { assign 'foo' } }

        specify { expect { run }.to change(client, :jobs).to([]) }
      end
    end
  end
end
