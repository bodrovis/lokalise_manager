# frozen_string_literal: true

require File.expand_path('lib/lokalise_manager/version', __dir__)

Gem::Specification.new do |spec|
  spec.name                  = 'lokalise_manager'
  spec.version               = LokaliseManager::VERSION
  spec.authors               = ['Ilya Krukowski']
  spec.email                 = ['golosizpru@gmail.com']
  spec.summary               = 'Lokalise integration for Ruby'
  spec.description           = 'This gem contains a collection of some common tasks for Lokalise. Specifically, it allows to import/export translation files from/to Lokalise TMS.'
  spec.homepage              = 'https://github.com/bodrovis/lokalise_manager'
  spec.license               = 'MIT'
  spec.platform              = Gem::Platform::RUBY
  spec.required_ruby_version = '>= 2.7'

  spec.files = Dir['README.md', 'LICENSE',
                   'CHANGELOG.md', 'lib/**/*.rb',
                   'lib/**/*.rake',
                   'lokalise_manager.gemspec', '.github/*.md',
                   'Gemfile', 'Rakefile']
  spec.extra_rdoc_files = ['README.md']
  spec.require_paths    = ['lib']

  spec.add_dependency 'ruby-lokalise-api', '~> 7'
  spec.add_dependency 'rubyzip', '~> 2.3'
  spec.add_dependency 'zeitwerk', '~> 2.4'

  spec.add_development_dependency 'dotenv', '~> 2.5'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.6'
  spec.add_development_dependency 'rubocop', '~> 1.0'
  spec.add_development_dependency 'rubocop-performance', '~> 1.5'
  spec.add_development_dependency 'rubocop-rake', '~> 0.6'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.6'
  spec.add_development_dependency 'simplecov', '~> 0.16'
  spec.add_development_dependency 'vcr', '~> 6.0'
  spec.metadata = {
    'rubygems_mfa_required' => 'true'
  }
end
