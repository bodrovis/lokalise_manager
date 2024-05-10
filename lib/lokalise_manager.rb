# frozen_string_literal: true

require 'zeitwerk'
require 'yaml'

loader = Zeitwerk::Loader.for_gem
loader.setup

# The LokaliseManager module provides functionalities to import and export translation
# files to and from the Lokalise TMS. It simplifies interactions with the Lokalise API
# by providing a straightforward interface to instantiate importers and exporters.
#
# Example:
#   importer = LokaliseManager.importer(api_token: '1234abc', project_id: '123.abc')
#   exporter = LokaliseManager.exporter(api_token: '1234abc', project_id: '123.abc')
#   importer.import!
#   exporter.export!
#
module LokaliseManager
  class << self
    # Creates an importer object for downloading translation files from Lokalise.
    #
    # @param custom_opts [Hash] Custom options for the importer (e.g., API token and project ID).
    # @param global_config [Object] Global configuration settings, defaults to LokaliseManager::GlobalConfig.
    # @return [LokaliseManager::TaskDefinitions::Importer] An instance of the importer.
    #
    def importer(custom_opts = {}, global_config = LokaliseManager::GlobalConfig)
      LokaliseManager::TaskDefinitions::Importer.new custom_opts, global_config
    end

    # Creates an exporter object for uploading translation files to Lokalise.
    #
    # @param custom_opts [Hash] Custom options for the exporter (e.g., API token and project ID).
    # @param global_config [Object] Global configuration settings, defaults to LokaliseManager::GlobalConfig.
    # @return [LokaliseManager::TaskDefinitions::Exporter] An instance of the exporter.
    #
    def exporter(custom_opts = {}, global_config = LokaliseManager::GlobalConfig)
      LokaliseManager::TaskDefinitions::Exporter.new custom_opts, global_config
    end
  end
end
