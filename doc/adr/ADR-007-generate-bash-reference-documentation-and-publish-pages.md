# ADR-007: Generate Bash Reference Documentation and Publish to Pages

Date: 2026-09-21

## Status

Accepted

## Context

The maintained uploader source contains Doxygen-style Bash documentation and is
governed by the shared Bash documentation standard.  The repository does not yet
compile those comments into browsable reference documentation.

Issue #250 requests that the project integrate `bash-doxygen`, expose
documentation generation through `make docs`, and publish the resulting site
through GitHub Pages.

ADR-005 established `bashdeps` and `dependencies.txt` as the repository
dependency boundary.  ADR-006 established a separate `adrctl`-based process for
maintaining the committed ADR landing page.  Reference generation should reuse
those decisions rather than introduce an independent downloader or another
generated-document ownership model.

## Decision Drivers

- Generate reference documentation from maintained Bash source rather than from
  the generated compatibility artifact.
- Use the same released Bash Doxygen filter that downstream consumers use.
- Keep documentation tooling pinned and digest-verified through bashdeps.
- Keep `make docs` network-free after dependencies are prepared.
- Treat generated HTML as disposable derivative state rather than maintained
  repository source.
- Verify documentation generation on pull requests.
- Publish the same documentation surface from `main` through GitHub Pages.
- Preserve the existing uploader runtime and release behavior.

## Decision

The repository SHALL pin released `bash-doxygen v0.5.2` in
`dependencies.txt` as:

- artifact: `doxygen-bash.awk`;
- destination: `vendor/doxygen-bash.awk`; and
- SHA-256:
  `4690fe688938794b2c6e76ca35b64ee2c5b33dd12592ac7475da800b57fd57e8`.

The filter is documentation/development tooling only.  It SHALL NOT be embedded
into the uploader runtime artifact.

The canonical documentation command is:

`make docs`

`make docs` SHALL consume already-prepared dependency state and SHALL NOT
bootstrap, synchronize, or repair dependencies.  Missing
`vendor/doxygen-bash.awk` SHALL fail with an actionable message directing the
maintainer to `make deps`.

The docs target SHALL:

1. require Doxygen and the prepared Bash Doxygen filter;
2. run the pinned filter in strict mode against the maintained
   `src/upload_sarif_to_defectdojo.bash` source before invoking Doxygen;
3. remove stale generated reference output;
4. invoke the committed `Doxyfile`;
5. generate HTML beneath `doc/reference/`; and
6. fail unless `doc/reference/index.html` exists.

The committed `Doxyfile` SHALL document maintained project material, including
the canonical Bash source and selected human-facing project/ADR documentation.
It SHALL NOT document the generated root compatibility script, `vendor/`,
future `dist/` output, tests, or prior generated `doc/reference/` content.

The maintained Bash source remains the source of truth for implementation-level
documentation.  Doxygen comments SHALL conform to the governing shared Bash
documentation standard.  Documentation corrections made to satisfy that standard
MUST preserve executable behavior exactly.

Generated `doc/reference/` content is derivative state and SHALL be ignored by
Git.  It SHALL NOT be committed and SHALL NOT become a source of truth for
implementation behavior or architecture.

Pull-request CI SHALL synchronize and verify dependencies, run `make docs`, and
verify that `doc/reference/index.html` exists while generated documentation
remains ignored/untracked repository state.

A dedicated GitHub Actions workflow SHALL publish documentation on pushes to
`main` and on explicit workflow dispatch.  That workflow SHALL:

1. check out the trusted repository revision;
2. install Doxygen;
3. run `make deps` and `make deps-check`;
4. regenerate the committed ADR inventory and verify that it is current;
5. run `make docs`;
6. verify the generated Pages artifact;
7. upload `doc/reference/` using the GitHub Pages artifact action; and
8. deploy it through the GitHub Pages deployment action.

The Pages workflow SHALL use least-privilege permissions appropriate to GitHub
Pages deployment: `contents: read`, `pages: write`, and `id-token: write`.

`make docs-clean` SHALL remove generated `doc/reference/` output without
altering maintained source or committed ADR documentation.

## Alternatives Considered

### Generate documentation from the root upload_sarif_to_defectdojo.bash file

Rejected because that file is generated and embeds bashlog.  It would duplicate
dependency documentation and make generated consumer bytes appear to be
maintained source.

### Commit doc/reference/

Rejected because generated HTML is derivative output that can be reproduced from
maintained source and pinned tooling.  Committing it would create unnecessary
review noise and drift.

### Download bash-doxygen directly in the Pages workflow

Rejected because ADR-005 already establishes bashdeps as the canonical
repository dependency manager.  Workflow-specific acquisition would duplicate
trust and pinning logic.

### Make make docs synchronize dependencies automatically

Rejected because it would blur the established boundary between networked
dependency convergence and offline generation.  Documentation builds should be
reproducible from already-prepared bytes.

### Publish only from a checked-in documentation directory

Rejected because Pages should publish the exact documentation generated from the
trusted `main` revision, not a separately maintained copy.

## Consequences

Maintainers need Doxygen installed locally to run `make docs`, and a fresh
checkout needs `make deps` before documentation generation.

Pull-request validation gains a documentation build.  The Pages workflow adds a
trusted deployment path with GitHub Pages permissions but does not change runtime
or release permissions elsewhere.

Generated reference content remains absent from ordinary repository diffs and
scanner surfaces.  The maintained source comments and ADR corpus remain the
reviewable inputs.

## Related Decisions

- ADR-001: Adopt Shared Coding Standards
- ADR-005: Adopt bashdeps-Managed Embedded bashlog
- ADR-006: Use adrctl to Maintain the ADR Inventory

## Related Issues

- #250: Generate Doxygen documentation with bash-doxygen
