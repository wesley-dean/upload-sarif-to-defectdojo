---
name: General issue
about: Capture work that does not fit a specialized issue type
title: ""
labels: ""
assignees: ""
---

## Context

The repository has several generated documentation artifacts, but no single
document explains which are committed, which are disposable, and which are release
outputs.

## Desired Outcome

Document the lifecycle and source-of-truth rules for generated documentation
artifacts.

## Constraints

The change should document existing behavior only.  Changes to build output or
release packaging belong in separate issues.

## References

- `Makefile`
- `doc/adr/README.md`
- the repository's testing standard

## Completion Criteria

- [ ] Every generated documentation artifact is classified.
- [ ] Source-of-truth relationships are documented.
- [ ] Disposable build output is distinguished from committed material.
- [ ] No build behavior changes are introduced.
