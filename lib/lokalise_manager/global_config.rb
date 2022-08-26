# frozen_string_literal: true

module LokaliseManager
  # Global configuration options available for LokaliseManager
  class GlobalConfig
    using LokaliseManager::Utils::PsychUtils

    class << self
      attr_accessor :api_token, :project_id
      attr_writer :import_opts, :import_safe_mode, :export_opts, :locales_path,
                  :file_ext_regexp, :skip_file_export, :branch, :timeouts,
                  :translations_loader, :translations_converter, :lang_iso_inferer,
                  :max_retries_export, :max_retries_import, :use_oauth2_token, :silent_mode,
                  :raise_on_export_fail

      # Main interface to provide configuration options
      def config
        yield self
      end

      # When enabled, will re-raise any exception that happens during file exporting
      def raise_on_export_fail
        @raise_on_export_fail || true
      end

      # When enabled, won't print any debugging info to $stdout
      def silent_mode
        @silent_mode || false
      end

      # When enabled, will use OAuth 2 Lokalise client and will require to provide a token obtained via OAuth 2 flow
      # rather than via Lokalise profile
      def use_oauth2_token
        @use_oauth2_token || false
      end

      # Full path to directory with translation files
      def locales_path
        @locales_path || "#{Dir.getwd}/locales"
      end

      # Project branch to use
      def branch
        @branch || ''
      end

      # Set request timeouts for the Lokalise API client
      def timeouts
        @timeouts || {}
      end

      # Maximum number of retries for file exporting
      def max_retries_export
        @max_retries_export || 5
      end

      # Maximum number of retries for file importing
      def max_retries_import
        @max_retries_import || 5
      end

      # Regular expression used to select translation files with proper extensions
      def file_ext_regexp
        @file_ext_regexp || /\.ya?ml\z/i
      end

      # Options for import rake task
      def import_opts
        @import_opts || {
          format: 'ruby_yaml',
          placeholder_format: :icu,
          yaml_include_root: true,
          original_filenames: true,
          directory_prefix: '',
          indentation: '2sp'
        }
      end

      # Options for export rake task
      def export_opts
        @export_opts || {}
      end

      # Enables safe mode for import. When enabled, will check whether the target folder is empty or not
      def import_safe_mode
        @import_safe_mode.nil? ? false : @import_safe_mode
      end

      # Additional file skip criteria to apply when performing export
      def skip_file_export
        @skip_file_export || ->(_) { false }
      end

      def translations_loader
        @translations_loader || ->(raw_data) { YAML.safe_load raw_data }
      end

      # Converts translations data to the proper format
      def translations_converter
        @translations_converter || ->(raw_data) { YAML.safe_dump(raw_data).gsub(/\\\\n/, '\n') }
      end

      # Infers lang ISO for the given translation file
      def lang_iso_inferer
        @lang_iso_inferer || ->(data) { YAML.safe_load(data)&.keys&.first }
      end
    end
  end
end
