# Consolidated Dependabot Version Update Standard

## Status

Recommended engineering standard

## Purpose

This standard reduces recurring Dependabot pull-request review work across a
portfolio of repositories while preserving security response, relevant CI
evidence, major-upgrade scrutiny, and repository approval protections.

The shared default is a **weekly, per-ecosystem group of routine version
updates**, with a **seven-day version-update cooldown**. Major, minor, and
patch updates are eligible for the same routine group. Security updates
remain a separate process and MUST NOT be intentionally delayed or mixed
with routine version updates.

Reducing PR count is an operational objective, not a promise of exactly one
PR per ecosystem per week or any particular portfolio-wide reduction.

## Applicability and Governance

Apply this standard when a repository uses GitHub Dependabot for scheduled
version updates. Repositories without supported dependency manifests or
with deliberately different requirements MAY document a local exception
through an accepted ADR or explicit repository policy.

This standard does not require a repository to enable every Dependabot
package ecosystem. A repository MUST configure only ecosystems and
directories that actually apply to its maintained dependencies.

The [reference Dependabot configuration](../examples/repository/github/dependabot.yml)
uses the `github-actions` ecosystem because that is the common pilot
across template-bash, adrctl, bashdeps, bashlog, and mktext. Additional
ecosystems SHOULD use the same grouping and scheduling principles when
their dependency semantics and test coverage make doing so appropriate.

A standards release provides governing text and a **non-normative**
reference configuration. Receiving the file in `doc/standards/` MUST
NOT create or replace `.github/dependabot.yml`. Local adoption is an
independent reviewed change, consistent with ADR-003 and ADR-009.

## Scheduled Version-Update Baseline

For each routinely maintained package ecosystem, the default SHOULD be:

- `schedule.interval: weekly` for actively maintained projects;
- `cooldown.default-days: 7` for ordinary version updates;
- one broadly matching group for `applies-to: version-updates`;
- `patterns: ["*"]` so all eligible named dependencies in that
  ecosystem may be grouped;
- **no** `update-types` restriction on the broad group, allowing major,
  minor, and patch releases together; and
- no newly restrictive `open-pull-requests-limit` while an existing
  dependency-update backlog is being reconciled.

The `github-actions` reference group is named
`actions-version-updates`. Other ecosystems MAY use a clear
ecosystem-specific group name. Grouping is normally scoped per
package ecosystem. Cross-ecosystem grouping is not part of this
baseline and MUST NOT be presumed to occur automatically.

The default does not require fixed weekdays or time zones: repositories
MAY select scheduling windows appropriate to their maintenance and
CI workloads.

A low-activity repository MAY choose `schedule.interval: monthly`
through explicit local governance. A cooldown up to 30 days MAY be
considered for low-activity repositories when the additional routine
update delay is acceptable. Neither slower scheduling nor a longer
cooldown may be treated as a substitute for security updates.

Do not impose an artificially low open-PR limit merely to hide backlog
volume. A low limit can suppress useful new version update proposals
while stale PRs occupy the available slots. Review or reconcile the
existing queue before changing the limit.

## Security Update Independence

The wildcard group MUST specify `applies-to: version-updates`. It MUST
NOT silently group security updates, or make security fixes wait for a
weekly or monthly scheduled version-update cycle. The `cooldown`
setting governs version updates, not Dependabot security updates.

Repositories relying on automated security remediation MUST verify
that the dependency graph, Dependabot alerts, and Dependabot security
updates are enabled and appropriately configured in their GitHub
settings. A `dependabot.yml` version-update schedule does not itself
establish this prerequisite.

A separate, explicitly governed security-update grouping policy MAY
exist, but it MUST NOT be conflated with or inferred from the routine
version-update group. Prompt security handling remains an independent
requirement.

## Major Upgrades and Review Controls

Bundling a major release with minor and patch releases is intentional.
A grouped PR MUST be reviewed according to its **highest-risk change**,
including release notes, migration impact, trust boundary, and the
test evidence that actually exercises the affected behavior.

A grouped PR containing any major update MUST NOT become eligible for
automatic merge merely because other dependencies in the group are
minor or patch updates. Where `dependabot/fetch-metadata` is used,
its documented `update-type` output represents the highest SemVer
change in a grouped PR; any major-containing group SHOULD be held out
of the non-major auto-merge path. Repositories MUST verify that the
actual auto-merge condition enforces the intended boundary.

