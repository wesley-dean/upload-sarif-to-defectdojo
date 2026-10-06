# AI Safety Standard

## Status

Recommended engineering standard

## Purpose

This standard defines reusable safety expectations for engineering work that uses
large language models, AI assistants, coding agents, review agents, model-generated
content, or other probabilistic AI systems.

The primary concern is ordinary model fallibility.  An AI system may misunderstand
intent, omit important context, hallucinate facts or interfaces, make an incorrect
inference, rely on stale information, misread tool output, or produce a plausible
but incorrect result.

The governing principle is:

> AI-generated output is a proposal or interpretation until supported by evidence
> appropriate to its intended use.

## Applicability

This standard applies when AI materially contributes to source code, tests,
documentation, architecture, repository review, operational analysis, tool
selection, generated configuration, release or deployment decisions, security
analysis, or other engineering work whose correctness matters.

It applies to interactive assistance and automated or semi-automated agents.

Repository-specific ADRs or explicit policy MAY refine this standard.  Such
refinements MUST NOT silently weaken its central principles of verification,
visible uncertainty, constrained authority, and deterministic mediation of
consequential side effects.

## Non-Goals

This standard does not assume that an AI system is malicious, self-directed, or
intentionally attempting harm.

It does not attempt to govern speculative catastrophic-AI scenarios.

Its focus is more ordinary and practical: a model can be confidently, fluently,
and consequentially wrong.

Security concerns such as prompt injection, credentials, identity, least
capability, and trust boundaries remain governed primarily by the general security
corpus.

## Normative Language

The terms MUST, MUST NOT, SHOULD, SHOULD NOT, and MAY are normative requirements.

## Core Safety Model

A safe AI-assisted workflow SHOULD separate:

1. **reasoning**, where the AI proposes, interprets, compares, or recommends;
2. **evidence**, where material claims are checked;
3. **authorization**, where policy determines whether an action is permitted; and
4. **execution**, where deterministic code performs the consequential operation.

These layers MAY exist in one application, but their responsibilities SHOULD
remain distinguishable.

Fluency is not evidence.

Model confidence is not evidence.

Agreement from another model is not necessarily independent evidence.

A plausible result MUST NOT be treated as verified merely because it is detailed,
confident, or internally consistent.

## Foundational Design Principles

The detailed requirements in this standard can be understood through a small set
of design principles.  These principles summarize the safety model; they do not
replace the normative requirements that follow.

- **Trust, but verify independently.**  Material claims and consequential outcomes
  SHOULD be established with evidence reasonably independent of the failure mode
  being checked.
- **AI may only reduce its permissions scope, never increase it.**  AI-controlled
  execution MAY preserve or reduce effective authority, but MUST NOT expand it.
  Any expansion of effective authority MUST originate outside the AI-controlled
  trust domain.
- **AI may solve the problem; it may not decide what counts as solved.**
  Authoritative objectives, constraints, acceptance criteria, and policy gates
  MUST remain outside the AI-controlled trust domain.  An AI MAY propose changes
  to them, but MUST NOT silently weaken them to make its work appear successful.
- **Use AI for judgment; use deterministic systems for rules.**  A safety property
  that can be enforced deterministically SHOULD be enforced outside the model
  rather than delegated to model behavior.
- **No single AI failure should have an unbounded consequence.**  Capability,
  rate, fan-out, duration, value, data scope, concurrency, and reversibility
  SHOULD be constrained according to consequence.
- **Make the safe path the fast path.**  Safety controls SHOULD minimize avoidable
  friction and redundant verification while preserving required assurance.
- **Authority may be delegated; accountability may not.**  Consequential AI
  workflows MUST retain an identifiable human or organizational owner accountable
  for the authority delegated to the system.

These principles are intentionally human-readable.  They are not stable
commandment identifiers and MAY be refined as the AI standards corpus matures.

## Epistemic Vocabulary

AI-assisted work SHOULD distinguish among the following when the distinction
materially affects correctness or review.

### Observation

An observation is information obtained directly from an inspected source, tool,
file, command result, API response, repository state, test run, or other observable
artifact.

An AI MUST NOT represent an inference as an observation.

### Source-Supported Fact

A source-supported fact is a claim directly supported by a relevant source.

The source SHOULD be identifiable when the claim materially affects architecture,
compatibility, security, release behavior, or another consequential decision.

### Inference

An inference is a conclusion drawn from observations or source-supported facts.

