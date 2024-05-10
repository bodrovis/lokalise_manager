# LokaliseManager

![Gem](https://img.shields.io/gem/v/lokalise_manager)
![CI](https://github.com/bodrovis/lokalise_manager/actions/workflows/ci.yml/badge.svg)
[![Coverage Status](https://coveralls.io/repos/github/bodrovis/lokalise_manager/badge.svg?branch=master)](https://coveralls.io/github/bodrovis/lokalise_manager?branch=master)
[![Maintainability](https://api.codeclimate.com/v1/badges/9b682367a274ee3dcdee/maintainability)](https://codeclimate.com/github/bodrovis/lokalise_manager/maintainability)
![Downloads total](https://img.shields.io/gem/dt/lokalise_manager)

The LokaliseManager gem provides seamless integration with [Lokalise](http://lokalise.com), enabling easy exchange of translation files between your Ruby project and the Lokalise translation management system (TMS). It leverages the [ruby-lokalise-api](https://lokalise.github.io/ruby-lokalise-api) to send and manage APIv2 requests.

For integration directly with Rails applications, refer to [lokalise_rails](https://github.com/bodrovis/lokalise_rails), which offers a suite of Rake tasks specifically designed for importing and exporting translation files.

## Getting Started

### Requirements

- **Ruby version**: Ruby 3.0 or higher is required.
- **Lokalise account**: You must have an active [Lokalise account](https://app.lokalise.com/signup).
- **Project setup**: Create a [translation project](https://docs.lokalise.com/en/articles/1400460-projects) within your Lokalise account.
- **API token**: Obtain a read/write [API token](https://docs.lokalise.com/en/articles/1929556-api-tokens) from your Lokalise profile.

### Optional

- **OAuth 2 token**: If you prefer using an OAuth 2 token instead of a standard API token, set the `:use_oauth2_token` option to `true` in your configuration settings.

### Installation

Add the gem to your `Gemfile`:

```ruby
gem 'lokalise_manager'
```

and run:

```
bundle
```

### Creating a client

To import or export translation files, you'll have to create the corresponding client:

```ruby
importer = LokaliseManager.importer api_token: '1234abc', project_id: '123.abc'

# OR

exporter = LokaliseManager.exporter api_token: '1234abc', project_id: '123.abc'
```

You *must* provide an API token and a project ID (your project ID can be found under Lokalise project settings). [Other options can be customized as well (see below)](#configuration) but they have sensible defaults.

### Importing files from Lokalise into your project

To download translation files from Lokalise into your project (by default all files will be stored under the `locales/` directory), run the following code:

```ruby
result = importer.import!
```

The `result` will contain a boolean value which says whether the operation was successfull or not.

Please note that upon importing translations any duplicating files inside the `locales` directory (or any other directory that you've specified in the options) **will be overwritten**! You can enable [safe mode](#import-config) to check whether the folder is empty or not.

### Exporting files from your project to Lokalise

To upload your translation files from a local directory (defaults to `locales/`) to a Lokalise project, run the following code: 

```ruby
processes = exporter.export!
```

The uploading process is multi-threaded.

`processes` will contain an array of objects responding to the following methods:

* `#success` — usually returns `true` (to learn more, check documentation for the `:raise_on_export_fail` option below)
* `#process` — returns an object (an instance of the `RubyLokaliseApi::Resources::QueuedProcess`) representing a [queued background process](https://lokalise.github.io/ruby-lokalise-api/api/queued-processes) as uploading is done in the background on Lokalise.
* `#path` — returns an instance of the `Pathname` class which represent the file being uploaded.

You can perform periodic checks to read the status of the process. Here's a very simple example:

```ruby
def uploaded?(process)
  5.times do # try to check the status 5 times
    process = process.reload_data # load new info about this process
    return(true) if process.status == 'finished' # return true if the upload has finished
    sleep 1 # wait for 1 second, adjust this number with regards to the upload size
  end

  false # if all 5 checks failed, return false (probably something is wrong)
end

processes = exporter.export!
puts "Checking status for the #{processes[0].path} file"
uploaded? processes[0].process
```

Please don't forget that Lokalise API has rate limiting and you cannot send more than six requests per second.

## Configuration

### Common config

* `api_token` (`string`, required) — Lokalise API token with read/write permissions.
* `use_oauth2_token` (`boolean`) — whether you would like to use a token obtained via [OAuth 2 flow](https://docs.lokalise.com/en/articles/5574713-oauth-2). Defaults to `false`.
* `project_id` (`string`, required) — Lokalise project ID. You must have import/export permissions in the specified project.
* `locales_path` (`string`) — path to the directory with your translation files. Defaults to `"#{Dir.getwd}/locales"`.
* `branch` (`string`) — Lokalise project branch to use. Defaults to `""` (no branch is provided).
* `timeouts` (`hash`) — set [request timeouts for the Lokalise API client](https://lokalise.github.io/ruby-lokalise-api/additional_info/customization#setting-timeouts). By default, requests have no timeouts: `{open_timeout: nil, timeout: nil}`. Both values are in seconds.
* `silent_mode` (`boolean`) — whether you would like to output debugging information to `$stdout`. By default, after a task is performed, a short notification message will be printed out to the terminal. When set to `false`, notifications won't be printed. Please note that currently `import_safe_mode` has higher priority. Even if you enable `silent_mode`, and the `import_safe_mode` is enabled as well, you will be prompted to confirm the import operation if the target directory is not empty.

### Import config

* `import_opts` (`hash`) — options that will be passed to Lokalise API when downloading translations to your app. Here are the default options:

```ruby
{
  format: 'ruby_yaml',
  placeholder_format: :icu,
  yaml_include_root: true,
  original_filenames: true,
  directory_prefix: '',
  indentation: '2sp'
}
```

Full list of available import options [can be found in the official API documentation](https://developers.lokalise.com/reference/download-files).

You can provide additional options, and they will be merged with the default ones. For example:

```ruby
importer = LokaliseManager.importer api_token: '1234abc',
                                    project_id: '123.abc',
                                    import_opts: {original_filenames: true}
```

In this case the `import_opts` will have `original_filenames` set to `true` and will also contain all the defaults (`format`, `placeholder_format`, and others). Of course, you can override defaults as well:

```ruby
importer = LokaliseManager.importer api_token: '1234abc',
                                    project_id: '123.abc',
                                    import_opts: {indentation: '4sp'}
```

* `import_safe_mode` (`boolean`) — default to `false`. When this option is enabled, the import task will check whether the directory set with `locales_path` is empty or not. If it is not empty, you will be prompted to continue.
* `max_retries_import` (`integer`) — this option is introduced to properly handle Lokalise API rate limiting. If the HTTP status code 429 (too many requests) has been received, this gem will apply an exponential backoff mechanism with a very simple formula: `2 ** retries`. If the maximum number of retries has been reached, a `RubyLokaliseApi::Error::TooManyRequests` exception will be raised and the operation will be halted.

### Export config

* `export_opts` (`hash`) — options that will be passed to Lokalise API when uploading translations. Full list of available export options [can be found in the official documentation](https://developers.lokalise.com/reference/upload-a-file). By default, the following options are provided:
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

**Please note** that if your Lokalise project does not have a language with the specified `lang_iso` code, the export will fail. It means that you first have to add all the locales to the project and then start the exporting process.

* `skip_file_export` (`lambda` or `proc`) — specify additional exclusion criteria for the exported files. By default, the rake task will ignore all non-file entries and all files with improper extensions (the latter is controlled by the `file_ext_regexp`). Lambda passed to this option should accept a single argument which is full path to the file (instance of the [`Pathname` class](https://ruby-doc.org/stdlib-2.7.1/libdoc/pathname/rdoc/Pathname.html)). For example, to exclude all files that have `fr` part in their names, add the following config:

```ruby
c.skip_file_export = ->(file) { f.split[1].to_s.include?('fr') }
```

* `max_retries_export` (`integer`) — this option is introduced to properly handle Lokalise API rate limiting. If the HTTP status code 429 (too many requests) has been received, LokaliseManager will apply an exponential backoff mechanism with a very simple formula: `2 ** retries` (initially `retries` is `0`). If the maximum number of retries has been reached, a `RubyLokaliseApi::Error::TooManyRequests` exception will be raised and the export operation will be halted. By default, LokaliseManager will make up to `5` retries which potentially means `1 + 2 + 4 + 8 + 16 + 32 = 63` seconds of waiting time. If the `max_retries_export` is less than `1`, LokaliseManager will not perform any retries and give up immediately after receiving error 429.
* `raise_on_export_fail` (`boolean`) — default is `true`. When this option is enabled, LokaliseManager will re-raise any exceptions that happened during the file uploading. In other words, if any uploading thread raised an exception, your exporting process will exit with an exception. Suppose, you are uploading 12 translation files; these files will be split in 2 groups with 6 files each, and each group will be uploaded in parallel (using threads). However, suppose some exception happens when uploading the first group. By default this exception will be re-raised for the whole process and the script will never try to upload the second group. If you would like to continue uploading even if an exception happened, set the `raise_on_export_fail` to `false`. In this case the `export!` method will return an array with scheduled processes and with information about processes that were not successfully scheduled. This information is represented as an object with three methods: `path` (contains an instance of the `Pathname` class which says which file could not be uploaded), `error` (the actual exception), and `success` (returns `false`). So, you can use the following snippet to check your processes:

```ruby
processes = exporter.export!

processes.each do |proc_data|
  if proc_data.success
    # Everything is good, the uploading is queued
    puts "#{proc_data.path} is sent to Lokalise!"
    process = proc_data.process
    puts "Current process status is #{process.status}"
  else
    # Something bad has happened
    puts "Could not send #{proc_data.path} to Lokalise"
    puts "Error #{proc_data.error.class}: #{proc_data.error.message}"
    # Or you could re-raise this exception:
    # raise proc_data.error.class
  end
end
```

* For example, you could collect all the files that were uploaded successfully, re-create the exporter object with the `skip_file_export` option (skipping all files that were successfully imported), and re-run the whole exporting process once again.

### Config to work with formats other than YAML

If your translation files are not in YAML format, you will need to adjust the following options:

* `file_ext_regexp` (`regexp`) — regular expression applied to file extensions to determine which files should be imported and exported. Defaults to `/\.ya?ml\z/i` (YAML files).
* `translations_loader` (`lambda` or `proc`) — loads translations data and makes sure they are valid before saving them to a translation file. Defaults to `->(raw_data) { YAML.safe_load raw_data }`. In the simplest case you may just return the data back, for example `-> (raw_data) { raw_data }`.
* `translations_converter` (`lambda` or `proc`) — converts translations data to a proper format before saving them to a translation file. Defaults to `->(raw_data) { YAML.dump(raw_data).gsub(/\\\\n/, '\n') }`. In the simplest case you may just return the data back, for example `-> (raw_data) { raw_data }`.
* `lang_iso_inferer` (`lambda` or `proc`) — infers language ISO code based on the translation file data and path before uploading it to Lokalise. Defaults to `->(data, _path) { YAML.safe_load(data)&.keys&.first }`. To infer locale based on the filename, you can use something like `->(_data, path) { path.basename('.yml').to_s }`. `path` is an instance of the `Pathname` class.

### Customizing JSON parser and network adapter

JSON parser and network adapter utilized by lokalise_manager can be customized as well. Please check [ruby-lokalise-api doc](https://lokalise.github.io/ruby-lokalise-api/additional_info/customization) to learn more.

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

You can also adjust individual options later using the `#config` instance variable (it contains a Struct object):

```
importer.config.project_id = '678xyz'
importer.config.branch = 'develop'
```

### Globally

You can also provide config globally. To achieve that, call `.config` on `LokaliseManager::Config` class:

```ruby
LokaliseManager::GlobalConfig.config do |c|
  c.api_token = '12345'
  c.project_id = '123.abc'

  c.branch = 'develop'
end
```

Global config takes precedence over the default options, however per-client config has higher precedence.

### Overriding defaults

You can even subclass the default `GlobalConfig` class and provide the new defaults:

```ruby
class CustomConfig < LokaliseManager::GlobalConfig
  class << self
    def branch
      @branch || 'develop'
    end

    def locales_path
      @locales_path || "#{Dir.getwd}/i18n/locales"
    end
  end
end
```

Check [`global_config.rb` source](https://github.com/bodrovis/lokalise_manager/blob/master/lib/lokalise_manager/global_config.rb) to find other defaults.

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

1. Copypaste `.env.example` file as `.env`. Put your Lokalise API token and project ID inside. The `.env` file is excluded from version control so your data is safe. All in all, we use stubs, so the actual API requests won’t be sent. However, providing at least some values is required.
2. Run `rspec .`. Observe test results and code coverage.

## License

Copyright (c) [Ilya Krukowski](http://bodrovis.tech). License type is [MIT](https://github.com/bodrovis/lokalise_manager/blob/master/LICENSE).
