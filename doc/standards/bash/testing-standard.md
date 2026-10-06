# Bash Testing Standard

## Status

Recommended Bash testing standard

## Purpose

This standard refines the
[General Testing Standard](../general/testing-standard.md) for Bash-oriented
repositories and for repositories that use Bats as a black-box test driver.

Bats is implemented in Bash, but the subject under test does not need to be Bash.
A Bats suite MAY drive AWK filters, Python programs, compiled executables,
documentation generators, container entry points, or any other subject that can
be invoked through observable process or filesystem boundaries.

The goal is to standardize the useful parts of Bats without coupling test design
to the implementation language of the software under test.

## Applicability

This standard applies when a repository uses Bats for automated behavioral tests.

For maintained Bash programs, these rules supplement the general testing
standard.  For non-Bash programs driven by Bats, only the Bats-specific driver,
reporting, and shell-boundary guidance applies; the implementation language's own
standards continue to govern the subject under test.

Repository-specific ADRs MAY preserve a different test framework or reporting
contract when that decision remains appropriate.

## Bats Version Compatibility

A repository using Bats SHOULD declare, pin, or otherwise verify a version that
supports the framework features its suite relies on.

This standard does not mandate one global Bats version.  Repositories using
features such as `bats_test_function`, expected-status forms of `run`, console
and report formatters, or other version-sensitive behavior SHOULD ensure that
local development and CI resolve a compatible version.

A suite SHOULD fail clearly when a required framework capability is unavailable
rather than silently degrade to different reporting or execution semantics.

## Bats as a Black-Box Driver

Bats SHOULD be considered a process-oriented test driver rather than a Bash-only
unit-test framework.

It is appropriate when the subject exposes observable behavior through one or
more of:

- exit status;
- stdout;
- stderr;
- argv passed to external commands;
- generated files;
- filesystem effects;
- serialized output;
- archive contents;
- documentation output; or
- another command-line-accessible interface.

A repository SHOULD NOT reject Bats merely because the implementation under test
is AWK, Python, JavaScript, a compiled language, Doxygen, or another non-Bash
tool.

The choice should depend on whether Bats provides a clear and maintainable driver
for the observable contract.

## Canonical Repository Entry Point

Where Make is the repository orchestration boundary, CI SHOULD invoke
`make test` rather than call Bats directly.

The Makefile remains responsible for preparing generated artifacts, choosing
required suites or representations, establishing environment variables that
select the subject under test, invoking Bats with repository-standard formatters,
and preserving aggregate pass/fail status.

Bats remains responsible for test registration, execution, assertion failures,
test names, and result serialization.

## TAP Is the Primary Console Format

Bats-based repositories SHOULD use TAP as the canonical terminal and CI log
format unless repository-specific governance explicitly establishes another
format.

A representative invocation is:

```bash
bats --formatter tap tests
```

TAP provides a stable developer-facing and automation-readable stream.

A CI integration that prefers JUnit MUST NOT by itself require replacement of
the established TAP console contract.

## JUnit Is Derivative Reporting Output

When structured CI reporting is desired, Bats SHOULD emit JUnit XML from the same
test execution that emits TAP.

A representative invocation is:

```bash
bats \
  --formatter tap \
  --report-formatter junit \
  --output "test-results/<suite-or-artifact>" \
  tests
```

The suite SHOULD NOT normally be run once for TAP and again for JUnit.  Two runs
cost more and can describe different executions.

JUnit XML is derivative reporting state.  TAP remains the canonical console
stream.

## Generated Report Layout

When a repository runs the same suite against multiple artifacts or
representations, each execution SHOULD have an unambiguous report directory.

For example:

```text
test-results/
├── source/report.xml
├── development/report.xml
├── ordinary/report.xml
└── minified/report.xml
```

The `test-results/` directory is governed by the generated-report rules in the
general testing standard: it is ignored, disposable, cleaned, and excluded from
broad linting and scanning.

