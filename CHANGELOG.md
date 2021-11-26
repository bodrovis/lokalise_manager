# Changelog

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