# AGENTS.md

## Purpose

`upload-sarif-to-defectdojo` is a Bash command-line client that imports scan
reports into DefectDojo.  The maintained uploader source is `src/upload_sarif_to_defectdojo.bash`.
The root `upload_sarif_to_defectdojo.bash` file is a generated and committed
standalone compatibility artifact; preserving that public path and its documented
CLI is part of the compatibility contract.

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

## Dependency and build boundaries

ADR-005 governs repository dependencies and bashlog integration.  Make directly
bootstraps only pinned `vendor/bashdeps.bash`; `dependencies.txt` owns ordinary
repository dependencies, beginning with `vendor/bashlog.dev.bash`.  The complete
`vendor/` directory is generated state and is never committed.

Use the boundaries consistently:

- `make deps` may use the network and repair dependency state;
- `make deps-check` is offline and verifies prepared state;
- `make build` is offline and consumes prepared state;
- `make all` performs dependency convergence followed by build; and
- `make test` builds and exercises all three prepared distribution flavors and remains network-free.

Do not edit `upload_sarif_to_defectdojo.bash` directly.  Edit maintained source
under `src/`, prepare dependencies, and run `make build`.  ADR-008 governs the
documented, ordinary, and minified `dist/` artifacts plus the generated root
compatibility file.  Every consumer artifact must remain runnable after
`vendor/` is removed.

Operational log records use the namespaced bashlog API and go to STDERR.  Do not
reintroduce direct `logger(1)`, syslog, network, or file transports without a
new architectural decision.  Application-specific diagnostic output such as the
redacted dry-run curl command may remain outside bashlog where its formatting is
part of the CLI contract.

## Distribution artifacts

ADR-008 governs the source-to-distribution pipeline.  `dist/` is generated
derivative state and must remain ignored and excluded from source/security
scanning.  Do not lint, format, or security-scan generated distribution files as
maintained source.

The build order is development artifact, ordinary comment-stripped artifact,
then minified artifact.  Each executable receives an adjacent `.sha256`
companion.  The root compatibility script is generated from the ordinary
transformation with stable compatibility provenance.

When changing build behavior, preserve:

- one canonical maintained source under `src/`;
- pinned bashlog and Bash-Minifier inputs through bashdeps;
- network-free `make build` and `make test` after dependency preparation;
- identical observable behavior across all three artifact flavors;
- the historical root raw-download path;
- exact six-file release publication; and
- release validation before release-write authority is used.

## ADR maintenance

ADR-006 governs `doc/adr/README.md` generation.  The
`<!-- adrctl-generated-footer -->` marker separates maintained current-governance
documentation from the exhaustive mechanical inventory.

When adding or materially changing an ADR:

1. keep the ADR status `Accepted`;
2. update the curated `Current Decisions` digest above the marker when current
   governance changes;
3. never hand-edit the inventory below the marker;
4. prepare dependencies with `make deps` when necessary; and
5. run `make adr-index` to regenerate the committed footer.

`make adr-index` consumes pinned `vendor/adrctl.bash`, is network-free, and
must preserve the curated prefix byte-for-byte.  A missing marker, duplicate
marker, or unexpected adrctl TOC shape is a hard failure rather than permission
to append or guess.

## Reference documentation

ADR-007 governs generated Doxygen reference documentation and GitHub Pages
publication.  The maintained source under `src/` is the documentation source of
truth; do not document the generated root compatibility artifact.

The pinned `vendor/doxygen-bash.awk` filter is managed through
`dependencies.txt`.  `make docs` consumes prepared dependency state and is
network-free.  It runs bash-doxygen in strict mode before Doxygen and generates
ignored derivative HTML beneath `doc/reference/`.

When changing maintained Bash documentation:

1. preserve executable behavior;
2. follow `doc/standards/bash/documentation-standard.md`;
3. run `make deps` if dependency state is absent;
4. run `make docs`; and
5. leave `doc/reference/` uncommitted.

The Pages workflow regenerates documentation from trusted `main` and publishes
only `doc/reference/`.  Do not grant Pages permissions to ordinary test or
pull-request workflows.

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
