.DEFAULT_GOAL := help

FLYB ?= flyb
THOTH ?= thoth
YQ ?= yq
JQ ?= jq

DOC_DESIGN_DIR := doc/design
DOC_META_DIR := doc/design-meta
DART_LOCAL_HOME := $(CURDIR)/.dart-home
PUB_CACHE_DIR ?= $(HOME)/.pub-cache
DART_ENV := HOME="$(DART_LOCAL_HOME)" PUB_CACHE="$(PUB_CACHE_DIR)" DART_SUPPRESS_ANALYTICS=true
DART_DIRS := lib test
UNIT_TEST_DIR := test/client
E2E_TEST_DIR := test/e2e
COVERAGE_DIR := coverage
COVERAGE_LCOV := $(COVERAGE_DIR)/lcov.info
COVERAGE_HTML_DIR := $(COVERAGE_DIR)/html
PACKAGE_NAME := beaming_yggdrasil

.PHONY: help check-tools install-tools-help \
	format format-dart \
	lint lint-dart analyze \
	test test-dart test-unit test-e2e test-flutter test-coverage coverage-summary coverage-html \
	review package-check publish-dry-run publish-check \
	doc-gen doc-design-dir check-thoth-meta \
	complexity dup \
	thoth-meta thoth-meta-dart thoth-meta-dart-test thoth-lint-dart thoth-meta-merge view-thoth-meta-dart-test

## Public developer targets

help: ## Show available commands.
	@awk 'BEGIN {FS = ":.*## "}; /^[a-zA-Z0-9_.-]+:.*## / {printf "  %-24s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

check-tools: ## Report required tool availability.
	@printf "dart=%s\n" "$$(command -v dart >/dev/null 2>&1 && echo true || echo false)"
	@printf "flutter=%s\n" "$$(command -v flutter >/dev/null 2>&1 && echo true || echo false)"
	@printf "flyb=%s\n" "$$(command -v $(FLYB) >/dev/null 2>&1 && echo true || echo false)"
	@printf "thoth=%s\n" "$$(command -v $(THOTH) >/dev/null 2>&1 && echo true || echo false)"
	@printf "yq=%s\n" "$$(command -v $(YQ) >/dev/null 2>&1 && echo true || echo false)"
	@printf "jq=%s\n" "$$(command -v $(JQ) >/dev/null 2>&1 && echo true || echo false)"
	@printf "scc=%s\n" "$$(command -v scc >/dev/null 2>&1 && echo true || echo false)"
	@printf "npx=%s\n" "$$(command -v npx >/dev/null 2>&1 && echo true || echo false)"
	@printf "lcov=%s\n" "$$(command -v lcov >/dev/null 2>&1 && echo true || echo false)"
	@printf "genhtml=%s\n" "$$(command -v genhtml >/dev/null 2>&1 && echo true || echo false)"

install-tools-help: ## Show how to install the main developer tools.
	@printf '%s\n' 'dart/flutter: https://dart.dev/get-dart or https://docs.flutter.dev/get-started/install'
	@printf '%s\n' 'flyb: install the flyb CLI used by doc/design-meta workflows'
	@printf '%s\n' 'thoth: install the thoth CLI used to run *.thoth.cue pipelines'
	@printf '%s\n' 'yq: brew install yq'
	@printf '%s\n' 'jq: brew install jq'
	@printf '%s\n' 'scc: brew install scc'
	@printf '%s\n' 'lcov/genhtml: brew install lcov'
	@printf '%s\n' 'jscpd: install Node.js, then run npm install -g jscpd'

format: format-dart ## Format all supported languages.

lint: lint-dart ## Run the default linters.

test: test-dart ## Run the default automated test suite.

review: format lint test ## Run the standard pre-handoff quality gate.

## Language-specific targets

format-dart: ## Format Dart sources and tests.
	@mkdir -p "$(DART_LOCAL_HOME)"
	$(DART_ENV) dart format $(DART_DIRS)

lint-dart: ## Run Dart static analysis.
	@mkdir -p "$(DART_LOCAL_HOME)"
	$(DART_ENV) dart analyze

analyze: lint-dart ## Backward-compatible alias for Dart analysis.

