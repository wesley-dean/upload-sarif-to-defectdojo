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

<!-- adrctl-generated-footer -->

## Architecture Decision Records

- [ADR-001: Adopt Shared Coding Standards](ADR-001-adopt-shared-coding-standards.md)
- [ADR-002: Define Runtime and Testing Contract](ADR-002-define-runtime-and-testing-contract.md)
- [ADR-003: Treat Configuration Files as Trusted Executable Input](ADR-003-trusted-executable-configuration.md)
- [ADR-004: Govern Release Classification Through Reviewed Conventional Titles](ADR-004-reviewed-conventional-release-classification.md)