An inference SHOULD remain distinguishable from the evidence on which it depends.

### Assumption

An assumption is a condition accepted temporarily so work can proceed.

Material assumptions SHOULD be stated explicitly and SHOULD be verified before
they control consequential or difficult-to-reverse actions.

### Hypothesis

A hypothesis is a proposition being investigated rather than an established
conclusion.

### Recommendation

A recommendation is advice based on evidence, constraints, tradeoffs, or judgment.

A recommendation SHOULD NOT be phrased as fact merely because the model strongly
prefers it.

### Unknown or Uncertain

Unknown information MUST NOT be replaced with plausible invention.

Uncertainty SHOULD be stated at the level needed for a human or downstream
component to make an informed decision.

## Do Not Manufacture Evidence

An AI system MUST NOT claim that an observation, verification, test, command,
review, fetch, build, source inspection, or other evidence-producing action
occurred when it did not occur.

Examples include:

- claiming tests passed when they were not run;
- claiming a file was inspected when it was not read;
- inventing command output;
- inventing repository state;
- inventing issues, pull requests, commits, releases, or workflow results;
- inventing APIs, functions, options, configuration keys, or file paths;
- fabricating citations or source references;
- attributing rationale to maintainers without evidence; and
- claiming a generated artifact was verified when only its source was inspected.

When direct evidence is unavailable, the correct state is uncertainty.

## Source Grounding

Consequential claims SHOULD be grounded in relevant source material.

Where practical, prefer current repository state, governing repository
documentation and ADRs, primary technical documentation, executable evidence, and
direct tool observations over plausible reconstruction.

An AI system SHOULD verify that a source actually supports the claim for which it
is cited.

Repository governance SHOULD be reviewed before making changes that affect
architecture, compatibility, security boundaries, release behavior, public
interfaces, or other governed contracts.

## Current State and Freshness

When correctness materially depends on state that can change, that state SHOULD be
observed rather than remembered.

Examples include:

- current branch and repository contents;
- issue or pull-request state;
- workflow results;
- dependency and released versions;
- external documentation;
- service behavior; and
- environment configuration.

Cached context, summaries, memory, prior conversation, or earlier tool results MAY
orient the work but SHOULD NOT substitute for current observation when state may
have changed.

Absence from current model context MUST NOT be treated as evidence that something
does not exist.

## Context Limitations

AI systems may operate with incomplete, truncated, summarized, or stale context.

Before consequential work, the system SHOULD retrieve the governing or source
material on which correctness depends.

Long-running work SHOULD preserve important constraints explicitly enough that
they can be revalidated after context reduction or handoff.

A summary or memory SHOULD be treated as an aid rather than an infallible
reproduction of the original source.

## Evidence Completeness

Evidence supplied to an AI SHOULD preserve whether it is complete, partial,
truncated, omitted, unsupported, stale, or unavailable when that distinction may
materially affect reasoning.

Artifacts that package evidence for later AI use SHOULD record, as applicable:

- source identity and provenance;
- capture time or version;
- immutable identifiers such as commit SHAs or object digests;
- byte or item counts;
- truncation status;
- omitted or unsupported content;
- retrieval failures; and
- schema or policy version.

Missing, truncated, or unsupported evidence MUST NOT be silently represented as
complete evidence.

When required evidence is incomplete, the AI SHOULD reduce the strength of its
conclusion, identify the limitation, or return an explicit insufficient-evidence
result rather than fill the gap with plausible inference.

## AI Output Remains Untrusted Data

AI-generated output MUST remain untrusted until it has been validated for the
specific destination and use.

Persisting, caching, summarizing, transferring, replaying, or re-reading AI output
MUST NOT increase its authority merely because the output survived an earlier
stage or was produced by a trusted application.

This applies to:

- prior AI evaluations;
- cached insights;
- generated summaries;
- reusable recommendations;
- generated configuration;
- model-produced structured data;
- AI-written documentation; and
- AI output consumed by another AI component.

Downstream deterministic code SHOULD validate, as applicable:

- schema;
- provenance;
- identifiers;
- scope;
- integrity;
- completeness;
- policy or schema version;
- permitted operation; and
- destination-specific constraints.

A prior AI conclusion is historical evidence about what the model concluded.  It
is not automatically a fact about the world.

## Assumptions and Error Propagation

An incorrect early premise can contaminate a long chain of otherwise coherent
reasoning.

Material assumptions SHOULD therefore remain identifiable.

