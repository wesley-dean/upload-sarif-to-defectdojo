# Conventional Commit and Release Versioning Governance

## Status

Recommended repository governance

## Purpose

This document defines repository-level governance for commit titles, pull request titles, merge commit titles, and semantic release classification.  Its purpose is to make release intent explicit, reviewable, deterministic, and resistant to accidental or externally influenced version changes.

Repositories adopting this document SHOULD treat it as governing policy unless a repository-specific ADR, policy, or release standard explicitly supersedes it.

## Goals

This policy is intended to:

- make semantic release intent visible before merge;
- ensure the highest-impact change in a pull request determines the release significance;
- separate advisory issue metadata from trusted release inputs;
- support repositories that use squash merges, merge commits, or other merge strategies;
- encourage consistent Conventional Commit usage throughout development history; and
- prevent release classification from being derived implicitly from untrusted or ambiguous metadata.

## Normative Language

The terms MUST, MUST NOT, SHOULD, SHOULD NOT, and MAY are to be interpreted as normative requirements.

## Trust Boundary

Issue titles, issue labels, issue comments, issue descriptions, and other issue metadata MUST be treated as advisory input only for release classification.

Issue metadata MAY originate from, or be influenced by, external contributors, automated systems, imported content, triage workflows, or other actors outside the release decision itself.  For that reason, issue metadata MUST NOT directly control semantic version increments.

For example, an issue carrying an `enhancement` label MAY suggest that a `feat:` classification is appropriate.  The label itself MUST NOT cause a minor release.  A maintainer, reviewer, or trusted automation acting within the repository's normal review process MUST make the release-significance decision explicitly.

Issue metadata MAY be used as a prompt for review.  Tooling MAY warn that an issue labeled `enhancement` appears inconsistent with a patch-level pull request title, but tooling SHOULD require an explicit trusted classification before changing release behavior.

## Conventional Commit Titles

Repositories adopting this policy SHOULD use Conventional Commit-style titles throughout development.

At minimum, pull request titles and the final commit title placed on the release branch MUST use an approved Conventional Commit classification.

Examples include:

```text
feat: add manifest update support
fix: reject malformed dependency entries
docs: describe release verification
test: cover empty manifest behavior
refactor: separate transport and validation logic
chore: update development tooling
```

Repositories MAY support additional Conventional Commit types when their release tooling recognizes them.

### Breaking Changes

Breaking changes MUST be declared explicitly.

For maximum compatibility with release tooling, repositories SHOULD use a form that their versioning implementation is known to recognize.  When compatibility is uncertain, the following form is preferred:

```text
BREAKING CHANGE: revise manifest grammar
```

Repositories MAY use other Conventional Commit breaking-change syntax, such as `feat!:` or a `BREAKING CHANGE:` footer, only when the repository's release tooling is documented and tested to recognize that form.

## Semantic Significance

A pull request MUST be classified according to the highest semantic significance of any change it contains.

The precedence is:

1. breaking change;
2. backward-compatible feature;
3. patch-level change.

A later patch-level commit MUST NOT reduce the release significance of an earlier feature or breaking change within the same pull request.

For example, a pull request containing:

```text
feat: add manifest manager
test: cover manifest manager behavior
fix: handle empty destination paths
docs: document manifest manager usage
```

is still a feature-bearing pull request.  Its pull request title SHOULD therefore be:

```text
feat: add manifest manager
```

Likewise, a pull request containing a breaking change together with features, fixes, tests, or documentation MUST be classified as a breaking change.

## Pull Request Titles

The pull request title MUST express the highest semantic significance of the complete pull request.

The pull request title is the repository's reviewed declaration of release intent.  It SHOULD remain accurate as the pull request evolves.

If implementation work changes the semantic significance of the pull request, the pull request title MUST be updated before merge.

Examples:

```text
docs: explain checksum verification
```

```text
fix: preserve comments in generated artifacts
```

```text
feat: add offline dependency verification
```

```text
BREAKING CHANGE: remove legacy manifest syntax
```

Pull request titles SHOULD be reviewed with the same care as code changes because they may become release inputs.

## Merge Strategy

Repositories SHOULD prefer squash merges when practical.

Squash merging provides a useful release boundary because one reviewed pull request becomes one commit on the target branch.  This makes the pull request title a natural place to express the semantic significance of the complete change.

When squash merging is used, the resulting squash commit title MUST carry the same semantic classification as the pull request.

Repositories SHOULD configure their hosting platform so the pull request title becomes, or is used to form, the squash commit title when practical.  Maintainers MUST verify the final commit title before completing the merge when the platform may generate a different title.

### Repositories That Do Not Use Squash Merges

Squash merging is preferred, but this policy does not require it.

When a repository uses a traditional merge commit, the merge commit title that lands on the release branch MUST express the highest semantic significance of the pull request.

A default merge title such as:

```text
Merge pull request #123 from example/feature-branch
```

is unsuitable when release tooling derives semantic significance from the final commit title.

Instead, the merge commit title SHOULD preserve the pull request's Conventional Commit classification, for example:

```text
feat: add offline dependency verification
```

