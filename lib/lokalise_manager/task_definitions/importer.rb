# frozen_string_literal: true

require 'zip'
require 'open-uri'
require 'fileutils'

module LokaliseManager
  module TaskDefinitions
    # The Importer class handles downloading translation files from Lokalise
    # and importing them into the specified project directory.
    class Importer < Base
      # Initiates the import process by checking configuration, ensuring safe mode conditions,
      # downloading files, and processing them. Outputs task completion status.
      #
      # @return [Boolean] Returns true if the import completes successfully, false if cancelled.
      def import!
        check_options_errors!

        unless proceed_when_safe_mode?
          $stdout.print('Task cancelled!') unless config.silent_mode
          return false
        end

        open_and_process_zip download_files.bundle_url

        $stdout.print('Task complete!') unless config.silent_mode
        true
      end

      private

      # Downloads translation files from Lokalise, handling retries and errors using exponential backoff.
      #
      # @return [Hash] Returns the response from Lokalise API containing download details.
      def download_files
        with_exp_backoff(config.max_retries_import) do
          api_client.download_files project_id_with_branch, config.import_opts
        end
      rescue StandardError => e
        raise e.class, "There was an error when trying to download files: #{e.message}"
      end

      # Opens a ZIP archive from a given path and processes each entry if it matches the required file extension.
      #
      # @param path [String] The URL or local path to the ZIP archive.
      def open_and_process_zip(path)
        Zip::File.open_buffer(open_file_or_remote(path)) do |zip|
          zip.each { |entry| process_entry(entry) if proper_ext?(entry.name) }
        end
      rescue StandardError => e
        raise e.class, "Error processing ZIP file: #{e.message}"
      end

      # Processes a single ZIP entry by extracting data, determining the correct directory structure,
      # and writing the data to the appropriate file.
      #
      # @param zip_entry [Zip::Entry] The ZIP entry to process.
      def process_entry(zip_entry)
        data = data_from(zip_entry)
        subdir, filename = subdir_and_filename_for(zip_entry.name)
        full_path = File.join(config.locales_path, subdir)
        FileUtils.mkdir_p full_path

        File.write(File.join(full_path, filename), config.translations_converter.call(data), mode: 'w+:UTF-8')
      rescue StandardError => e
        raise e.class, "Error processing entry #{zip_entry.name}: #{e.message}"
      end

      # Determines if the import should proceed based on the safe mode setting and the content of the target directory.
      # In safe mode, the directory must be empty, or the user must confirm continuation.
      #
      # @return [Boolean] Returns true if the import should proceed, false otherwise.
      def proceed_when_safe_mode?
        return true unless config.import_safe_mode && !Dir.empty?(config.locales_path.to_s)

        $stdout.puts "The target directory #{config.locales_path} is not empty!"
        $stdout.print 'Enter Y to continue: '
        $stdin.gets.strip.upcase == 'Y'
      end

      # Opens a local file or a remote URL using the provided path, safely handling different path schemes.
      #
      # @param path [String] The path to the file, either a local path or a URL.
      # @return [IO] Returns an IO object for the file.
      def open_file_or_remote(path)
        uri = URI.parse(path)
        uri.scheme&.start_with?('http') ? uri.open : File.open(path)
      end

      # Loads translations from the ZIP file.
      #
      # @param zip_entry [Zip::Entry] The ZIP entry to process.
      def data_from(zip_entry)
        config.translations_loader.call zip_entry.get_input_stream.read
      end
    end
  end
end
