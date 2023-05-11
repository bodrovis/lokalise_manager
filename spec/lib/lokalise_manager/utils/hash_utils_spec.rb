# frozen_string_literal: true

describe LokaliseManager::Utils::HashUtils do
  using described_class
  let(:h_one) { { a: 100, b: 200, c: { c1: 100 } } }
  let(:h_two) { { b: 250, c: { c1: 200 } } }

  specify '#deep_merge' do
    result = h_one.deep_merge(h_two) { |_key, this_val, other_val| this_val + other_val }
    expect(result[:b]).to eq(450)
    expect(result[:c][:c1]).to eq(300)
  end
end
