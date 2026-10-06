# Security Disclosure Standard

## Purpose

This standard defines how a project communicates its security posture,
assumptions, threat model, evidence, limitations, compromises, and residual risk.

Disclosure is the D in IDEA.

The purpose is informed decision-making.  Security documentation SHOULD help
maintainers, operators, integrators, and users understand what the system is
designed to protect, what evidence supports those protections, and where
uncertainty or risk remains.

## Disclosure Does Not Mean Publishing Vulnerabilities

This standard does not require public disclosure of exploitable vulnerabilities,
secrets, active incident details, or other information whose publication would
increase risk.

Sensitive findings MUST follow the repository's security-reporting and incident
handling policy.

Security posture documentation should be candid without becoming an exploit
guide.

## Security Claims

Material security claims SHOULD be specific.

Prefer:

> Outbound HTTP configuration rejects plaintext HTTP endpoints.

over:

> Network access is secure.

Prefer:

> The publisher cannot read the review agent's output directory before the review
> is finalized under the documented filesystem permissions.

over:

> The agent is isolated.

A claim SHOULD identify the property being asserted closely enough that evidence
can support or challenge it.

## Claims, Assumptions, Controls, and Evidence

For consequential security properties, projects SHOULD distinguish:

- **claim**: the property the project intends to provide;
- **assumption**: a condition that must hold for the claim to remain valid;
- **control**: the mechanism intended to enforce the claim;
- **evidence**: observations, tests, configuration, or analysis supporting the
  control;
- **limitation**: what the control or evidence does not establish;
- **residual risk**: risk remaining after the control; and
- **compromise or exception**: a deliberate decision to accept weaker protection.

These categories SHOULD NOT be collapsed into one statement.

## Uncertainty Must Be Visible

Security engineering cannot establish perfect certainty.

Projects SHOULD avoid absolute statements when the available evidence establishes
only a narrower property.

Tests, reviews, cryptographic verification, static analysis, threat models, and
formal reasoning can increase assurance.  They do not eliminate all uncertainty.

Uncertainty SHOULD be described at the level necessary for a maintainer or user to
make an informed decision.

## Threat Modeling

Projects SHOULD threat-model material trust boundaries and security-sensitive
flows.

Threat modeling SHOULD begin with enough system description to identify:

- assets;
- actors and identities;
- components;
- data flows;
- control flows;
- trust boundaries;
- privileged operations;
- external dependencies;
- security-sensitive transformations; and
- important assumptions.

The depth of analysis SHOULD be proportional to the consequences of failure,
exposed attack surface, privilege involved, and sensitivity of the affected data.

A small utility may require only a concise threat review.  Release signing,
deployment, credential management, or privileged agentic automation may require a
substantial documented model.

## STRIDE

STRIDE is the preferred baseline threat-modeling taxonomy unless
repository-specific governance selects another method.

This preference is based on common recognition and reviewer familiarity rather
than a claim of technical superiority.  A frequently encountered framework
reduces the amount of framework-specific explanation a reviewer must absorb and
makes threat models easier to compare across repositories and teams.

Another threat-modeling method MAY be used when repository-specific governance,
domain needs, or the nature of the system makes it a better fit.  Reviewers
SHOULD NOT treat the use of STRIDE itself as evidence that a threat model is more
complete, rigorous, or correct than one produced with another suitable method.

For each material boundary or flow, consider:

- **Spoofing**: can an actor, service, workload, or signer be impersonated?
- **Tampering**: can data, control information, configuration, or artifacts be
  modified without detection?
- **Repudiation**: can a consequential action occur without adequate attribution
  or evidence?
- **Information Disclosure**: can data reach an unauthorized party?
- **Denial of Service**: can the boundary be abused to exhaust, block, starve, or
  destabilize the system?
- **Elevation of Privilege**: can an actor, value, component, or instruction gain
  authority beyond what was intended?

Not every STRIDE category is meaningful for every boundary.  A category MAY be
marked not applicable when the reasoning is evident.

STRIDE is a shared prompt for systematic reasoning, not a substitute for
engineering judgment and not a quality ranking over other threat-modeling
frameworks.

## Taint and Data-Flow Analysis

Threat models SHOULD consider externally influenced data from source to sink.

Useful source categories include:

- command-line arguments;
- environment variables;
- files;
- standard input;
- network input;
- external-service responses;
- databases;
- subprocess output;
- repository content;
- issue and pull-request metadata;
- generated artifacts; and
- AI-generated output.

Useful sink categories include:

- process execution;
- shell interpretation;
- filesystem mutation;
- authorization decisions;
- network requests;
- database queries;
- release classification;
- deployment;
- publication;
- credential access; and
- privileged API operations.

The threat model SHOULD identify where the invariant required by a consequential
sink is established.