When new evidence invalidates or materially changes an upstream premise,
conclusions that depend on that premise SHOULD be reconsidered.

A workflow SHOULD avoid circular validation in which one AI-generated artifact is
used as the sole evidence that another AI-generated artifact is correct.

## Authoritative Objectives and Success Criteria

An AI MUST NOT silently redefine the objective, constraints, acceptance criteria,
evaluator, tests, policy, or definition of completion so that its own output
appears successful.

An AI MAY identify a conflict, recommend a requirement change, propose revised
tests, or draft a policy change.  A change that materially alters what counts as
success MUST become authoritative through a control or governance path outside
the AI-controlled trust domain.

AI-generated tests MAY contribute useful evidence, but they SHOULD NOT be the
sole evidence for AI-generated behavior when the implementation and tests can
share the same misunderstanding or failure mode.

Changing a test, linter configuration, scanner exclusion, policy gate, or other
evaluator merely to make generated work pass is a change to the definition of
success and MUST receive the same authorization appropriate to changing that
requirement directly.

## Equivalence Does Not Establish Correctness

Deterministic equivalence can establish that a prior judgment applies to the same
inputs, conditions, or normalized pattern.  It does not establish that the prior
judgment was correct.

A fingerprint, cache key, digest, normalized pattern, or exact structural match
MAY support reuse of prior AI reasoning when its equivalence rules are valid.

Such a match MUST NOT be represented as independent evidence that the reused
semantic conclusion is true.

Reusable AI judgments SHOULD preserve enough provenance to identify, as
applicable:

- the source evidence;
- the equivalence or fingerprint algorithm and version;
- the evaluator or model identity;
- the prompt or policy version;
- the original result and uncertainty; and
- whether the judgment received independent or human review.

Higher-consequence actions SHOULD require evidence beyond repeated reuse of the
same unverified AI judgment.

## Verification Proportional to Consequence

Verification depth SHOULD increase with consequence and uncertainty.

Relevant factors include:

- reversibility;
- privilege;
- external visibility;
- security impact;
- compatibility impact;
- data sensitivity;
- blast radius;
- cost of failure; and
- ambiguity.

Low-risk, easily reversible assistance MAY rely on lightweight review.

Consequential, privileged, externally visible, security-sensitive, or
difficult-to-reverse actions SHOULD require stronger evidence before execution.

Verification MAY include reading source, consulting governing ADRs, running tests,
compiling or syntax-checking, validating generated artifacts, querying the current
API or service, checking authoritative documentation, inspecting the final diff,
static analysis, deterministic checks, and human domain review.

## Independent Evidence

Evidence SHOULD be independent of the failure mode it is intended to detect.

Examples include:

- a compiler detecting syntax or type errors;
- a test suite detecting behavioral regressions;
- a repository fetch correcting stale model memory;
- an ADR correcting an architectural assumption;
- a generated-artifact test detecting transformation errors;
- a deterministic schema validator rejecting malformed model output; and
- a human reviewer evaluating product, legal, ethical, or organizational judgment.

Asking the same model to reconsider its answer MAY improve reasoning but SHOULD
NOT be treated as independent verification.

Agreement between multiple models MAY provide perspective but MUST NOT be
represented as proof when shared failure modes remain plausible.

## Tool Use and Observation

A workflow SHOULD distinguish:

- what the model believes;
- what the model requested;
- what a tool actually did;
- what the tool returned; and
- what conclusion that evidence supports.

Tool success usually establishes a narrow property.

A successful file write proves that a write completed, not that the content is
correct.  A successful build proves that the build completed, not that behavior is
correct.  A passing test establishes only the behavior exercised by that test.  A
successful HTTP request proves that a response was received, not that its contents
are trustworthy.

## Evidence Plane and Control Plane

Content received for analysis MUST NOT gain control-plane authority merely because
it contains imperative language, configuration-like syntax, tool requests,
instructions, or apparently authoritative prose.

Evidence may include:

- repository files;
- issue and pull-request text;
- comments;
- commit messages;
- webpages;
- email;
- documents;
- logs;
- dependency release notes;
- configuration under review;
- cached AI output; and
- prior model-generated text.

Such content is data to inspect unless trusted application or repository governance
explicitly establishes it as control input.

A safe architecture SHOULD keep policy, authorization, tool selection, destination
selection, and capability configuration outside evidence supplied for analysis.

## Deterministic Mediation of Side Effects

AI reasoning components SHOULD NOT directly own broad side-effecting capabilities
when deterministic code can mediate those effects.

