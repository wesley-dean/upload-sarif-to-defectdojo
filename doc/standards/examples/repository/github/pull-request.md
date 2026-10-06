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

- [x] Relevant automated tests pass.
- [x] Generated or distributed artifacts were verified where applicable.
- [x] Documentation affected by this change was updated.
- [x] Governing ADRs and standards affected by this change were reviewed.

## Known Limitations and Follow-Up

This change verifies archive structure and checksum presence.  It does not add
artifact signing; that remains separate scope.

## Readiness Checklist

- [x] Related issues are linked where applicable.
- [x] The pull request title reflects the highest semantic significance of the
  complete change.
- [x] The diff remains within the declared scope.
- [x] Required verification has been completed to the extent available.
- [x] Material assumptions, limitations, and risks are visible.
- [x] The pull request is ready for normal review and may be merged once repository
  checks and review requirements are satisfied.
