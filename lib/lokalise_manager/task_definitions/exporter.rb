# frozen_string_literal: true

require 'base64'

module LokaliseManager
  module TaskDefinitions
    # Handles exporting translation files from a local project to Lokalise.
    class Exporter < Base
      # Maximum number of concurrent uploads to avoid exceeding Lokalise API rate limits.
      MAX_THREADS = 6

      ProcessResult = Struct.new(:success, :process, :path, :error, keyword_init: true)

      # Exports translation files to Lokalise in batches to optimize performance.
      #
      # - Validates configuration.
      # - Gathers translation files from the project directory.
      # - Uploads files to Lokalise in parallel, respecting API rate limits.
      # - Handles errors and ensures failed uploads are reported.
      #
      # @return [Array] An array of process results for each uploaded file.
      def export!
        check_options_errors!

        queued_processes = all_files.each_slice(MAX_THREADS).flat_map do |files_group|
          parallel_upload(files_group).tap do |threads|
            threads.each { |thr| raise_on_fail(thr) if config.raise_on_export_fail }
          end
        end

        print_completion_message unless config.silent_mode

        queued_processes
      end

      private

      # Uploads a group of files in parallel using threads.
      #
      # @param files_group [Array] List of file path pairs (full and relative).
      # @return [Array] Array of results from the upload process.
      def parallel_upload(files_group)
        files_group.map do |file_data|
          Thread.new { do_upload(*file_data) }
        end.map(&:value)
      end

      # Raises an error if a file upload thread failed.
      #
      # @param thread [Struct] The result of the file upload thread.
      def raise_on_fail(thread)
        return if thread.success

        raise thread.error
      end

      # Uploads a single file to Lokalise.
      #
      # Uses exponential backoff to retry failed uploads.
      #
      # @param f_path [Pathname] Full file path.
      # @param r_path [Pathname] Relative file path within the project.
      # @return [Struct] Struct containing upload status, process details, and error (if any).
      def do_upload(f_path, r_path)
        process = with_exp_backoff(config.max_retries_export) do
          api_client.upload_file(project_id_with_branch, opts(f_path, r_path))
        end

        ProcessResult.new(success: true, process: process, path: f_path)
      rescue StandardError => e
        ProcessResult.new(success: false, path: f_path, error: e)
      end

      # Prints a message indicating that the export process is complete.
      def print_completion_message
        $stdout.puts 'Task complete!'
      end

      # Collects all translation files that match export criteria.
      #
      # @return [Array] List of [Pathname, Pathname] pairs (full and relative paths).
      def all_files
        loc_path = Pathname.new(config.locales_path)

        Dir["#{loc_path}/**/*"].filter_map do |file|
          full_path = Pathname.new(file)
          next unless file_matches_criteria?(full_path)

          relative_path = full_path.relative_path_from(loc_path)
          [full_path, relative_path]
        end
      end

      # Constructs upload options for a file.
      #
      # Reads and encodes the file content in Base64 before sending it to Lokalise.
      #
      # @param full_path [Pathname] Full file path.
      # @param relative_path [Pathname] Relative path within the project.
      # @return [Hash] Upload options including encoded content, filename, and language.
      def opts(full_path, relative_path)
        content = File.read(full_path).strip

        {
          data: Base64.strict_encode64(config.export_preprocessor.call(content, full_path)),
          filename: config.export_filename_generator.call(full_path, relative_path).to_s,
          lang_iso: config.lang_iso_inferer.call(content, full_path)
        }.merge(config.export_opts)
      end

      # Determines if a file meets the criteria for export.
      #
      # - Must be a valid file (not a directory).
      # - Must match the allowed file extensions.
      # - Must not be explicitly skipped by `skip_file_export`.
      #
      # @param full_path [Pathname] Full file path.
      # @return [Boolean] `true` if the file should be uploaded, `false` otherwise.
      def file_matches_criteria?(full_path)
        full_path.file? && proper_ext?(full_path) &&
          !config.skip_file_export.call(full_path)
      end
    end
  end
end
