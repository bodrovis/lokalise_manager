# frozen_string_literal: true

require 'zeitwerk'
require 'yaml'

loader = Zeitwerk::Loader.for_gem
loader.setup

# LokaliseManager main module that exposes helper methods:
#
#   importer = LokaliseManager.importer api_token: '1234abc', project_id: '123.abc'
#   exporter = LokaliseManager.exporter api_token: '1234abc', project_id: '123.abc'
#
# Use the instantiated objects to import or export your translation files:
#
#   importer.import!
#   exporter.export!
#
module LokaliseManager
  class << self
    # Initializes a new importer client which is used to download
    # translation files from Lokalise to the current project
    #
    # @return [LokaliseManager::TaskDefinitions::Importer]
    # @param custom_opts [Hash]
    # @param global_config [Object]
    def importer(custom_opts = {}, global_config = LokaliseManager::GlobalConfig)
      LokaliseManager::TaskDefinitions::Importer.new custom_opts, global_config
    end

    # Initializes a new exporter client which is used to upload
    # translation files from the current project to Lokalise
    #
    # @return [LokaliseManager::TaskDefinitions::Exporter]
    # @param custom_opts [Hash]
    # @param global_config [Object]
    def exporter(custom_opts = {}, global_config = LokaliseManager::GlobalConfig)
      LokaliseManager::TaskDefinitions::Exporter.new custom_opts, global_config
    end
  end
end
