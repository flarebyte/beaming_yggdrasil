# Changelog

All notable changes to `beaming_yggdrasil` will be documented in this file.

The format is based on Keep a Changelog, and this package follows semantic
versioning.

## [1.0.0] - 2026-04-06

### Added

- spec-aligned pure Dart client primitives intended to embed cleanly in Flutter apps
- classic `Future` and `Stream` client API plus optional Rx adapter surface
- separate testing client for snapshot replacement in tests only
- immutable model, REST DTO, light WebSocket DTO, diagnostics, and recovery primitives
- in-memory harness for examples, acceptance tests, and early integration work
- unit and E2E Dart test coverage, including E2E coverage against `chatty-ratatoskr`
- Makefile workflows for formatting, analysis, testing, coverage, and publish dry-run checks
