# Clean Architecture Standard

## Purpose

Software architecture should protect the core behavior and policies of a system from unnecessary dependence on frameworks, infrastructure, delivery mechanisms, persistence technologies, and other implementation details.

This standard establishes general architectural principles for structuring software so that important behavior remains understandable, testable, maintainable, and adaptable as external technologies change.

These principles are influenced by Robert C. Martin's *Clean Architecture*, the Dependency Rule, the Stable Dependencies Principle, Hexagonal Architecture, Ports and Adapters, and related approaches to software design.

This standard is authoritative for projects that adopt it.  The referenced architectural approaches provide background and context; they do not override repository-specific requirements or architectural decisions.

## Precedence

Accepted Architecture Decision Records (ADRs), documented interfaces, security requirements, compatibility requirements, platform constraints, and repository-specific architectural standards take precedence over this general standard.

Do not restructure an existing system solely to make it resemble a particular architectural diagram or textbook model.

Architectural changes should be justified by system requirements, maintainability concerns, risk reduction, or established project goals rather than aesthetic preference.

## Architecture Should Express Intent

The structure of a system should communicate what the system does.

Prefer architectures organized around meaningful system capabilities, domain concepts, or use cases rather than primarily around frameworks or technical mechanisms.

For example, a system concerned with invoicing might expose concepts such as:

```text
invoice
customer
payment
billing
tax
```

rather than making the primary structure:

```text
controllers
repositories
database
framework
utils
```

Technical organization may still exist, but the purpose of the system should remain visible.

A developer examining the repository should be able to determine the important responsibilities of the system without first understanding every framework or infrastructure component.

## Follow the Dependency Rule

Source-code dependencies should point toward the parts of the system containing the most important and stable policies.

Core business or application logic should not depend directly on implementation details such as:

- web frameworks;
- database libraries;
- message brokers;
- cloud SDKs;
- user-interface frameworks;
- command-line parsing libraries;
- serialization frameworks;
- logging implementations;
- network clients; or
- vendor-specific services.

Infrastructure may depend on application policy.

Application policy should not depend unnecessarily on infrastructure.

Conceptually:

```text
frameworks
    |
    v
adapters
    |
    v
application
    |
    v
domain
```

Dependencies point inward toward higher-level policy.

The exact number and names of architectural layers are not prescribed by this standard.

The direction of dependency is more important than reproducing a specific diagram.

## Separate Policy from Mechanism

Business rules, workflow decisions, validation policy, and other core behavior should be separated from the mechanisms used to deliver or persist that behavior.

Examples of mechanisms include:

- HTTP;
- command-line interfaces;
- databases;
- files;
- queues;
- email;
- cloud services;
- GUI frameworks; and
- external APIs.

A rule such as:

```text
An invoice may not be finalized without at least one line item.
```

is application or domain policy.

The fact that an invoice is stored in PostgreSQL or submitted through an HTTP endpoint is an implementation mechanism.

The policy should not require knowledge of those mechanisms unless the mechanism itself is genuinely part of the rule.

## Treat Frameworks as Details

Frameworks are tools used by the application.

The application should not become unnecessarily shaped around the framework.

Avoid allowing framework-specific types, annotations, lifecycle rules, or conventions to penetrate deeper into the system than necessary.

Prefer boundary code that translates between framework concepts and application concepts.

For example:

```text
HTTP Request
    |
    v
HTTP Adapter
    |
    v
Application Request
    |
    v
Use Case
```

rather than requiring the use case itself to understand HTTP.

Framework coupling may be acceptable when the cost of abstraction would exceed its benefit.  Such coupling should be deliberate rather than accidental.

## Treat Persistence as a Detail

Core application behavior should not depend unnecessarily on a specific persistence technology.

The application should express what information it needs rather than how that information is stored.

Prefer application-facing abstractions such as:

```text
find_customer()
save_invoice()
load_configuration()
```

over business logic that directly constructs database queries or manipulates storage-specific records.

Persistence adapters may translate between application models and database representations.

This does not require every project to implement a repository pattern, ORM abstraction, or custom persistence framework.

Introduce abstractions when they protect meaningful policy or improve testability, maintainability, or portability.

Do not create abstractions solely because an architectural pattern says that one should exist.

## Keep External Systems at Boundaries

External services should normally be accessed through explicit boundaries.

