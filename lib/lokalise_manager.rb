# frozen_string_literal: true

require 'zeitwerk'
require 'yaml'

loader = Zeitwerk::Loader.for_gem
loader.setup

# The `LokaliseManager` module provides a high-level interface for importing and exporting
# translation files between a Ruby project and the Lokalise TMS.
#
# This module simplifies interactions with the Lokalise API by exposing two factory methods:
# - `importer` → Instantiates an importer for fetching translations from Lokalise.
# - `exporter` → Instantiates an exporter for uploading translations to Lokalise.
#
# ## Example Usage:
#
# ```ruby
# importer = LokaliseManager.importer(api_token: '1234abc', project_id: '123.abc')
# exporter = LokaliseManager.exporter(api_token: '1234abc', project_id: '123.abc')
#
# importer.import!
# exporter.export!
# ```
#
module LokaliseManager
  class << self
    # Instantiates an importer for retrieving translation files from Lokalise.
    #
    # @param custom_opts [Hash] Custom options for the importer (e.g., `api_token`, `project_id`).
    # @param global_config [Object] The global configuration object (defaults to `LokaliseManager::GlobalConfig`).
    # @return [LokaliseManager::TaskDefinitions::Importer] An `Importer` instance for downloading translations.
    #
    # ## Example:
    # ```ruby
    # importer = LokaliseManager.importer(api_token: 'xyz', project_id: '456.abc')
    # importer.import!
    # ```
    #
    def importer(custom_opts = {}, global_config = LokaliseManager::GlobalConfig)
      LokaliseManager::TaskDefinitions::Importer.new custom_opts, global_config
    end

    # Instantiates an exporter for uploading translation files to Lokalise.
    #
    # @param custom_opts [Hash] Custom options for the exporter (e.g., `api_token`, `project_id`).
    # @param global_config [Object] The global configuration object (defaults to `LokaliseManager::GlobalConfig`).
    # @return [LokaliseManager::TaskDefinitions::Exporter] An `Exporter` instance for uploading translations.
    #
    # ## Example:
    # ```ruby
    # exporter = LokaliseManager.exporter(api_token: 'xyz', project_id: '456.abc')
    # exporter.export!
    # ```
    #
    def exporter(custom_opts = {}, global_config = LokaliseManager::GlobalConfig)
      LokaliseManager::TaskDefinitions::Exporter.new custom_opts, global_config
    end
  end
end
