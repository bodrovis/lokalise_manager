# frozen_string_literal: true

require 'zip'
require 'open-uri'
require 'fileutils'

module LokaliseManager
  module TaskDefinitions
    # Handles downloading translation files from Lokalise and importing them into the project directory.
    class Importer < Base
      # Initiates the translation import process.
      #
      # - Validates configuration.
      # - Ensures safe mode conditions are met.
      # - Downloads translation files.
      # - Extracts and processes the downloaded files.
      #
      # @return [Boolean] Returns `true` if the import completes successfully, `false` if cancelled.
      def import!
        check_options_errors!

        unless proceed_when_safe_mode?
          $stdout.print('Task cancelled!') unless config.silent_mode
          return false
        end

        open_and_process_zip(download_bundle)

        $stdout.print('Task complete!') unless config.silent_mode
        true
      end

      private

      # Retrieves the download URL of the translation files.
      #
      # If `import_async` is enabled, initiates an asynchronous download process.
      #
      # @return [String] The URL of the downloaded translation bundle.
      def download_bundle
        return download_files.bundle_url unless config.import_async

        process = download_files_async
        process.details['download_url'] || process.details[:download_url]
      end

      # Downloads translation files from Lokalise using a synchronous request.
      #
      # Handles retries and errors using exponential backoff.
      #
      # @return [Hash] The response from Lokalise API containing download details.
      def download_files
        fetch_with_retry { api_client.download_files(project_id_with_branch, config.import_opts) }
      end

      # Initiates an asynchronous download request for translation files.
      #
      # Waits for the process to complete before proceeding.
      #
      # @return [QueuedProcess] The completed async download process object.
      def download_files_async
        process = fetch_with_retry { api_client.download_files_async(project_id_with_branch, config.import_opts) }
        wait_for_async_download(process.process_id)
      end

      # Waits for an asynchronous translation file download process to finish.
      #
      # Uses exponential backoff for polling the process status.
      #
      # @param process_id [String] The ID of the asynchronous process.
      # @return [QueuedProcess] The process object when completed successfully.
      # @raise [LokaliseManager::Error] If the process fails or takes too long.
      def wait_for_async_download(process_id)
        (config.max_retries_import + 1).times do |i|
          process = reload_process(process_id)

          case process.status
          when 'failed' then raise LokaliseManager::Error, 'Asynchronous download process failed'
          when 'finished' then return process
          end

          sleep_with_backoff(i)
        end

        raise LokaliseManager::Error, "Asynchronous download process timed out after #{config.max_retries_import} tries"
      end

      # Retrieves the latest status of an asynchronous download process.
      #
      # @param process_id [String] The process ID to check.
      # @return [QueuedProcess] The process object with updated status.
      def reload_process(process_id)
        api_client.queued_process project_id_with_branch, process_id
      end

      # Extracts and processes files from a ZIP archive.
      #
      # @param path [String] The URL or local path to the ZIP archive.
      def open_and_process_zip(path)
        io = open_file_or_remote(path)
        Zip::File.open_buffer(io) do |zip|
          zip.each { |entry| process_entry(entry) if proper_ext?(entry.name) }
        end
      ensure
        io.close if io && !io.closed?
      end

      # Extracts data from a ZIP entry and writes it to the correct directory.
      #
      # - Extracts file content.
      # - Determines the appropriate subdirectory and filename.
      # - Writes the processed file.
      #
      # @param zip_entry [Zip::Entry] The ZIP entry to process.
      def process_entry(zip_entry)
        data = data_from(zip_entry)
        dest = safe_dest_path(zip_entry.name)
        return unless dest

        FileUtils.mkdir_p(dest.dirname)
        File.write(dest, config.translations_converter.call(data), mode: 'w:UTF-8')
      end

      def safe_dest_path(entry_name)
        base = Pathname.new(config.locales_path).expand_path
        normalized = entry_name.tr('\\', '/')
        dest = base.join(normalized).cleanpath
        base_s = base.to_s
        dest_s = dest.to_s
        return nil unless dest_s == base_s || dest_s.start_with?(base_s + File::SEPARATOR)

        dest
      end

      # Checks whether the import should proceed under safe mode constraints.
      #
      # If `import_safe_mode` is enabled, the target directory must be empty,
      # or the user must explicitly confirm continuation.
      #
      # @return [Boolean] `true` if the import should proceed, `false` otherwise.
      def proceed_when_safe_mode?
        path = config.locales_path.to_s
        return true unless config.import_safe_mode
        return true unless Dir.exist?(path)
        return true if Dir.empty?(path)

        $stdout.puts "The target directory #{path} is not empty!"
        $stdout.print 'Enter Y to continue: '
        $stdin.gets.strip.upcase == 'Y'
      end

      # Opens a local file or downloads a remote file.
      #
      # @param path [String] The file path (local or URL).
      # @return [IO] An IO object for reading the file.
      def open_file_or_remote(path)
        uri = URI.parse(path)
        uri.scheme&.start_with?('http') ? uri.open(open_timeout: 10, read_timeout: 60) : File.open(path)
      end

      # Reads and processes data from a ZIP file entry.
      #
      # @param zip_entry [Zip::Entry] The ZIP entry containing translation data.
      # @return [String] The extracted file content.
      def data_from(zip_entry)
        config.translations_loader.call zip_entry.get_input_stream.read
      end

      # Executes a block with exponential backoff for retrying failed operations.
      #
      # @yield The operation to retry.
      # @return [Object] The result of the successful operation.
      def fetch_with_retry(&block)
        with_exp_backoff(config.max_retries_import, &block)
      end

      # Extracts the subdirectory and filename from a given path.
      #
      # @param entry [String] The file path.
      # @return [Array<Pathname, Pathname>] An array containing the subdirectory and filename.
      def subdir_and_filename_for(entry)
        Pathname.new(entry).split
      end
    end
  end
end
