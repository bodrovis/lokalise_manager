# frozen_string_literal: true

describe LokaliseManager do
  it 'returns a proper version' do
    expect(described_class::VERSION).to be_a(String)
  end

  specify '.importer' do
    expect(described_class.importer).to be_a(LokaliseManager::TaskDefinitions::Importer)
  end

  specify '.exporter' do
    expect(described_class.exporter).to be_a(LokaliseManager::TaskDefinitions::Exporter)
  end
end
