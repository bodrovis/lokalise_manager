# frozen_string_literal: true

require 'dotenv/load'
require 'simplecov'
require 'webmock/rspec'

SimpleCov.start do
  skip 'spec/'
  skip '.github/'
end

require_relative '../lib/lokalise_manager'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.include FileManager
  config.include SpecAddons
  config.include Stubs
end
