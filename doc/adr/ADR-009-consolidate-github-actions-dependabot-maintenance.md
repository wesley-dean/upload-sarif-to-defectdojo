# ADR-009: Consolidate GitHub Actions Dependabot Version Updates

Date: 2026-11-12

## Status

Accepted

## Decision

Preserve weekly Dependabot GitHub Actions routine version updates,
the existing seven-day cooldown, and commit-message conventions.
Replace the minor/patch-only group with one wildcard
`actions-version-updates` group using `applies-to: version-updates`
and `patterns: ["*"]` without an `update-types` restriction.
Eligible major, minor, and patch routine updates may be grouped.

Security updates remain independent and must not wait for the weekly
schedule or routine cooldown. Retain the existing
`dependabot/fetch-metadata` non-major-only auto-merge condition.
Any group containing a major version requires targeted manual review
of every dependency and its compatibility and security implications.

## Context and Decision Drivers

The previous weekly configuration groups only minor/patch GitHub Actions
versions. Separate major proposals add recurring review effort.
The verified `coding_standards@v3.2.0` release recommends
weekly per-ecosystem wildcard grouping and a seven-day cooldown,
with unchanged security and major-upgrade review boundaries.

This project uploads potentially sensitive security scan reports to a
DefectDojo API. Its accepted ADRs protect executable Bash configuration
trust, CLI and environment precedence, authenticated API communication,
embedded bashlog, deterministic release artifacts, tested Bash behavior,
and separation of validation from publication authority. CI and release
Action upgrades can affect those boundaries even when runtime files do
not change.

## Assumptions and Operational Constraints

- GitHub Actions is the sole configured Dependabot ecosystem.
- Existing weekly cadence and seven-day version-update cooldown stay.
- Existing non-major-only auto-merge guard and workflow permissions stay.
- Routine version groups MUST NOT include or delay security updates.
- Grouped changes with write-capable Actions require release-note,
  permissions, migration, and relevant CI/release evidence review.
- GitHub-side required check identities, branch protections, code-owner
  review requirements, dependency alerts, and security-update settings
  are not established by local configuration and require verification.
- No DefectDojo token, API endpoint, configuration evaluation boundary,
  Bash runtime behavior, report format, public CLI, source layout,
  published artifact, or release permission change is authorized.
- The optional shared CI test-gate examples are not installed by
  adoption of their governing standards.

## Alternatives Considered

1. Keep minor/patch-only grouping. Rejected as the default because
   it maintains separate routine major PRs without automatically
   imposing more meaningful review than the documented major guard.
2. Group all eligible routine major/minor/patch versions per ecosystem.
   Selected with heightened review for major-containing groups.
3. Change to monthly updates or extend cooldown. Rejected because
   slower routine visibility is not yet supported by activity evidence.
4. Auto-merge major-containing groups. Rejected because breaking
   changes in privileged Actions could affect security data handling,
   CI trust, or artifact publication.
5. Immediately close current Dependabot PRs. Rejected because updated
   grouping configuration does not prove equivalent upgrade coverage.

## Consequences, Security, and Tradeoffs

Routine version-update PR volume may decline, but incompatible Action
versions and resolver constraints can still produce multiple PRs.
Grouped failures can be harder to diagnose. A sensitive dependency may
need a narrowly documented group isolation exception rather than an
`ignore` rule that hides maintenance needs.

Each grouped PR still requires dependency-by-dependency review.
The highest-risk change governs review depth. A passing linter alone
does not validate DefectDojo API behavior, executable configuration
boundaries, tests, or privileged release publication. Existing
Dependabot PR #266 remains open until actual replacement coverage
and appropriate verification are observed.

## Expected Outcomes and Verification

Observe subsequent Dependabot proposals, inspect grouped update types,
confirm the major auto-merge guard continues to exclude breaking
updates, and verify independent security-update settings and effective
review protections. Compare actual PR volume and review effort over
multiple cycles; no exact reduction is guaranteed.

No runtime, published interface, deployment, release artifact, or
credential migration is required by this maintenance-only change.

## Related Decisions

ADR-001 governs the complete released shared standards snapshot;
ADR-002 and ADR-003 govern runtime and configuration safety;
ADR-004 governs reviewed release classification; ADR-005/006/007/008
govern dependencies, ADR inventory, reference documentation, and
validated release artifacts. None is superseded.
