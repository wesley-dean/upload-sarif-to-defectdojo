# General Testing Standard

## Status

Recommended engineering standard

## Purpose

This standard defines reusable expectations for automated testing across
repositories, languages, frameworks, and build systems.  Tests are executable
evidence about observable software contracts, not merely framework-specific
implementation details.

The goals are to make tests deterministic, reviewable, automation-friendly,
representative of shipped behavior, useful during failure, and safe to integrate
with continuous-integration systems.

## Applicability

This standard applies to repositories that maintain automated tests.

Language- or framework-specific testing standards MAY refine these rules.
The [Bash Testing Standard](../bash/testing-standard.md) defines Bats-specific
practice when that framework is used.  Repository-specific ADRs or explicit
policy MAY also refine these rules, but deviations MUST be visible governance
rather than silent exceptions.

Not every repository requires every category of test described here.  The
appropriate test surface follows the software's risks, public contracts,
deployment model, and distribution forms.

## Canonical Test Entry Point

A repository SHOULD expose one documented repository-level command that means
"run the required project test suite."

When Make is already the repository orchestration interface, the canonical entry
point SHOULD normally be:

```bash
make test
```

CI SHOULD invoke the same repository-level entry point rather than duplicate
framework-specific commands in workflow YAML.

A canonical test command SHOULD:

- return zero only when all required tests represented by that command pass;
- return nonzero when any required test represented by that command fails;
- run without interactive input;
- avoid interactive-terminal assumptions;
- be suitable for unattended CI execution; and
- preserve the same pass/fail semantics whether or not structured reporting is
  enabled.

Repositories MAY expose narrower targets such as `test-unit`,
`test-integration`, `test-source`, or `test-dist` when those boundaries are
meaningful.  Their relationship to the canonical test target SHOULD be
documented.

## Determinism and Repeatability

Given the same source, dependencies, inputs, and controlled environment,
repeated test runs SHOULD produce the same pass/fail result.

Tests SHOULD avoid uncontrolled dependencies on:

- wall-clock time;
- unseeded randomness;
- filesystem enumeration order;
- locale or timezone unless explicitly under test;
- mutable remote services;
- network availability;
- ambient credentials;
- shared machine state; or
- incidental execution order.

When nondeterminism is part of the behavior under test, tests SHOULD control it
through injected clocks, seeded randomness, isolated fixtures, fakes, or an
equivalent explicit boundary.

## Isolation from Live Infrastructure

Unit and characterization tests SHOULD NOT require live infrastructure by
default.

External boundaries such as HTTP APIs, SSH, cloud services, databases,
registries, package repositories, Git hosting, routers, or other networked
systems SHOULD normally be represented by deterministic fakes, stubs, fixtures,
or controlled test doubles when the purpose of the test is local behavior.

Tests that intentionally depend on live infrastructure SHOULD be identifiable as
integration, system, end-to-end, or acceptance tests and SHOULD be separately
invokable when practical.

A test suite MUST NOT silently depend on production credentials or production
systems.

## Test Observable Contracts

Tests SHOULD primarily assert behavior visible at meaningful boundaries, such as:

- process exit status;
- stdout;
- stderr;
- command arguments;
- generated files;
- serialized output;
- persisted state;
- API responses;
- filesystem effects; and
- externally visible cleanup behavior.

Private implementation details SHOULD NOT become the primary assertion surface
when the same contract can be verified through observable behavior.

Refactoring an internal helper SHOULD NOT ordinarily require broad test rewrites
when externally visible behavior remains unchanged.

## Command-Line Exit Status and Output

For command-line software, exit status is part of the public behavioral contract
and SHOULD be tested intentionally.

Failure-path tests SHOULD assert the expected exit status.  When stdout or stderr
is also part of the contract, tests SHOULD verify the relevant stream or
diagnostic content.

Tests SHOULD distinguish between an expected command failure, a test assertion
failure, a prerequisite failure, and a test environment that is too broken to
continue meaningfully.

## Successful and Unsuccessful Paths

Meaningful operations SHOULD normally receive coverage beyond the happy path.

Relevant cases MAY include:

- successful execution;
- invalid or malformed input;
- missing prerequisites;
- external-command failure;
- partial failure;
- cleanup failure;
- configuration precedence;
- boundary values;
- simultaneous failures; and
- precedence among cascading failures.

This standard does not prescribe a fixed number of tests per operation.  Coverage
SHOULD follow risk and observable behavior.

## Public Artifact Equivalence

When a repository distributes multiple representations that claim behavioral
equivalence, the same behavioral suite SHOULD exercise each relevant
representation where practical.

Examples include:

```text
maintained source
compatibility artifact
development artifact
ordinary distribution artifact
minified artifact
packaged executable
container entry point
```

Passing tests against maintained source alone does not prove that transformation,
minification, packaging, or distribution preserved behavior.