For non-major-only groups, requesting automatic merge MAY remain
permitted where existing repository governance permits it, but GitHub
MUST still enforce its configured required checks, CODEOWNERS review,
branch protections, and rulesets. A successful auto-merge workflow does
not itself prove the PR was approved or merged.

Review of each changed dependency is still necessary. In particular,
GitHub Actions with write-capable tokens, release-publishing authority,
tag creation, package or container registry credentials, signing access,
or other privileged operations deserve targeted evidence. Passing a
linter or unit test that never exercises a changed release workflow
does not prove that release workflow remains safe or functional.

Preserve full-commit-SHA pinning and other established provenance rules
when maintaining GitHub Actions dependencies. A grouped update MUST NOT
silently relax an independently governing dependency security standard.

## Repository-Specific Grouping Exceptions

The broad wildcard is a default, not a requirement to mix every
dependency into one PR under all circumstances.

Repositories MAY define narrow `exclude-patterns`, separate named
version-update groups, or independent update entries for dependencies
whose authority or migration needs justify isolation. Examples include
sensitive release automation, registry authentication, and changes
that need separately exercised compatibility tests.

Exceptions MUST be documented, scoped to the reason for isolation,
and periodically reconsidered. Excluding a dependency **from a group**
is different from ignoring its updates entirely; avoid `ignore` rules
as a substitute for routing a dependency into its own review path.

Multiple package ecosystems SHOULD generally have separately reviewed
groups, since runtime packages, container bases, and GitHub Actions
present different change and verification surfaces. No single-PR
guarantee spans all ecosystems or repositories.

## Adoption and Backlog Reconciliation

A maintainer or agent adopting this model SHOULD:

1. Review repository governance, existing Dependabot configuration,
   package ecosystems, update-specific ADRs, and required PR gates.
2. Measure the current open Dependabot PR backlog and existing grouping
   and cadence before changing the policy.
3. Copy and adapt the reference YAML into `.github/dependabot.yml`
   through a normal reviewed repository PR; merge with any existing
   ecosystem entries instead of replacing them blindly.
4. Keep security updates separate and verify the repository-level
   security configuration and effective CODEOWNERS protections.
5. Preserve the existing non-major-only auto-merge behavior, or
   document a separate reviewed decision if changing it.
6. Leave pre-existing PRs open until a later actual grouped PR
   demonstrably covers their updates and necessary test evidence;
   do not assume Dependabot will retroactively consolidate them.
7. Observe subsequent Dependabot runs, compare PR volume and
   maintainer review effort, inspect grouped failures, and refine
   narrow exceptions only when evidence supports them.

A group may fail resolution or contain an incompatible upgrade. Split
or isolate the problematic dependency when needed rather than making
all of the grouped changes an automatic approval.

## Failure Modes and Limits

- Wildcard groups admit major releases, including breaking changes.
- One grouped failure can be harder to diagnose than an isolated PR.
- Resolver constraints, update availability, unsupported dependencies,
  or group failures can still generate multiple separate PRs.
- Existing PRs are not guaranteed to be closed or replaced when a group
  is added.
- A seven-day cooldown reduces routine release churn but does not
  prove an upstream version is trustworthy.
- Disabled or misconfigured security-update settings leave a separate
  vulnerability-remediation gap.
- Review and CODEOWNERS requirements must be enforced by GitHub
  rulesets/branch protection, not by the mere presence of a
  `CODEOWNERS` file.
- Grouping alone does not reduce PRs across multiple repositories;
  it reduces eligible updates **within an ecosystem in one repository**.

## Related Governance

The [Development Workflow and Backlog Governance](development-workflow-governance.md)
continues to govern authorized work, PR readiness, review, and auto-merge.
The [General Testing Standard](testing-standard.md) governs meaningful
validation and aggregate failure reporting. The
[GitHub Actions Check Naming and Optional-Presence Gate Standard][check-gate]
does not prove mandatory tests ran, and a green `test-gate` MUST NOT be
mistaken for complete dependency compatibility or release-path evidence.

[check-gate]: github-actions-check-gate-standard.md
