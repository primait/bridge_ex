# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Next]

### Changed

- [**Breaking**] Return full graphql error objects instead of just a concatenated error message
- Better exdocs

### Added

- Support for global log options i.e. `config :bridge_ex, log_options: [...]`
- Compile time detection of incorrect auth0 config: if audience is not set but auth0 is enabled a `CompileError` is raised

### Removed

- Local `log_options` opt is no longer supported

## [0.4.1]

### Added

- New `log_options` keyword list with options `:log_query_on_error` and `:log_response_on_error` for better control of what the lib logs on HTTP errors/request errors

## [0.4.0]

### Changed

- Require `config :bridge_ex, :auth0_enabled` to be set in order to use auth0 authentication

## [0.3.0-rc.3]

### Changed

- Removed `http_` prefix from header option

## [0.3.0-rc.2]

### Fixed

- Fixed handling of custom headers

## [0.3.0-rc.1]

### Added

- Support authenticating calls via Auth0 through `auth0_ex`

### Fixed

- Fixed typo in bridge for `max_attempts` configuration.

## [0.2.0-rc.1]

### Added

- Added package publication on hex.pm

## [0.1.0]

### Added

- Initial implementation of `bridge_ex`
