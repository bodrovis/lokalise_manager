# frozen_string_literal: true

require 'dotenv/load'
require 'simplecov'
require 'webmock/rspec'

SimpleCov.start do
  add_filter 'spec/'
  add_filter '.github/'
end

require_relative '../lib/lokalise_manager'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.include FileManager
  config.include SpecAddons
  config.include Stubs
end
