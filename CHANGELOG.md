# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

---

## [2.4.0] - 2023-09-11

### Added

- `auth0` options list now has an optional `:client` property, in case multiple clients have been defined with `prima_auth0_ex`

### Changed

- Minimum `prima_auth0_ex` version is now `0.6`

---

## [2.3.0] - 2022-10-25

### Added

- options can now be configured through `config` for each single bridge

### Changed

- base `:endpoint` is not required anymore during `use BridgeEx.Graphql`

---

## [2.2.0] - 2022-09-19

### Added

- New `:decode_keys` option to determine how JSON keys in GraphQL responses are decoded

---

## [2.1.1] - 2022-07-29

### Changed

- **Deprecation**: a warning is emitted if global `log_options` config is set. This option was introduced to save some boilerplate when multiple bridges are used in the same app, but it's a footgun for umbrella apps and a bad design pattern for libraries

---

## [2.1.0] - 2022-07-07

### Added

- New `format_variables` option to format query `variables` keys as camelCase, as per GraphQL conventions
- New `BridgeEx.Graphql.Formatter.SnakeCase` and `BridgeEx.Graphql.Formatter.CamelCase` formatters

---

## [2.0.0] - 2022-05-19

### Changed

- **Breaking**: `BridgeEx.Graphql.Client.call` now accepts an `opts :: Keyword.t()` parameter instead of specific options

### Fixed

- `BridgeEx.Graphql.Client.call` accepts only `variables :: map()` once again
- `BridgeEx.Graphql.Client.call` now performs `variables` encoding internally

---

## [1.2.0] - 2022-05-16

### Added

- New `BridgeEx.Extensions.ExternalResources` module useful to embed external resources with less boilerplate

### Fixed

- Typespec of `BridgeEx.Graphql.Client.call` function is now compatible with `encode_variables: true` option

---

## [1.1.0] - 2022-03-07

### Added

- New `retry_options` to `call`: clients can customize how to handle a call retry (more details [here](./README.md#customizing-the-retry-options))

### Changed

- [**Breaking**] More detailed errors on bad response and http error: instead of returning a string, return an atom with some additional info
- Retries, by default, follow an exponential backoff timing instead of a constant one
- Retry delay starts with 100ms by default,
- `max_attempts` option is now deprecated in favour of `retry_options`

---

## [1.0.1] - 2022-03-07

### Added

- If `PrimaAuth0Ex` is not loaded a `RuntimeError` is raised

### Changed

- `prima_auth0_ex` dependency is now `optional: true` instead of `runtime: false`
- Removed global `:auth0_enabled` flag support: `prima_auth0_ex` is not "ensured" on start anymore and must be included by the lib user
- If audience is not set but auth0 is enabled a `RuntimeError` is now raised instead of a `CompileError`
- Global log options are fetched with `get_env` instead of `compile_env`

---

## [1.0.0] - 2022-02-18

### Changed

- [**Breaking**] Return full graphql error objects instead of just a concatenated error message
- Better exdocs

### Added

- Support for global log options i.e. `config :bridge_ex, log_options: [...]`
- Compile time detection of incorrect auth0 config: if audience is not set but auth0 is enabled a `CompileError` is raised

---

## [0.4.1] - 2022-02-07

### Added

- New `log_options` keyword list with options `:log_query_on_error` and `:log_response_on_error` for better control of what the lib logs on HTTP errors/request errors

---

## [0.4.0] - 2022-02-02

### Changed

- Require `config :bridge_ex, :auth0_enabled` to be set in order to use auth0 authentication

---

## [0.3.1]

### Changed

- Removed `http_` prefix from header option

### Fixed

- Fixed handling of custom headers

---

## [0.3.0-rc.1]

### Added

- Support authenticating calls via Auth0 through `auth0_ex`

### Fixed

- Fixed typo in bridge for `max_attempts` configuration.

---

## [0.2.0-rc.1]

### Added

- Added package publication on hex.pm

---

## [0.1.0]

### Added

- Initial implementation of `bridge_ex`


[Unreleased]: https://github.com/primait/bridge_ex/compare/2.4.0...HEAD
[2.4.0]: https://github.com/primait/bridge_ex/compare/2.3.0...2.4.0
[2.3.0]: https://github.com/primait/bridge_ex/compare/2.2.0...2.3.0
[2.2.0]: https://github.com/primait/bridge_ex/compare/2.1.1...2.2.0
[2.1.1]: https://github.com/primait/bridge_ex/compare/2.1.0...2.1.1
[2.1.0]: https://github.com/primait/bridge_ex/compare/2.0.0...2.1.0
[2.0.0]: https://github.com/primait/bridge_ex/compare/1.2.0...2.0.0
[1.2.0]: https://github.com/primait/bridge_ex/compare/1.1.0...1.2.0
[1.1.0]: https://github.com/primait/bridge_ex/compare/1.0.1...1.1.0
[1.0.1]: https://github.com/primait/bridge_ex/compare/1.0.0...1.0.1
[1.0.0]: https://github.com/primait/bridge_ex/compare/0.4.1...1.0.0
[0.4.1]: https://github.com/primait/bridge_ex/compare/0.4.0...0.4.1
[0.4.0]: https://github.com/primait/bridge_ex/compare/0.3.1...0.4.0
[0.3.1]: https://github.com/primait/bridge_ex/compare/0.3.0-rc.1...0.3.1
[0.3.0-rc.1]: https://github.com/primait/bridge_ex/compare/0.2.0-rc.1.1...0.3.0-rc.1
[0.2.0-rc.1]: https://github.com/primait/bridge_ex/compare/0.1.1...0.2.0-rc.1
[0.1.0]: https://github.com/primait/bridge_ex/releases/tag/0.1.0
