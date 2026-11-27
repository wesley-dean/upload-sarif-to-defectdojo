# ADR-010: Migrate Scheduled Dependency Updates to Central Renovate

Date: 2026-11-26

## Status

Accepted

## Decision

Use the Jenkins-hosted Renovate service for scheduled routine dependency version updates. Retain the existing minimal root `renovate.json` and remove `.github/dependabot.yml`, which configures competing Dependabot version-update proposals. Keep GitHub's independently configured Dependabot security-update mechanism as the intended security response channel. This decision supersedes ADR-009 only for scheduled Dependabot version-update cadence and grouping. Its expectations for dependency-specific review, major-upgrade scrutiny, security independence, existing review gates, and limited CI authority remain in force.

## Context and Drivers

The repository previously grouped GitHub Actions updates through Dependabot. The owner has centralized routine dependency maintenance in a Jenkins Renovate process that discovers `wesley-dean/*`. Running two schedulers for the same ecosystem creates duplicate PRs and wastes reviewer attention. The uploader processes security scan results for DefectDojo, and CI/release dependencies can exercise sensitive authority; changing update orchestration does not justify weakening their review.

## Assumptions and Constraints

- Jenkins discovery, execution, and repository authorization are configured outside this repository; successful future Renovate runs must be verified separately.
- GitHub's dependency graph, security alerts, and Dependabot security updates are repository-level controls. Removing scheduled Dependabot YAML alone neither enables nor verifies those features.
- Preserve non-major-only Dependabot auto-merge guard for any remaining security-update PRs; do not broaden release credentials or repository workflow permissions.
- Keep the uploader CLI, DefectDojo API behavior, token handling, runtime configuration boundary, tested artifacts, and release pipeline unchanged.
- Closing superseded routine Dependabot PRs is queue cleanup, not a claim that Renovate replacements are already merged or tested.

## Alternatives Considered

1. Continue ADR-009's grouped Dependabot schedule. Rejected because it duplicates the selected central Renovate scheduler.
2. Run both scheduled systems. Rejected because parallel updates create overlapping review queues and conflicts.
3. Disable security updates alongside routine updates. Rejected because this removes an independent urgent response channel.
4. Store a second schedule/grouping policy in repository Renovate JSON. Rejected because the central configuration owns this policy and duplicating it would cause drift.

## Consequences and Verification

Routine version PRs now originate from the configured Jenkins Renovate service when it next discovers eligible versions. Existing open Dependabot version PRs can be closed after classification, while security PRs remain intact. Confirm the next Jenkins Renovate run, applicable update PRs, GitHub security-update settings, relevant CI/test evidence, and protected review gates before declaring operations fully migrated. The security and compatibility posture of a proposed dependency change remains subject to individual review.

## Related Decisions

ADR-009 is superseded for routine Dependabot scheduling and grouping only. ADR-001 governs adopted standards; ADR-002/003 govern runtime and configuration trust; ADR-004 governs reviewed release classification; ADR-005 through ADR-008 govern dependency acquisition, documentation, and release artifacts. None of those contracts is changed.