Examples include:

- payment providers;
- authentication systems;
- email services;
- cloud storage;
- source-control platforms;
- ticketing systems;
- third-party APIs; and
- operating-system services.

Core behavior should depend on an interface representing the capability it needs rather than directly on a vendor-specific implementation when that distinction is meaningful.

Conceptually:

```text
Application
    |
    v
Payment Service Interface
    ^
    |
Stripe Adapter
```

The application depends on the capability.

The adapter depends on the external provider.

## Use Dependency Inversion at Architectural Boundaries

When high-level policy needs a capability supplied by a lower-level implementation, define the dependency in terms of the needs of the higher-level policy.

For example:

```text
Application Policy
        |
        v
Notification Interface
        ^
        |
SMTP Adapter
```

The application defines or owns the contract it requires.

The implementation satisfies that contract.

This prevents core policy from depending directly on lower-level implementation details.

Do not introduce dependency inversion mechanically.  Use it where a dependency crosses a meaningful architectural boundary or where substitutability, isolation, testing, or changeability provides practical value.

## Keep Boundaries Explicit

Architectural boundaries should be visible in the codebase.

A boundary may be represented through:

- interfaces;
- functions;
- modules;
- packages;
- processes;
- services;
- message schemas;
- data-transfer objects; or
- other explicit contracts.

The representation should be appropriate to the language and system.

A boundary should clarify:

- what crosses it;
- in which direction dependencies flow;
- who owns the contract;
- what behavior is expected; and
- what implementation details are intentionally hidden.

Hidden or informal boundaries are difficult to enforce.

## Keep Boundary Data Deliberate

Data crossing an architectural boundary should be represented in forms appropriate to that boundary.

Avoid leaking infrastructure-specific objects deeply into application code.

Examples include:

- database rows;
- ORM entities;
- HTTP request objects;
- framework contexts;
- vendor SDK objects;
- serialization-specific classes; and
- UI widgets.

Translate these into application-appropriate representations where the separation provides meaningful architectural value.

Do not create redundant translation layers when the boundary is trivial and provides no practical isolation.

## Keep Use Cases Focused

Application behavior should be organized around meaningful operations or use cases.

Examples might include:

```text
create_invoice
approve_payment
register_user
publish_release
rotate_credentials
generate_report
```

A use case should coordinate the policy required to accomplish a meaningful system action.

It may invoke domain behavior, persistence interfaces, external-service interfaces, and other collaborators.

A use case should not ordinarily contain low-level framework or infrastructure mechanics.

## Keep Core Policy Testable

Important application behavior should be testable without requiring unnecessary external infrastructure.

Core tests should not require a real:

- database;
- HTTP server;
- cloud environment;
- filesystem;
- message broker;
- external API; or
- GUI

unless the behavior being tested genuinely depends on that mechanism.

Architectural separation should make it possible to test policy independently from infrastructure.

This does not eliminate integration or end-to-end testing.

Infrastructure should also be tested at appropriate boundaries.

## Do Not Let Infrastructure Define the Domain

Database schemas, API payloads, framework models, or vendor objects should not automatically become the system's conceptual model.

The domain model should reflect the concepts and rules that matter to the application.

For example, a database may contain:

```text
invoice_status CHAR(1)
```

while the application may reason about:

```text
Draft
Pending
Paid
Cancelled
```

The storage representation is an implementation detail.

The application concept is part of the system's meaning.

## Prefer Stable Dependencies

Code that changes frequently should generally depend on code that is more stable rather than forcing stable policy to depend on volatile implementation details.

Examples of comparatively volatile components may include:

- external APIs;
- UI frameworks;
- cloud providers;
- database technologies;
- authentication providers;
- deployment environments; and
- third-party libraries.

Examples of comparatively stable components may include:

- core business rules;
- domain concepts;
- application policies; and
- established contracts.

When volatility differs significantly, place the dependency so that changes in volatile components do not unnecessarily propagate into stable policy.

## Isolate Change

Architecture should contain foreseeable change rather than allowing it to spread throughout the system.

When a dependency is expected to vary, consider placing it behind a boundary.

Examples include:

```text
database implementation
payment provider
notification service
authentication mechanism
file format
deployment environment
```

However, do not introduce speculative abstraction around every dependency.