test-dart: ## Run Dart unit and package tests.
	@mkdir -p "$(DART_LOCAL_HOME)"
	$(DART_ENV) dart test $(UNIT_TEST_DIR)

test-unit: test-dart ## Backward-compatible alias for Dart tests.

test-e2e: ## Run Dart E2E tests against the local ../chatty-ratatoskr mock server when available.
	@mkdir -p "$(DART_LOCAL_HOME)"
	CHATTY_REPO_DIR="../chatty-ratatoskr" $(DART_ENV) dart test $(E2E_TEST_DIR)

test-flutter: ## Run Flutter tests when the package is used in Flutter contexts.
	@mkdir -p "$(DART_LOCAL_HOME)"
	$(DART_ENV) flutter test

package-check: review ## Backward-compatible alias for the main package gate.

publish-dry-run: ## Run pub package validation without publishing.
	@mkdir -p "$(DART_LOCAL_HOME)"
	$(DART_ENV) dart pub publish --dry-run

publish-check: review publish-dry-run ## Run the publish-oriented package quality gate.

## Documentation and metadata targets

doc-design-dir:
	@if [ -e "$(DOC_DESIGN_DIR)" ] && [ ! -d "$(DOC_DESIGN_DIR)" ]; then \
		echo "$(DOC_DESIGN_DIR) exists but is not a directory"; \
		exit 1; \
	fi
	@mkdir -p "$(DOC_DESIGN_DIR)"

doc-gen: doc-design-dir ## Validate and generate markdown from doc/design-meta.
	$(FLYB) validate --config $(DOC_META_DIR)
	$(FLYB) generate markdown --config $(DOC_META_DIR)

check-thoth-meta: ## Report orphaned Thoth YAML files and Dart metadata missing meta.purpose.
	YQ="$(YQ)" sh ./scripts/check_thoth_meta.sh

thoth-meta: thoth-meta-dart thoth-meta-dart-test ## Refresh Dart Thoth metadata and aggregate it.
	$(THOTH) run --config ./pipeline-thoth-meta-aggregate.thoth.cue

thoth-meta-dart: ## Generate Thoth metadata for lib/**/*.dart.
	$(THOTH) run --config ./pipeline-dart-maat.thoth.cue

thoth-meta-dart-test: ## Generate Thoth metadata for test/**/*.dart.
	$(THOTH) run --config ./pipeline-dart-test-maat.thoth.cue

thoth-meta-merge: ## Aggregate persisted Thoth metadata into temp JSON.
	$(THOTH) run --config ./pipeline-thoth-meta-aggregate.thoth.cue

view-thoth-meta-dart-test: ## Show detected Dart test titles from persisted Thoth metadata.
	find thoth-meta/dart-test/test -name '*.thoth.yaml' -exec $(YQ) '.meta.testcase_titles_list' {} \;

## Coverage and diagnostics

test-coverage: ## Run Dart tests with coverage output.
	@mkdir -p "$(DART_LOCAL_HOME)" "$(COVERAGE_DIR)"
	rm -rf "$(COVERAGE_DIR)"
	$(DART_ENV) dart run coverage:test_with_coverage --out="$(COVERAGE_DIR)" --scope-output="$(PACKAGE_NAME)"

coverage-summary: test-coverage ## Print a coverage summary from lcov output.
	lcov --summary "$(COVERAGE_LCOV)"

coverage-html: test-coverage ## Generate an HTML coverage report.
	rm -rf "$(COVERAGE_HTML_DIR)"
	genhtml "$(COVERAGE_LCOV)" --output-directory "$(COVERAGE_HTML_DIR)"

thoth-lint-dart: ## Report complex Dart functions and methods from Thoth thresholds.
	$(THOTH) run --config ./pipeline-dart-function-thresholds.thoth.cue
	$(JQ) '.meta.reduced.worstOffenders' temp/pipeline-dart-function-thresholds.json

complexity: ## Show the top Dart file complexity hotspots.
	scc --sort complexity --by-file -i dart . | head -n 15

dup: ## Run duplication scanning for Dart sources.
	jscpd --format dart --min-lines 10 --gitignore --ignore ".dart-home/**,.dart_tool/**,coverage/**,build/**,temp/**,thoth-meta/**" .
