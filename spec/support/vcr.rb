# frozen_string_literal: true

require 'vcr'

VCR.configure do |c|
  c.ignore_hosts 'codeclimate.com'
  c.hook_into :faraday
  c.cassette_library_dir = File.join(File.dirname(__FILE__), '..', 'fixtures', 'vcr_cassettes')
  c.filter_sensitive_data('<LOKALISE_TOKEN>') do |_i|
    ENV.fetch('LOKALISE_API_TOKEN')
  end
  c.configure_rspec_metadata!
end