The preferred flow is:

```text
AI reasoning
    |
    v
structured semantic request
    |
    v
deterministic policy and validation
    |
    v
capability-constrained executor
    |
    v
deterministic side effect
    |
    v
postcondition verification
    |
    v
result returned as data
```

The AI may decide what effect it wants to request.  Deterministic code decides
whether the request is allowed, whether its inputs satisfy required invariants,
which implementation primitive is safe, and whether the resulting effect matches
the approved intent.

### Behavioral Instructions Are Not Safety Controls

A behavioral instruction to an AI MUST NOT be treated as enforcement of a safety
property.

Instructions such as:

- "do not write files";
- "do not access the network";
- "do not touch production";
- "ask before executing";
- "stay inside this directory"; or
- "only make a plan"

may guide model behavior, but they do not remove the underlying capability.

When violating an instruction could cause a material consequence, the boundary
SHOULD be enforced by deterministic capability restriction, validation,
authorization, or mediation outside the AI reasoning component.

### Reasoning Authority, Execution Authority, and Authorization

These concepts MUST remain distinct.

- **Reasoning authority** means the AI may recommend or request an action.
- **Execution authority** means a component has the technical capability to
  perform an action.
- **Authorization** means policy permits the action in the current context.

The ability to request an operation MUST NOT grant the capability or authorization
to perform it.

### Deterministic Orchestration Owns Workflow Success

When multiple operations are required to establish a safety property, their
required ordering, failure handling, and success conditions MUST be enforced by
deterministic orchestration rather than by instructions asking the AI to invoke
the steps correctly.

An AI assertion that an operation ran, succeeded, or produced a particular state
MUST NOT itself establish that fact.  Authoritative workflow state SHOULD be
derived from deterministic execution records, verified postconditions, receipts,
or equivalent evidence outside the model.

The AI MAY explain or summarize authoritative workflow state after it has been
established, but its explanation MUST NOT replace that state.

### Prefer Semantic Operations Over General Primitives

AI-facing operations SHOULD express the intended effect at the narrowest practical
semantic level.

For example, a request to replace one known value in a file SHOULD prefer an
operation such as:

```text
replace_literal(path, expected, replacement, expected_count)
```

over a general shell, arbitrary redirection, or unrestricted whole-file write.

When a narrow semantic operation can express the requested effect, an AI MUST NOT
be given a more general destructive primitive solely for convenience.

The deterministic mediator SHOULD select or implement the low-level primitive
needed to realize the approved semantic operation.

### Capability Boundaries Follow the Component

When a capability is prohibited for an AI-bearing component, implementations
SHOULD exclude that capability structurally from the component's dependency graph
and execution environment rather than rely only on runtime flags, model
instructions, or code paths that promise not to use it.

Useful layers include:

- separate executables or processes;
- dependency or import boundaries;
- separate runtime environments;
- dedicated operating-system identities;
- read-only or narrowly scoped mounts;
- denied network namespaces;
- dropped operating-system capabilities;
- absent credential material; and
- constrained IPC or tool interfaces.

The strongest practical design uses multiple independent layers so failure of one
control does not silently restore the prohibited capability.

### Network Access

AI reasoning components MUST NOT initiate arbitrary network connections directly.

When network access is required, a deterministic network mediator SHOULD perform
the request and constrain, as applicable:

- protocol;
- destination host and port;
- path;
- operation or HTTP method;
- redirects;
- request and response sizes;
- timeout;
- authentication;
- TLS validation; and
- allowed response handling.

The AI SHOULD receive retrieved data rather than unrestricted socket or HTTP
client capability.

### Filesystem Reads

AI reasoning components MUST NOT receive unrestricted filesystem read access when
a narrower deterministic interface can provide the required data.

A filesystem mediator SHOULD constrain, as applicable:

- allowed roots;
- path normalization and traversal;
- symbolic links;
- file type;
- file size;
- encoding;
- device or special files; and
- sensitive locations.

The AI SHOULD request the data it needs rather than traverse the host filesystem
freely.

### Filesystem Writes

AI reasoning components MUST NOT directly mutate arbitrary filesystem paths.

When AI-assisted work requires mutation, deterministic code SHOULD mediate the
operation.

Preferred patterns include:

- replacing a specific expected value;
- applying a validated patch;
- proposing replacement content for a known file;
- creating a file beneath an approved root; or
- requesting another named repository operation.

The mediator SHOULD enforce, as applicable:

