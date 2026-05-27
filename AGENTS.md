# Repository Guidelines

## Project Structure & Module Organization
`lib/` contains the published Dart package. Public exports start in `lib/beaming_yggdrasil.dart`, while most implementation lives under `lib/src/client/`. Unit and contract-style tests live in `test/client/`; end-to-end tests and harness helpers live in `test/e2e/` and `test/e2e/support/`. Local-only helpers used by examples and tests live in `support/` and are not part of the runtime API. Design sources live in `doc/design-meta/`; generated design output goes to `doc/design/specs.md`.

## Build, Test, and Development Commands
Use the Make targets instead of ad hoc commands when possible:

- `make format-dart`: format `lib/` and `test/` with `dart format`.
- `make analyze`: run `dart analyze`.
- `make test-unit`: run the main package tests in `test/client/`.
- `make test-e2e`: run E2E tests against the sibling mock server repo at `../chatty-ratatoskr`.
- `make review`: run the standard pre-handoff gate: format, lint, and tests.
- `make publish-dry-run`: validate the package for publishing.
- `make doc-gen`: validate `doc/design-meta/` and regenerate `doc/design/specs.md`.

## Coding Style & Naming Conventions
Follow `.editorconfig`: spaces, 2-space indentation, UTF-8, and final newlines. This package uses `package:lints/recommended.yaml` plus `always_declare_return_types` and `directives_ordering`, so keep imports ordered and prefer explicit return types. Match the existing naming style: `snake_case.dart` files, UpperCamelCase types such as `BeamingYggdrasilClient`, and focused client modules under `lib/src/client/`.

## Testing Guidelines
Add tests beside the relevant area under `test/client/` and use `*_test.dart` filenames. Prefer deterministic unit coverage for models, DTOs, recovery, diagnostics, and client behavior. Use `test/e2e/` only for flows that need the mock server boundary. Run `make test-unit` before opening a PR; run `make test-e2e` when transport-facing behavior changes.

## Generated Artifacts & Metadata
Treat `doc/design/specs.md` and `thoth-meta/` as generated outputs. Edit the source files in `doc/design-meta/` or the relevant pipeline configs first, then regenerate artifacts with the provided Make targets.
