# frozen_string_literal: true

RSpec.describe EasyStalk::Job do
  subject(:job) { described_class.new(payload, client: client) }
  let(:client) { EasyStalk::Test::Client.new }
  let(:payload) { client.push(data, tube: 'foo') }
  let(:data) { {} }

  describe '.encode' do
    subject(:encode) { described_class.encode(body) }

    context 'with a Hash' do
      let(:body) { {} }

      specify { expect(encode).to eq('{}') }
    end

    context 'with an Array' do
      let(:body) { ['x'] }

      specify { expect { encode }.to raise_error(TypeError) }
    end

    context 'with a String' do
      let(:body) { 'x' }

      specify { expect { encode }.to raise_error(TypeError) }
    end

    context 'with a an object that responds to #to_h' do
      let(:body) { Struct.new(:to_h).new('x' => 'y') }

      specify { expect(encode).to eq('{"x":"y"}') }
    end
  end

  describe '#body' do
    subject(:body) { job.body }

    it { is_expected.to eq(data) }
  end

  describe '#delayed_release' do
    subject(:delayed_release) { job.delayed_release }

    specify do
      expect { delayed_release }.to change(client, :delayed).to(payload => be_within(3).of(11))
    end

    context 'twice' do
      before { payload.releases += 1 }

      specify do
        expect { delayed_release }.to change(client, :delayed).to(payload => be_within(10).of(35))
      end
    end

    context 'thrice' do
      before { payload.releases += 2 }

      specify do
        expect { delayed_release }.to change(client, :delayed).to(payload => be_within(45).of(100))
      end
    end

    context 'again' do
      before { job.delayed_release }

      specify { expect { delayed_release }.to raise_error(described_class::AlreadyFinished) }
    end
  end

  describe '#bury' do
    subject(:bury) { job.bury }

    specify do
      expect { bury }.to change(client, :buried).from([]).to([payload])
    end

    context 'again' do
      before { job.bury }

      specify { expect { bury }.to raise_error(described_class::AlreadyFinished) }
    end
  end

  describe '#complete' do
    subject(:complete) { job.complete }

    specify do
      expect { complete }.to change { client.completed }.from([]).to([payload])
    end

    context 'again' do
      before { job.complete }

      specify { expect { complete }.to raise_error(described_class::AlreadyFinished) }
    end
  end
end
