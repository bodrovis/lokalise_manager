# frozen_string_literal: true

describe LokaliseManager::TaskDefinitions::Base do
  let(:described_object) { described_class.new }

  describe '.new' do
    it 'allows to override config' do
      obj = described_class.new api_token: 'fake'
      expect(obj.config.api_token).to eq('fake')
    end

    it 'lists all unknown config keys in the error message' do
      expect do
        described_class.new(wtf_key: 'nope', another_one: 123)
      end.to raise_error(LokaliseManager::Error) { |e|
        expect(e.message).to match(/Unknown config keys:/)
        expect(e.message).to include('wtf_key')
        expect(e.message).to include('another_one')
      }
    end
  end

  describe '#config' do
    it 'allows to update config after initialization' do
      obj = described_class.new api_token: 'fake', project_id: '123'

      obj.config.project_id = '345'

      expect(obj.config.project_id).to eq('345')
      expect(obj.config.api_token).to eq('fake')
    end
  end

  specify '.reset_api_client!' do
    expect(described_object.api_client).to be_an_instance_of(RubyLokaliseApi::Client)
    described_object.reset_api_client!
    current_client = described_object.instance_variable_get :@api_client
    expect(current_client).to be_nil
  end

  specify '.project_id_with_branch' do
    obj = described_class.new(api_token: 't', project_id: '123')

    expect(obj.send(:project_id_with_branch)).to eq('123')

    obj.config.branch = 'develop'
    expect(obj.send(:project_id_with_branch)).to eq('123:develop')

    obj.config.branch = '   '
    expect(obj.send(:project_id_with_branch)).to eq('123')
  end

  describe '.check_options_errors!' do
    it 'raises an error when the API key is not set' do
      allow(LokaliseManager::GlobalConfig).to receive(:api_token).and_return(nil)

      obj = described_class.new(project_id: '123') # ensure project_id

      expect do
        obj.send(:check_options_errors!)
      end.to raise_error(LokaliseManager::Error, /API token is not set/i)

      expect(LokaliseManager::GlobalConfig).to have_received(:api_token)
    end

    it 'raises an error when the project_id is not set' do
      obj = described_class.new(api_token: 't', project_id: '123')

      allow_project_id obj, nil do
        expect { obj.send(:check_options_errors!) }
          .to raise_error(LokaliseManager::Error, /ID is not set/i)
      end
    end
  end

  describe '.proper_ext?' do
    it 'works properly with path represented as a string' do
      path = 'my_path/here/file.yml'
      expect(described_object.send(:proper_ext?, path)).to be true
    end

    it 'works properly with path represented as a pathname' do
      path = Pathname.new 'my_path/here/file.json'
      expect(described_object.send(:proper_ext?, path)).to be false
    end
  end

  describe '.api_client' do
    it 'is possible to set timeouts' do
      allow(described_object.config).to receive(:additional_client_opts).and_return({
                                                                                      open_timeout: 100,
                                                                                      timeout: 500
                                                                                    })

      client = described_object.api_client
      expect(client).to be_an_instance_of(RubyLokaliseApi::Client)
      expect(client).not_to be_an_instance_of(RubyLokaliseApi::OAuth2Client)
      expect(client.open_timeout).to eq(100)
      expect(client.timeout).to eq(500)
      expect(client.api_host).to be_nil
    end

    it 'is possible to set API host' do
      api_host = 'http://example.com/api'
      allow(described_object.config).to receive(:additional_client_opts).and_return({
                                                                                      api_host: api_host
                                                                                    })

      client = described_object.api_client
      expect(client).to be_an_instance_of(RubyLokaliseApi::Client)
      expect(client).not_to be_an_instance_of(RubyLokaliseApi::OAuth2Client)
      expect(client.open_timeout).to be_nil
      expect(client.timeout).to be_nil
      expect(client.api_host).to eq(api_host)
    end

    it 'uses .oauth2_client when the use_oauth2_token is true' do
      allow(described_object.config).to receive(:use_oauth2_token).and_return(true)

      client = described_object.api_client

      expect(client).to be_an_instance_of(RubyLokaliseApi::OAuth2Client)
      expect(client).not_to be_an_instance_of(RubyLokaliseApi::Client)
    end
  end

  describe '#with_exp_backoff' do
    let(:obj) { described_class.new(api_token: 't', project_id: 'p') }

    before do
      stub_const("#{described_class}::BACKOFF_JITTER_RANGE", 0.0)
      allow(obj).to receive(:sleep)
    end

    it 'retries with exponential delays' do
      calls = 0
      expect do
        obj.send(:with_exp_backoff, 2) do
          calls += 1
          raise RubyLokaliseApi::Error::TooManyRequests if calls <= 3
        end
      end.to raise_error(RubyLokaliseApi::Error::TooManyRequests)

      expect(obj).to have_received(:sleep).with(1.0).ordered
      expect(obj).to have_received(:sleep).with(2.0).ordered
      expect(obj).to have_received(:sleep).exactly(2).times
    end
  end
end