A useful boundary protects against a realistic form of change, isolates a significant implementation detail, or makes important behavior easier to test and understand.

## Avoid Premature Abstraction

Clean Architecture does not require maximum indirection.

Do not create:

- an interface for every class;
- a repository for every data structure;
- an adapter for every function;
- a service layer that merely forwards calls;
- unnecessary DTO transformations;
- empty abstraction layers; or
- abstractions that exist solely to satisfy a diagram.

Each architectural boundary should have a reason to exist.

A boundary is justified when it protects policy, isolates volatility, improves testability, establishes a meaningful contract, or prevents inappropriate coupling.

Abstraction without purpose increases complexity.

## Avoid Circular Dependencies

Architectural components should not form dependency cycles.

For example:

```text
A -> B -> C -> A
```

creates coupling that makes the components difficult to reason about, test independently, and change safely.

When a cycle appears, examine whether:

- responsibilities are incorrectly divided;
- a shared abstraction is missing;
- dependency inversion is appropriate;
- a component contains multiple concerns; or
- the purported architectural boundary is not meaningful.

Cycles across major architectural boundaries should be treated as design problems unless explicitly justified.

## Keep Direction of Control Separate from Direction of Dependency

Runtime control flow and source-code dependency do not need to point in the same direction.

For example, an application may invoke persistence behavior at runtime:

```text
Use Case
    |
    v
Database
```

while the source-code dependency is inverted:

```text
Use Case
    |
    v
Persistence Interface
    ^
    |
Database Adapter
```

The use case controls the operation.

The database adapter implements the application's required interface.

This distinction is fundamental to maintaining architectural boundaries.

## Separate Delivery from Application Behavior

Delivery mechanisms should adapt external input into application operations.

Delivery mechanisms may include:

- HTTP controllers;
- CLI commands;
- GUI events;
- scheduled jobs;
- message consumers; and
- serverless handlers.

They should generally be responsible for concerns such as:

- parsing input;
- authentication context;
- protocol validation;
- translating external representations;
- invoking application behavior; and
- presenting results.

They should not become the primary location for business rules.

Prefer:

```text
CLI Handler
    |
    v
CreateInvoice Use Case
```

rather than embedding invoicing policy directly into command-line parsing code.

## Keep Infrastructure Replaceable Where It Matters

A well-separated system should permit important implementation details to change without rewriting core application policy.

Possible substitutions might include:

```text
PostgreSQL -> SQLite
SMTP -> API-based email
CLI -> HTTP service
Local filesystem -> Object storage
Vendor A -> Vendor B
```

This does not mean every implementation detail must actually be interchangeable.

Replaceability is primarily evidence that architectural dependencies have been separated appropriately.

Do not build unused interchangeable implementations merely to demonstrate flexibility.

## Preserve Domain Language

Core application code should use terminology that reflects the problem domain.

Prefer:

```text
invoice
customer
subscription
release
credential
repository
```

over framework-centric terms where domain terminology would communicate intent more clearly.

Shared terminology between software, documentation, requirements, and domain experts reduces translation cost and misunderstanding.

## Make Architecture Inspectable

Architectural intent should be discoverable from the repository.

Important architectural decisions should be documented through appropriate mechanisms, including:

- directory structure;
- module boundaries;
- interfaces;
- README documentation;
- architecture documentation; and
- Architecture Decision Records.

When the reason for an architectural boundary is non-obvious, document it.

Do not rely solely on institutional memory.

## Record Meaningful Architectural Decisions

Use an ADR when introducing or materially changing architecture involving:

- major component boundaries;
- dependency direction;
- external integrations;
- security boundaries;
- persistence strategy;
- communication mechanisms;
- public interfaces;
- compatibility commitments;
- deployment architecture; or
- other consequential design decisions.

An ADR should capture the context, decision, alternatives, tradeoffs, consequences, and relevant assumptions.

Architectural intent that affects future implementation should be durable and reviewable.

## Preserve Existing Contracts

Architectural cleanup should not silently change established behavior.

Before modifying a boundary, identify relevant:

- public interfaces;
- data formats;
- error behavior;
- security expectations;
- compatibility requirements;
- persistent data;
- external integrations; and
- accepted ADRs.

A cleaner internal architecture does not justify an unapproved external behavior change.

## Guidance for Automated Agents

When generating, modifying, or reviewing software:

