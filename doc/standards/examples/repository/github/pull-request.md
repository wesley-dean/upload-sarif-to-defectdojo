Closes #42

## Purpose

The release workflow currently publishes artifacts before verifying that the
generated archive matches the repository's documented package contract.  This
change adds direct verification of the generated archive before publication.

## Proposed Changes

- add an archive-content verification step to the release workflow;
- fail publication when the required checksum or expected files are missing; and
- document the new release verification behavior.

## Assumptions

The existing deterministic archive build remains the canonical source of release
artifacts.

## Compatibility and Migration

No consumer-facing format changes are expected.  Existing release artifact names
and archive layout remain unchanged.

## Security and Trust Boundaries

The release job crosses a privileged publication boundary.  Verification occurs
before release credentials are used so malformed build output cannot be published
merely because the build step completed successfully.

## Verification

- [x] Local archive structure and checksum verification passed.
- [x] CI is still pending; no CI pass is claimed yet.
- [x] Generated archive locally verified against the documented contract.
- [x] Documentation affected by this change updated.
- [x] Governing ADRs and standards affected by this change reviewed.

## Known Limitations and Follow-Up

This change verifies archive structure and checksum presence.  It does not add
artifact signing; that remains separate scope.

## Readiness Checklist

- [x] Related issues are linked where applicable.
- [x] The pull request title reflects the highest semantic significance of the
  complete change.
- [x] The diff remains within the declared scope.
- [x] Available author-side verification completed and honestly reported.
- [x] Material assumptions, limitations, and risks are visible.
- [x] Final planned commits pushed; no further implementation is expected.
- [x] PR marked Ready while CI remains pending.
- [x] Auto-merge armed; protected CI and human review gate merge.
