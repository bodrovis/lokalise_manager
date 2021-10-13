# LokaliseManager

![Gem](https://img.shields.io/gem/v/lokalise_manager)
[![Build Status](https://travis-ci.com/bodrovis/lokalise_manager.svg?branch=master)](https://travis-ci.com/github/bodrovis/lokalise_rails)
[![Test Coverage](https://codecov.io/gh/bodrovis/lokalise_manager/graph/badge.svg)](https://codecov.io/gh/bodrovis/lokalise_rails)
![Downloads total](https://img.shields.io/gem/dt/lokalise_manager)

This gem provides [Lokalise](http://lokalise.com) integration for Ruby and allows to exchange translation files easily. It relies on [ruby-lokalise-api](https://lokalise.github.io/ruby-lokalise-api) to send APIv2 requests.

If you are looking for a Rails integration, please check [lokalise_rails](https://github.com/bodrovis/lokalise_rails) which provides a set of Rake tasks for importing/exporting.

## Getting started

### Requirements

This gem requires Ruby 2.5+. You will also need to [setup a Lokalise account](https://app.lokalise.com/signup) and create a [translation project](https://docs.lokalise.com/en/articles/1400460-projects). Finally, you will need to generate a [read/write API token](https://docs.lokalise.com/en/articles/1929556-api-tokens) at your Lokalise profile.

### Installation

Add the gem to your `Gemfile`:

```ruby
gem 'lokalise_manager'
```

and run:

```
bundle
```

### Performing import/export

To import or export translation files, you'll have to create the corresponding client:

```ruby
importer = LokaliseManager.importer api_token: '1234abc', project_id: '123.abc'

# OR

exporter = LokaliseManager.exporter api_token: '1234abc', project_id: '123.abc'
```

You must provide an API token and the project ID (project ID can be found in your Lokalise project settings.)

Now you can launch the corresponding operation:

```ruby
result = importer.import! # => Returns `true` or `false`

# OR

processes = exporter.export! # => Returns an array of queued background processes (file uploading in performed in the background on Lokalise)
```

Please note that upon importing translations any duplicating files inside the `locales` directory (or any other directory that you've specified in the options) will be overwritten! You can enable [safe mode](https://github.com/bodrovis/lokalise_rails#import-settings) to check whether the folder is empty or not.

Other options can be customized as well (see below) but they have sensible defaults.

## Configuration

### Common config

* `api_token` (`string`, required) — Lokalise API token with read/write permissions.
* `project_id` (`string`, required) — Lokalise project ID. You must have import/export permissions in the specified project.
* `locales_path` (`string`) — path to the directory with your translation files. Defaults to `"#{Dir.getwd}/locales"`.
* `branch` (`string`) — Lokalise project branch to use. Defaults to `"master"`.
* `timeouts` (`hash`) — set [request timeouts for the Lokalise API client](https://lokalise.github.io/ruby-lokalise-api/additional_info/customization#setting-timeouts). By default, requests have no timeouts: `{open_timeout: nil, timeout: nil}`. Both values are in seconds.

### Import config

* `import_opts` (`hash`) — options that will be passed to Lokalise API when downloading translations to your app. Here are the default options:

```ruby
{
  format: 'yaml',
  placeholder_format: :icu,
  yaml_include_root: true,
  original_filenames: true,
  directory_prefix: '',
  indentation: '2sp'
}
```

Full list of available import options [can be found in the official API documentation](https://app.lokalise.com/api2docs/curl/#transition-download-files-post).

You can provide additional options, and they will be merged with the default ones. For example:

```ruby
importer = LokaliseManager.importer api_token: '1234abc',
                                    project_id: '123.abc',
                                    import_opts: {original_filenames: true}
```

In this case the `import_opts` will have `original_filenames` set to `true` and will also contain all the defaults (`format`, `placeholder_format`, and others).

* `import_safe_mode` (`boolean`) — default to `false`. When this option is enabled, the import task will check whether the directory set with `locales_path` is empty or not. If it is not empty, you will be prompted to continue.
* `max_retries_import` (`integer`) — this option is introduced to properly handle Lokalise API rate limiting. If the HTTP status code 429 (too many requests) has been received, LokaliseRails will apply an exponential backoff mechanism with a very simple formula: `2 ** retries`. If the maximum number of retries has been reached, a `Lokalise::Error::TooManyRequests` exception will be raised and the export operation will be halted.

### Export config

* `export_opts` (`hash`) — options that will be passed to Lokalise API when uploading translations. Full list of available export options [can be found in the official documentation](https://app.lokalise.com/api2docs/curl/#transition-upload-a-file-post). By default, the following options are provided:
  + `data` (`string`, required) — base64-encoded contents of the translation file.
  + `filename` (`string`, required) — translation file name. If the file is stored under a subdirectory (for example, `nested/en.yml` inside the `locales/` directory), the whole path acts as a name. Later when importing files with such names, they will be placed into the proper subdirectories.
  + `lang_iso` (`string`, required) — language ISO code which is determined using the root key inside your YAML file. For example, in this case the `lang_iso` is `en_US`:

```yaml
en_US:
  my_key: "my value"
```

You can provide additional options, and they will be merged with the default ones. For example:

```ruby
exporter = LokaliseManager.exporter api_token: '1234abc',
                                    project_id: '123.abc',
                                    export_opts: {detect_icu_plurals: true}
```

In this case the `export_opts` will have `detect_icu_plurals` set to `true` and will also contain all the defaults (`data`, `filename`, and `lang_iso`).

**Please note** that if your Lokalise project does not have a language with the specified `lang_iso` code, the export will fail.

* `skip_file_export` (`lambda` or `proc`) — specify additional exclusion criteria for the exported files. By default, the rake task will ignore all non-file entries and all files with improper extensions (the latter is controlled by the `file_ext_regexp`). Lambda passed to this option should accept a single argument which is full path to the file (instance of the [`Pathname` class](https://ruby-doc.org/stdlib-2.7.1/libdoc/pathname/rdoc/Pathname.html)). For example, to exclude all files that have `fr` part in their names, add the following config:

```ruby
c.skip_file_export = ->(file) { f.split[1].to_s.include?('fr') }
```

* `max_retries_export` (`integer`) — this option is introduced to properly handle Lokalise API rate limiting. If the HTTP status code 429 (too many requests) has been received, LokaliseRails will apply an exponential backoff mechanism with a very simple formula: `2 ** retries` (initially `retries` is `0`). If the maximum number of retries has been reached, a `Lokalise::Error::TooManyRequests` exception will be raised and the export operation will be halted. By default, LokaliseRails will make up to `5` retries which potentially means `1 + 2 + 4 + 8 + 16 + 32 = 63` seconds of waiting time. If the `max_retries_export` is less than `1`, LokaliseRails will not perform any retries and give up immediately after receiving error 429.

### Config to work with formats other than YAML

If your translation files are not in YAML format, you will need to adjust the following options:

* `file_ext_regexp` (`regexp`) — regular expression applied to file extensions to determine which files should be imported and exported. Defaults to `/\.ya?ml\z/i` (YAML files).
* `translations_loader` (`lambda` or `proc`) — loads translations data and makes sure they are valid before saving them to a translation file. Defaults to `->(raw_data) { YAML.safe_load raw_data }`. In the simplest case you may just return the data back, for example `-> (raw_data) { raw_data }`.
* `translations_converter` (`lambda` or `proc`) — converts translations data to a proper format before saving them to a translation file. Defaults to `->(raw_data) { raw_data.to_yaml }`. In the simplest case you may just return the data back, for example `-> (raw_data) { raw_data }`.
* `lang_iso_inferer` (`lambda` or `proc`) — infers language ISO code based on the translation file data before uploading it to Lokalise. Defaults to `->(data) { YAML.safe_load(data)&.keys&.first }`.


## Providing config options
### Per-client

The simplest way to provide your config is on per-client basis, for example:

```ruby
importer = LokaliseManager.importer api_token: '1234abc',
                                    project_id: '123.abc',
                                    import_opts: {original_filenames: true},
                                    export_opts: {detect_icu_plurals: true},
                                    translations_converter: -> (raw_data) { raw_data }
```

These options will be merged with the default ones. Please note that per-client config has the highest priority.

You can also individual options later using the `#config` instance variable (it contains an OpenStruct object):

```
importer.config.project_id = '678xyz'
importer.config.branch = 'develop'
```

### Globally

You can also provide config globally. To achieve that, call `.config` on `LokaliseManager::Config` class:

```ruby
LokaliseManager::Config.config do |c|
  c.api_token = '12345'
  c.project_id = '123.abc'

  c.branch = 'develop'
end
```

Global config takes precedence over the default options, however per-client config has higher precedence.

### Overriding defaults

You can even subclass the default `Config` class and provide the new defaults:

```ruby
class CustomConfig < LokaliseManager::GlobalConfig
  class << self
    def branch
      @branch || 'develop'
    end

    def locales_path
      @locales_path || "#{Dir.getwd}/locales"
    end
  end
end
```

Check `global_config.rb` source to find other defaults.

Now when you have created a custom config, you can also set some global options (this is not required though):

```ruby
CustomConfig.config do |c|
  c.api_token = '123'
  c.project_id = '456.abc'
end
```

However, it's required to pass your new class when instantiating the clients:

```ruby
importer = LokaliseManager.importer({}, CustomConfig)
```

Please note that round brackets are required in this case.

The first argument is your per-client options, whereas the second argument contains the class with all the defaults.

Of course, you can still provide options on per-client basis:

```ruby
importer = LokaliseManager.importer({api_token: '890abcdef'}, CustomConfig)

# Now we can run the import process as before:

importer.import!
```

## Running tests

1. Copypaste `.env.example` file as `.env`. Put your Lokalise API token and project ID inside. The `.env` file is excluded from version control so your data is safe. All in all, we use pre-recorded VCR cassettes, so the actual API requests won’t be sent. However, providing at least some values is required.
2. Run `rspec .`. Observe test results and code coverage.

## License

Copyright (c) [Lokalise team](http://lokalise.com), [Ilya Bodrov](http://bodrovis.tech). License type is [MIT](https://github.com/bodrovis/lokalise_manager/blob/master/LICENSE).