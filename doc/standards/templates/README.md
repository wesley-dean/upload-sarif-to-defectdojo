# Reusable Templates

## Purpose

This directory contains reusable reference templates for recurring engineering,
repository, and governance artifacts.

Templates are non-normative.  Governing standards define requirements; templates
provide a recommended structure for applying or communicating those requirements.

## Relationship to Standards and Examples

The standards library distinguishes:

- **standards**, which define governing requirements;
- **templates**, which provide recommended structures; and
- **examples**, which show realistic completed applications.

If a template or example conflicts with a governing standard, the standard is
authoritative and the template or example should be corrected.

## Format

Templates are maintained as Markdown files.

Completion guidance is embedded in HTML comments so it is visible while editing
but omitted from rendered Markdown:

```markdown
<!-- Describe what belongs in this section and whether it may be omitted. -->
```

Visible Markdown outside the comments represents the structure intended to remain
in the completed artifact.

## Template Families

The initial corpus contains:

- `repository/github/` for pull-request and issue templates;
- `general/security/` for security and STRIDE disclosure;
- `adr/` for Architecture Decision Records; and
- `git/` for Conventional Commit and merge-message references.

Additional families may be added as reusable structures become sufficiently
established.

## Source Material

Existing repository-local templates may be used as source material when designing
reusable references.  The reusable template should generalize the useful
structure without requiring the source repository's active template to change.

## Adoption

These templates are distributed inside the complete coding-standards release and
materialize beneath the managed standards destination, normally:

```text
doc/standards/templates/
```

Receiving a template does not activate it.

Standards adoption and refresh do not copy templates into `.github/`, configure
Git, install hooks, change workflows, or modify other active repository files.

A repository that wants to use a template should copy or adapt it through an
ordinary reviewed change.  Once copied outside the managed standards tree, the
local derivative belongs to that repository and may evolve according to local
governance.

Future standards upgrades do not automatically synchronize repository-local
copies.

## Examples

Where a realistic completed example improves understanding, a corresponding
non-normative example lives beneath the parallel `standards/examples/` tree.

For example:

```text
templates/general/security/stride-disclosure.md
examples/general/security/stride-disclosure.md
```

Examples normally omit the instructional HTML comments and show what completed
visible content can look like.

## Git Reference Templates

The commit and merge-message files are Markdown references for humans and
automated agents.

They do not imply automatic configuration of Git's `commit.template`, hooks,
hosting-platform merge settings, or release tooling.

## Governing Principle

Templates make recurring work easier to start and easier to review without
turning recommended document structure into a second source of policy.
