FLYB := flyb

DOC_DESIGN_DIR := doc/design
DOC_META_DIR := doc/design-meta
DART_LOCAL_HOME := $(CURDIR)/.dart-home
PUB_CACHE_DIR ?= $(HOME)/.pub-cache
COVERAGE_DIR := coverage
COVERAGE_LCOV := $(COVERAGE_DIR)/lcov.info
COVERAGE_HTML_DIR := $(COVERAGE_DIR)/html
PACKAGE_NAME := beaming_yggdrasil

.PHONY: doc-gen doc-design-dir analyze package-check test-unit test-flutter test-coverage coverage-summary coverage-html format-dart

analyze:
	@mkdir -p "$(DART_LOCAL_HOME)"
	HOME="$(DART_LOCAL_HOME)" PUB_CACHE="$(PUB_CACHE_DIR)" DART_SUPPRESS_ANALYTICS=true dart analyze

package-check: format-dart analyze test-unit

doc-gen: doc-design-dir
	$(FLYB) validate --config $(DOC_META_DIR)
	$(FLYB) generate markdown --config $(DOC_META_DIR)

test-unit:
	@mkdir -p "$(DART_LOCAL_HOME)"
	HOME="$(DART_LOCAL_HOME)" PUB_CACHE="$(PUB_CACHE_DIR)" DART_SUPPRESS_ANALYTICS=true dart test

test-flutter:
	@mkdir -p "$(DART_LOCAL_HOME)"
	HOME="$(DART_LOCAL_HOME)" PUB_CACHE="$(PUB_CACHE_DIR)" DART_SUPPRESS_ANALYTICS=true flutter test

test-coverage:
	@mkdir -p "$(DART_LOCAL_HOME)" "$(COVERAGE_DIR)"
	rm -rf "$(COVERAGE_DIR)"
	HOME="$(DART_LOCAL_HOME)" PUB_CACHE="$(PUB_CACHE_DIR)" DART_SUPPRESS_ANALYTICS=true dart run coverage:test_with_coverage --out="$(COVERAGE_DIR)" --scope-output="$(PACKAGE_NAME)"

coverage-summary: test-coverage
	lcov --summary "$(COVERAGE_LCOV)"

coverage-html: test-coverage
	rm -rf "$(COVERAGE_HTML_DIR)"
	genhtml "$(COVERAGE_LCOV)" --output-directory "$(COVERAGE_HTML_DIR)"

format-dart:
	@mkdir -p "$(DART_LOCAL_HOME)"
	HOME="$(DART_LOCAL_HOME)" PUB_CACHE="$(PUB_CACHE_DIR)" DART_SUPPRESS_ANALYTICS=true dart format lib test

doc-design-dir:
	@if [ -e "$(DOC_DESIGN_DIR)" ] && [ ! -d "$(DOC_DESIGN_DIR)" ]; then \
		echo "$(DOC_DESIGN_DIR) exists but is not a directory"; \
		exit 1; \
	fi
	@mkdir -p "$(DOC_DESIGN_DIR)"

complexity:
	scc --sort complexity --by-file -i dart . | head -n 15

dup:
	npx jscpd --format dart --min-lines 10 --gitignore .