When artifact selection can be parameterized cleanly, one shared suite SHOULD be
preferred over duplicated test files.

## Validate Generated Deliverables

A successful generator or build command proves only that generation completed.
Generated deliverables SHOULD be validated directly when they form part of the
public contract.

Appropriate checks MAY include:

- executing generated programs;
- syntax-checking generated source;
- inspecting archive contents;
- validating checksums;
- verifying expected file sets;
- checking metadata or provenance; and
- running the same behavioral suite against generated representations.

Large generated artifacts SHOULD NOT become golden maintained source merely to
prove that generation occurred when narrower behavioral assertions are
sufficient.

## Working-Tree Cleanliness

Test execution MUST NOT silently mutate maintained repository source.

Generated test state SHOULD be written beneath ignored derivative directories or
removed predictably by cleanup targets.

CI MAY use `git diff`, `git status --short`, targeted ignore checks, or
equivalent verification when working-tree cleanliness is part of the repository
contract.

## Complete Failure Reporting

When a test target covers multiple independent artifacts, environments, suites,
or implementations, it SHOULD attempt all useful independent surfaces even when
an earlier surface fails, when doing so is safe and practical.

The aggregate command MUST still return nonzero when any required surface fails.

The desired model is:

```text
execute useful independent suites
            |
            v
collect complete results
            |
            v
publish reporting artifacts
            |
            v
preserve aggregate failure status
```

Reporting MUST NOT convert a failing test gate into success.

## Flaky Tests

A test whose result changes without a corresponding source, dependency, input, or
controlled environment change SHOULD be treated as defective until the source of
nondeterminism is understood.

Retries MAY be used diagnostically or as a temporary containment measure.
Permanent automatic retries SHOULD NOT become the default remedy for recurring
flakiness.

The preferred outcome is restoration of deterministic behavior in the test, the
implementation, or the controlled environment.

## Test Independence

Tests SHOULD NOT normally depend on another test having executed first or on a
specific incidental ordering.

Where the framework supports it reasonably, tests SHOULD tolerate isolated,
reordered, and repeated execution.

Shared setup is acceptable when it establishes explicit controlled fixtures
rather than hidden inter-test dependencies.

## Fixtures and Temporary State

Tests SHOULD use framework-provided or securely created temporary locations where
practical.

Tests SHOULD avoid casually writing into persistent shared locations such as:

```text
$HOME
/tmp/<fixed-name>
repository root
system configuration directories
```

unless the behavior under test requires that location and the test establishes
appropriate isolation and cleanup.

Fixtures SHOULD remain small enough to inspect directly when practical.

Golden files are appropriate when exact textual or serialized output is an owned
observable contract.  Golden files SHOULD represent owned behavior rather than
incidental formatting from an external dependency.

## Test Doubles

A fake, stub, mock, or other test double SHOULD model the minimum interface
required by the subject under test.

A test double SHOULD NOT grow into an unnecessary reimplementation of the remote
system it represents.

For process boundaries, a useful fake often needs only to record argv, expose
controlled stdout or stderr, create or inspect a small fixture, and return a
controlled exit status.

The purpose is to test the subject's behavior at the boundary, not the realism of
the fake.

## Security-Sensitive Boundaries

Security-sensitive transformation and input boundaries SHOULD receive explicit
regression coverage when they are part of the software's risk model.

Relevant cases MAY include:

- shell metacharacters;
- whitespace in paths;
- path traversal;
- command-injection attempts;
- malformed URLs;
- unsafe environment values;
- unexpected Unicode;
- serialization boundaries; and
- values interpolated into another command language.

Security tests SHOULD verify observable behavior at the boundary rather than rely
only on internal helper assertions.

## Regression Tests for Defects

When practical, a defect fix SHOULD add or refine a test that fails under the
previous behavior and passes under the corrected behavior.

Test names SHOULD describe the enduring contract rather than depend solely on the
historical issue number.

For example:

```text
SSH private key path with spaces remains one argv element
```

is more durable than:

```text
regression for issue 117
```

Issue references MAY still appear in comments, commit history, or supporting
documentation.

## Coverage Metrics

Coverage is diagnostic information, not proof of correctness.

This standard does not establish a universal minimum line-, branch-, or
statement-coverage percentage.

Coverage tools MAY locate unexercised behavior and guide review.  Arbitrary
percentages MUST NOT substitute for risk-based test design, boundary analysis,
meaningful assertions, or evidence that public behavior is protected.

Repository-specific governance MAY establish quantitative thresholds when a
clear project-specific reason exists.

## Test Categories

Repositories MAY distinguish categories such as:

```text
unit
characterization
integration
system / end-to-end
acceptance
```

Not every repository requires every category.

