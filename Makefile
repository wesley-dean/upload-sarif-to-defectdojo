SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

PROJECT_NAME := upload_sarif_to_defectdojo
SCRIPT := upload_sarif_to_defectdojo.bash
SOURCE_SCRIPT := src/upload_sarif_to_defectdojo.bash
DIST_DIR := dist
DIST_DEV_SCRIPT := $(DIST_DIR)/$(PROJECT_NAME).dev.bash
DIST_SCRIPT := $(DIST_DIR)/$(PROJECT_NAME).bash
DIST_MIN_SCRIPT := $(DIST_DIR)/$(PROJECT_NAME).min.bash
DIST_SCRIPTS := $(DIST_DEV_SCRIPT) $(DIST_SCRIPT) $(DIST_MIN_SCRIPT)
DIST_CHECKSUMS := $(addsuffix .sha256,$(DIST_SCRIPTS))
LEGACY_CHECKSUMS := $(addsuffix .256,$(DIST_SCRIPTS))
BATS_FILES := $(wildcard tests/*.bats)
BASH_HELPERS := $(wildcard tests/*.bash)
SHFMT_ARGS := -i 2 -bn -ci -sr -kp

VENDOR_DIR := vendor
DEPENDENCY_MANIFEST := dependencies.txt
BASHDEPS := $(VENDOR_DIR)/bashdeps.bash
BASHDEPS_VERSION := 0.4.1
BASHDEPS_URL := https://github.com/wesley-dean/bashdeps/releases/download/v$(BASHDEPS_VERSION)/bashdeps.bash
BASHDEPS_SHA256 := 5131ebb6a3a85e1d76624a37146c2442b2e57be6ffd8139b9590d28239876701
BASHLOG_DEV := $(VENDOR_DIR)/bashlog.dev.bash
BASHLOG_VERSION := 0.0.18
BASH_MINIFIER := $(VENDOR_DIR)/bash-minifier.bash
ADRCTL := $(VENDOR_DIR)/adrctl.bash
ADR_INDEX_FILE := doc/adr/README.md
ADR_INDEX_MARKER := <!-- adrctl-generated-footer -->
BASH_DOXYGEN := $(VENDOR_DIR)/doxygen-bash.awk
DOCS_OUTPUT := doc/reference

VERSION ?= 0.0.0-dev
BUILD_COMMIT ?= $(shell commit="$(git rev-parse --short=12 HEAD 2>/dev/null || printf 'unknown')"; if git rev-parse --is-inside-work-tree >/dev/null 2>&1 && [[ -n "$(git status --porcelain --untracked-files=normal -- Makefile dependencies.txt src 2>/dev/null)" ]]; then printf '%s-dirty' "$commit"; else printf '%s' "$commit"; fi)
BUILD_DATE ?= $(shell git show -s --format=%cI HEAD 2>/dev/null || printf 'unknown')
COMPAT_VERSION := 0.0.0-dev
COMPAT_BUILD_DATE := unknown
COMPAT_BUILD_COMMIT := unknown

.PHONY: adr-index all build check checksums clean deps deps-check distclean docs docs-clean FORCE format format-check test verify-bashdeps

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

build: $(DIST_SCRIPTS) $(DIST_CHECKSUMS) $(SCRIPT)
	rm -f $(LEGACY_CHECKSUMS)

$(DIST_DEV_SCRIPT): FORCE $(SOURCE_SCRIPT)
	@test -r "$(BASHLOG_DEV)" || { \
		printf '%s\n' 'Missing build dependency vendor/bashlog.dev.bash; run make deps or make all' >&2; \
		exit 1; \
	}
	@mkdir -p "$(DIST_DIR)"
	@overview="$$(awk ' \
		/^[[:space:]]*##[[:space:]]*@file/ { capture=1 } \
		capture && /^[[:space:]]*$$/ { exit } \
		capture { \
			line=$$0; \
			gsub(/[[:space:]]*@(author|copyright|version)[[:space:]]*/, "", line); \
			gsub(/^[[:space:]]*##[[:space:]]*/, "", line); \
			gsub(/^@(file|brief|details)[[:space:]]*/, "", line); \
			print line; \
		}' "$(SOURCE_SCRIPT)")"; \
	tmp="$@.tmp"; \
	trap 'rm -f "$$tmp"' EXIT; \
	{ \
		printf '%s\n' '#!/usr/bin/env bash'; \
		printf '%s\n' '#'; \
		printf '%s\n' '# Generated by make build. Do not edit directly.'; \
		printf '%s\n' '# Project: $(PROJECT_NAME)'; \
		printf '%s\n' '# Version: $(VERSION)'; \
		printf '%s\n' '# Build date: $(BUILD_DATE)'; \
		printf '%s\n' '# Build commit: $(BUILD_COMMIT)'; \
		printf '%s\n' '# Maintained source: $(SOURCE_SCRIPT)'; \
		printf '%s\n' '# Embedded dependency: bashlog.dev.bash v$(BASHLOG_VERSION)'; \
		printf '\n'; \
		printf 'UPLOAD_SARIF_PROJECT_NAME=%q\n' "$(PROJECT_NAME)"; \
		printf 'UPLOAD_SARIF_VERSION=%q\n' "$(VERSION)"; \
		printf 'UPLOAD_SARIF_BUILD_DATE=%q\n' "$(BUILD_DATE)"; \
		printf 'UPLOAD_SARIF_BUILD_COMMIT=%q\n' "$(BUILD_COMMIT)"; \
		printf 'UPLOAD_SARIF_USAGE_OVERVIEW=%q\n' "$$overview"; \
		printf '\n'; \
		sed '1d' "$(BASHLOG_DEV)"; \
		printf '\n'; \
		sed '1d' "$(SOURCE_SCRIPT)"; \
	} >"$$tmp"; \
	chmod 0755 "$$tmp"; \
	bash -n "$$tmp"; \
	mv "$$tmp" "$@"; \
	trap - EXIT

