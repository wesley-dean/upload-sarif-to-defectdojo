# ADR-005: Adopt bashdeps-Managed Embedded bashlog

Date: 2026-09-21

## Status

Accepted

## Context

The uploader currently implements its own operational logging helper.  That
helper optionally invokes `logger(1)` and otherwise writes to standard error.
The surrounding Bash project family now has two purpose-built tools that provide
a stronger and more repeatable model:

- `bashdeps` materializes exact repository dependencies declared by URL,
  destination, and SHA-256 digest; and
- `bashlog` provides a sourceable Bash 4.3+ logging library whose routine output
  boundary is standard error.

Issue #248 requests adoption of those tools while preserving the uploader's
existing public entry point.  That creates an important packaging constraint:
`upload_sarif_to_defectdojo.bash` is directly downloadable and must continue to
work as a standalone file.  Requiring a sibling `vendor/bashlog.bash` at runtime
would preserve the filename while breaking the one-file consumption model.

The repository also has planned follow-up work in issue #251 to produce
development, ordinary, and minified release artifacts with checksum companions.
The dependency decision made here should become that build pipeline's foundation
rather than a temporary acquisition mechanism that must later be replaced.

## Decision Drivers

- Replace project-specific logging code with the dedicated project-family logger.
- Preserve the directly downloadable, standalone root executable.
- Make dependency identity explicit and digest-verified.
- Keep runtime execution independent of the network and repository vendor state.
- Keep ordinary tests network-free.
- Establish dependency/build boundaries that can be reused by later artifact,
  documentation, and ADR-tooling work.
- Avoid copying or manually maintaining bashlog implementation code in this
  repository.

## Decision

The repository SHALL use a pinned released `bashdeps` executable as its
repository-dependency bootstrap.

The initial bootstrap is:

- release: `bashdeps v0.4.1`;
- artifact: `bashdeps.bash`; and
- SHA-256:
  `5131ebb6a3a85e1d76624a37146c2442b2e57be6ffd8139b9590d28239876701`.

Make SHALL own only this bootstrap acquisition.  The bootstrap SHALL be downloaded
only when missing or when existing bytes fail the committed digest, and downloaded
bytes SHALL be verified before publication.

All ordinary repository dependencies SHALL be declared in
`dependencies.txt` and materialized by bashdeps.  The initial manifest-managed
dependency is:

- release: `bashlog v0.0.18`;
- artifact: `bashlog.bash`;
- destination: `vendor/bashlog.bash`; and
- SHA-256:
  `186562a526a42d3f105e36ca1006669246ee9149c83d12e0ba9044f2159fff8d`.

The entire `vendor/` directory is generated dependency state and SHALL NOT be
committed.

The Make dependency boundaries are:

- `make deps`: bootstrap/verify bashdeps and synchronize the manifest; MAY use
  the network and MAY repair dependency state;
- `make deps-check`: verify prepared bootstrap and manifest state without
  network access or repair;
- `make build`: consume already-prepared dependency state without network access
  or repair;
- `make all`: run dependency convergence and then build; MAY use the network;
  and
- `make test`: exercise the committed public artifact without dependency
  synchronization and remain network-free.

The canonical maintained uploader source SHALL move to
`src/upload_sarif_to_defectdojo.bash`.  The root
`upload_sarif_to_defectdojo.bash` file SHALL become a generated and committed
compatibility artifact.  `make build` SHALL assemble it atomically from the
verified `vendor/bashlog.bash` artifact followed by the maintained uploader
source, with only one executable shebang in the resulting file.

The generated public executable SHALL contain the complete bashlog implementation
and therefore SHALL NOT require `vendor/`, `dependencies.txt`, bashdeps, or
network access at runtime.  CI SHALL prepare dependencies, rebuild the public
artifact, and verify that the committed artifact matches the deterministic build
result.

Project logging call sites SHALL use the namespaced bashlog API directly rather
than retain a project-local logging wrapper.  Existing application-specific
diagnostics that are not ordinary log records, such as the copy/paste-oriented
redacted dry-run curl command and stack trace details, MAY remain
application-owned.

Adopting bashlog intentionally changes the transport boundary.  Operational log
records SHALL go to standard error through bashlog.  The uploader SHALL no longer
invoke `logger(1)` or attempt direct syslog delivery.  Downstream runtimes,
containers, CI systems, service managers, and shell redirection remain responsible
for transport and persistence.

The existing credential-safety contract remains in force.  The uploader SHALL
continue to avoid logging `DD_TOKEN`, and the dry-run request renderer SHALL
continue to redact the Authorization token before writing diagnostics.

Issue #251 may extend the build into `dist/` development, ordinary, and
minified artifacts with SHA-256 companions and release metadata.  That later
decision MAY refine the generated-artifact layout, but it SHOULD retain the
bashdeps manifest boundary, verified bashlog input, standalone artifact property,
and network separation established here.

## Alternatives Considered

### Source vendor/bashlog.bash at runtime

Rejected because a user who downloads only the documented root script would then
receive an incomplete program.  It would also couple runtime behavior to
repository layout.

### Download bashlog at runtime

Rejected because executable dependency acquisition is a build/maintenance concern,
not an upload-time side effect.  It would add network availability and moving
external state to the runtime trust boundary.

### Copy bashlog source into this repository

Rejected because a copied library would drift from its upstream release and lose
the byte-identity guarantees provided by the release artifact and bashdeps
manifest.

### Keep the project-local logger

Rejected because it duplicates a responsibility now owned by bashlog, retains an
external `logger(1)` branch, and increases local code that must be documented,
tested, and audited.

### Defer all dependency work until issue #251

Rejected because bashlog adoption itself requires a reliable way to acquire and
embed the library.  Establishing the dependency boundary now gives #251 and the
other tooling issues a common foundation.

## Consequences

The maintained uploader source and public executable become distinct files.  The
root script remains the stable consumer path, while maintainers edit the source
under `src/` and regenerate the root artifact.

A fresh checkout needs `make deps` or `make all` before rebuilding.  Existing
committed product bytes remain testable without network access.

The runtime loses direct syslog delivery via `logger(1)`.  Operational logging is
instead consistently emitted to standard error, where the execution environment
may route or persist it.

The repository gains a small dependency bootstrap surface in Make and a committed
manifest.  In exchange, dependency provenance becomes explicit and reusable by
later tooling work.

## Related Decisions

- ADR-002: Define Runtime and Testing Contract
- ADR-004: Govern Release Classification Through Reviewed Conventional Titles

## Related Issues

- #248: Adopt bashdeps and bashlog for logging
- #251: Add .dev.bash, .bash, and .min.bash release artifacts with bash-minifier
