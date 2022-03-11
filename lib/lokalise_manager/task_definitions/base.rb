# frozen_string_literal: true

require 'ruby_lokalise_api'
require 'pathname'

module LokaliseManager
  module TaskDefinitions
    # Base class for LokaliseManager task definitions that includes common methods and logic
    class Base
      using LokaliseManager::Utils::HashUtils

      attr_accessor :config

      # Creates a new importer or exporter. It accepts custom config and merges it
      # with the global config (custom config take precendence)
      #
      # @param custom_opts [Hash]
      # @param global_config [Object]
      def initialize(custom_opts = {}, global_config = LokaliseManager::GlobalConfig)
        primary_opts = global_config.
                       singleton_methods.
                       filter { |m| m.to_s.end_with?('=') }.
                       each_with_object({}) do |method, opts|
          reader = method.to_s.delete_suffix('=')
          opts[reader.to_sym] = global_config.send(reader)
        end

        all_opts = primary_opts.deep_merge(custom_opts)

        config_klass = Struct.new(*all_opts.keys, keyword_init: true)

        @config = config_klass.new all_opts
      end

      # Creates a Lokalise API client
      #
      # @return [RubyLokaliseApi::Client]
      def api_client
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

      # Checks task options
      #
      # @return Array
      def check_options_errors!
        errors = []
        errors << 'Project ID is not set!' if config.project_id.nil? || config.project_id.empty?
        errors << 'Lokalise API token is not set!' if config.api_token.nil? || config.api_token.empty?

        raise(LokaliseManager::Error, errors.join(' ')) if errors.any?
      end

      # Checks whether the provided file has a proper extension as dictated by the `file_ext_regexp` option
      #
      # @return Boolean
      # @param raw_path [String, Pathname]
      def proper_ext?(raw_path)
        path = raw_path.is_a?(Pathname) ? raw_path : Pathname.new(raw_path)
        config.file_ext_regexp.match? path.extname
      end

      # Returns directory and filename for the given entry
      #
      # @return Array
      # @param entry [String]
      def subdir_and_filename_for(entry)
        Pathname.new(entry).split
      end

      # Returns Lokalise project ID and branch, semicolumn separated
      #
      # @return [String]
      def project_id_with_branch
        return config.project_id.to_s if config.branch.to_s.strip.empty?

        "#{config.project_id}:#{config.branch}"
      end

      # Sends request with exponential backoff mechanism
      def with_exp_backoff(max_retries)
        return unless block_given?

        retries = 0
        begin
          yield
        rescue RubyLokaliseApi::Error::TooManyRequests => e
          raise(e.class, "Gave up after #{retries} retries") if retries >= max_retries

          sleep 2**retries
          retries += 1
          retry
        end
      end
    end
  end
end
