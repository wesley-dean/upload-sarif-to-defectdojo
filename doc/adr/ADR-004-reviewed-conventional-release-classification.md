# ADR-004: Govern Release Classification Through Reviewed Conventional Titles

Date: 2026-09-21

## Status

Accepted

## Context

The repository already creates semantic-version releases, but default GitHub merge
titles do not reliably encode the semantic significance of a complete change.
The shared governance requires release classification to be reviewed and
auditable.

## Decision

Pull request titles use Conventional Commit classification and represent the
highest semantic significance of the complete PR.  Squash merge is the preferred
merge strategy, and the resulting target-branch commit title preserves the
reviewed PR title.

Issue labels and other issue metadata are advisory and do not control semantic
version classification.  CI validates PR title syntax using repository-owned
shell logic rather than adding another third-party action.

The existing semantic-version publication workflow remains in place unless a
separate architecture decision changes it.

## Alternatives Considered

Default merge titles were rejected because they hide release significance.  Issue
labels were rejected as authoritative version inputs because they are advisory.
A third-party PR-title validation action was rejected because the required check
is small enough to own locally.

## Consequences

Release intent is visible before merge and maps cleanly to squash history.
Contributors must keep the PR title synchronized with scope.
