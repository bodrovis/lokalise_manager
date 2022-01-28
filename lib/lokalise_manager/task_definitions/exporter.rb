# frozen_string_literal: true

require 'base64'

module LokaliseManager
  module TaskDefinitions
    class Exporter < Base
      using LokaliseManager::Utils::ArrayUtils

      # Lokalise allows no more than 6 requests per second
      MAX_THREADS = 6

      # Performs translation file export to Lokalise and returns an array of queued processes
      #
      # @return [Array]
      def export!
        check_options_errors!

        queued_processes = []

        all_files.each_slice(MAX_THREADS) do |files_group|
          parallel_upload(files_group).each do |thr|
            raise_on_fail(thr) if config.raise_on_export_fail

            queued_processes.push thr
          end
        end

        $stdout.print('Task complete!') unless config.silent_mode

        queued_processes
      end

      private

      def parallel_upload(files_group)
        files_group.compact.map do |file_data|
          do_upload(*file_data)
        end.map(&:value)
      end

      def raise_on_fail(thread)
        raise(thread.error.class, "Error while trying to upload #{thread.path}: #{thread.error.message}") unless thread.success
      end

      # Performs the actual file uploading to Lokalise. If the API rate limit is exceeed,
      # applies exponential backoff
      def do_upload(f_path, r_path)
        proc_klass = Struct.new(:success, :process, :path, :error, keyword_init: true)

        Thread.new do
          process = with_exp_backoff(config.max_retries_export) do
            api_client.upload_file project_id_with_branch, opts(f_path, r_path)
          end
          proc_klass.new success: true, process: process, path: f_path
        rescue StandardError => e
          proc_klass.new success: false, path: f_path, error: e
        end
      end

      # Gets translation files from the specified directory
      def all_files
        files = []
        loc_path = config.locales_path
        Dir["#{loc_path}/**/*"].sort.each do |f|
          full_path = Pathname.new f

          next unless file_matches_criteria? full_path

          relative_path = full_path.relative_path_from Pathname.new(loc_path)

          files << [full_path, relative_path]
        end
        files
      end

      # Generates export options
      #
      # @return [Hash]
      # @param full_p [Pathname]
      # @param relative_p [Pathname]
      def opts(full_p, relative_p)
        content = File.read full_p

        initial_opts = {
          data: Base64.strict_encode64(content.strip),
          filename: relative_p,
          lang_iso: config.lang_iso_inferer.call(content)
        }

        initial_opts.merge config.export_opts
      end

      # Checks whether the specified file has to be processed or not
      #
      # @return [Boolean]
      # @param full_path [Pathname]
      def file_matches_criteria?(full_path)
        full_path.file? && proper_ext?(full_path) &&
          !config.skip_file_export.call(full_path)
      end
    end
  end
end