- allowed roots;
- constrained targets;
- path normalization and traversal prevention;
- symbolic-link policy;
- expected file type and size;
- overwrite policy;
- permissions;
- working-tree scope;
- current-state preconditions;
- maximum permitted change size; and
- post-write verification.

### Preconditions

Filesystem mutations SHOULD carry preconditions sufficient to detect stale or
unexpected state before modification.

Useful preconditions MAY include:

- expected file hash;
- expected original text;
- expected occurrence count;
- expected file size or type;
- expected base revision;
- expected working-tree state; and
- expected target existence or nonexistence.

If a material precondition fails, the mediator SHOULD reject the request rather
than reinterpret the model's intent.

### Postconditions and Diff Validation

Filesystem mutations SHOULD carry postconditions sufficient to detect unintended
changes before the result becomes durable or externally visible.

Useful postconditions MAY include:

- only the requested literal or region changed;
- unrelated bytes or lines remain unchanged;
- the resulting file parses or validates;
- the file was not unexpectedly truncated;
- the resulting size change remains within an allowed bound;
- the resulting diff is limited to approved paths and scope; and
- the expected semantic outcome is present.

For repository changes, deterministic code SHOULD inspect the resulting diff
against the approved operation before publication, commit, merge, deployment, or
other consequential use.

A generic write that succeeds is not evidence that the requested transformation
was performed correctly.

### Command and Process Execution

AI reasoning components MUST NOT receive unrestricted shell execution when a
narrow deterministic executor can perform the required operations.

A deterministic executor SHOULD prefer named operations, fixed executables,
explicit argument vectors, constrained working directories, minimal environment,
timeouts, resource limits, controlled output, and explicit exit-status handling.

AI-generated or externally influenced text SHOULD NOT be interpolated into an
arbitrary shell command when a structured operation can express the same intent.

Shell redirection, recursive deletion, broad file replacement, and similar
high-impact primitives SHOULD remain behind deterministic interfaces rather than
being exposed as general-purpose AI tools.

### Credentials

AI reasoning components SHOULD NOT receive credentials merely because a
downstream deterministic component requires them.

Credentials SHOULD remain within the narrowest component that performs the
authorized operation.

The AI MAY request an operation requiring a credential without receiving, reading,
logging, or reproducing that credential.

### Semantic Output Interfaces

AI-facing output interfaces SHOULD represent the semantic result the component is
authorized to emit rather than expose generic storage, transport, or mutation
primitives.

For example:

```text
emit_evaluation_result(result)
```

is preferable to:

```text
write_file(path, bytes)
```

when the component's only legitimate output is an evaluation result.

Where practical, the surrounding runtime SHOULD own redirection, persistence,
transport, path selection, or publication so the AI-bearing component never
receives those broader capabilities.

### Durable AI-Derived State

AI-bearing components SHOULD NOT directly maintain durable knowledge, cache, or
policy state when deterministic code can validate and persist the same output
through a narrow interface.

A preferred pattern is:

```text
AI produces structured candidate insight
    |
    v
deterministic validation
    |
    v
mechanical persistence with provenance
```

The deterministic persistence stage SHOULD verify schema, identifiers, provenance,
integrity, supported versions, permitted destination, and any other invariants
required by the durable store.

An AI component SHOULD NOT be able to rewrite provenance, history, policy
versions, cache counters, trust metadata, or other durable control information
merely by generating new prose or structured output.

### External Mutation

Publication, deployment, merge, release, account mutation, infrastructure change,
repository mutation, and similar consequential effects SHOULD be performed by
deterministic components that independently validate and authorize the request.

The AI SHOULD provide structured intent rather than unrestricted mutation
authority.

Where practical, the executor SHOULD validate the resulting state against the
requested semantic outcome rather than treating successful API or tool execution
as sufficient evidence.

### Revalidate Mutable State Before Consequential Mutation

A consequential action MUST NOT rely solely on state captured during an earlier
reasoning phase when the relevant state can change.

Immediately before a consequential mutation, deterministic code SHOULD revalidate
the mutable preconditions on which authorization or correctness depends.

Examples include:

- current object or resource identity;
- repository and branch;
- target commit or content digest;
- pull-request head SHA;
- test or check state;
- authorization state;
- deployment version;
- existence or nonexistence of a target;
- expected prior value; and
- policy or schema version.

If the live state no longer matches the reviewed state, the operation SHOULD fail
closed or return for re-evaluation rather than proceed using stale approval.

