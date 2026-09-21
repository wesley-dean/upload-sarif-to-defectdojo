# Architecture Decisions

This directory contains accepted Architecture Decision Records for
`upload-sarif-to-defectdojo`.

## Current Decisions

### ADR-001: Adopt Shared Coding Standards

The repository commits the complete selected shared standards release beneath
`doc/standards/` and records its provenance in `.codingstandardrc`.
Applicable imported standards govern the project, while accepted local ADRs and
explicit policy may refine them.  Imported standards are not edited locally.

See [ADR-001](ADR-001-adopt-shared-coding-standards.md).

### ADR-002: Define Runtime and Testing Contract

The uploader targets Bash 4.3 or newer on Linux and retains the root-level
`upload_sarif_to_defectdojo.bash` executable as its public artifact.  Bats is
the primary network-free behavior test framework, with external services replaced
by fixtures and fakes.  Container construction remains a separate validation
surface.

See [ADR-002](ADR-002-define-runtime-and-testing-contract.md).

### ADR-003: Treat Configuration Files as Trusted Executable Input

Configuration files remain trusted executable Bash for compatibility.  Precedence
is command line, environment, selected configuration file, then built-in
defaults; explicit `--config` selections take priority over discovery.  Missing
explicit configuration fails visibly.

See [ADR-003](ADR-003-trusted-executable-configuration.md).

### ADR-004: Govern Release Classification Through Reviewed Conventional Titles

Pull request titles carry the reviewed Conventional Commit classification for the
complete change, and squash merge is the preferred release boundary.  Issue
metadata is advisory rather than authoritative for versioning.  CI validates PR
title syntax with repository-owned shell logic.

See [ADR-004](ADR-004-reviewed-conventional-release-classification.md).

### ADR-005: Adopt bashdeps-Managed Embedded bashlog

Repository dependencies are prepared through a pinned, digest-verified
`bashdeps` bootstrap and a committed `dependencies.txt` manifest.  The
`bashlog` release artifact is a build input, not a runtime sidecar: the public
root executable embeds verified bashlog bytes so the existing one-file download
contract remains intact.  Prepared dependency state is generated under
`vendor/`; dependency convergence may use the network, while verification,
building, and ordinary tests remain offline.

See [ADR-005](ADR-005-adopt-bashdeps-managed-embedded-bashlog.md).

### ADR-006: Use adrctl to Maintain the ADR Inventory

The curated governance digest above the ADR footer marker remains maintained
project knowledge, while the exhaustive inventory beneath it is generated from
the ADR corpus with pinned `adrctl`.  Regeneration preserves the maintained
prefix byte-for-byte, uses the existing bashdeps dependency boundary, and is
network-free after dependencies are prepared.  CI verifies both idempotence and
that the committed inventory is current.

See [ADR-006](ADR-006-use-adrctl-to-maintain-adr-inventory.md).

### ADR-007: Generate Bash Reference Documentation and Publish to Pages

The maintained Bash source is compiled into reference HTML with the pinned
`bash-doxygen` release through the repository's existing bashdeps dependency
boundary.  `make docs` is network-free after dependency preparation and writes
only ignored derivative output under `doc/reference/`.  Pull-request CI verifies
documentation generation, while a dedicated least-privilege GitHub Pages workflow
rebuilds and publishes the same documentation surface from trusted `main`.

See [ADR-007](ADR-007-generate-bash-reference-documentation-and-publish-pages.md).

<!-- adrctl-generated-footer -->

## Architecture Decision Records

* [ADR-001: Adopt Shared Coding Standards](ADR-001-adopt-shared-coding-standards.md)
* [ADR-002: Define Runtime and Testing Contract](ADR-002-define-runtime-and-testing-contract.md)
* [ADR-003: Treat Configuration Files as Trusted Executable Input](ADR-003-trusted-executable-configuration.md)
* [ADR-004: Govern Release Classification Through Reviewed Conventional Titles](ADR-004-reviewed-conventional-release-classification.md)
* [ADR-005: Adopt bashdeps-Managed Embedded bashlog](ADR-005-adopt-bashdeps-managed-embedded-bashlog.md)
* [ADR-006: Use adrctl to Maintain the ADR Inventory](ADR-006-use-adrctl-to-maintain-adr-inventory.md)
* [ADR-007: Generate Bash Reference Documentation and Publish to Pages](ADR-007-generate-bash-reference-documentation-and-publish-pages.md)