Expensive, privileged, destructive, or externally dependent tests SHOULD NOT
masquerade as ordinary local tests.  Their prerequisites and invocation boundary
SHOULD be explicit.

## Test Code Is Maintained Code

Test source is maintained source.

Applicable coding, documentation, formatting, reviewability, and maintainability
standards SHOULD apply to test code just as they apply to runtime code, subject to
reasonable test-specific conventions.

Tests SHOULD remain understandable enough that a reviewer can identify what
behavior is protected, why the assertion matters, which boundary is being
exercised, and what a failure means.

## Structured Test Reports

Repositories MAY generate structured reports in addition to their normal
developer-facing output.

JUnit XML is a common interoperable format and SHOULD be treated as derivative
reporting state unless repository-specific governance establishes otherwise.

When structured reports are generated, the conventional repository-relative
location SHOULD be:

```text
test-results/
```

The directory SHOULD:

- be listed in `.gitignore`;
- be removed by the appropriate cleanup target;
- remain uncommitted;
- be regenerated from canonical test execution; and
- be excluded explicitly from broad linting or scanning tools that would
  otherwise treat generated reports as maintained source.

When MegaLinter is used, `test-results/` SHOULD be included in
`ADDITIONAL_EXCLUDED_DIRECTORIES` and SHOULD also be covered by any repository
global exclusion expression that would otherwise match generated reports.

Ignoring generated `test-results/` MUST NOT be interpreted as a reason to
ignore maintained `tests/` source.

## CI Test Result Publication

CI systems SHOULD publish structured test results when publication materially
improves reviewability.

Useful surfaces MAY include stable test-result checks, failure annotations, job
summaries, and updated durable pull-request comments.

Publication is a reporting concern.  The validation workflow remains
authoritative for test pass/fail status.

This standard does not require a specific CI provider or publishing action.

## CI Trust Boundary

A workflow that executes pull-request code SHOULD remain read-only whenever
practical.

If publishing checks, comments, or other review metadata requires write
permissions, privileged publication SHOULD be separated from execution of
potentially untrusted code.

A preferred GitHub Actions shape is:

```text
read-only validation workflow
  |
  +-- execute repository / pull-request code
  +-- run tests
  +-- emit structured reports
  +-- upload report artifact
          |
          v
privileged workflow_run publisher
  |
  +-- download report artifact
  +-- consume trusted source-event metadata
  +-- do not check out or execute pull-request code
  +-- checks: write
  +-- pull-requests: write
  +-- publish durable review feedback
```

When source event metadata is required by the privileged publisher, that metadata
SHOULD be preserved by a no-checkout job that does not execute repository or
pull-request code.  Untrusted code SHOULD NOT be allowed to rewrite metadata used
to associate privileged publication with a pull request.

Fork and dependency-update pull requests SHOULD be considered explicitly when
designing this boundary.

## Guidance That Is Not Universal

Unless repository-specific governance says otherwise, this standard does not
require:

- a fixed coverage percentage;
- mandatory mocking;
- a prescribed testing pyramid;
- a particular assertion library;
- a specific CI provider;
- a particular JUnit publishing action;
- every possible testing category; or
- a fixed ratio of test code to production code.

Prefer observable contracts, risk-based reasoning, deterministic evidence, and
maintainable tests over cargo-cult metrics.

## Review Checklist

Before merging a material testing change, verify as applicable:

- [ ] The repository has a clear canonical test entry point.
- [ ] CI invokes repository-owned test orchestration rather than duplicating it.
- [ ] Tests are deterministic or explicitly control necessary nondeterminism.
- [ ] Ordinary local tests do not silently require live production infrastructure.
- [ ] Assertions primarily protect observable behavior.
- [ ] Command-line exit statuses and relevant output streams are tested.
- [ ] Important failure paths receive coverage.
- [ ] Equivalent public artifacts share equivalent behavioral coverage.
- [ ] Generated deliverables are exercised directly where they form part of the contract.
- [ ] Test execution leaves maintained source unchanged.
- [ ] Multi-surface failures preserve aggregate nonzero status.
- [ ] Flakiness is treated as a defect rather than normalized permanently.
- [ ] Tests are independent and use isolated temporary state.
- [ ] Test doubles remain smaller than the systems they represent.
- [ ] Security-sensitive boundaries receive appropriate regression coverage.
- [ ] Defect fixes include durable regression tests when practical.
- [ ] Coverage metrics supplement rather than replace reasoning.
- [ ] Generated structured reports are ignored derivative state.
- [ ] Broad linters and scanners exclude generated reports.
- [ ] CI reporting does not weaken the validation result.
- [ ] Privileged publication is separated from untrusted code execution.

## Governing Principle

Tests are executable evidence about software contracts.  Keep that evidence
deterministic, behavior-focused, representative of what users receive,
inspectable during failure, and independent from the mechanics used to publish
the results.
