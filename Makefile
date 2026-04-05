FLYB := flyb

doc-gen:
	$(FLYB) validate --config doc/design-meta
	$(FLYB) generate markdown --config doc/design-meta
