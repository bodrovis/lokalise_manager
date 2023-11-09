# frozen_string_literal: true

require 'dotenv/load'
require 'simplecov'
require 'webmock/rspec'

SimpleCov.start do
  if ENV['CI']
    require 'simplecov-lcov'

    SimpleCov::Formatter::LcovFormatter.config do |c|
      c.report_with_single_file = true
      c.single_report_path = 'coverage/lcov.info'
    end

    formatter SimpleCov::Formatter::LcovFormatter
  end

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
