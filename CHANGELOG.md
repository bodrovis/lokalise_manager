# Changelog

## 6.2.0 (25-Feb-2025)

* Strengthened configuration merging logic for `import_opts` and `export_opts` to retain default values when overridden.

## 6.1.1 (20-Feb-2025)

* Prevent error swallowing in rare cases

## 6.1.0 (19-Feb-2025)

* Added support for `import_async` option (default to `false`). When enabled, the [import process will happen in the background](https://developers.lokalise.com/reference/download-files-async) and the gem will use exponential backoff to wait for its completion according to the `max_retries_import` option.

## 6.0.0 (29-Nov-2024)

* **Breaking change**: rename the `timeouts` config method to `additional_client_opts`. It has the same usage but now enables you to set both client timeouts and override the API host to send requests to.

```ruby
additional_client_opts: {
  open_timeout: 100,
  timeout: 500,
  api_host: 'http://example.com/api'
}
```

## 5.1.2 (01-Nov-2024)

* Update dependencies

## 5.1.1 (10-May-2024)

* Update documentation, minor code fixes

## 5.1.0 (09-Feb-2024)

* Handle rare case when the server returns HTML instead of JSON which happens when too many requests are sent

## 5.0.0 (09-Nov-2023)

* **Breaking change**: require Ruby 3+. Version 2.7 has reached end-of-life and thus we are not planning to support it anymore. If you need support for Ruby 2.7, please stay on 4.0.0.
* **Potential breaking change**: lambda returned by the `lang_iso_inferer` method has been slightly enhanced. It now accepts not only the file data but also the full path to the file. Therefore, if you redefine the `lang_iso_inferer` option please make sure that the returned lambda accepts two params, not one. This way, you can be more flexible when inferring the locale. For example:

```ruby
lang_iso_inferer: ->(_data, path) { path.basename('.yml').to_s }
```

* Use ruby-lokalise-api v9.0.0

## 4.0.0 (27-Jul-2023)

* **Use ruby-lokalise-api version 8**. It should not introduce any breaking changes (as main methods have similar signatures) but you should be aware that v8 is a complete rewrite of the original SDK so please make sure your tests pass.
* Replace VCR with WebMock in tests
* Various minor updates
* Do not test with Ruby 2.7 (EOL)

## 3.3.0 (18-Nov-22)

* Use newer ruby-lokalise-api
* Minor updates

## 3.2.0 (26-Aug-22)

* Fixed an issue when `\n` inside translations was imported as `\\n`. The default value for the `translations_converter` is now `->(raw_data) { YAML.dump(raw_data).gsub(/\\\\n/, '\n') }`.

## 3.1.0 (17-Aug-22)

* The default format is now `ruby_yaml` (it used to be `yaml`)

## 3.0.0 (11-Mar-22)

* **Breaking change**: Require Ruby 2.7 or above
* **Breaking change (potentially)**: Use ruby-lokalise-api v6. In general, this transition should not affect you if you employ `export!` and `import!` methods only. However, please be aware that ruby-lokalise-api has a few breaking changes [listed in its own changelog](https://lokalise.github.io/ruby-lokalise-api/additional_info/changelog)
* Use Zeitwerk loader
* Prettify and update source code

## 2.2.1 (19-Oct-22)

* Replaced `filter` with `select` as it does not work with Ruby 2.5

## 2.2.0 (23-Feb-22)

* Use ruby-lokalise-api v5
* Don't use any compression options (compression is now enabled by default)
* Update tests

## 2.1.0 (27-Jan-22)

* **Breaking change**: `export!` will now return an array of objects responding to the following methods:
  + `success` — usually returns `true` (to learn more, check documentation for the `:raise_on_export_fail` option below)
  + `process` — returns an object (an instance of the `Lokalise::Resources::QueuedProcess`) representing a [queued background process](https://lokalise.github.io/ruby-lokalise-api/api/queued-processes) as uploading is done in the background on Lokalise. You can use this object to check the process status (whether the uploading is completed or not).
  + `path` — returns an instance of the `Pathname` class which represent the file being uploaded.
* Here's an example:

```ruby
def uploaded?(process)
  5.times do # try to check the status 5 times
    process = process.reload_data # load new data
    return(true) if process.status == 'finished' # return true is the upload has finished
    sleep 1 # wait for 1 second, adjust this number with regards to the upload size
  end

  false # if all 5 checks failed, return false (probably something is wrong)
end

processes = exporter.export!
puts "Checking status for the #{processes[0].path} file"
uploaded? processes[0].process
```

* Introduced a new option `raise_on_export_fail` (`boolean`) which is `true` by default. When this option is enabled, LokaliseManager will re-raise any exceptions that happened during the file uploading. When this option is disabled, the exporting process will continue even if something goes wrong. In this case you'll probably need to check the result yourself and make the necessary actions. For example:

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

## 2.0.0 (27-Jan-22)

* `export!` method is now taking advantage of multi-threading (as Lokalise API allows to send requests in parallel since January 2022)
* Test with Ruby 3.1.0
* Other minor fixes

## 1.2.1 (26-Nov-21)

* Use refinements instead of monkey patching to add hash methods
* Don't use `OpenStruct` anymore to store config opts
* Minor fixes

## 1.2.0 (26-Oct-21)

* Add a new option `:silent_mode` which is `false` by default. When silent mode is enabled, no debug info will be printed out to `$stdout`. The only exception are the "safe mode" messages — you'll still be prompted to continue if the target directory is not empty.
* Use `#deep_merge` instead of a simple merge when processing options.

## 1.1.0 (25-Oct-21)

* Add a new option `:use_oauth2_token` which is `false` by default. When enabled, you'll be able to provide a token obtained via [OAuth 2 flow](https://docs.lokalise.com/en/articles/5574713-oauth-2) rather than generated via Lokalise profile. The token should still be provided via the `:api_token` option:

```ruby
importer = LokaliseManager.importer api_token: 'TOKEN_VIA_OAUTH2', project_id: '123.abc', use_oauth2_token: true
```

## 1.0.0 (14-Oct-21)

* Initial release