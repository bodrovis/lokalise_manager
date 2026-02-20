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

  it '.importer passes custom opts' do
    importer = described_class.importer(api_token: 't', project_id: 'p')
    expect(importer.config.api_token).to eq('t')
    expect(importer.config.project_id).to eq('p')
  end

  it '.exporter passes custom opts' do
    exporter = described_class.exporter(api_token: 't', project_id: 'p')
    expect(exporter.config.api_token).to eq('t')
    expect(exporter.config.project_id).to eq('p')
  end

  it '.importer raises on unknown opts' do
    expect { described_class.importer(wtf_key: 1) }
      .to raise_error(LokaliseManager::Error, /Unknown config keys/i)
  end
end
