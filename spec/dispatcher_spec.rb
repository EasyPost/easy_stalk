# frozen_string_literal: true

RSpec.describe EasyStalk::Dispatcher do
  let(:dispatcher) { described_class.new(reserve_timeout: 1, client: EasyStalk::Test::Client.new) }
  let(:client) { EasyStalk::Test::Client.new }

  describe '.shutdown!' do
    subject(:shutdown!) { dispatcher.shutdown! }

    specify { expect { shutdown! }.to change(dispatcher, :shutdown).from(false).to(true) }
  end
end
