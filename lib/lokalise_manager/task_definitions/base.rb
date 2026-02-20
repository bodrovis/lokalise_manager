# frozen_string_literal: true

require 'ruby_lokalise_api'
require 'pathname'

module LokaliseManager
  module TaskDefinitions
    # Base class for LokaliseManager task definitions.
    #
    # Provides shared functionality for Importer and Exporter classes, including:
    # - API client management.
    # - Configuration merging.
    # - File validation helpers.
    # - Exponential backoff for retrying failed API requests.
    class Base
      using LokaliseManager::Utils::HashUtils

      attr_accessor :config

      # Defines exceptions that should trigger a retry with exponential backoff.
      #
      # - `JSON::ParserError`: Occurs when the API responds with non-JSON content (e.g., HTML due to rate limits).
      # - `RubyLokaliseApi::Error::TooManyRequests`: Raised when too many requests are sent in a short period.
      EXCEPTIONS = [JSON::ParserError, RubyLokaliseApi::Error::TooManyRequests].freeze

      # All configuration-related keys
      CONFIG_KEYS = %i[
        api_token project_id import_opts import_safe_mode export_opts locales_path file_ext_regexp
        skip_file_export branch additional_client_opts translations_loader translations_converter
        lang_iso_inferer max_retries_export max_retries_import use_oauth2_token silent_mode
        raise_on_export_fail import_async export_preprocessor export_filename_generator
      ].freeze

      BACKOFF_BASE_SECONDS = 1 # base multiplier (1,2,4,8...)
      BACKOFF_CAP_SECONDS  = 32         # max sleep cap
      BACKOFF_JITTER_RANGE = 1.0        # adds rand * range

      # Initializes a new task object with merged global and custom configurations.
      #
      # @param custom_opts [Hash] Custom configuration options specific to the task.
      # @param global_config [Object] The global configuration object.
      def initialize(custom_opts = {}, global_config = LokaliseManager::GlobalConfig)
        merged_opts = merge_configs(global_config, custom_opts)
        @config = build_config_class(merged_opts)
      end

      # Retrieves or initializes the Lokalise API client based on the current configuration.
      #
      # @return [RubyLokaliseApi::Client] An instance of the Lokalise API client.
      def api_client
        @api_client ||= create_api_client
      end

      # Resets the API client, clearing cached instances.
      #
      # Useful when switching authentication tokens or handling connection issues.
      def reset_api_client!
        ::RubyLokaliseApi.reset_client!
        ::RubyLokaliseApi.reset_oauth2_client!
        @api_client = nil
      end

      private

      # Creates a new Lokalise API client instance based on the configuration.
      #
      # @return [RubyLokaliseApi::Client] The initialized API client.
      def create_api_client
        client_opts = [config.api_token, config.additional_client_opts]
        client_method = config.use_oauth2_token ? :oauth2_client : :client

        ::RubyLokaliseApi.public_send(client_method, *client_opts)
      end

      # Merges global and custom configurations.
      #
      # - Extracts all global config values.
      # - Merges them with custom options using a deep merge strategy.
      #
      # @param global_config [Object] The global configuration object.
      # @param custom_opts [Hash] The custom configuration options.
      # @return [Hash] The merged configuration.
      def merge_configs(global_config, custom_opts)
        primary_opts = CONFIG_KEYS.to_h { |k| [k, global_config.public_send(k)] }

        custom_opts = custom_opts.transform_keys(&:to_sym)

        unknown = custom_opts.keys - CONFIG_KEYS
        raise LokaliseManager::Error, "Unknown config keys: #{unknown.join(', ')}" if unknown.any?

        primary_opts.deep_merge(custom_opts)
      end

      # Constructs a configuration object from a hash of options.
      #
      # Uses a struct to provide attribute-style access to settings.
      #
      # @param all_opts [Hash] The merged configuration options.
      # @return [Struct] A configuration object.
      def build_config_class(all_opts)
        Struct.new(*all_opts.keys, keyword_init: true).new(all_opts)
      end

      # Validates required configuration options.
      #
      # @raise [LokaliseManager::Error] If required configurations are missing.
      def check_options_errors!
        errors = []
        errors << 'Project ID is not set!' if config.project_id.nil? || config.project_id.empty?
        errors << 'Lokalise API token is not set!' if config.api_token.nil? || config.api_token.empty?
        raise LokaliseManager::Error, errors.join(' ') unless errors.empty?
      end

      # Checks if a file has a valid extension based on the configuration.
      #
      # @param raw_path [String, Pathname] The file path to check.
      # @return [Boolean] `true` if the file has a valid extension, `false` otherwise.
      def proper_ext?(raw_path)
        path = raw_path.is_a?(Pathname) ? raw_path : Pathname.new(raw_path)
        config.file_ext_regexp.match? path.extname
      end

      # Constructs a Lokalise project identifier that may include a branch.
      #
      # If a branch is specified, the project ID is formatted as `project_id:branch`.
      #
      # @return [String] The formatted project identifier.
      def project_id_with_branch
        config.branch.to_s.strip.empty? ? config.project_id.to_s : "#{config.project_id}:#{config.branch}"
      end

      # Executes a block with exponential backoff for handling API rate limits and temporary failures.
      #
      # Retries the operation for a defined number of attempts, doubling the wait time after each failure.
      #
      # @param max_retries [Integer] Maximum number of retries before giving up.
      # @yield The operation to retry.
      # @return [Object] The result of the block if successful.
      def with_exp_backoff(max_retries)
        return unless block_given?

        max_retries = max_retries.to_i
        max_retries = 0 if max_retries.negative?

        retries = 0

        begin
          yield
        rescue *EXCEPTIONS => e
          raise_on_max_retries(retries, max_retries, e)

          sleep_with_backoff(retries)

          retries += 1
          retry
        end
      end

      def sleep_with_backoff(retries)
        base_sleep = BACKOFF_BASE_SECONDS.to_f * (2**retries)
        capped = [base_sleep, BACKOFF_CAP_SECONDS.to_f].min
        jitter = BACKOFF_JITTER_RANGE.to_f <= 0 ? 0.0 : rand * BACKOFF_JITTER_RANGE.to_f
        sleep(capped + jitter)
      end

      def raise_on_max_retries(retries, max_retries, error)
        # We already failed (retries+1) times total including this one.
        return unless retries >= max_retries

        # Preserve original exception class + backtrace, but add context.
        attempts = retries + 1
        raise error.class,
              "Gave up after #{retries} retries (#{attempts} attempts). Last error: #{error.class}: #{error.message}",
              error.backtrace
      end
    end
  end
end
