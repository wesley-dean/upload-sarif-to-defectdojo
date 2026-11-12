# GitHub Actions Check Naming and Optional-Presence Gate Standard

## Status

Recommended engineering standard

## Purpose

This standard establishes predictable GitHub Actions check-run names and a
single, observable aggregate status for repositories that choose to use the
`matiasalbarello/wait-on-check-action-ts` GitHub Marketplace action. It is designed to
permit a new repository created from a template to have no matching checks
yet, without manufacturing a failed build, while accepting matching checks
**observed by the action** when their conclusions are `success`, `skipped`, or
`cancelled`.

The aggregation contract is intentionally weaker than a complete expected-test
inventory. A passing gate MUST NOT be represented as proof that tests ran,
that every expected check appeared, or that every workflow was enabled.

## Applicability

The check-name convention applies to GitHub Actions CI jobs in repositories
using this standard. The Marketplace aggregator and ruleset reference are for
GitHub-hosted repositories; the [General Testing Standard](testing-standard.md)
continues to govern test content and failure semantics independently.

Repositories that already have required check names MUST preserve their
effective branch protections and check identities during adoption. This
standard does not retroactively rename jobs, add required status contexts,
activate branch rulesets, or supersede repository-specific accepted ADRs.

## Check-Run Naming Convention

GitHub Checks reports **job names**, not workflow filenames or merely
workflow-level display names. Repositories using the gate SHOULD give each
eligible job a stable lowercase `jobs.<job_id>.name` matching one of these
case-sensitive patterns:

| Check family | Pattern | Valid examples |
| --- | --- | --- |
| General tests | `^test(-.+)?$` | `test`, `test-unit`, `test-bats` |
| End-to-end tests | `^(e2e|end-to-end)(-.+)?$` | `e2e`, `end-to-end-protocol` |
| Integration tests | `^integration(-.+)?$` | `integration`, `integration-db` |
| Lint and format | `^lint(-.+)?$` | `lint`, `lint-shellcheck` |
| Security analysis | `^security(-.+)?$` | `security`, `security-codeql` |
| Build validation | `^build(-.+)?$` | `build`, `build-container` |
| Compatibility | `^compat(-.+)?$` | `compat`, `compat-bash43` |

The combined pattern used by the gate is:

```regex
^(test|e2e|end-to-end|integration|lint|security|build|compat)(-.+)?$
```

It matches both an exact family name and a family name followed by a hyphen
and at least one character. For example, `test` and `test-unit` match;
`testing`, `testy-little-test`, `my-test`, and `test-` do not.

The name `test-gate` also matches this pattern and MUST be excluded from
the gate's own polling to prevent a self-dependency. A repository MAY use
different nomenclature through explicit local governance, but it MUST adapt
its regex and rule configuration accordingly rather than silently weakening
the declared selection policy.

When a matrix or reusable workflow changes the actual published check name,
the repository MUST verify the name as reported by GitHub rather than infer
it from the YAML source.

## Presence Is Optional; Accepted Conclusions Are Explicit

**No check family is mandatory solely because it is listed here.** In
particular, a newly created repository MAY have zero test, E2E,
integration, lint, security, build, or compatibility jobs and still receive
a successful aggregate result.

The required Marketplace action configuration is:

```yaml
allowed-conclusions: success,skipped,cancelled
fail-on-no-checks: 'false'
```

`fail-on-no-checks: 'false'` is a deliberate policy choice, not an exception
to be removed during template initialization. The action's upstream default
is `true`, so repositories MUST set `false` explicitly when adopting this
profile. The action's upstream default for `allowed-conclusions` accepts
`success` and `skipped`; this profile MUST explicitly configure the three
accepted conclusions as `success,skipped,cancelled`.

The resulting observational policy is:

- Zero matching check runs: the aggregate MAY succeed.
- One or more matching check runs: the action waits for the matched checks
  it observes and accepts conclusions of `success`, `skipped`, or `cancelled`.
- A matching check with a conclusion outside that explicit list, including
  `failure`, `timed_out`, `action_required`, or `neutral`, MUST NOT be accepted.
- Accepted `skipped` and `cancelled` conclusions MUST NOT be presented as
  evidence that test execution completed successfully. Cancellation can result
  from concurrency supersession or interruption; neither proves coverage.
- A check that is absent because no job was defined, a workflow was disabled,
  a job was never scheduled, the wrong revision was queried, or an expected
  run has not yet appeared is **not necessarily detected**.

This profile MUST NOT be described as requiring at least one test, proving all
tests were run, proving the repository is secure, or guaranteeing complete CI
coverage.

## Standard Aggregate Job

A GitHub Actions repository adopting this profile SHOULD maintain one
separate aggregation workflow with an actual GitHub check-run name of
`test-gate`. It SHOULD use the published Marketplace action with a fully
pinned commit SHA, the combined expression above, read-only
`checks: read` access, and a bounded job timeout.

The aggregator MUST exclude `test-gate` from its own matched checks using
`running-workflow-name: test-gate` or an independently verified equivalent.
It MUST NOT require each test workflow to run its own copy of the waiting action.

