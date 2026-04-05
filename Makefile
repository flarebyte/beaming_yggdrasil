FLYB := flyb

DOC_DESIGN_DIR := doc/design
DOC_META_DIR := doc/design-meta

.PHONY: doc-gen doc-design-dir test-unit

doc-gen: doc-design-dir
	$(FLYB) validate --config $(DOC_META_DIR)
	$(FLYB) generate markdown --config $(DOC_META_DIR)

test-unit:
	DART_SUPPRESS_ANALYTICS=true dart test

doc-design-dir:
	@if [ -e "$(DOC_DESIGN_DIR)" ] && [ ! -d "$(DOC_DESIGN_DIR)" ]; then \
		echo "$(DOC_DESIGN_DIR) exists but is not a directory"; \
		exit 1; \
	fi
	@mkdir -p "$(DOC_DESIGN_DIR)"