1. Identify the core application or domain policy involved in the requested change.
2. Identify frameworks, infrastructure, persistence, delivery mechanisms, and external services involved.
3. Keep core policy independent of implementation details where practical.
4. Ensure dependencies across architectural boundaries point toward higher-level policy.
5. Introduce interfaces at meaningful boundaries when inversion protects important behavior or isolates significant volatility.
6. Keep framework-specific and vendor-specific types near the boundaries where they are used.
7. Avoid placing business rules in controllers, handlers, persistence adapters, or framework glue.
8. Keep use cases focused on meaningful application operations.
9. Prefer domain terminology over infrastructure terminology in core code.
10. Preserve explicit architectural boundaries already established by the repository.
11. Respect accepted ADRs and documented architectural constraints.
12. Do not introduce abstraction solely to imitate a Clean Architecture diagram.
13. Do not introduce interfaces, adapters, repositories, or layers unless they serve a concrete architectural purpose.
14. Avoid circular dependencies.
15. Preserve existing public interfaces and compatibility requirements unless the requested work explicitly changes them.
16. Do not perform unrelated architectural refactoring outside the requested scope.
17. When a requested change materially alters architecture, identify whether an ADR is required.
18. When existing architecture conflicts with this standard, do not silently restructure it.  Identify the conflict and follow repository governance.

## Review Questions

When reviewing architecture, consider:

- Can I identify the core policies of the system?
- Does the repository structure communicate what the system does?
- Do core policies depend unnecessarily on frameworks or infrastructure?
- Do dependencies point toward more stable policy?
- Are external systems isolated behind meaningful boundaries?
- Are framework-specific objects leaking into core application logic?
- Are business rules implemented in delivery or persistence code?
- Are architectural boundaries explicit and understandable?
- Does each abstraction have a concrete reason to exist?
- Are there circular dependencies?
- Can important application behavior be tested without unnecessary infrastructure?
- Could a volatile implementation detail be changed without rewriting core policy?
- Does the architecture preserve domain terminology?
- Are meaningful architectural decisions documented?
- Is the architecture more complicated than the requirements justify?

These questions are heuristics.  They support engineering judgment rather than replace it.

## Common Warning Signs

The following conditions may indicate architectural problems:

- controllers containing substantial business logic;
- domain objects importing framework classes;
- use cases constructing SQL directly;
- application policy depending on cloud SDKs;
- vendor-specific objects passed throughout the application;
- circular dependencies between major components;
- framework upgrades requiring widespread changes to core policy;
- tests of business rules requiring full infrastructure startup;
- directories organized entirely around technical mechanisms;
- interfaces that exist only because every class was given one;
- adapters that merely forward calls without isolating anything meaningful;
- business terminology replaced by framework terminology; and
- significant architectural behavior that exists only as undocumented convention.

These are indicators for investigation rather than automatic defects.

## Further Reading

The following sources provide additional background for the principles described in this standard:

- Robert C. Martin, *Clean Architecture: A Craftsman's Guide to Software Structure and Design*.  In particular, see the discussion of the Dependency Rule, boundaries, use cases, entities, dependency inversion, and the separation of policy from implementation details.
- Robert C. Martin's writings on the Stable Dependencies Principle, Stable Abstractions Principle, and SOLID principles.
- Alistair Cockburn, "Hexagonal Architecture," also known as Ports and Adapters.
- Jeffrey Palermo, writings on Onion Architecture.
- Eric Evans, *Domain-Driven Design*, particularly where domain modeling and ubiquitous language intersect with architectural boundaries.
- Architecture Decision Records maintained by the project for decisions that govern or intentionally depart from general architectural guidance.

## Summary

Prefer architecture that:

- makes the system's purpose visible;
- separates policy from implementation mechanisms;
- points dependencies toward higher-level, more stable policy;
- treats frameworks, databases, and external services as implementation details;
- keeps architectural boundaries explicit;
- protects core behavior from unnecessary infrastructure coupling;
- isolates meaningful volatility;
- preserves domain language;
- remains testable without unnecessary external systems;
- documents consequential decisions; and
- introduces abstraction only when the abstraction serves a concrete purpose.

Clean Architecture is not the reproduction of a particular set of concentric circles or a prescribed number of layers.

Its central concern is protecting important software policy from unnecessary dependence on details that are more likely to change.
