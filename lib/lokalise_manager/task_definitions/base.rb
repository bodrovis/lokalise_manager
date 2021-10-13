# frozen_string_literal: true

require 'ruby-lokalise-api'
require 'pathname'
require 'ostruct'

module LokaliseManager
  module TaskDefinitions
    class Base
      attr_accessor :options

      def initialize(custom_opts = {})
        primary_opts = LokaliseManager.singleton_methods.filter { |m| m.to_s.end_with?('=') }.each_with_object({}) do |method, opts|
          reader = method.to_s.delete_suffix('=')
          opts[reader.to_sym] = LokaliseManager.send(reader)
        end

        @options = OpenStruct.new primary_opts.merge(custom_opts)
      end

      # Creates a Lokalise API client
      #
      # @return [Lokalise::Client]
      def api_client
        @api_client ||= ::Lokalise.client options.api_token, {enable_compression: true}.merge(options.timeouts)
      end

      # Resets API client
      def reset_api_client!
        Lokalise.reset_client!
        @api_client = nil
      end

      private

      # Checks task options
      #
      # @return Array
      def check_options_errors!
        errors = []
        errors << 'Project ID is not set!' if options.project_id.nil? || options.project_id.empty?
        errors << 'Lokalise API token is not set!' if options.api_token.nil? || options.api_token.empty?

        raise(LokaliseManager::Error, errors.join(' ')) if errors.any?
      end

      # Checks whether the provided file has a proper extension as dictated by the `file_ext_regexp` option
      #
      # @return Boolean
      # @param raw_path [String, Pathname]
      def proper_ext?(raw_path)
        path = raw_path.is_a?(Pathname) ? raw_path : Pathname.new(raw_path)
        options.file_ext_regexp.match? path.extname
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
        "#{options.project_id}:#{options.branch}"
      end

      # Sends request with exponential backoff mechanism
      def with_exp_backoff(max_retries)
        return unless block_given?

        retries = 0
        begin
          yield
        rescue Lokalise::Error::TooManyRequests => e
          raise(e.class, "Gave up after #{retries} retries") if retries >= max_retries

          sleep 2**retries
          retries += 1
          retry
        end
      end
    end
  end
end
