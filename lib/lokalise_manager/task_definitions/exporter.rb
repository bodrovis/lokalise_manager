# frozen_string_literal: true

require 'base64'

module LokaliseManager
  module TaskDefinitions
    # Class to handle exporting translation files from a local project to Lokalise.
    class Exporter < Base
      # Maximum number of concurrent uploads to avoid exceeding Lokalise API rate limits.
      MAX_THREADS = 6

      # Exports translation files to Lokalise and handles any necessary concurrency and error checking.
      #
      # @return [Array] An array of process statuses for each file uploaded.
      def export!
        check_options_errors!

        queued_processes = []

        all_files.each_slice(MAX_THREADS) do |files_group|
          parallel_upload(files_group).each do |thr|
            raise_on_fail(thr) if config.raise_on_export_fail

            queued_processes.push thr
          end
        end

        print_completion_message unless config.silent_mode

        queued_processes
      end

      private

      # Handles parallel uploads of a group of files, utilizing threading.
      #
      # @param files_group [Array] Group of files to be uploaded.
      # @return [Array] Array of threads handling the file uploads.

      def parallel_upload(files_group)
        files_group.map do |file_data|
          Thread.new { do_upload(*file_data) }
        end.map(&:value)
      end

      def raise_on_fail(thread)
        return if thread.success

        raise(thread.error.class, "Error while trying to upload #{thread.path}: #{thread.error.message}")
      end

      # Performs the actual upload of a file to Lokalise.
      #
      # @param f_path [Pathname] Full path to the file.
      # @param r_path [Pathname] Relative path of the file within the project.
      # @return [Struct] A struct with the success status, process details, and any error information.
      def do_upload(f_path, r_path)
        proc_klass = Struct.new(:success, :process, :path, :error, keyword_init: true)
        begin
          process = with_exp_backoff(config.max_retries_export) do
            api_client.upload_file(project_id_with_branch, opts(f_path, r_path))
          end
          proc_klass.new(success: true, process: process, path: f_path)
        rescue StandardError => e
          proc_klass.new(success: false, path: f_path, error: e)
        end
      end

      # Prints a completion message to standard output.
      def print_completion_message
        $stdout.print('Task complete!')
      end

      # Gets translation files from the specified directory
      def all_files
        loc_path = config.locales_path
        Dir["#{loc_path}/**/*"].filter_map do |f|
          full_path = Pathname.new f

          next unless file_matches_criteria? full_path

          relative_path = full_path.relative_path_from Pathname.new(loc_path)

          [full_path, relative_path]
        end
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
          lang_iso: config.lang_iso_inferer.call(content, full_p)
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
