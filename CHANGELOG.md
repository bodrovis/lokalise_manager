# Changelog

## 1.1.0 (25-Oct-21)

* Add a new option `:use_oauth2_token` which is `false` by default. When enabled, you'll be able to provide a token obtained via [OAuth 2 flow](https://docs.lokalise.com/en/articles/5574713-oauth-2) rather than generated via Lokalise profile. The token should still be provided via the `:api_token` option:

```ruby
importer = LokaliseManager.importer api_token: 'TOKEN_VIA_OAUTH2', project_id: '123.abc', use_oauth2_token: true
```

## 1.0.0 (14-Oct-21)

* Initial release