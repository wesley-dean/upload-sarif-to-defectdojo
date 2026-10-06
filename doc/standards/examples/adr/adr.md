# ADR-012: Separate Analysis from Publication Authority

Date: 2026-09-28

## Status

Accepted

## Context

The repository uses an automated review component to analyze pull-request content
and a publisher to post the resulting review.  Pull-request content is externally
influenced and may contain instruction-like text.

Giving the analysis component publication credentials would allow content under
review to influence a process that already possesses repository-mutation
authority.  The workflow needs to preserve useful automated analysis without
requiring the analyzer itself to be trusted with publication capability.

## Decision Drivers

- keep externally influenced analysis separate from repository mutation;
- minimize credential exposure;
- preserve attributable publication;
- allow the analysis component to operate without network access;
- make the privileged boundary independently testable; and
- keep the workflow understandable to maintainers and reviewers.

## Decision

The analysis component will run without repository publication credentials and
without network access.

Its output will cross a narrow data interface into a separate validation stage.
The publisher will receive only validated review content and the minimum
repository identity needed for the intended publication operation.

The publisher will independently authorize the target operation and will not
interpret arbitrary analyzer output as commands.

## Alternatives Considered

### Give the Analyzer the Publisher Credential

Rejected because it combines untrusted-content analysis and repository mutation
inside one security domain, increasing blast radius and making prompt or
instruction injection more consequential.

### Require Human Copy and Paste for Every Review

Rejected because it removes useful automation and imposes recurring manual work
when a narrow mediated publication boundary can provide the required separation.

## Consequences

### Positive

- the analyzer cannot publish directly;
- publication credentials remain outside the analysis environment;
- network denial can be enforced independently;
- the publisher interface is narrow and testable; and
- compromise of the analyzer does not automatically grant repository mutation.

### Negative

- the workflow requires separate validation and publication stages;
- additional integration tests are required; and
- failures can occur at the handoff even when analysis itself succeeds.

## Compatibility and Migration

Existing review prompts and analysis behavior remain compatible.  The publisher
credential must move out of the analysis environment, and current direct
publication calls must be replaced by the mediated output interface.

## Expected Outcome

Automated reviews remain publishable while externally influenced analysis is
prevented from directly exercising repository-mutation authority.

## Related Decisions

- ADR-008 governs the IDEA zero-trust security framework.
