# ADR-006: Use adrctl to Maintain the ADR Inventory

Date: 2026-09-21

## Status

Accepted

## Context

The repository's ADR landing page has two different ownership domains.
Everything above `<!-- adrctl-generated-footer -->` is curated current-governance
documentation maintained by contributors.  Everything below that marker is an
exhaustive inventory of the ADR corpus.

The inventory is currently maintained by hand.  That is workable for a small
corpus, but it duplicates information already present in the ADR files and makes
omissions increasingly likely as the repository grows.  Issue #249 requests that
the inventory be generated with `adrctl` while preserving the curated portion
byte-for-byte.

ADR-005 established `bashdeps` as the repository dependency manager and
`dependencies.txt` as the declaration surface for ordinary repository tools.
That boundary should also govern adrctl rather than introducing a second
acquisition mechanism.

## Decision Drivers

- Preserve the curated `Current Decisions` digest as maintained project
  knowledge.
- Generate the exhaustive inventory from the ADR corpus rather than editing it by
  hand.
- Preserve the exact marker boundary required by the shared ADR standard.
- Make repeated regeneration deterministic and idempotent.
- Detect stale committed inventory in CI.
- Reuse the repository's established bashdeps dependency boundary.
- Keep ordinary ADR-index regeneration network-free after dependencies are
  prepared.

## Decision

The repository SHALL pin released `adrctl v0.0.16` in `dependencies.txt` as:

- artifact: `adrctl.bash`;
- destination: `vendor/adrctl.bash`; and
- SHA-256:
  `782469485927d6eb6a3e7c480e793680cfc029accd15bb5e700ade82a9aa8204`.

`vendor/adrctl.bash` is development/documentation tooling only.  It SHALL NOT
be embedded into the uploader runtime artifact.

The committed `doc/adr/README.md` remains the repository's ADR landing page.
The line:

`<!-- adrctl-generated-footer -->`

is the ownership boundary.  The file MUST contain that marker exactly once.

Everything above the marker is maintained project documentation.  Regeneration
MUST preserve those bytes exactly.  The marker itself remains in the committed
file.  Everything below the marker is mechanically owned and MAY be replaced on
every regeneration.

The canonical regeneration command is:

`make adr-index`

That target SHALL consume already-prepared `vendor/adrctl.bash` state and SHALL
NOT synchronize or repair dependencies.  Missing adrctl state SHALL fail with an
actionable message directing the maintainer to `make deps`.

The target SHALL:

1. verify that the marker exists exactly once;
2. capture the maintained prefix through and including the marker;
3. run `adrctl.bash generate toc` against the repository ADR corpus;
4. demote adrctl's top-level generated heading from
   `# Architecture Decision Records` to
   `## Architecture Decision Records` so it nests beneath the landing page;
5. compose the maintained prefix, exactly one blank line, and the generated
   inventory into a temporary candidate;
6. publish the candidate atomically only after generation succeeds; and
7. produce byte-identical output when invoked repeatedly without source changes.

The mechanically generated bullet representation is adrctl's output.  The
repository SHALL NOT post-process bullet markers or titles merely to preserve the
hand-written inventory's previous cosmetic style.

CI SHALL prepare dependencies, run `make adr-index`, verify that the maintained
prefix is unchanged, verify that a second regeneration is byte-identical, and
fail when the resulting committed landing page differs from repository state.

Contributors and agents SHALL edit only the curated portion above the marker when
changing current-governance summaries.  They SHALL add or modify ADR files as
ordinary maintained source, then run `make adr-index` to refresh the exhaustive
inventory.  They SHALL NOT hand-edit the generated footer.

## Alternatives Considered

### Maintain the inventory by hand

Rejected because it duplicates discoverable ADR metadata and makes omissions easy
to introduce.

### Make doc/adr/README.md entirely generated and uncommitted

Rejected because the landing page contains curated current-governance knowledge
that should remain visible and reviewable in the repository.

### Split the curated prefix into a separate README.intro.md source file

Rejected for this repository because the governing standard already defines the
marker inside `doc/adr/README.md` as the maintained/generated ownership
boundary.  Keeping the curated text in the landing page itself makes that contract
directly inspectable.

### Let Make download adrctl directly

Rejected because ADR-005 already establishes bashdeps as the canonical manager for
ordinary repository dependencies.

### Reformat adrctl output to match the existing dash-bullet footer

Rejected because cosmetic rewriting adds another transformation layer with no
governance value.  The generated inventory should remain recognizably owned by
adrctl.

## Consequences

Adding or renaming an ADR requires regenerating the committed inventory.
Reviewers can distinguish curated governance edits from mechanical inventory
changes at the marker.

A fresh checkout must run `make deps` before `make adr-index`, while prepared
checkouts and CI can regenerate the inventory without network access.

The footer's bullet markers change from the previous hand-written dash style to
adrctl's asterisk style.  That is a representational change only; the links and
titles remain the inventory contract.

## Related Decisions

- ADR-001: Adopt Shared Coding Standards
- ADR-005: Adopt bashdeps-Managed Embedded bashlog

## Related Issues

- #249: Use adrctl to maintain doc/adr/README.md
