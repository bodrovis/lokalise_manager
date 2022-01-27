# frozen_string_literal: true

require 'base64'

module LokaliseManager
  module TaskDefinitions
    class Exporter < Base
      using LokaliseManager::Utils::ArrayUtils
      # Performs translation file export to Lokalise and returns an array of queued processes
      #
      # @return [Array]
      def export!
        check_options_errors!

        queued_processes = []

        all_files.in_groups_of(6) do |files_group|
          parallel_upload(files_group).each do |thr|
            raise_on_fail thr

            queued_processes.push thr[:process]
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
        raise thread[:error].class, "Error while trying to upload #{thread[:path]}: #{thread[:error].message}" if thread[:status] == :fail
      end

      # Performs the actual file uploading to Lokalise. If the API rate limit is exceeed,
      # applies exponential backoff
      def do_upload(f_path, r_path)
        Thread.new do
          process = with_exp_backoff(config.max_retries_export) do
            api_client.upload_file project_id_with_branch, opts(f_path, r_path)
          end
          {status: :ok, process: process}
        rescue StandardError => e
          {status: :fail, path: f_path, error: e}
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
