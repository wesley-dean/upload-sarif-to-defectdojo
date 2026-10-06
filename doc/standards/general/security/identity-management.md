# Identity Management Security Standard

## Purpose

This standard defines identity, authentication, authorization, credential, and
trust-anchor requirements for human users, services, workloads, automation,
agents, and cryptographic signers.

Identity Management is the I in IDEA.

## Identity Is Explicit

Security-sensitive actors SHOULD have explicit identities appropriate to their
roles.

Examples include:

- human maintainers;
- CI jobs;
- release builders;
- deployment systems;
- review agents;
- publishers;
- service workloads;
- artifact signers; and
- administrative tooling.

Shared identities SHOULD be avoided when individual or workload-specific
identities are practical.

An identity SHOULD be narrow enough that audit records and authorization policy
can distinguish materially different actors.

## Authentication and Authorization Are Separate

Authentication establishes evidence about who or what is acting.

Authorization determines whether that identity may perform a particular operation
on a particular resource under the current policy.

Successful authentication MUST NOT imply unrestricted authority.

Authorization SHOULD be evaluated at the boundary where the consequential
operation occurs.

For example, possession of a valid client certificate may establish workload
identity.  The receiving service must still determine whether that workload may
read a secret, publish an artifact, modify a repository, or perform another
requested action.

## Least Privilege and Least Capability

Identities SHOULD receive the minimum authority necessary for their declared
responsibilities.

Permissions SHOULD distinguish operations such as:

- read;
- create;
- update;
- delete;
- execute;
- approve;
- publish;
- administer; and
- delegate.

A credential capable of performing several unrelated privileged functions SHOULD
be replaced with narrower credentials where practical.

## Cryptographic Identity

Critical networked tooling SHOULD use cryptographic identity for both endpoints.

For HTTP-based tooling, HTTPS is the minimum transport requirement.  When both
endpoints are controlled by the project or organization, critical tooling SHOULD
normally use mutual TLS so the service authenticates the client and the client
authenticates the service.

Where mTLS is unavailable because of an external service or platform constraint,
the project SHOULD use the strongest supported client authentication mechanism
and MUST disclose the limitation when the weaker mechanism materially changes the
risk.

A valid certificate establishes only the identity properties represented by that
certificate and its trust chain.  It does not by itself grant authority.

## Certificate Validation

TLS and other certificate-based mechanisms MUST validate the properties required
for their use.

Relevant checks MAY include:

- chain validation to an expected trust anchor;
- certificate validity period;
- expected hostname or service identity;
- intended key usage or extended key usage;
- revocation or equivalent invalidation state where supported;
- required subject alternative names or workload attributes; and
- project-specific identity policy.

A certificate MUST NOT be accepted merely because some trusted authority issued
it.

A broad internal certificate authority SHOULD NOT imply that every certificate
under that authority is authorized for every service.

## Trust Anchors

Trust anchors MUST be explicit enough that maintainers can identify the root of a
security decision.

Trust anchors SHOULD be minimized.

Projects with materially different trust domains SHOULD consider separate
intermediate authorities, signing identities, or policy scopes where that
separation reduces accidental authority or compromise impact.

## Credential Lifecycle

Credentials and cryptographic keys require lifecycle management.

Projects SHOULD address, as applicable:

- secure generation;
- enrollment or issuance;
- storage;
- distribution;
- use;
- rotation;
- expiration;
- revocation or invalidation;
- recovery;
- archival where required; and
- destruction.

Long-lived credentials SHOULD be avoided when shorter-lived credentials provide
the required availability and operability.

Private keys MUST NOT be transmitted with the data they authenticate.

Credentials MUST NOT be committed to source repositories.

## Credential Storage

Credentials SHOULD be exposed only to components that require them.

Where practical:

