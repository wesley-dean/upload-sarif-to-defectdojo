SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

SCRIPT := upload_sarif_to_defectdojo.bash
SOURCE_SCRIPT := src/upload_sarif_to_defectdojo.bash
BATS_FILES := $(wildcard tests/*.bats)
BASH_HELPERS := $(wildcard tests/*.bash)
SHFMT_ARGS := -i 2 -bn -ci -sr -kp

VENDOR_DIR := vendor
DEPENDENCY_MANIFEST := dependencies.txt
BASHDEPS := $(VENDOR_DIR)/bashdeps.bash
BASHDEPS_VERSION := 0.4.1
BASHDEPS_URL := https://github.com/wesley-dean/bashdeps/releases/download/v$(BASHDEPS_VERSION)/bashdeps.bash
BASHDEPS_SHA256 := 5131ebb6a3a85e1d76624a37146c2442b2e57be6ffd8139b9590d28239876701
BASHLOG := $(VENDOR_DIR)/bashlog.bash
BASHLOG_VERSION := 0.0.18
ADRCTL := $(VENDOR_DIR)/adrctl.bash
ADR_INDEX_FILE := doc/adr/README.md
ADR_INDEX_MARKER := <!-- adrctl-generated-footer -->
BASH_DOXYGEN := $(VENDOR_DIR)/doxygen-bash.awk
DOCS_OUTPUT := doc/reference

.PHONY: adr-index all build check clean deps deps-check distclean docs docs-clean FORCE format format-check test verify-bashdeps

all: deps
	$(MAKE) --no-print-directory build

FORCE:

$(BASHDEPS): FORCE
	@mkdir -p "$(VENDOR_DIR)"
	@verify_hash() { \
		path=$$1; \
		if command -v sha256sum >/dev/null 2>&1; then \
			printf '%s  %s\n' "$(BASHDEPS_SHA256)" "$$path" | sha256sum -c - >/dev/null 2>&1; \
		elif command -v shasum >/dev/null 2>&1; then \
			[[ "$$(shasum -a 256 "$$path" | awk '{print $$1}')" == "$(BASHDEPS_SHA256)" ]]; \
		else \
			return 2; \
		fi; \
	}; \
	if ! command -v sha256sum >/dev/null 2>&1 && ! command -v shasum >/dev/null 2>&1; then \
		printf '%s\n' 'No SHA-256 verification command is available for bashdeps.bash' >&2; \
		exit 1; \
	fi; \
	if [[ -f "$@" ]] && verify_hash "$@"; then \
		chmod 0755 "$@"; \
		exit 0; \
	fi; \
	tmp="$@.tmp"; \
	trap 'rm -f "$$tmp"' EXIT; \
	if command -v curl >/dev/null 2>&1; then \
		curl -fsSL "$(BASHDEPS_URL)" -o "$$tmp"; \
	elif command -v wget >/dev/null 2>&1; then \
		wget -qO "$$tmp" "$(BASHDEPS_URL)"; \
	else \
		printf '%s\n' 'curl or wget is required to bootstrap bashdeps.bash' >&2; \
		exit 1; \
	fi; \
	if ! verify_hash "$$tmp"; then \
		printf '%s\n' 'Downloaded bashdeps.bash does not match the committed SHA-256 digest' >&2; \
		exit 1; \
	fi; \
	chmod 0755 "$$tmp"; \
	mv "$$tmp" "$@"; \
	trap - EXIT

verify-bashdeps:
	@test -x "$(BASHDEPS)" || { \
		printf '%s\n' 'Missing or non-executable bashdeps bootstrap; run make deps' >&2; \
		exit 1; \
	}
	@if command -v sha256sum >/dev/null 2>&1; then \
		printf '%s  %s\n' "$(BASHDEPS_SHA256)" "$(BASHDEPS)" | sha256sum -c - >/dev/null 2>&1 || { \
			printf '%s\n' 'bashdeps.bash does not match the committed SHA-256 digest; run make deps' >&2; \
			exit 1; \
		}; \
	elif command -v shasum >/dev/null 2>&1; then \
		[[ "$$(shasum -a 256 "$(BASHDEPS)" | awk '{print $$1}')" == "$(BASHDEPS_SHA256)" ]] || { \
			printf '%s\n' 'bashdeps.bash digest mismatch; run make deps' >&2; \
			exit 1; \
		}; \
	else \
		printf '%s\n' 'No SHA-256 verification command is available for bashdeps.bash' >&2; \
		exit 1; \
	fi

deps: $(BASHDEPS) $(DEPENDENCY_MANIFEST)
	$(MAKE) --no-print-directory verify-bashdeps
	"$(BASHDEPS)" sync "$(DEPENDENCY_MANIFEST)"

deps-check: verify-bashdeps $(DEPENDENCY_MANIFEST)
	"$(BASHDEPS)" verify "$(DEPENDENCY_MANIFEST)"

adr-index:
	@test -r "$(ADRCTL)" || { \
		printf '%s\n' 'Missing documentation dependency vendor/adrctl.bash; run make deps' >&2; \
		exit 1; \
	}
	@marker='$(ADR_INDEX_MARKER)'; \
	count="$$(grep -Fxc "$$marker" "$(ADR_INDEX_FILE)" || true)"; \
	[[ "$$count" == 1 ]] || { \
		printf 'Expected exactly one ADR inventory marker in %s; found %s\n' "$(ADR_INDEX_FILE)" "$$count" >&2; \
		exit 1; \
	}; \
	prefix_tmp="$(ADR_INDEX_FILE).prefix.tmp"; \
	toc_tmp="$(ADR_INDEX_FILE).toc.tmp"; \
	candidate_tmp="$(ADR_INDEX_FILE).tmp"; \
	trap 'rm -f "$$prefix_tmp" "$$toc_tmp" "$$candidate_tmp"' EXIT; \
	awk -v marker="$$marker" '{ print; if ($$0 == marker) exit }' "$(ADR_INDEX_FILE)" >"$$prefix_tmp"; \
	bash "$(ADRCTL)" generate toc >"$$toc_tmp"; \
	IFS= read -r heading <"$$toc_tmp"; \
	[[ "$$heading" == '# Architecture Decision Records' ]] || { \
		printf 'Unexpected adrctl TOC heading: %s\n' "$$heading" >&2; \
		exit 1; \
	}; \
	{ \
		cat "$$prefix_tmp"; \
		printf '\n'; \
		sed '1s/^# Architecture Decision Records$$/## Architecture Decision Records/' "$$toc_tmp"; \
	} >"$$candidate_tmp"; \
	if ! cmp -s "$$candidate_tmp" "$(ADR_INDEX_FILE)"; then \
		mv "$$candidate_tmp" "$(ADR_INDEX_FILE)"; \
	fi; \
	trap - EXIT; \
	rm -f "$$prefix_tmp" "$$toc_tmp" "$$candidate_tmp"

docs:
	@test -r "$(BASH_DOXYGEN)" || { \
		printf '%s\n' 'Missing documentation dependency vendor/doxygen-bash.awk; run make deps' >&2; \
		exit 1; \
	}
	@command -v doxygen >/dev/null 2>&1 || { \
		printf '%s\n' 'doxygen is required to generate reference documentation' >&2; \
		exit 1; \
	}
	awk -f "$(BASH_DOXYGEN)" -- --strict "$(SOURCE_SCRIPT)" >/dev/null
	rm -rf "$(DOCS_OUTPUT)"
	doxygen Doxyfile
	@test -f "$(DOCS_OUTPUT)/index.html" || { \
		printf '%s\n' 'Doxygen did not generate doc/reference/index.html' >&2; \
		exit 1; \
	}

docs-clean:
	rm -rf "$(DOCS_OUTPUT)"

build: $(SOURCE_SCRIPT)
	@test -r "$(BASHLOG)" || { \
		printf '%s\n' 'Missing build dependency vendor/bashlog.bash; run make deps or make all' >&2; \
		exit 1; \
	}
	@tmp="$(SCRIPT).tmp"; \
	trap 'rm -f "$$tmp"' EXIT; \
	{ \
		printf '%s\n' '#!/usr/bin/env bash'; \
		printf '%s\n' '#'; \
		printf '%s\n' '# Generated by make build. Do not edit directly.'; \
		printf '%s\n' '# Canonical source: $(SOURCE_SCRIPT)'; \
		printf '%s\n' '# Embedded dependency: bashlog v$(BASHLOG_VERSION) (dependencies.txt)'; \
		printf '\n'; \
		sed '1d' "$(BASHLOG)"; \
		printf '\n'; \
		sed -e '1d' \
			-e 's|^## @file src/upload_sarif_to_defectdojo.bash|## @file upload_sarif_to_defectdojo.bash|' \
			"$(SOURCE_SCRIPT)"; \
	} >"$$tmp"; \
	chmod 0755 "$$tmp"; \
	bash -n "$$tmp"; \
	mv "$$tmp" "$(SCRIPT)"; \
	trap - EXIT

check:
	bash -n "$(SOURCE_SCRIPT)"
	bash -n "$(SCRIPT)"
	bash -n $(BASH_HELPERS)
	shellcheck "$(SOURCE_SCRIPT)"
	# bashlog v$(BASHLOG_VERSION) intentionally uses these three constructs.
	# Maintained uploader source is checked separately above without exclusions.
	shellcheck -e SC2034,SC2053,SC2059 "$(SCRIPT)"

format:
	shfmt $(SHFMT_ARGS) -w "$(SOURCE_SCRIPT)" $(BASH_HELPERS)
	shfmt -ln=bats $(SHFMT_ARGS) -w $(BATS_FILES)

format-check:
	shfmt $(SHFMT_ARGS) -d "$(SOURCE_SCRIPT)" $(BASH_HELPERS)
	shfmt -ln=bats $(SHFMT_ARGS) -d $(BATS_FILES)

test:
	bats tests

clean:
	rm -f "$(SCRIPT).tmp"

distclean: clean docs-clean
	rm -rf "$(VENDOR_DIR)"
