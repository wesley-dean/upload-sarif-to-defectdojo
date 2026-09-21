# ADR-002: Define Runtime and Testing Contract

Date: 2026-09-21

## Status

Accepted

## Context

The existing workflow proves that a container can build but does not verify the
uploader's CLI, configuration behavior, Git metadata discovery, request
construction, failure handling, or credential redaction.

The implementation intentionally uses Bash arrays and namerefs plus
GNU-compatible Linux utilities.

## Decision

Support Bash 4.3 or newer on Linux.  Upload behavior requires `curl` and the
GNU-compatible baseline utilities used by the implementation.  Git is optional
metadata enrichment.  The `file` command is an optional MIME fallback for
unknown formats.

Use Bats as the primary behavior test framework.  `make test` is the canonical
network-free test entry point.  Tests replace DefectDojo, curl, Git repositories,
and filesystem state with fixtures, temporary repositories, and PATH-injected
fakes as appropriate.

Keep `upload_sarif_to_defectdojo.bash` as the directly downloadable public
executable.  Container build/smoke validation remains separate from source
behavior tests.

## Alternatives Considered

Container-only testing was rejected as insufficient.  Live DefectDojo CI was
rejected because it adds secrets and mutable external state.  Source-to-dist
packaging and minified artifact variants were rejected because there is no
demonstrated need for them.

## Consequences

The runtime claim becomes explicit and testable.  Development CI gains Bats and
static-analysis dependencies, while production use remains a single Bash script
or container image.
