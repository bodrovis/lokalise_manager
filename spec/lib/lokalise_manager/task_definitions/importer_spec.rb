# frozen_string_literal: true

describe LokaliseManager::TaskDefinitions::Importer do
  let(:described_object) do
    described_class.new project_id: project_id,
                        api_token: ENV.fetch('LOKALISE_API_TOKEN', nil),
                        max_retries_import: 2
  end
  let(:loc_path) { described_object.config.locales_path }
  let(:project_id) { ENV.fetch('LOKALISE_PROJECT_ID', nil) }
  let(:local_trans) { "#{Dir.getwd}/spec/fixtures/response_files/trans.zip" }
  let(:local_trans_slashes) { "#{Dir.getwd}/spec/fixtures/response_files/trans_slashes.zip" }
  let(:common_params) do
    {
      format: 'ruby_yaml',
      placeholder_format: 'icu',
      yaml_include_root: true,
      original_filenames: true,
      directory_prefix: '',
      indentation: '2sp'
    }
  end

  describe '#open_and_process_zip' do
    it 're-raises errors during file processing' do
      entry = double
      allow(entry).to receive(:name).and_return('fail.yml')
      allow(described_object).to receive(:data_from).with(entry).and_raise(EncodingError)
      expect { described_object.send(:process!, entry) }
        .to raise_error(EncodingError, /Error when trying to process fail\.yml/)

      expect(described_object).to have_received(:data_from)
    end

    it 're-raises errors during file opening' do
      fake_path = 'http://fake.url/wrong/path.zip'

      stub_request(
        :get,
        fake_path
      ).to_raise(SocketError.new('Failed to open TCP connection'))

      expect { described_object.send(:open_and_process_zip, fake_path) }
        .to raise_error(SocketError, /Failed to open TCP connection/)
    end
  end

  describe '#download_files' do
    it 'returns a proper download URL' do
      stub_download(common_params, 'download_files.json')

      response = described_object.send :download_files

      expect(response['project_id']).to eq('672198945b7d72fc048021.15940510')
      expect(response['bundle_url']).to include('s3-eu-west-1.amazonaws.com')
    end

    it 're-raises errors during file download' do
      allow_project_id described_object, 'invalid'

      stub_download(common_params, 'invalid_project_id.json', status: 400, project_id: 'invalid')

      expect { described_object.send :download_files }
        .to raise_error(RubyLokaliseApi::Error::BadRequest, /Invalid `project_id` parameter/)
    end
  end

  describe '.import!' do
    context 'with errors' do
      it 'handles too many requests' do
        fake_client = instance_double(RubyLokaliseApi::Client)
        allow(fake_client).to receive(:download_files).and_raise(RubyLokaliseApi::Error::TooManyRequests)
        allow(described_object).to receive_messages(sleep: 0, api_client: fake_client)

        expect do
          described_object.import!
        end.to raise_error(RubyLokaliseApi::Error::TooManyRequests, /Gave up after 2 retries/i)

        expect(described_object).to have_received(:sleep).exactly(2).times
        expect(described_object).to have_received(:api_client).exactly(3).times
        expect(fake_client).to have_received(:download_files).exactly(3).times
      end

      it 'halts when the API key is not set' do
        allow(described_object.config).to receive(:api_token).and_return(nil)
        expect { described_object.import! }.to raise_error(LokaliseManager::Error, /API token is not set/i)
        expect(described_object.config).to have_received(:api_token)
        expect(count_translations).to eq(0)
      end

      it 'halts when the project_id is not set' do
        allow_project_id described_object, nil do
          expect { described_object.import! }.to raise_error(LokaliseManager::Error, /ID is not set/i)
          expect(count_translations).to eq(0)
        end
      end
    end

    context 'when directory is empty' do
      before do
        mkdir_locales
      end

      after do
        rm_translation_files
      end

      it 'runs import successfully for local files' do
        data = {
          'project_id' => '123.abc',
          'bundle_url' => local_trans
        }
        allow(described_object).to receive(:download_files).and_return(
          RubyLokaliseApi::Generics::DownloadBundle.new(data)
        )

        expect(described_object.import!).to be true

        expect(count_translations).to eq(4)
        expect(described_object).to have_received(:download_files)
        expect_file_exist loc_path, 'en/nested/main_en.yml'
        expect_file_exist loc_path, 'en/nested/deep/secondary_en.yml'
        expect_file_exist loc_path, 'ru/main_ru.yml'
      end

      it 'runs import successfully' do
        data = {
          'project_id' => '123.abc',
          'bundle_url' => local_trans
        }
        allow(described_object).to receive(:download_files).and_return(
          RubyLokaliseApi::Generics::DownloadBundle.new(data)
        )

        result = nil

        stub_download(common_params, 'import.json')

        expect { result = described_object.import! }.to output(/complete!/).to_stdout

        expect(result).to be true

        expect(count_translations).to eq(4)
      end

      it 'handles newlines properly', :slow do
        importer = described_class.new project_id: '913601666308c64dc13bb9.52811572',
                                       api_token: ENV.fetch('LOKALISE_API_TOKEN', nil),
                                       import_opts: { replace_breaks: false }

        data = {
          'project_id' => '123.abc',
          'bundle_url' => local_trans_slashes
        }

        allow(importer).to receive(:download_files).and_return(RubyLokaliseApi::Generics::DownloadBundle.new(data))

        stub_download(common_params.merge({ replace_breaks: false }), 'import.json')

        expect { importer.import! }.to output(/complete!/).to_stdout

        trans_data = YAML.load_file(File.join(loc_path, 'en.yml'))
        expect(trans_data['en']['hi_html']).to eq("<h1>\nhello world\n</h1>\n\n")
      end

      it 'handles backslashes properly' do
        importer = described_class.new project_id: '913601666308c64dc13bb9.52811572',
                                       api_token: ENV.fetch('LOKALISE_API_TOKEN', nil),
                                       max_retries_import: 2

        data = {
          'project_id' => '123.abc',
          'bundle_url' => local_trans_slashes
        }
        allow(importer).to receive(:download_files).and_return(RubyLokaliseApi::Generics::DownloadBundle.new(data))

        stub_download(common_params, 'import.json')

        expect { importer.import! }.to output(/complete!/).to_stdout

        trans_data = YAML.load_file(File.join(loc_path, 'en.yml'))
        expect(trans_data['en']['hello_html']).to eq("<h1>\nhello\nworld\n</h1>\n")
      end

      it 'runs import successfully but does not provide any output when silent_mode is enabled' do
        data = {
          'project_id' => '123.abc',
          'bundle_url' => local_trans
        }

        allow(described_object).to receive(:download_files).and_return(
          RubyLokaliseApi::Generics::DownloadBundle.new(data)
        )

        allow(described_object.config).to receive(:silent_mode).and_return(true)
        result = nil

        stub_download(common_params, 'import.json')

        expect { result = described_object.import! }.not_to output(/complete!/).to_stdout

        expect(result).to be true
        expect_file_exist loc_path, 'en/nested/main_en.yml'
        expect(described_object.config).to have_received(:silent_mode).at_most(1).times
      end
    end

    context 'when directory is not empty and safe mode enabled' do
      let(:safe_mode_obj) do
        described_class.new project_id: project_id,
                            api_token: ENV.fetch('LOKALISE_API_TOKEN', nil),
                            import_safe_mode: true
      end

      before do
        mkdir_locales
        rm_translation_files
        add_translation_files!
      end

      after do
        rm_translation_files
      end

      it 'import proceeds when the user agrees' do
        data = {
          'project_id' => '123.abc',
          'bundle_url' => local_trans
        }
        allow(safe_mode_obj).to receive(:download_files).and_return(RubyLokaliseApi::Generics::DownloadBundle.new(data))

        allow($stdin).to receive(:gets).and_return('Y')
        expect { safe_mode_obj.import! }.to output(/is not empty/).to_stdout

        expect(count_translations).to eq(5)
        expect($stdin).to have_received(:gets)
        expect(safe_mode_obj).to have_received(:download_files)
        expect_file_exist loc_path, 'en/nested/main_en.yml'
        expect_file_exist loc_path, 'en/nested/deep/secondary_en.yml'
        expect_file_exist loc_path, 'ru/main_ru.yml'
      end

      it 'import halts when a user chooses not to proceed' do
        allow(safe_mode_obj).to receive(:download_files).at_most(0).times
        allow($stdin).to receive(:gets).and_return('N')
        expect { safe_mode_obj.import! }.to output(/cancelled/).to_stdout

        expect(safe_mode_obj).not_to have_received(:download_files)
        expect($stdin).to have_received(:gets)
        expect(count_translations).to eq(1)
      end

      it 'import halts when a user chooses to halt and debug info is not printed out when silent_mode is enabled' do
        allow(safe_mode_obj.config).to receive(:silent_mode).and_return(true)
        allow(safe_mode_obj).to receive(:download_files).at_most(0).times
        allow($stdin).to receive(:gets).and_return('N')
        expect { safe_mode_obj.import! }.not_to output(/cancelled/).to_stdout

        expect(safe_mode_obj).not_to have_received(:download_files)
        expect(safe_mode_obj.config).to have_received(:silent_mode)
        expect($stdin).to have_received(:gets)
        expect(count_translations).to eq(1)
      end
    end
  end
end
