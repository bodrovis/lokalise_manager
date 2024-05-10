# frozen_string_literal: true

require 'ruby_lokalise_api'
require 'pathname'

module LokaliseManager
  module TaskDefinitions
    # Base class for LokaliseManager task definitions, including common methods and logic.
    # This class serves as the foundation for importer and exporter classes, handling API
    # client interactions and configuration merging.
    class Base
      using LokaliseManager::Utils::HashUtils

      attr_accessor :config

      # Initializes a new task object by merging custom and global configurations.
      #
      # @param custom_opts [Hash] Custom configurations for specific tasks.
      # @param global_config [Object] Reference to the global configuration.
      def initialize(custom_opts = {}, global_config = LokaliseManager::GlobalConfig)
        primary_opts = global_config
                       .singleton_methods
                       .filter { |m| m.to_s.end_with?('=') }
                       .each_with_object({}) do |method, opts|
          reader = method.to_s.delete_suffix('=')
          opts[reader.to_sym] = global_config.send(reader)
        end

        all_opts = primary_opts.deep_merge(custom_opts)

        config_klass = Struct.new(*all_opts.keys, keyword_init: true)

        @config = config_klass.new all_opts
      end

      # Creates or retrieves a Lokalise API client based on configuration.
      #
      # @return [RubyLokaliseApi::Client] Lokalise API client.
      def api_client
        return @api_client if @api_client

        client_opts = [config.api_token, config.timeouts]
        client_method = config.use_oauth2_token ? :oauth2_client : :client

        @api_client = ::RubyLokaliseApi.send(client_method, *client_opts)
      end

      # Resets API client
      def reset_api_client!
        ::RubyLokaliseApi.reset_client!
        ::RubyLokaliseApi.reset_oauth2_client!
        @api_client = nil
      end

      private

      # Checks and validates task options, raising errors if configurations are missing.
      def check_options_errors!
        errors = []
        errors << 'Project ID is not set!' if config.project_id.nil? || config.project_id.empty?
        errors << 'Lokalise API token is not set!' if config.api_token.nil? || config.api_token.empty?
        raise LokaliseManager::Error, errors.join(' ') if errors.any?
      end

      # Determines if the file has the correct extension based on the configuration.
      #
      # @param raw_path [String, Pathname] Path to check.
      # @return [Boolean] True if the extension matches, false otherwise.
      def proper_ext?(raw_path)
        path = raw_path.is_a?(Pathname) ? raw_path : Pathname.new(raw_path)
        config.file_ext_regexp.match? path.extname
      end

      # Extracts the directory and filename from a given path.
      #
      # @param entry [String] The file path.
      # @return [Array] Contains [Pathname, Pathname] representing the directory and filename.
      def subdir_and_filename_for(entry)
        Pathname.new(entry).split
      end

      # Constructs a project identifier string that may include a branch.
      #
      # @return [String] Project identifier potentially including the branch.
      def project_id_with_branch
        config.branch.to_s.strip.empty? ? config.project_id.to_s : "#{config.project_id}:#{config.branch}"
      end

      # In rare cases the server might return HTML instead of JSON.
      # It happens when too many requests are being sent.
      # Until this is fixed, we revert to this quick'n'dirty solution.
      EXCEPTIONS = [JSON::ParserError, RubyLokaliseApi::Error::TooManyRequests].freeze

      # Implements an exponential backoff strategy for handling retries after failures.
      def with_exp_backoff(max_retries)
        return unless block_given?

        retries = 0
        begin
          yield
        rescue *EXCEPTIONS => e
          raise(e.class, "Gave up after #{retries} retries") if retries >= max_retries

          sleep 2**retries
          retries += 1
          retry
        end
      end
    end
  end
end
