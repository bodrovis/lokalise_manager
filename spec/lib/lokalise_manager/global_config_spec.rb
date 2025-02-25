# frozen_string_literal: true

describe LokaliseManager::GlobalConfig do
  let(:fake_config) { Class.new(described_class) }

  describe 'configuration management' do
    it 'yields itself during configuration block' do
      fake_config.config do |c|
        expect(c).to eq(fake_config)
      end
    end
  end

  describe 'global options' do
    it 'allows setting project_id' do
      fake_config.project_id = '123.abc'
      expect(fake_config.project_id).to eq('123.abc')
    end

    it 'allows setting api_token' do
      fake_config.api_token = 'abc'
      expect(fake_config.api_token).to eq('abc')
    end

    it 'allows setting branch' do
      fake_config.branch = 'custom'
      expect(fake_config.branch).to eq('custom')
    end

    it 'allows setting locales_path' do
      fake_config.locales_path = '/demo/path'
      expect(fake_config.locales_path).to eq('/demo/path')
    end
  end

  describe 'boolean flags' do
    it 'allows setting raise_on_export_fail' do
      fake_config.raise_on_export_fail = false
      expect(fake_config.raise_on_export_fail).to be(false)
    end

    it 'allows setting silent_mode' do
      fake_config.silent_mode = true
      expect(fake_config.silent_mode).to be(true)
    end

    it 'allows setting use_oauth2_token' do
      fake_config.use_oauth2_token = true
      expect(fake_config.use_oauth2_token).to be(true)
    end

    it 'allows setting import_safe_mode' do
      fake_config.import_safe_mode = true
      expect(fake_config.import_safe_mode).to be(true)
    end

    it 'allows setting import_async' do
      fake_config.import_async = true
      expect(fake_config.import_async).to be(true)
    end
  end

  describe 'retry settings' do
    it 'allows setting max_retries_export' do
      fake_config.max_retries_export = 10
      expect(fake_config.max_retries_export).to eq(10)
    end

    it 'allows setting max_retries_import' do
      fake_config.max_retries_import = 10
      expect(fake_config.max_retries_import).to eq(10)
    end
  end

  describe 'path and regex settings' do
    it 'allows setting file_ext_regexp' do
      fake_config.file_ext_regexp = /\.json\z/i
      expect(fake_config.file_ext_regexp).to eq(/\.json\z/i)
    end
  end

  describe 'API client settings' do
    it 'allows setting additional_client_opts' do
      fake_config.additional_client_opts = {
        open_timeout: 100,
        timeout: 500,
        api_host: 'http://example.com'
      }

      expect(fake_config.additional_client_opts).to eq(
        open_timeout: 100,
        timeout: 500,
        api_host: 'http://example.com'
      )
    end
  end

  describe '#import_opts' do
    it 'returns default options when not set' do
      expect(fake_config.import_opts).to eq(
        format: 'ruby_yaml',
        placeholder_format: :icu,
        yaml_include_root: true,
        original_filenames: true,
        directory_prefix: '',
        indentation: '2sp'
      )
    end

    it 'merges user-defined import_opts with defaults' do
      fake_config.import_opts = { indentation: '4sp', format: 'json', export_empty_as: :empty }

      expect(fake_config.import_opts).to eq(
        format: 'json',
        placeholder_format: :icu,
        yaml_include_root: true,
        original_filenames: true,
        directory_prefix: '',
        indentation: '4sp',
        export_empty_as: :empty
      )
    end
  end

  describe '#export_opts' do
    it 'returns an empty hash by default' do
      expect(fake_config.export_opts).to eq({})
    end

    it 'allows setting export_opts' do
      fake_config.export_opts = { convert_placeholders: true, detect_icu_plurals: true }

      expect(fake_config.export_opts).to eq(
        convert_placeholders: true,
        detect_icu_plurals: true
      )
    end

    it 'ensures export_opts always returns a hash, even when set to nil' do
      fake_config.export_opts = nil

      expect(fake_config.export_opts).to eq({})
    end
  end

  describe 'custom callable settings' do
    it 'allows setting translations_loader' do
      loader = lambda(&:to_json)
      fake_config.translations_loader = loader
      expect(fake_config.translations_loader).to eq(loader)
    end

    it 'allows setting translations_converter' do
      converter = lambda(&:to_json)
      fake_config.translations_converter = converter
      expect(fake_config.translations_converter).to eq(converter)
    end

    it 'allows setting lang_iso_inferer' do
      inferer = ->(file, _) { file.to_json }
      fake_config.lang_iso_inferer = inferer
      expect(fake_config.lang_iso_inferer).to eq(inferer)
    end
  end

  describe 'conditional settings' do
    it 'allows setting skip_file_export' do
      condition = lambda(&:nil?)
      fake_config.skip_file_export = condition
      expect(fake_config.skip_file_export).to eq(condition)
    end
  end
end