### Capability Scope and Monotonic Attenuation

An AI component MUST NOT be able to broaden its own filesystem, network, process,
credential, API, mutation, delegation, output, or other effective capabilities
merely by requesting them.

An AI-bearing execution context SHOULD begin with the minimum effective authority
practical for the task.

For an AI-controlled transition from effective capability set `P(n)` to
`P(n+1)`, `P(n+1)` MUST be a subset of or equal to `P(n)`.  AI-controlled
execution MAY voluntarily reduce authority but MUST NOT increase it.

Any increase in effective authority MUST originate from governance or mediation
outside the AI-controlled trust domain and SHOULD begin a new execution context
where practical.

Capability comparisons MUST consider effective authority rather than the number
or names of exposed tools.  A narrow-looking interface that permits arbitrary
shell execution, unrestricted network access, broad mutation, or equivalent
effects carries the authority of those effects.

A delegated child agent or subprocess MUST NOT receive effective authority beyond
that available to the delegating AI-controlled context.

## Fail Closed on Invalid Requests

A deterministic mediator SHOULD reject unsupported, ambiguous, malformed, or
unauthorized consequential requests rather than guessing the model's intent.

If a required invariant cannot be established, the operation SHOULD fail closed.

Error messages MAY provide enough structured information for the AI to revise its
proposal without granting broader authority.

## Structured Interfaces

AI-to-tool interfaces SHOULD prefer structured schemas over free-form executable
text when practical.

Schema validation is evidence that a request has an expected shape.  It does not
replace authorization, semantic validation, or destination-specific checks.

## Scope and Reversibility

AI-assisted changes SHOULD favor narrow scope, small blast radius, explicit
targets, reversible operations, inspectable diffs, and clear recovery paths.

The AI SHOULD NOT introduce unrelated cleanup, architectural change, dependency
updates, or expanded scope merely because those changes appear beneficial.

When material scope is ambiguous, follow the repository's Development Workflow
Governance.

Destructive or difficult-to-reverse operations SHOULD receive stronger validation
and, where appropriate, human approval.

## Bounded Consequence and Aggregate Authority

Narrow permission does not by itself guarantee a narrow blast radius.

AI-assisted systems SHOULD bound the consequence of a plausible single error
across relevant dimensions such as resource count, request rate, transaction
value, fan-out, concurrency, duration, data volume, output destinations, and
reversibility.

Repeated individually permitted actions MUST be evaluated for their aggregate
effect.  Multi-agent or delegated workflows MUST consider aggregate authority
across concurrent agents and descendants rather than evaluating each agent in
isolation.

Where consequence warrants, deterministic controls SHOULD provide quotas, rate
limits, transaction ceilings, bounded fan-out, bounded concurrency, staged
rollout, circuit breakers, snapshots, rollback, or equivalent containment.

## Safety Controls and Delivery Velocity

AI can generate changes faster than humans or conventional verification pipelines
can meaningfully inspect them.  Safety architecture SHOULD account for that
asymmetry rather than assume that routine human review will scale with generation
speed.

The safe workflow SHOULD be practical enough that normal delivery pressure does
not create a persistent incentive to bypass it.

Implementations SHOULD reduce avoidable verification latency through deterministic
pre-fixing, incremental analysis, changed-scope analysis, trustworthy caching,
parallel execution, targeted checks, or staged verification when those techniques
preserve the required assurance.

A faster workflow MUST NOT obtain its speed merely by silently reducing required
assurance, skipping applicable controls, weakening acceptance criteria, or
treating an incomplete check as complete.

When cached or incremental verification is used, deterministic invalidation rules
SHOULD establish whether prior evidence remains applicable.

## Confidence Values and Policy Gates

AI-generated confidence values MUST NOT be interpreted as calibrated probabilities
unless calibration has been demonstrated for the specific use.

A confidence score MAY be useful for triage, prioritization, or communicating
uncertainty.

Confidence MUST NOT override deterministic policy gates, missing evidence,
authorization requirements, stale-state checks, blocking findings, or other hard
preconditions.

Where confidence affects consequential behavior, deterministic code SHOULD apply
configured bounds, caps, or eligibility rules so a model cannot authorize an
operation merely by asserting greater certainty.

## Human Oversight

Human review SHOULD be proportional to consequence rather than required for every
AI-assisted action.

