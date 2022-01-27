# frozen_string_literal: true

require 'yaml'

require 'lokalise_manager/utils/hash_utils'
require 'lokalise_manager/utils/array_utils'

require 'lokalise_manager/version'
require 'lokalise_manager/error'
require 'lokalise_manager/global_config'
require 'lokalise_manager/task_definitions/base'
require 'lokalise_manager/task_definitions/importer'
require 'lokalise_manager/task_definitions/exporter'

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
