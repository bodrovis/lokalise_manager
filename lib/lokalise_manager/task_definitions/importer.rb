# frozen_string_literal: true

require 'zip'
require 'open-uri'
require 'fileutils'

module LokaliseManager
  module TaskDefinitions
    # Importer class is used when you want to download translation files from Lokalise into your project
    class Importer < Base
      # Performs translation files import from Lokalise
      #
      # @return [Boolean]
      def import!
        check_options_errors!

        unless proceed_when_safe_mode?
          $stdout.print('Task cancelled!') unless config.silent_mode
          return false
        end

        open_and_process_zip download_files['bundle_url']

        $stdout.print('Task complete!') unless config.silent_mode
        true
      end

      private

      # Downloads files from Lokalise using the specified config.
      # Utilizes exponential backoff if "too many requests" error is received
      #
      # @return [Hash]
      def download_files
        with_exp_backoff(config.max_retries_import) do
          api_client.download_files project_id_with_branch, config.import_opts
        end
      rescue StandardError => e
        raise e.class, "There was an error when trying to download files: #{e.message}"
      end

      # Opens ZIP archive (local or remote) with translations and processes its entries
      #
      # @param path [String]
      def open_and_process_zip(path)
        Zip::File.open_buffer(open_file_or_remote(path)) do |zip|
          fetch_zip_entries(zip) { |entry| process!(entry) }
        end
      rescue StandardError => e
        raise e.class, "There was an error when trying to process the downloaded files: #{e.message}"
      end

      # Iterates over ZIP entries. Each entry may be a file or folder.
      def fetch_zip_entries(zip)
        return unless block_given?

        zip.each do |entry|
          next unless proper_ext? entry.name

          yield entry
        end
      end

      # Processes ZIP entry by reading its contents and creating the corresponding translation file
      def process!(zip_entry)
        data = data_from zip_entry
        subdir, filename = subdir_and_filename_for zip_entry.name
        full_path = "#{config.locales_path}/#{subdir}"
        FileUtils.mkdir_p full_path

        File.open(File.join(full_path, filename), 'w+:UTF-8') do |f|
          f.write config.translations_converter.call(data)
        end
      rescue StandardError => e
        raise e.class, "Error when trying to process #{zip_entry&.name}: #{e.message}"
      end

      # Checks whether the user wishes to proceed when safe mode is enabled and the target directory is not empty
      #
      # @return [Boolean]
      def proceed_when_safe_mode?
        return true unless config.import_safe_mode && !Dir.empty?(config.locales_path.to_s)

        $stdout.puts "The target directory #{config.locales_path} is not empty!"
        $stdout.print 'Enter Y to continue: '
        answer = $stdin.gets
        answer.to_s.strip == 'Y'
      end

      # Opens a local file or a remote URL using the provided patf
      #
      # @return [String]
      def open_file_or_remote(path)
        parsed_path = URI.parse(path)
        if parsed_path&.scheme&.include?('http')
          parsed_path.open
        else
          File.open path
        end
      end

      def data_from(zip_entry)
        config.translations_loader.call zip_entry.get_input_stream.read
      end
    end
  end
end
