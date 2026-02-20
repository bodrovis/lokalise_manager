# frozen_string_literal: true

require File.expand_path('lib/lokalise_manager/version', __dir__)

Gem::Specification.new do |spec|
  spec.name                  = 'lokalise_manager'
  spec.version               = LokaliseManager::VERSION
  spec.authors               = ['Ilya Krukowski']
  spec.email                 = ['golosizpru@gmail.com']
  spec.summary               = 'Lokalise integration for Ruby'
  spec.description           = 'This gem contains a collection of some common tasks for Lokalise. Specifically, ' \
                               'it allows to import/export translation files from/to Lokalise TMS.'
  spec.homepage              = 'https://github.com/bodrovis/lokalise_manager'
  spec.license               = 'MIT'
  spec.platform              = Gem::Platform::RUBY
  spec.required_ruby_version = '>= 3.0'

  spec.files = Dir['README.md', 'LICENSE',
                   'CHANGELOG.md', 'lib/**/*.rb',
                   'lokalise_manager.gemspec']
  spec.extra_rdoc_files = ['README.md']
  spec.require_paths    = ['lib']

  spec.add_dependency 'base64', '~> 0.3.0'
  spec.add_dependency 'ruby-lokalise-api', '~> 9.3'
  spec.add_dependency 'rubyzip', '>= 2.3', '< 4.0'
  spec.add_dependency 'zeitwerk', '~> 2.4'

  spec.add_development_dependency 'dotenv', '~> 3.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.13'
  spec.add_development_dependency 'rubocop', '~> 1.0'
  spec.add_development_dependency 'rubocop-performance', '~> 1.5'
  spec.add_development_dependency 'rubocop-rake', '~> 0.7'
  spec.add_development_dependency 'rubocop-rspec', '~> 3.0'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'webmock', '~> 3.18'
  spec.metadata = {
    'rubygems_mfa_required' => 'true',
    'bug_tracker_uri' => 'https://github.com/bodrovis/lokalise_manager/issues',
    'changelog_uri' => 'https://github.com/bodrovis/lokalise_manager/blob/master/CHANGELOG.md',
    'documentation_uri' => 'https://github.com/bodrovis/lokalise_manager/blob/master/README.md',
    'homepage_uri' => spec.homepage
  }
end