$(DIST_SCRIPT): $(DIST_DEV_SCRIPT)
	sed '1b; /^[[:space:]]*#/d' "$<" >"$@.tmp"
	chmod 0755 "$@.tmp"
	bash -n "$@.tmp"
	mv "$@.tmp" "$@"

$(DIST_MIN_SCRIPT): $(DIST_SCRIPT)
	@test -r "$(BASH_MINIFIER)" || { \
		printf '%s\n' 'Missing build dependency vendor/bash-minifier.bash; run make deps or make all' >&2; \
		exit 1; \
	}
	bash "$(BASH_MINIFIER)" -F <"$(DIST_SCRIPT)" >"$@.tmp"
	chmod 0755 "$@.tmp"
	bash -n "$@.tmp"
	mv "$@.tmp" "$@"

$(DIST_DIR)/%.bash.sha256: $(DIST_DIR)/%.bash
	@digest=''; \
	if command -v sha256sum >/dev/null 2>&1; then \
		digest="$$(sha256sum "$<" | awk '{print $$1}')"; \
	elif command -v shasum >/dev/null 2>&1; then \
		digest="$$(shasum -a 256 "$<" | awk '{print $$1}')"; \
	else \
		printf '%s\n' 'No SHA-256 command is available for build checksums' >&2; \
		exit 1; \
	fi; \
	printf '%s  %s\n' "$$digest" "$(notdir $<)" >"$@.tmp"; \
	mv "$@.tmp" "$@"

$(SCRIPT): $(DIST_SCRIPT)
	@tmp="$@.tmp"; \
	trap 'rm -f "$$tmp"' EXIT; \
	sed \
		-e 's/^UPLOAD_SARIF_VERSION=.*/UPLOAD_SARIF_VERSION=$(COMPAT_VERSION)/' \
		-e 's/^UPLOAD_SARIF_BUILD_DATE=.*/UPLOAD_SARIF_BUILD_DATE=$(COMPAT_BUILD_DATE)/' \
		-e 's/^UPLOAD_SARIF_BUILD_COMMIT=.*/UPLOAD_SARIF_BUILD_COMMIT=$(COMPAT_BUILD_COMMIT)/' \
		"$(DIST_SCRIPT)" >"$$tmp"; \
	chmod 0755 "$$tmp"; \
	bash -n "$$tmp"; \
	mv "$$tmp" "$@"; \
	trap - EXIT

checksums: build

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

test: build
	@set -e; for artifact in $(DIST_SCRIPTS); do \
		printf 'Testing %s\n' "$artifact"; \
		UPLOAD_SARIF_ARTIFACT="$(pwd)/$artifact" bats tests; \
	done

clean: docs-clean
	rm -rf "$(DIST_DIR)"
	rm -f "$(SCRIPT).tmp"

distclean: clean
	rm -rf "$(VENDOR_DIR)"