Human judgment is especially important when a decision depends on product intent,
organizational priorities, legal interpretation, ethical judgment, acceptance of
residual risk, architectural tradeoffs, compatibility policy, irreversible
consequences, or unresolved ambiguity.

Human approval MUST NOT be treated as proof that a technical control is correct.

Deterministic containment SHOULD complement rather than be replaced by human
oversight where practical.

Human attention is a scarce safety resource.  Humans SHOULD NOT be used as routine
checksums for properties that deterministic systems can establish more reliably
and economically.

Every consequential AI workflow MUST have an identifiable human or organizational
owner appropriate to the scope of delegated authority.  Delegating execution,
reasoning, or operational discretion to AI MUST NOT be treated as delegating away
accountability for granting and governing that authority.

An AI system's unpredictability does not reduce the need for accountable
ownership.  Greater uncertainty about behavior SHOULD instead motivate narrower
authority, stronger containment, and stronger verification.

## AI-Generated Code and Documentation

AI-generated code is maintained code and MUST satisfy the same applicable coding,
architecture, documentation, compatibility, testing, security, and review
standards as human-written code.

AI-generated documentation is maintained documentation when committed or
published.

Generated documentation SHOULD be checked against actual behavior, governing ADRs,
public interfaces, and source material.

A generated summary MUST NOT silently change the meaning of the authoritative
source it summarizes.

Once accepted into a maintained system, generated code becomes ordinary maintained
code.  AI provenance does not reduce ownership, maintainability, documentation,
security, operability, compatibility, or verification obligations.

When an AI-generated artifact exceeds realistic human review capacity, human
approval MUST NOT be represented as evidence that the artifact was exhaustively
inspected.  The workflow SHOULD compensate with decomposition, independent tests,
static analysis, architectural constraints, bounded execution, staged rollout, or
other evidence appropriate to consequence.

## Testing AI-Assisted Work

AI-assisted changes SHOULD receive the same project-owned test and verification
process as equivalent human-authored changes.

Additional evidence MAY be warranted when the model influences a consequential
boundary.

Relevant checks MAY include regression tests, negative tests, generated-artifact
tests, static analysis, schema validation, adversarial inputs, diff-scope review,
governance review, mediator tests, and tests demonstrating that unsupported
capability requests are rejected.

Passing tests remain scoped evidence rather than proof of complete correctness.

When the same AI materially influences both an implementation and its tests, the
tests SHOULD be treated as potentially sharing the implementation's assumptions.
Independent project-owned tests, requirements-derived tests, deterministic
analysis, or other differently failing evidence SHOULD be added when consequence
warrants.

## Testing Deterministic Mediators

Deterministic mediators SHOULD receive direct automated tests when they protect
material side effects.

Tests SHOULD cover, as applicable:

- allowed requests;
- rejected operation types;
- malformed requests;
- unauthorized targets;
- traversal attempts;
- disallowed network destinations;
- command argument boundaries;
- missing authorization;
- size and resource limits;
- timeout behavior;
- symbolic-link or path edge cases;
- partial failure;
- fail-closed behavior; and
- audit output that avoids secret disclosure.

The model itself does not need to behave deterministically for these controls to
be tested deterministically.

## Disclosure and Handoff

Consequential AI-assisted work SHOULD preserve enough context for another human or
agent to understand what was established and what remains uncertain.

Where material, preserve assumptions, authoritative sources consulted,
observations, verification performed, tests actually run, limitations, unresolved
uncertainty, relevant human decisions, known risks, and deferred follow-up work.

Routine low-risk assistance does not require an exhaustive process transcript.

The purpose is to preserve decision-relevant evidence, not to archive every token
of model reasoning.

## Relationship to Security Standards

This standard and the security corpus are complementary.

This standard focuses on model fallibility, epistemic discipline, verification,
uncertainty, mediated execution, and the safe conversion of AI recommendations
into effects.

The security corpus remains authoritative for identity, authorization, taint,
least capability, credentials, trust boundaries, source-to-sink validation,
containment, threat modeling, evidence, and residual risk.

AI workflows that cross security-sensitive boundaries MUST follow the applicable
security standards.

Relevant security commandments include SEC-01, SEC-02, SEC-03, SEC-04, SEC-05,
SEC-06, SEC-07, SEC-09, SEC-10, SEC-11, and SEC-12.

## Relationship to Development Workflow

Development Workflow Governance remains authoritative for task scope, backlog
capture, ambiguity, commits, pull requests, review readiness, and scope control.

AI assistance MUST NOT be used as a reason to bypass those controls.

