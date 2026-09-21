# Architecture Decision Record Standard

## Status

Recommended repository governance

## Purpose

This standard defines how repositories record, accept, relate, summarize, and maintain Architecture Decision Records (ADRs).  It is intended for both human contributors and automated coding agents.

The goals are to keep decision history explicit, make acceptance semantics unambiguous, preserve supersession history without overloading the ADR status field, and maintain a concise current-decision digest that can be reviewed before implementation work begins.

## Applicability

This standard applies to repositories that use ADRs.  It does not require a repository that has no ADR practice to introduce one unless other governing repository policy requires ADRs.

Repository-specific ADR conventions may refine this standard through accepted local governance, but deviations must be explicit rather than inferred or silently applied.

## ADR Status

Every committed ADR MUST use the status:

```text
Accepted
```

`Accepted` records that the decision entered the repository's governed decision history.  The status is not used to describe whether a decision is still the newest decision on a subject.

Statuses such as `Proposed`, `Draft`, `Superseded`, `Deprecated`, `Rejected`, or compound forms such as `Accepted; partially superseded by ADR-008` MUST NOT be used as the status of a committed ADR.

An ADR included in a pull request intended for merge SHOULD already say `Accepted`.  By project convention, merging a pull request that contains a new or materially changed ADR is generally understood to be acceptance of that ADR.  A separate post-merge status-edit pull request is neither required nor preferred.

A draft pull request may therefore contain an ADR whose status is `Accepted`: the pull request remains proposed work, while the ADR text expresses the status it will have if that pull request is accepted and merged.

## Decision Relationships and Historical State

Acceptance and current applicability are separate concepts.  An ADR can remain accepted historical governance even after another accepted ADR refines, replaces, narrows, or supersedes some or all of its decision.

Relationships among ADRs MUST be recorded in the ADR narrative rather than encoded as alternate status values.  Appropriate sections include:

```text
## Supersedes

## Superseded By

## Related Decisions

## Decision History
```

The wording should state the relationship precisely.  Partial supersession should identify which portion of the earlier decision changed when that distinction matters.

A superseded ADR MUST remain in the repository unless repository-specific governance explicitly requires another archival mechanism.  Historical ADRs remain useful for understanding why an earlier decision was reasonable under the conditions that existed when it was accepted.

## ADR Content

An ADR should be thorough enough to support later engineering review without relying on conversational history.  Where relevant, it SHOULD capture:

- the decision being made;
- why the decision is being made;
- conditions and constraints that exist at the time;
- material assumptions;
- alternatives considered;
- alternatives rejected and why;
- tradeoffs and consequences;
- expected outcomes;
- compatibility and migration implications; and
- relationships to prior ADRs.

Repositories with an established ADR template SHOULD preserve that template's structure when it captures equivalent information.

## Pull Request Acceptance

For work intended to merge, the ADR and implementation belong to the same reviewable decision boundary whenever practical.

The normal lifecycle is:

1. draft or update the ADR with status `Accepted`;
2. review and update `doc/adr/README.md` when the change affects current governance;
3. include implementation and documentation governed by that decision as appropriate;
4. review the pull request as a whole; and
5. treat merge of the pull request as acceptance of the ADR.

If reviewers do not accept the decision, the pull request should remain unmerged, be revised, or be closed.  The repository should not merge an ADR as `Proposed` with the expectation that a later mechanical status change will make the decision authoritative.

## ADR Landing Page

A repository that contains ADRs MUST maintain:

```text
doc/adr/README.md
```

The landing page serves two distinct purposes:

1. it provides a curated digest of decisions that continue to govern current work in whole or in material part; and
2. it provides access to the complete ADR corpus, including fully superseded historical decisions.

The landing page does not replace the ADRs themselves.

### Current Decisions

The maintained portion of `doc/adr/README.md` MUST contain a `Current Decisions` section.  Each accepted decision that continues to govern the repository in whole or in material part MUST have a corresponding digest entry.

Each current-decision entry SHOULD generally contain three to five sentences that provide enough context for a reader to understand the present architectural commitment before following the ADR link.

A useful current-decision entry normally includes:

- the current decision or governing rule;
- enough reasoning to explain why that rule matters to present work;
- an important consequence, constraint, or implementation implication; and
- any important relationship to another ADR that changes how the decision currently applies.

Each entry MUST include a direct reference to its governing ADR.

