# frozen_string_literal: true

require 'base64'

describe LokaliseManager::TaskDefinitions::Exporter do
  let(:path) { "#{Dir.getwd}/locales/nested/en.yml" }
  let(:relative_name) { 'nested/en.yml' }
  let(:project_id) { ENV.fetch('LOKALISE_PROJECT_ID', nil) }
  let(:described_object) do
    described_class.new project_id: project_id,
                        api_token: ENV.fetch('LOKALISE_API_TOKEN', nil),
                        max_retries_export: 2
  end

  context 'with many translation files' do
    describe '.export!' do
      context 'with three files' do
        before do
          add_translation_files! with_ru: true, additional: 1
        end

        after do
          rm_translation_files
        end

        it 'sends a proper API request and handles rate limiting' do
          process = nil

          stub_upload({
                        data: 'ZW46CiAgbXlfa2V5OiAiTXkgdmFsdWUiCiAgbmVzdGVkOgogICAga2V5OiAiVmFsdWUgMiIK',
                        filename: 'nested/en.yml',
                        lang_iso: 'en'
                      }, 'upload_nested.json')

          stub_upload({
                        data: 'cnVfUlU6CiAgbXlfa2V5OiAi0JzQvtGRINC30L3QsNGH0LXQvdC40LUiCiAgbmVzdGVkOgogIC' \
                              'Aga2V5OiAi0JfQvdCw0YfQtdC90LjQtSAyIgo=',
                        filename: 'ru.yml',
                        lang_iso: 'ru_RU'
                      }, 'upload_ru.json')

          stub_upload({
                        data: 'LS0tCmVuOgogIGtleV8wOiB2YWx1ZSAwCg==', filename: 'en_0.yml', lang_iso: 'en'
                      }, 'upload0.json')

          expect { process = described_object.export!.first.process }.to output(/complete!/).to_stdout

          expect(process.project_id).to eq(project_id)
          expect(process.status).to eq('queued')
        end
      end

      context 'with seven files' do
        before do
          add_translation_files! with_ru: true, additional: 5
        end

        after do
          rm_translation_files
        end

        it 'handles too many requests but does not re-raise anything when raise_on_export_fail is false' do
          allow(described_object.config).to receive_messages(max_retries_export: 1, raise_on_export_fail: false)

          fake_client = instance_double(RubyLokaliseApi::Client)
          allow(fake_client).to receive(:upload_file).with(any_args).and_raise(RubyLokaliseApi::Error::TooManyRequests)
          allow(described_object).to receive_messages(sleep: 0, api_client: fake_client)
          processes = []
          expect { processes = described_object.export! }.not_to raise_error

          expect(processes[0].success).to be false
          expect(processes[1].error.class).to eq(RubyLokaliseApi::Error::TooManyRequests)
          expect(processes.count).to eq(7)

          expect(described_object).to have_received(:sleep).exactly(7).times
          expect(described_object).to have_received(:api_client).at_least(14).times
          expect(fake_client).to have_received(:upload_file).exactly(14).times
        end

        it 'handles non-json responses but does not re-raise anything when raise_on_export_fail is false' do
          allow(described_object.config).to receive_messages(max_retries_export: 1, raise_on_export_fail: false)

          fake_client = instance_double(RubyLokaliseApi::Client)
          allow(fake_client).to receive(:upload_file).with(any_args).and_raise(JSON::ParserError)
          allow(described_object).to receive_messages(sleep: 0, api_client: fake_client)
          processes = []
          expect { processes = described_object.export! }.not_to raise_error

          expect(processes[0].success).to be false
          expect(processes[1].error.class).to eq(JSON::ParserError)
          expect(processes.count).to eq(7)

          expect(described_object).to have_received(:sleep).exactly(7).times
          expect(described_object).to have_received(:api_client).at_least(14).times
          expect(fake_client).to have_received(:upload_file).exactly(14).times
        end
      end
    end
  end

  context 'with errors' do
    before do
      add_translation_files! with_ru: true
    end

    after do
      rm_translation_files
    end

    it 'handles too many requests' do
      allow(described_object.config).to receive(:max_retries_export).and_return(1)

      fake_client = instance_double(RubyLokaliseApi::Client)
      allow(fake_client).to receive(:token).with(any_args).and_return('fake_token')
      allow(fake_client).to receive(:upload_file).with(any_args).and_raise(RubyLokaliseApi::Error::TooManyRequests)
      allow(described_object).to receive_messages(sleep: 0, api_client: fake_client)

      expect do
        described_object.export!
      end.to raise_error(RubyLokaliseApi::Error::TooManyRequests, /Gave up after 1 retries/i)

      expect(described_object).to have_received(:sleep).exactly(2).times
      expect(described_object).to have_received(:api_client).at_least(4).times
      expect(fake_client).to have_received(:upload_file).exactly(4).times
    end

    it 'halts when the API key is not set' do
      allow(described_object.config).to receive(:api_token).and_return(nil)

      expect { described_object.export! }.to raise_error(LokaliseManager::Error, /API token is not set/i)
      expect(described_object.config).to have_received(:api_token)
    end

    it 'halts when the project_id is not set' do
      allow_project_id described_object, nil do
        expect { described_object.export! }.to raise_error(LokaliseManager::Error, /ID is not set/i)
      end
    end
  end

  context 'with one translation file' do
    before do
      add_translation_files!
    end

    after do
      rm_translation_files
    end

    describe '.export!' do
      it 'sends a proper API request but does not output anything when silent_mode is enabled' do
        allow(described_object.config).to receive(:silent_mode).and_return(true)

        process = nil

        stub_upload({
                      data: 'ZW46CiAgbXlfa2V5OiAiTXkgdmFsdWUiCiAgbmVzdGVkOgogICAga2V5OiAiVmFsdWUgMiIK',
                      filename: 'nested/en.yml',
                      lang_iso: 'en'
                    }, 'upload_nested.json')

        expect { process = described_object.export!.first.process }.not_to output(/complete!/).to_stdout

        expect(process.status).to eq('queued')
        expect(described_object.config).to have_received(:silent_mode).at_most(1).times
      end

      it 'sends a proper API request' do
        stub_upload({
                      data: 'ZW46CiAgbXlfa2V5OiAiTXkgdmFsdWUiCiAgbmVzdGVkOgogICAga2V5OiAiVmFsdWUgMiIK',
                      filename: 'nested/en.yml',
                      lang_iso: 'en'
                    }, 'upload_nested.json')

        process = described_object.export!.first.process

        expect(process.project_id).to eq(project_id)
        expect(process.status).to eq('queued')
      end

      it 'sends a proper API request when a different branch is provided' do
        allow(described_object.config).to receive(:branch).and_return('develop')

        stub_upload({
                      data: 'ZW46CiAgbXlfa2V5OiAiTXkgdmFsdWUiCiAgbmVzdGVkOgogICAga2V5OiAiVmFsdWUgMiIK',
                      filename: 'nested/en.yml',
                      lang_iso: 'en'
                    }, 'upload_nested.json', project_id: "#{ENV.fetch('LOKALISE_PROJECT_ID', nil)}:develop")

        process_data = described_object.export!.first

        expect(described_object.config).to have_received(:branch).at_most(2).times
        expect(process_data.success).to be true
        expect(process_data.path.to_s).to include('en.yml')

        process = process_data.process
        expect(process).to be_an_instance_of(RubyLokaliseApi::Resources::QueuedProcess)
        expect(process.project_id).to eq(project_id)
        expect(process.status).to eq('queued')
      end

      it 'can infer locale based on the path' do
        allow(described_object.config).to receive(:lang_iso_inferer).and_return(
          ->(_data, path) { path.basename('.yml').to_s }
        )

        paths = described_object.send(:all_files).flatten
        opts = described_object.send(:opts, *paths)

        expect(opts[:filename].to_s).to eq('nested/en.yml')
        expect(opts[:lang_iso].to_s).to eq('en')

        expect(described_object.config).to have_received(:lang_iso_inferer)
      end

      it 'runs preprocessor' do
        allow(described_object.config).to receive(:export_preprocessor).and_return(
          ->(data, _path) { data.upcase }
        )

        paths = described_object.send(:all_files).flatten
        opts = described_object.send(:opts, *paths)

        demo_content = File.read(paths[0], mode: 'r:UTF-8')
        expect(opts[:data]).to eq(Base64.strict_encode64(demo_content.upcase))

        expect(described_object.config).to have_received(:export_preprocessor)
      end

      it 'runs filename generator' do
        allow(described_object.config).to receive(:export_filename_generator).and_return(
          ->(_full_path, relative_path) { relative_path.to_s.upcase }
        )

        paths = described_object.send(:all_files).flatten
        opts = described_object.send(:opts, *paths)

        expect(opts[:filename]).to eq(paths[1].to_s.upcase)

        expect(described_object.config).to have_received(:export_filename_generator)
      end
    end

    describe '#all_files' do
      it 'yield proper arguments' do
        expect(described_object.send(:all_files).flatten).to include(
          Pathname.new(path),
          Pathname.new(relative_name)
        )
      end
    end

    describe '.opts' do
      let(:base64content) { Base64.strict_encode64(File.read(path, mode: 'r:UTF-8')) }

      it 'generates proper options' do
        resulting_opts = described_object.send(:opts, path, relative_name)

        expect(resulting_opts[:data]).to eq(base64content)
        expect(resulting_opts[:filename]).to eq(relative_name)
        expect(resulting_opts[:lang_iso]).to eq('en')
      end

      it 'allows to redefine options' do
        allow(described_object.config).to receive(:export_opts).and_return({
                                                                             detect_icu_plurals: true,
                                                                             convert_placeholders: true
                                                                           })

        resulting_opts = described_object.send(:opts, path, relative_name)

        expect(described_object.config).to have_received(:export_opts)
        expect(resulting_opts[:data]).to eq(base64content)
        expect(resulting_opts[:filename]).to eq(relative_name)
        expect(resulting_opts[:lang_iso]).to eq('en')
        expect(resulting_opts[:detect_icu_plurals]).to be true
        expect(resulting_opts[:convert_placeholders]).to be true
      end
    end
  end

  context 'with two translation files' do
    let(:filename_ru) { 'ru.yml' }
    let(:path_ru) { "#{Dir.getwd}/locales/#{filename_ru}" }

    before do
      add_translation_files! with_ru: true
    end

    after do
      rm_translation_files
    end

    describe '.export!' do
      it 're-raises export errors' do
        stub_upload({
                      data: 'ZW46CiAgbXlfa2V5OiAiTXkgdmFsdWUiCiAgbmVzdGVkOgogICAga2V5OiAiVmFsdWUgMiIK',
                      filename: 'nested/en.yml',
                      lang_iso: 'en'
                    }, 'upload_nested.json')

        stub_upload({
                      data: 'cnVfUlU6CiAgbXlfa2V5OiAi0JzQvtGRINC30L3QsNGH0LXQvdC40LUiCiAgbmVzdGVkOgogI' \
                            'CAga2V5OiAi0JfQvdCw0YfQtdC90LjQtSAyIgo=',
                      filename: 'ru.yml',
                      lang_iso: 'ru_RU'
                    }, 'unknown_lang_iso.json', status: 400)

        expect { described_object.export! }.to raise_error(RubyLokaliseApi::Error::BadRequest, /Unknown `lang_iso`/)
      end
    end

    describe '.opts' do
      let(:base64content_ru) { Base64.strict_encode64(File.read(path_ru, mode: 'r:UTF-8')) }

      it 'generates proper options' do
        resulting_opts = described_object.send(:opts, path_ru, filename_ru)

        expect(resulting_opts[:data]).to eq(base64content_ru)
        expect(resulting_opts[:filename]).to eq(filename_ru)
        expect(resulting_opts[:lang_iso]).to eq('ru_RU')
      end

      it 'does not trim file content' do
        tmp = File.join(Dir.getwd, 'locales', 'tmp.yml')
        File.write(tmp, "en:\n  a: \"b\"\n")

        opts = described_object.send(:opts, tmp, 'tmp.yml')
        expect(Base64.decode64(opts[:data])).to eq("en:\n  a: \"b\"\n")
      ensure
        FileUtils.rm_f(tmp)
      end
    end

    describe '#all_files' do
      it 'returns all files' do
        files = described_object.send(:all_files).flatten
        expect(files).to include(
          Pathname.new(path),
          Pathname.new(relative_name)
        )
        expect(files).to include(
          Pathname.new(path_ru),
          Pathname.new(filename_ru)
        )
      end

      it 'does not return files that have to be skipped' do
        allow(described_object.config).to receive(:skip_file_export).twice.and_return(
          ->(f) { f.split[1].to_s.include?('ru') }
        )
        files = described_object.send(:all_files).sort
        expect(files[0]).to include(
          Pathname.new(path),
          Pathname.new(relative_name)
        )
        expect(files.count).to eq(1)

        expect(described_object.config).to have_received(:skip_file_export).twice
      end
    end
  end
end
