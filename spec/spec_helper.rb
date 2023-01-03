# frozen_string_literal: true

require 'dotenv/load'
require 'simplecov'

SimpleCov.start do
  add_filter 'spec/'
  add_filter '.github/'
end

require 'lokalise_manager'

# Support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.include FileManager
  config.include SpecAddons
end
