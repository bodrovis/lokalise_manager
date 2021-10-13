# frozen_string_literal: true

require 'yaml'

require 'lokalise_manager/version'
require 'lokalise_manager/error'
require 'lokalise_manager/global_config'
require 'lokalise_manager/task_definitions/base'
require 'lokalise_manager/task_definitions/importer'
require 'lokalise_manager/task_definitions/exporter'

module LokaliseManager
  class << self
    def importer(custom_opts = {}, global_config = LokaliseManager::GlobalConfig)
      LokaliseManager::TaskDefinitions::Importer.new custom_opts, global_config
    end

    def exporter(custom_opts = {}, global_config = LokaliseManager::GlobalConfig)
      LokaliseManager::TaskDefinitions::Exporter.new custom_opts, global_config
    end
  end
end
