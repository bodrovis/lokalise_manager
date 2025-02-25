# frozen_string_literal: true

module LokaliseManager
  # GlobalConfig provides a central place to manage configuration settings for LokaliseManager.
  # It allows setting various operational parameters such as API tokens, paths, and behavior modifiers.
  class GlobalConfig
    class << self
      attr_accessor :api_token, :project_id
      attr_writer :import_opts, :import_safe_mode, :export_opts, :locales_path,
                  :file_ext_regexp, :skip_file_export, :branch, :additional_client_opts,
                  :translations_loader, :translations_converter, :lang_iso_inferer,
                  :max_retries_export, :max_retries_import, :use_oauth2_token, :silent_mode,
                  :raise_on_export_fail, :import_async

      # Yield self to block for configuration
      def config
        yield self
      end

      # Return whether to raise on export failure
      def raise_on_export_fail
        @raise_on_export_fail.nil? ? true : @raise_on_export_fail
      end

      # Return whether debugging information is suppressed
      def silent_mode
        @silent_mode || false
      end

      # Return whether to use OAuth2 tokens instead of regular API tokens
      def use_oauth2_token
        @use_oauth2_token || false
      end

      # Return the path to locales
      def locales_path
        @locales_path || "#{Dir.getwd}/locales"
      end

      # Return the project branch
      def branch
        @branch || ''
      end

      # Return additional API client options
      def additional_client_opts
        @additional_client_opts || {}
      end

      # Return the max retries for export
      def max_retries_export
        @max_retries_export || 5
      end

      # Return the max retries for import
      def max_retries_import
        @max_retries_import || 5
      end

      # Return the regex for file extensions
      def file_ext_regexp
        @file_ext_regexp || /\.ya?ml\z/i
      end

      # Return import options with defaults
      def import_opts
        defaults = {
          format: 'ruby_yaml',
          placeholder_format: :icu,
          yaml_include_root: true,
          original_filenames: true,
          directory_prefix: '',
          indentation: '2sp'
        }

        defaults.merge(@import_opts || {})
      end

      # Return export options
      def export_opts
        @export_opts || {}
      end

      # Return whether import should check if target is empty
      def import_safe_mode
        @import_safe_mode.nil? ? false : @import_safe_mode
      end

      # Return whether import should be performed asynchronously
      def import_async
        @import_async.nil? ? false : @import_async
      end

      # Return whether to skip file export based on a lambda condition
      def skip_file_export
        @skip_file_export || ->(_) { false }
      end

      # Load translations from raw data
      def translations_loader
        @translations_loader || ->(raw_data) { YAML.safe_load(raw_data) }
      end

      # Convert raw translation data to YAML format
      def translations_converter
        @translations_converter || ->(raw_data) { YAML.dump(raw_data).gsub('\\\\n', '\n') }
      end

      # Infer language ISO code from translation file
      def lang_iso_inferer
        @lang_iso_inferer || ->(data, _path) { YAML.safe_load(data)&.keys&.first }
      end
    end
  end
end