## Prefer Framework Registration Over Hand-Rolled TAP

A repository using Bats SHOULD let Bats own:

- test numbering;
- TAP serialization;
- failure bookkeeping;
- test names;
- assertion failure propagation;
- per-test isolation; and
- JUnit report generation.

A bespoke shell harness SHOULD NOT continue to implement those responsibilities
merely because it historically emitted valid TAP.

Existing fixture comparison, normalization, or domain-specific helper functions
MAY remain when they still express useful project behavior.

Migrating to Bats need not mean rewriting the testing model.  It may mean
replacing only the test driver while preserving fixtures, golden outputs,
diagnostic expectations, and integration semantics.

## Dynamic Test Registration

Bats supports dynamic test registration through `bats_test_function`.

Repositories with fixture matrices, artifact matrices, or data-driven cases
SHOULD consider dynamic registration rather than duplicating hand-written
`@test` blocks.

Conceptually:

```bash
check_fixture() {
  local label=$1
  local executable=$2
  local fixture=$3

  # Exercise the selected subject and assert the fixture contract.
}

for fixture in "${fixtures[@]}"; do
  bats_test_function \
    --description "source output: ${fixture}" \
    -- check_fixture source ./tool "${fixture}"
done
```

Each matrix element becomes a first-class Bats test and therefore a first-class
TAP/JUnit test result.

Dynamic registration is particularly useful when one observable behavior suite
must exercise several equivalent distribution artifacts.

## Artifact-Agnostic Suites

When the same behavioral suite targets several executables or artifacts, the
subject under test SHOULD be selected through one explicit injection boundary.

An environment variable is often sufficient:

```bash
TOOL_UNDER_TEST=./dist/tool.min.bash bats tests
```

The exact variable name is repository-specific.

The test body SHOULD consume that selection rather than duplicate test files for
each artifact.

When artifact selection is better represented through dynamically registered
arguments, `bats_test_function` MAY be used instead.

## The run Helper and Process Contracts

Bats' `run` helper SHOULD be preferred when a test needs to observe command
execution without causing the test body to terminate immediately on the command's
status.

Tests SHOULD assert `status` intentionally.  When relevant, they SHOULD also
assert `output`, individual output lines, generated files, or captured stderr
according to the repository's Bats version and invocation pattern.

Expected failure is test data, not a failing test harness.

For example:

```bash
run -1 ./tool --invalid-input

[ "$status" -eq 1 ]
[[ "$output" == *"invalid input"* ]]
```

## PATH-Injected Fakes

For command-line software whose external boundaries are ordinary executables,
PATH-injected fakes are a preferred technique when they provide a small,
deterministic boundary.

A fake executable SHOULD normally do only what the test requires, such as:

- record argv exactly;
- write controlled stdout;
- write controlled stderr;
- create a small fixture;
- return a selected exit status; or
- expose whether it was invoked.

A fake SSH client should not become a RouterOS emulator.  A fake `curl` should
not become an HTTP server unless the behavior under test genuinely requires that
level of integration.

## Argument Preservation

Tests that protect shell command construction SHOULD inspect argv boundaries
rather than compare reconstructed command strings whenever practical.

This is especially important for paths containing spaces, option values
containing shell metacharacters, empty arguments, arrays, repeated flags, and
values that would be unsafe if re-parsed through `eval` or a shell.

The goal is to prove that one logical argument remains one argv element.

## Golden Files and Diagnostics

Bats MAY drive fixture-to-golden comparisons when exact textual output is an
owned observable contract.

Helpers that normalize unstable prefixes, paths, timestamps, or equivalent
incidental data MAY be retained when the normalization itself is explicit and
reviewable.

Diagnostic tests SHOULD verify both the process status and the normalized
diagnostic contract when both are meaningful.

A migration from a shell harness to Bats SHOULD preserve small,
behavior-focused fixtures rather than replacing them with large opaque snapshots.