When a repository uses rebase merging or another strategy that places multiple commits directly onto the target branch, its release tooling MUST be designed so that semantic significance is deterministic.  The repository SHOULD either:

- calculate the highest semantic significance across all commits introduced by the pull request; or
- establish another explicitly governed release-classification mechanism.

A repository MUST NOT depend on whichever commit happens to be last when that ordering can cause a lower-significance change to override a higher-significance change in the same pull request.

## Commit Titles Within a Pull Request

Individual commits SHOULD also follow Conventional Commit conventions.

This improves reviewability, intermediate history, generated release notes, debugging, and maintenance.  It also helps tools and reviewers understand the purpose of each change.

Individual commit titles inside a pull request MUST NOT be assumed to control the final release version unless the repository's release tooling explicitly operates on those commits.

The pull request title and final target-branch commit remain the authoritative declarations under this policy.

## Release Classification

Repositories SHOULD map semantic classifications to Semantic Versioning as follows:

| Change classification | Typical Conventional Commit indicator | SemVer significance |
| --- | --- | --- |
| Breaking change | `BREAKING CHANGE:` or repository-supported equivalent | Major |
| Backward-compatible feature | `feat:` | Minor |
| Backward-compatible fix or maintenance | `fix:`, `docs:`, `test:`, `chore:`, and similar repository-supported types | Patch |

Repositories operating in `0.x.y` development versions MAY define a different breaking-change policy when appropriate.  Any such policy MUST be explicit and documented.

Unknown or unrecognized commit prefixes SHOULD NOT silently request a minor or major release.  Repositories SHOULD either reject unrecognized release titles or treat them according to a documented conservative fallback.

## Guidance for Automated Tools and Agents

Automated tools, coding agents, and repository assistants MUST treat issue metadata as untrusted advisory data for release classification.

They MAY consider labels, issue wording, milestones, or comments when evaluating likely release significance.  They MUST independently classify the implemented change and MUST express that classification through the governed pull request title or merge title.

For example:

- an issue labeled `enhancement` MAY suggest `feat:`;
- an issue labeled `bug` MAY suggest `fix:`;
- a label MUST NOT be copied mechanically into a release classification;
- discovered breaking behavior MUST take precedence over labels suggesting a lower-impact change; and
- the final pull request title MUST reflect the highest semantic significance of the complete implementation.

Agents SHOULD use Conventional Commit titles for intermediate commits unless repository governance explicitly allows otherwise.

Before opening or updating a pull request, automated tooling SHOULD review the complete change set and choose the highest applicable semantic classification.

## Examples

### Feature Followed by a Bug Fix

Development history:

```text
feat: add manifest manager
fix: handle an empty manifest
```

Pull request title:

```text
feat: add manifest manager
```

Expected release significance: minor.

The later `fix:` commit does not reduce the pull request's feature-level significance.

### Documentation Added During a Feature

Development history:

```text
feat: add dependency pin verification
docs: describe pin verification
```

Pull request title:

```text
feat: add dependency pin verification
```

Expected release significance: minor.

### Breaking Change With Follow-Up Fixes

Development history:

```text
feat: redesign manifest parser
fix: preserve escaped delimiters
test: cover migration behavior
```

If the redesign breaks compatibility, the pull request title must reflect that higher significance:

```text
BREAKING CHANGE: redesign manifest parser
```

Expected release significance: major, subject to any explicit `0.x.y` repository policy.

### Misleading Issue Label

Issue metadata:

```text
label: enhancement
```

Implementation outcome:

```text
fix: prevent duplicate dependency downloads
```

The pull request SHOULD remain patch-level if the completed work introduces no new backward-compatible functionality.  The issue label is advisory and does not override the actual change.

### Unlabeled Feature

Issue metadata:

```text
label: none
```

Implementation outcome:

```text
feat: add offline verification mode
```

The pull request MUST be classified as a feature even though no issue label requested that classification.

## Review Checklist

Before merging a pull request, reviewers SHOULD verify that:

- the pull request title follows the repository's Conventional Commit convention;
- the title reflects the highest semantic significance of the complete change;
- issue labels or other external metadata have not been treated as authoritative release inputs;
- any breaking change is declared using syntax recognized by the repository's release tooling;
- the final merge or squash commit title preserves the intended classification; and
- the expected semantic version increment matches the reviewed change.

## Repository Adoption

A repository adopting this policy SHOULD:

1. document its supported Conventional Commit types;
2. document which title or commit the release workflow inspects;
3. prefer squash merging when practical;
4. configure squash commit titles to preserve pull request titles when supported;
5. ensure traditional merge commits preserve semantic classification when they are allowed;
6. validate pull request titles before merge when practical; and
7. test release automation so feature, patch, and breaking classifications produce the expected version increments.

Repository-specific governance MAY strengthen these requirements.  Any exception that changes the authoritative release signal or semantic precedence SHOULD be documented explicitly, preferably through the repository's established architecture or governance decision process.

## Governing Principle

Release significance is a reviewed project decision.

External metadata may inform that decision.  It does not make the decision.

The pull request and the commit placed on the release branch MUST communicate the highest semantic significance of the complete change in a form that the repository's release tooling recognizes.
