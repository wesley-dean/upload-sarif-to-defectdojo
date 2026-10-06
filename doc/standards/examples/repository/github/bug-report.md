---
name: Bug report
about: Report reproducible incorrect behavior
title: ""
labels: bug
assignees: ""
---

## Observed Behavior

Running `make dist-check` succeeds even when a stale file remains in the
temporary extraction directory from a previous run.

## Expected Behavior

Each verification run should begin from an empty temporary directory so the
result reflects only the current source tree.

## Steps to Reproduce

1. Run `make dist-check`.
2. Interrupt the command after the first archive is extracted.
3. Add an unrelated file beneath the retained temporary directory.
4. Run the verification again while reusing that directory.
5. Observe that the stale file is not detected.

## Environment

- Project version: v2.4.0
- Operating system: Ubuntu 26.04 LTS
- Runtime / shell: GNU Make 4.4.1, Bash 5.3
- Other relevant versions: GNU tar 1.35

## Impact

The deterministic-build check can report success even when its temporary state is
not clean, reducing confidence in release verification.

## Regression Information

The behavior is present in v2.4.0.  The last known working version is unknown.

## Workaround

Remove the temporary verification directory before rerunning `make dist-check`.

## Additional Context

The release artifact itself is not known to be malformed; the problem is limited
to the verification path.