## Relationship to Testing

The General Testing Standard remains authoritative for test architecture,
determinism, public artifact verification, CI result publication, and evidence
semantics.

This standard adds AI-specific guidance about what should be verified and how
model-generated conclusions should relate to evidence.

## Examples

The non-normative
[AI Safety Examples](../../examples/general/ai/safety.md)
show how these principles apply to hallucination, stale state, source grounding,
deterministic network and filesystem mediation, constrained process execution,
publication boundaries, capability expansion, and human judgment.

## Review Checklist


Before relying on AI-assisted work for a material engineering outcome, review as
applicable:

- [ ] Observations are distinguishable from inferences and assumptions.
- [ ] Material claims are grounded in current or authoritative evidence.
- [ ] No evidence-producing action is claimed unless it actually occurred.
- [ ] Unknown information has not been replaced with plausible invention.
- [ ] Current state was refreshed where correctness depends on freshness.
- [ ] Material assumptions are visible and verified where consequence warrants.
- [ ] Dependent conclusions were revisited when upstream premises changed.
- [ ] Verification depth is proportional to consequence and uncertainty.
- [ ] Evidence is reasonably independent of the failure mode it should detect.
- [ ] Authoritative objectives and acceptance criteria were not silently changed to make the AI's output pass.
- [ ] AI-generated tests are not the sole evidence where they plausibly share the implementation's failure mode.
- [ ] Required workflow sequencing and authoritative success state are owned by deterministic orchestration where practical.
- [ ] Tool output is interpreted only as broadly as the result supports.
- [ ] Behavioral instructions are not being mistaken for enforced safety boundaries.
- [ ] Arbitrary network initiation is absent from the AI reasoning component.
- [ ] Unrestricted filesystem access is absent where deterministic mediation can provide the required data or mutation.
- [ ] AI-facing mutation tools express semantic intent rather than unnecessarily broad destructive primitives.
- [ ] Filesystem mutations carry appropriate preconditions and postconditions.
- [ ] Repository mutations receive diff validation before consequential use.
- [ ] Arbitrary shell execution is absent where named operations can express the work.
- [ ] Credentials remain outside the reasoning component where practical.
- [ ] External mutation crosses deterministic validation and authorization.
- [ ] The AI cannot broaden its own capabilities.
- [ ] AI-controlled capability transitions preserve or reduce effective authority.
- [ ] Delegated child agents and subprocesses do not receive greater effective authority than their parent context.
- [ ] Aggregate rate, fan-out, concurrency, duration, value, and other blast-radius dimensions are bounded where consequence warrants.
- [ ] Invalid or ambiguous consequential requests fail closed.
- [ ] Changes remain narrow, reviewable, and reversible where practical.
- [ ] Human review is present where human judgment is required.
- [ ] Human attention is not being used as a routine substitute for deterministic verification.
- [ ] Consequential AI workflows retain an identifiable accountable human or organizational owner.
- [ ] Verification latency has been reduced through safe optimization rather than by silently weakening assurance.
- [ ] AI-generated code and documentation meet normal project standards.
- [ ] Tests and deterministic checks provide scoped evidence for material claims.
- [ ] AI-generated output remains untrusted after persistence, caching, transfer, or reuse.
- [ ] Deterministic equivalence is not being mistaken for proof that a prior semantic judgment was correct.
- [ ] Evidence completeness, truncation, and retrieval failure are explicit where material.
- [ ] Prohibited capabilities are enforced structurally in the component boundary where practical.
- [ ] Durable AI-derived state is validated and persisted by deterministic code where practical.
- [ ] Evidence-plane content cannot redefine control-plane policy or capabilities.
- [ ] Mutable live state is revalidated immediately before consequential mutation.
- [ ] AI-facing output interfaces expose semantic results rather than unnecessarily broad storage or transport primitives.
- [ ] Confidence values do not override deterministic gates or masquerade as calibrated probabilities.
- [ ] Material uncertainty, limitations, and residual risk remain visible.

## Governing Principle

AI systems are useful reasoning tools and unreliable authorities.

Use them to propose, interpret, compare, and assist.  Require independent evidence
for material claims.  Keep authoritative objectives, permission expansion,
workflow success, and consequential side effects outside the AI-controlled trust
domain.  Use deterministic systems for enforceable rules, bound the consequence
of plausible mistakes, make the safe path practical enough to survive delivery
pressure, and retain accountable human or organizational ownership for delegated
authority.
