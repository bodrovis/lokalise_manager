# Changelog

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