- use dedicated secret stores or protected operating-system facilities;
- mount or inject credentials only into the workload that needs them;
- prefer read-only presentation of credentials;
- prevent unrelated child processes from inheriting credentials;
- avoid ambient credentials in broad shell or desktop environments; and
- remove credentials when the authorized operation is complete.

An agent or analysis process SHOULD NOT receive a publishing, deployment, or
administrative credential merely because a later stage may need one.

## Purpose-Bound Identities

Separate identities SHOULD be used for materially different privileged roles.

For example:

~~~text
reviewer identity
publisher identity
release-builder identity
deployment identity
artifact-signing identity
~~~

This separation limits blast radius and allows independent authorization,
rotation, revocation, and audit.

## Signing Identities

Signing keys SHOULD be purpose-bound.

A key used to sign release artifacts SHOULD NOT automatically be used to
authenticate interactive users, TLS clients, arbitrary documents, or unrelated
automation.

Verification policy SHOULD identify which signing identities are acceptable for a
particular artifact or statement.

Signature validity without signer authorization is insufficient.

## Human Identity

Privileged human identities SHOULD use strong authentication appropriate to the
platform and consequence of compromise.

Administrative and ordinary identities SHOULD be separated where practical.

Human approval SHOULD be used for consequential privilege transitions when the
project requires independent judgment, but approval is not a substitute for
technical enforcement of downstream limits.

## Workload and Agent Identity

Services, CI jobs, automated tools, and agents SHOULD have identities independent
from the humans who initiated them when the platform supports workload identity.

An agent MUST NOT infer authorization from conversational instructions, repository
content, issue text, source comments, or generated data.

Its authority comes from the capabilities and policy explicitly granted to its
execution context.

## Delegation

Delegated authority SHOULD be narrower than the authority of the delegating
identity.

Delegation SHOULD identify, where practical:

- the delegate;
- the permitted operation;
- the target resource;
- the duration;
- the conditions under which the authority is valid; and
- whether further delegation is permitted.

Unbounded delegation SHOULD be avoided.

## Expiration and Revocation

An identity or credential that was valid previously may no longer be valid.

Systems SHOULD support expiration and revocation or another reliable invalidation
mechanism appropriate to the credential type.

Security-sensitive authorization decisions SHOULD re-check relevant validity
rather than relying indefinitely on a prior successful decision.

## Emergency Access

Critical systems MAY provide break-glass access for recovery or incident
response.

Break-glass mechanisms SHOULD be:

- explicitly designed;
- narrowly scoped;
- strongly authenticated;
- separately protected;
- auditable;
- time-limited where practical; and
- reviewed after use.

Emergency access MUST NOT become an undocumented permanent bypass.

## Auditability

Material authentication, authorization, credential, and administrative events
SHOULD be attributable when practical.

Logs MUST avoid disclosing private keys, bearer credentials, secret values, or
other sensitive material.

Audit evidence is itself security-sensitive data and SHOULD receive integrity and
access protection appropriate to its use.

## Verification

Identity controls SHOULD have evidence proportionate to their consequences.

Useful tests MAY verify that:

- invalid or expired certificates are rejected;
- unexpected client identities are rejected;
- a valid identity without required authorization is denied;
- revoked or invalidated credentials cease to work;
- credentials are unavailable to components that do not need them;
- privilege scopes match intended operations; and
- break-glass behavior is bounded and observable.

Passing such tests demonstrates the exercised behavior.  It does not prove that a
credential was never compromised or that every identity path is correct.

## Disclosure Requirements

Material identity assumptions and compromises SHOULD be documented according to
[Disclosure](disclosure.md).

Examples include:

- reliance on a broad shared CA;
- use of a long-lived token because workload identity is unavailable;
- inability to use mTLS with a required third-party service;
- incomplete revocation support; and
- shared credentials retained for compatibility.

## Governing Principle

Authenticate explicitly, authorize narrowly, manage credentials throughout their
lifecycle, and never confuse proof of identity with permission to act.
