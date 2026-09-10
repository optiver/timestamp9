# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.5.0] - 2026-09-10

### Added
- `timestamp9_now()` function - returns current time with nanosecond precision
- `timestamp9_diff(timestamp9, timestamp9)` function - computes interval between timestamps
- `timestamp9_epoch(timestamp9)` function - converts to Unix epoch as double precision
- `epoch_to_timestamp9(double precision)` function - converts Unix epoch to timestamp9
- Comprehensive test suite for operators, timezones, and advanced features
- GitHub Actions CI workflow for PostgreSQL 14, 15, 16, 17
- Expanded documentation with examples and performance considerations

### Changed
- Improved code clarity: renamed `count` variable to `found_decimal` in `parse_fractional_ratio`
- Added named constant `TIMESTAMP9_OUT_BUF_LEN` for output buffer size
- Added comments explaining epoch conversion logic
- Removed stale `parse_gmt_offset` declaration from header

### Fixed
- Typo fix: "determin" → "determine" in comment

### Security
- Added overflow validation in `timestamp9_in` for parsed timestamps
- Added range validation in interval arithmetic functions

### Build
- Updated `build.sh` to support PostgreSQL 14, 15, 16, 17
- Removed TimescaleDB references from test configuration
- Removed empty migration file `timestamp9--1.3.0--1.4.0.sql`

## [1.4.0] - 2024-XX-XX

### Changed
- Updated license information
- Updated repository URL

## [1.3.0] - 2023-XX-XX

### Added
- PostgreSQL 16 compatibility

## [1.2.0] - 2022-XX-XX

### Added
- Hash index support with `hash_timestamp9_ops` operator class
- Allow parsing nanosecond precision timestamps without timezone
- `timestamp9_to_date()` and `date_to_timestamp9()` cast functions

### Fixed
- Raise error if `pg_localtime()` returns NULL

## [1.1.0] - 2021-XX-XX

### Added
- Allow users to control timezone via GUC (session timezone)

### Fixed
- Prevent potential buffer overflow in timestamp parsing

## [1.0.1] - 2020-XX-XX

### Fixed
- Minor bug fixes

## [1.0.0] - 2020-XX-XX

### Added
- Initial stable release
- Nanosecond-precision timestamp type
- B-tree index support
- Casts to/from `timestamptz`, `timestamp`, `date`, `bigint`
- Comparison operators: `=`, `<>`, `<`, `<=`, `>`, `>=`
- Arithmetic operators: `+ interval`, `- interval`
- Aggregate functions: `min()`, `max()`

## [0.3.0] - 2019-XX-XX

### Added
- Interval arithmetic support

## [0.2.0] - 2019-XX-XX

### Added
- Date casting support

## [0.1.0] - 2019-XX-XX

### Added
- Initial release
- Basic timestamp9 type with nanosecond precision
- Input/output functions
- B-tree comparison operators

---

[Unreleased]: https://github.com/optiver/timestamp9/compare/v1.5.0...HEAD
[1.5.0]: https://github.com/optiver/timestamp9/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/optiver/timestamp9/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/optiver/timestamp9/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/optiver/timestamp9/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/optiver/timestamp9/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/optiver/timestamp9/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/optiver/timestamp9/compare/v0.3.0...v1.0.0
[0.3.0]: https://github.com/optiver/timestamp9/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/optiver/timestamp9/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/optiver/timestamp9/releases/tag/v0.1.0