A fully superseded historical ADR does not require an entry in `Current Decisions`.  It remains preserved in the repository and discoverable through the complete ADR inventory.

When a decision remains partly applicable, its digest entry SHOULD describe the portion that continues to govern and identify the later ADR that refined, narrowed, or superseded the rest.

### Maintained and Generated Content

The landing page MUST use the marker:

```text
<!-- adrctl-generated-footer -->
```

to separate maintained project knowledge from the complete ADR inventory.

Everything above the marker is curated project documentation.  Everything below the marker is reserved for the complete ADR inventory and MAY be regenerated mechanically from the ADR corpus.

Repositories using `adrctl` SHOULD generate the inventory with:

```bash
adrctl.bash generate toc
```

Equivalent tooling MAY be used when it produces a complete inventory of the ADR corpus.  Inventory tooling MUST preserve the maintained content above the marker and MUST fail rather than append blindly when the marker cannot be found.

The generated or mechanically maintained inventory is exhaustive.  The curated `Current Decisions` section is intentionally selective.

## Maintaining the Current-Decision Digest

Adding an ADR requires reviewing whether the new decision belongs in `Current Decisions`.

Materially changing an ADR requires reviewing and, when necessary, updating its current-decision entry in the same pull request.

Adding a new ADR that supersedes or refines an earlier ADR requires reviewing the digest entries for both the new decision and every earlier decision whose current applicability changed.

A fully superseded decision SHOULD be removed from `Current Decisions` once the later ADR governs the relevant subject completely.  Removing the digest entry MUST NOT delete or rewrite the historical ADR itself.

Agents and contributors MUST NOT treat the landing page as a write-once historical artifact.  The maintained portion is current project governance and should remain synchronized with what actually governs.

A repository-wide ADR review SHOULD verify that:

- every ADR status is `Accepted`;
- every currently governing decision is represented in `Current Decisions`;
- every current-decision entry references its ADR;
- digest entries are generally three to five sentences rather than title-only index entries;
- fully superseded decisions remain in the complete inventory without requiring current-decision entries;
- partial supersession is reflected accurately in both ADR narrative and the current digest;
- supersession and related-decision relationships are represented in narrative form; and
- no current guidance incorrectly depends on `Proposed`, `Superseded`, or another alternate ADR status.

## Guidance for Automated Tools and Agents

Before consequential repository work, an agent SHOULD read `doc/adr/README.md` and the ADRs relevant to the requested change.  The current-decision digest provides an initial orientation layer; linked ADRs remain authoritative for the complete reasoning, scope, alternatives, and consequences.

When an agent creates or materially changes an ADR, it MUST:

1. use `Accepted` as the ADR status;
2. record supersession or related-decision information in narrative sections;
3. review and update `doc/adr/README.md` in the same change when current governance changes;
4. keep each affected current-decision entry to roughly three to five useful sentences unless additional context is genuinely necessary;
5. include a direct reference from each current-decision entry to its ADR; and
6. preserve or regenerate the complete ADR inventory below `<!-- adrctl-generated-footer -->`.

An agent MUST NOT create a follow-up pull request whose sole purpose is to change an ADR from `Proposed` to `Accepted` after the governing pull request has already been merged.

## Review Checklist

Before merging a pull request that adds or changes ADR governance, verify:

- [ ] Every affected ADR says `Accepted` under `## Status`.
- [ ] Supersession, replacement, or deprecation relationships are preserved in narrative form.
- [ ] `doc/adr/README.md` accurately represents every decision that continues to govern current work.
- [ ] Every affected current-decision entry has been reviewed and updated where necessary.
- [ ] Each current-decision entry is generally three to five sentences and links directly to its ADR.
- [ ] Fully superseded ADRs remain preserved and discoverable in the complete inventory.
- [ ] Partial supersession is reflected accurately in both the ADR narrative and current-decision digest.
- [ ] The maintained/generated ownership marker is present and the complete ADR inventory remains below it.
- [ ] The pull request is sufficient to treat merge as acceptance of every ADR it introduces or materially changes.

## Governing Principle

An ADR records an accepted decision and remains part of the repository's decision history.  Later decisions may change what governs now, but they do not erase the fact that an earlier decision was accepted.  Keep acceptance in the status field, keep evolution in the narrative, keep current governance in `doc/adr/README.md`, and keep the complete historical corpus discoverable beneath the same landing page.
