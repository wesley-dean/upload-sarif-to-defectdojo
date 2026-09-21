# ADR-001: Adopt Shared Coding Standards

Date: 2026-09-21

## Status

Accepted

## Context

This repository predates the shared `wesley-dean/coding_standards` library.
It needs current, locally inspectable engineering governance without replacing
repository-specific decisions or introducing update machinery that changes policy
outside review.

The selected release is `coding_standards@v1.0.11`, whose tag resolves to
`ef7e670f1de3d9912011bd8398181630c2d446f2`.  GitHub reports SHA-256
`d4f931a089782e3b7c6c8ee09fcb0ca999c42f3dc99353f38243bb1565af8138`
for the release archive.

## Decision

Commit the complete released `standards/` tree beneath `doc/standards/`.
Record source, concrete release, archive digest, and managed destination in
`.codingstandardrc`.

Applicable imported standards are governing requirements.  Presence does not make
every language-specific standard applicable.  Accepted repository ADRs and
explicit policy may refine or supersede imported standards.

Do not edit imported standards locally.  Shared changes belong upstream.
Future standards updates replace the complete managed snapshot through review.
Do not install permanent consumer-side standards-fetching or synchronization
machinery solely for this purpose.

## Alternatives Considered

Maintaining local independent standards was rejected because copies drift.
Partial imports were rejected because they weaken provenance.  Dynamic CI-time
fetching was rejected because governance could change without a repository diff.

## Consequences

The project gains deterministic standards provenance and locally readable
governance.  Standards changes become explicit reviewable maintenance work.
Runtime behavior is unchanged by this decision.