## Bats Driving Non-Bash Subjects

A Bats suite MAY invoke a non-Bash subject directly.

Examples include:

```bash
run awk -f ./filter.awk -- --strict ./fixture.bash
run python3 ./tool.py --check ./fixture
run ./dist/tool --version
run doxygen ./tests/Doxyfile
```

Bats is the driver in these examples.  It does not change the implementation
language, portability contract, lint rules, documentation standard, or release
requirements of the subject under test.

This separation permits one behavioral-test vocabulary and one TAP/JUnit
reporting path across several implementation languages.

## Integration and Semantic Tests

Bats MAY drive integration tools such as Doxygen when the integration can be
expressed through deterministic local inputs and observable generated outputs.

For example, a documentation-filter project can generate intermediate output from
a fixture, run Doxygen against a focused configuration, inspect generated XML for
stable semantic content, and register each semantic expectation as a named Bats
test.

Tests SHOULD assert stable semantics rather than snapshot complete generated HTML
or other presentation-heavy output unless presentation itself is the contract.

External tool availability MAY remain a distinct environment prerequisite.
Repositories MAY keep integration targets separate from the ordinary local suite
when that separation improves portability or developer feedback.

## Complete Matrix Execution

When one `make test` invocation covers several equivalent artifacts, the
orchestration SHOULD attempt all independent artifact suites where practical and
return an aggregate nonzero status if any fail.

Bats dynamic registration can often express the artifact/fixture matrix in one
suite.  Separate Bats executions are also acceptable when the repository needs
separate report files or materially different setup.

If separate executions are used, Make orchestration MUST preserve failure status
while continuing useful independent runs.

## Dependency Tradeoff

Bats is an additional test dependency.  That cost SHOULD be justified by the
testing value it provides.

Adoption is particularly reasonable when it replaces home-grown machinery for
TAP numbering, assertion bookkeeping, failure accumulation, parameterized test
registration, or structured report generation.

A repository with a small stable harness MAY retain it when Bats would add
dependency cost without reducing complexity or increasing evidence quality.

The decision should compare the maintained test system against the framework
benefits rather than assume either "frameworks are always better" or "no
dependency is always better."

## CI Publication

The general testing standard governs generated `test-results/`, MegaLinter
exclusion, structured result publication, and the separation between read-only
pull-request execution and privileged result publication.

Bats/JUnit repositories SHOULD use that model rather than grant write permissions
to the job executing pull-request code merely to publish test metadata.

## Review Checklist

Before merging a Bats-based testing change, verify as applicable:

- [ ] The repository's canonical test entry point remains authoritative.
- [ ] TAP remains the intended console format unless local governance says otherwise.
- [ ] JUnit, when enabled, is generated from the same execution.
- [ ] `test-results/` remains ignored derivative state.
- [ ] MegaLinter or equivalent broad scanners exclude generated reports.
- [ ] Bats owns test registration and serialization instead of duplicate harness code.
- [ ] Fixture and golden-file behavior remains small and inspectable.
- [ ] Equivalent artifacts share one behavioral suite where practical.
- [ ] Dynamic registration is used when it materially reduces matrix duplication.
- [ ] The subject under test is selected through an explicit boundary.
- [ ] PATH fakes preserve argv and remain intentionally small.
- [ ] Expected command failure is asserted rather than confused with harness failure.
- [ ] Non-Bash subjects remain governed by their own implementation-language standards.
- [ ] CI publication does not grant write authority to code-executing PR jobs.

## Governing Principle

Use Bats when it provides a clearer behavioral-test driver, not merely because the
repository contains Bash.  Keep TAP human- and automation-readable, derive JUnit
without a second execution, preserve observable fixture contracts, and let the
same black-box testing vocabulary apply to any command-line subject that Bats can
exercise cleanly.

See the non-normative
[dynamic Bats example](../examples/bash/testing/example.bats) for one compact
artifact-matrix pattern.
