SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

SCRIPT := upload_sarif_to_defectdojo.bash
BATS_FILES := $(wildcard tests/*.bats)
BASH_HELPERS := $(wildcard tests/*.bash)
SHFMT_ARGS := -i 2 -bn -ci -sr -kp

.PHONY: check clean format format-check test

check:
	bash -n "$(SCRIPT)"
	shellcheck "$(SCRIPT)" $(BASH_HELPERS) $(BATS_FILES)

format:
	shfmt $(SHFMT_ARGS) -w "$(SCRIPT)" $(BASH_HELPERS)
	shfmt -ln=bats $(SHFMT_ARGS) -w $(BATS_FILES)

format-check:
	shfmt $(SHFMT_ARGS) -d "$(SCRIPT)" $(BASH_HELPERS)
	shfmt -ln=bats $(SHFMT_ARGS) -d $(BATS_FILES)

test:
	bats tests

clean:
	@:
