# frozen_string_literal: true

describe Hash do
  let(:h1) { {a: 100, b: 200, c: {c1: 100}} }
  let(:h2) { {b: 250, c: {c1: 200}} }

  specify '#deep_merge' do
    result = h1.deep_merge(h2) { |_key, this_val, other_val| this_val + other_val }
    expect(result[:b]).to eq(450)
    expect(result[:c][:c1]).to eq(300)
  end
end
