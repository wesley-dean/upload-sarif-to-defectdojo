# AGENTS.md

## Purpose

`upload-sarif-to-defectdojo` is a Bash command-line client that imports scan
reports into DefectDojo.  The maintained public executable is
`upload_sarif_to_defectdojo.bash`; preserving that path and its documented CLI
is part of the compatibility contract.

Before changing behavior, read `README.md`, this file,
`doc/adr/README.md`, the ADRs relevant to the work, and the applicable
standards under `doc/standards/`.

## Governance

Files under `doc/standards/` are governing project requirements, not
suggestions.  Apply every relevant standard unless an accepted
repository-specific ADR or explicit repository policy supersedes or refines it.
Do not silently deviate from governing requirements, and do not edit imported
standards locally.  Shared-standard changes belong in
`wesley-dean/coding_standards`.

Presence does not imply applicability.  General and cross-cutting standards
apply where relevant.  The Bash standard applies to maintained Bash source.
Other language-specific standards apply only when maintained content in that
language is in scope.  Content under `doc/standards/examples/` is illustrative
and non-normative unless a governing standard explicitly says otherwise.

## Public contract

- Keep `upload_sarif_to_defectdojo.bash` as the directly downloadable public
  executable unless an accepted ADR changes that contract.
- Preserve documented short and long CLI flags unless a compatibility decision
  explicitly changes them.
- Read scan files from paths supplied as positional arguments.
- Treat an unmatched glob as a successful no-op and an explicitly missing path
  as an error.
- Never write the DefectDojo token to diagnostic output.
- Keep dry-run mode free of network I/O.
- Keep unit and behavior tests independent of a live DefectDojo instance.

## Runtime and external boundaries

ADR-002 defines the supported runtime and testing contract.  The maintained
script targets Bash 4.3 or newer on Linux.  Runtime upload behavior requires
`curl`; Git is optional metadata enrichment rather than a prerequisite.

DefectDojo, Git, the filesystem, and subprocess commands are external boundaries.
Tests should replace those boundaries with temporary repositories, fixtures, or
PATH-injected fakes rather than depending on mutable external services.

## Configuration trust boundary

ADR-003 governs configuration.  Configuration files are trusted executable Bash
and are sourced intentionally.  Do not weaken the README warning or imply that
configuration is parsed as inert data.

Configuration precedence is:

1. command-line values;
2. pre-existing environment variables;
3. the selected configuration file; and
4. built-in defaults.

An explicit `--config` / `-c` selection takes precedence over automatic
configuration discovery.

## Tests

Bats is the primary behavior test framework.  `make test` is the canonical test
entry point and must remain network-free.  Add focused regression coverage for
confirmed bugs, especially around command construction, credential redaction,
configuration precedence, Git metadata, and path handling.

The container build is a separate product validation surface.  CI should run the
behavior suite against the maintained script and also build and smoke-test the
container image.

## Scope discipline

Keep changes surgical and reviewable.  Do not introduce source-layout changes,
build-time minification, dependency managers, or generated artifact flavors merely
to resemble another repository.  Those mechanisms require a demonstrated need and
an accepted architectural decision.

When consequential behavior, compatibility, trust boundaries, release behavior,
or interfaces change, update or add an ADR and keep
`doc/adr/README.md` synchronized with current governance.