The current reference is
[`matiasalbarello/wait-on-check-action-ts`](https://github.com/matiasalbarello/wait-on-check-action-ts),
release `v1.2.0`, resolved to commit
`8087812521cdb59ebc7751984b31b17209b30eeb`. This native Node.js 24
GitHub Action uses a bundled JavaScript distribution instead of runtime Ruby
setup and Bundler installation. It paginates Checks API results across multiple
pages. Maintainers MUST review any change to the selected action revision and
its bundled/transitive JavaScript dependencies as a supply-chain change.
Pinning identifies code; it does not prove that code is trustworthy.

A non-normative [GitHub workflow example](../examples/repository/github/workflows/ci-gate.yml)
provides a concrete starting point. Copying it from an adopted standards
snapshot to `.github/workflows/` is a separate, reviewed repository change,
not part of standards adoption.

## Commit Identity and Workflow Events

The action queries checks against the configured Git ref. A workflow's event
type affects where GitHub attaches the result: for example, branch-push jobs
generally report against the branch head SHA, while pull-request-triggered
jobs may report against the synthetic PR merge SHA.

A repository MUST verify which ref contains **each check family it intends
to observe**, rather than presume that one PR head/merge SHA represents every
workflow. A single-regex action invocation over one ref may omit checks
attached to another revision. The example targets PR-head branch-push checks
and is not a universal mixed-event or fork-compatible solution.

Repositories MUST retain any separately required checks that this aggregator
does not reliably observe. Fork PRs, merge queues, status check source
identity, workflow path filters, and conditional jobs require separate local
review before asserting compatibility.

## Incomplete-Inventory and Early-Success Limits

The Marketplace action evaluates matching checks present in its API results.
It does **not** derive the expected checks from repository workflow files.

Consequently, a check that finishes early may allow the aggregator to succeed
before another intended check has been registered. If one check matches,
`fail-on-no-checks: 'false'` does not establish that any *other* expected
check exists. A disabled workflow or job renamed outside the regex might not
be noticed. These properties are not bugs in the chosen optional-presence
contract; they are limits of observable-check aggregation.

Unlike the original Ruby action, the selected TypeScript implementation does
not collapse duplicate check names to the latest run. When old and new check
runs share a name on the same ref, it can consider both, so a superseded failed
run may still fail the aggregate even after a newer run succeeds. Conversely,
its API pagination avoids a first-page-only check inventory. Repositories
SHOULD verify duplicate check, rerun, and multi-suite behavior against actual
GitHub check runs before treating the gate as a reliable merge signal.

A repository MUST NOT use this aggregate as the sole evidence of mandatory
security, release, compliance, or other fail-closed verification unless
separate controls independently establish the required coverage and trusted
check identity. Existing individually required checks MUST remain effective
until an explicit, reviewed migration establishes an equivalent or stronger
result.

## Ruleset Declaration and Activation

The [importable JSON ruleset example](../examples/repository/github/rulesets/ci-gate-main.json)
declares the exact `test-gate` status-check context for the repository's
`main` branch. GitHub rulesets name **specific** required status checks;
the regex belongs in the waiting action, not in the ruleset.

Importing JSON through GitHub settings is an explicit administrative action.
Committing the example inside `doc/standards/` does not activate it, nor
does adopting a standards release install any workflow. The example is
a **single-check ruleset fragment**, not a replacement for CODEOWNERS review,
pull-request protections, or other active policy. Its `active` enforcement
setting takes effect upon an administrator's deliberate import and creation,
so maintainers MUST inspect and adapt the branch target and existing
protections before importing it.

A repository SHOULD enable the required `test-gate` status check only after
verifying the gate executes for its intended pull requests and produces its
result on the commit identity required by branch protection. A green
`test-gate` remains the optional-presence assertion described above;
GitHub requiring that check to pass does not strengthen the meaning of the
action's observed-check selection.

## Adoption and Review Checklist

1. Inventory all existing required status contexts and their actual GitHub
   check-run names; do not rename a protected check without a migration.
2. Name eligible CI jobs using the standardized patterns where practical,
   preserving the repository's test execution and failure propagation.
3. Copy and adapt the non-normative aggregate workflow for the repository's
   actual event model, including a suitable check-ref and timeout.
4. Verify the exact action SHA, permissions, no-match success path, matching
   failure path, acceptance of `skipped` and `cancelled`, rejection of other
   conclusions, and the gate's self-exclusion.
5. Observe actual mixed-event, matrix, and rerun behavior before relying on
   the result in review automation.
6. Import and enable the reference ruleset only as a separate administrative
   decision, retaining all independently mandatory checks and CODEOWNERS gates.
7. Document any checks outside the observed ref or outside the prefix taxonomy,
   plus any repository-specific stronger completeness requirements.

## Relationship to Other Standards

The [General Testing Standard](testing-standard.md) continues to govern test
quality, required project test commands, generated artifact qualification,
failure propagation, and credential safety. The
[Development Workflow and Backlog Governance](development-workflow-governance.md)
continues to govern review readiness and auto-merge under effective human and
CI gates. This convention standardizes check naming and optional-presence
reporting without replacing those requirements.