## Data and Control Boundaries

Threat models SHOULD identify locations where data can influence control.

Examples include:

- executable configuration;
- template-generated commands;
- dynamic module or plugin loading;
- shell evaluation;
- workflow definitions;
- deserialization with executable behavior;
- AI instructions derived from repository or issue content; and
- generated output consumed by a privileged publisher.

A system MUST NOT assume that content is authoritative merely because a component
can interpret it as control.

## Controls

A documented threat SHOULD identify the controls intended to reduce its
likelihood or impact when the threat is material.

Controls MAY include:

- authentication;
- authorization;
- validation;
- cryptographic protection;
- signature verification;
- freshness checks;
- privilege separation;
- sandboxing;
- filesystem restrictions;
- network restrictions;
- resource limits;
- independent approval;
- monitoring; and
- recovery mechanisms.

A control should be linked to the threat or claim it addresses rather than listed
as an unexplained security feature.

## Evidence

Evidence SHOULD be appropriate to the claim.

Examples include:

- unit or behavioral tests;
- negative tests;
- integration tests;
- configuration inspection;
- policy checks;
- static analysis;
- dependency or provenance verification;
- permission tests;
- certificate tests;
- audit records; and
- manual review.

Evidence SHOULD identify meaningful gaps when complete automation is impractical.

## Evidence Is Scoped

Passing a test proves only the behavior actually exercised under the tested
conditions.

For example:

~~~text
Claim:
    Plain HTTP endpoints are rejected.

Evidence:
    Tests demonstrate rejection of http:// and acceptance of https://.

Limitation:
    The tests do not prove CA integrity, endpoint integrity, payload provenance,
    or resistance to endpoint compromise.
~~~

A project MUST NOT represent narrow evidence as proof of a broader property that
it does not test.

## Accepted Compromises and Exceptions

A project MAY accept a weaker control when a stronger control is unavailable or
would impose disproportionate compatibility, availability, usability,
performance, operational, or maintenance cost.

Material compromises SHOULD record:

- the preferred stronger control;
- the control actually used;
- the reason for the compromise;
- compensating controls;
- affected assets or boundaries;
- residual risk;
- who or what accepted the risk when that matters; and
- a review trigger or review condition.

A compromise MUST NOT remain implicit merely because it is convenient or common.

## Residual Risk

Residual risk is the risk remaining after applicable controls are considered.

Security documentation SHOULD make material residual risk visible enough that a
user or maintainer can decide whether the system is appropriate for their
environment.

Residual risk MAY be accepted.  Acceptance does not mean the risk has been
eliminated.

## Review Triggers

A security assumption, threat model, or accepted compromise SHOULD identify
conditions that require reconsideration when practical.

Triggers MAY include:

- a new external integration;
- authentication mechanism changes;
- privilege changes;
- new network exposure;
- a new deployment environment;
- dependency or platform changes;
- a security incident;
- a changed threat model;
- replacement of a limiting third-party service; or
- material architectural changes.

A review trigger is often more useful than a calendar date for project-specific
engineering risks.

## Documentation Location

Small repositories MAY keep security disclosure in one maintained document.

Larger repositories MAY separate:

- trust-boundary documentation;
- threat models;
- risk acceptances;
- security assumptions;
- operational security guidance; and
- incident-response material.

The repository SHOULD make the authoritative location discoverable to humans and
automated agents.

Architecture-changing security decisions MAY require ADRs in addition to
operational risk documentation.

## Suggested Boundary Record

A concise trust-boundary record may contain:

~~~text
Boundary:
Assets:
Actors / identities:
Inputs:
Outputs:
Trust assumptions:
STRIDE threats:
Controls:
Evidence:
Known limitations:
Residual risk:
Accepted compromises:
Review triggers:
Related tests:
Related ADRs:
~~~

Projects MAY adapt this structure to their needs.

## Relationship to Testing

[Engineering](engineering.md) defines how security controls are implemented and
tested.

The [General Testing Standard](../testing-standard.md) governs shared testing
principles.

Disclosure explains what the resulting evidence means and what it does not mean.

## Guidance for Automated Agents

When an automated agent changes a material security boundary, it SHOULD:

1. identify affected security claims and assumptions;
2. update the relevant threat model;
3. apply STRIDE or the repository's governing alternative;
4. identify the controls implemented or changed;
5. add or update evidence where practical;
6. identify limitations in that evidence;
7. disclose any weaker-than-preferred control;
8. record material residual risk; and
9. identify a review trigger when the accepted risk depends on current
   conditions.

An agent MUST NOT hide security uncertainty by describing an unverified property
as established fact.

## Governing Principle

Security disclosure should tell users and maintainers what the system claims,
what those claims depend on, what evidence supports them, what compromises were
made, and what risk remains.
