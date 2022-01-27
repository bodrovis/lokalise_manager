# frozen_string_literal: true

describe LokaliseManager::Utils::ArrayUtils do
  using described_class
  let(:arr) { (1..8).to_a }

  describe '#in_groups_of' do
    it 'raises an exception when the number is less than 1' do
      expect(-> { arr.in_groups_of(-1) }).to raise_error(ArgumentError)
    end

    it 'uses collection itself if fill_with is false' do
      enum = arr.in_groups_of(5, false)
      enum.next
      expect(enum.next.count).to eq(3)
    end
  end
end
