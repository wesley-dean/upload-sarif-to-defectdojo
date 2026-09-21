# Clean Coding Standard

## Purpose

Code should communicate its intent clearly, minimize unnecessary complexity, and make behavior straightforward to understand, test, modify, and review.

This standard establishes general principles for writing and modifying code.  It applies across programming languages unless a language-specific or project-specific standard establishes a more appropriate rule.

These principles are influenced by Robert C. Martin's *Clean Code*, Bertrand Meyer's Command-Query Separation principle, and related software design practices.  They are used here as engineering guidelines rather than as an assertion that every recommendation from those sources applies universally.

## Precedence

Repository-specific requirements, accepted Architecture Decision Records (ADRs), documented interfaces, compatibility requirements, and language-specific standards take precedence over this general standard.

Do not perform unrelated refactoring solely to bring existing code into compliance with this standard unless that work is part of the requested scope.

## Functions Should Do One Thing

A function should have one clearly identifiable responsibility.

The operations inside a function should contribute directly to that responsibility.  If describing the function accurately requires combining multiple independent actions with words such as "and" or "then," consider whether those actions belong in separate functions.

Prefer:

```text
validate_configuration()
load_configuration()
write_configuration()
```

over:

```text
validate_load_and_write_configuration()
```

This does not mean that a function may contain only one statement or invoke only one other function.  A higher-level function may coordinate several lower-level operations when that coordination is itself the function's single responsibility.

For example:

```text
deploy_application()
    validate_configuration()
    build_application()
    publish_application()
```

The responsibility of `deploy_application()` is deployment.  The implementation details are delegated to functions operating at a lower level of abstraction.

### Practical test

When reviewing a function, ask:

> What does this function do?

A concise answer describing one responsibility is a good indication that the function is appropriately focused.

If the answer becomes a list of substantially independent activities, the function should be examined for possible decomposition.

## Separate Commands from Queries

Follow the principle of **Command-Query Separation (CQS)** where practical.

A function should normally behave as either:

- a **query**, which returns information without changing observable state; or
- a **command**, which changes state without also being used to obtain information about that state.

Prefer:

```text
exists = user_exists(username)

if ! exists:
    create_user(username)
```

over an interface conceptually similar to:

```text
created = create_user_if_missing(username)
```

when the return value ambiguously represents both an action and a question.

Separating commands from queries makes code easier to reason about because a caller can determine whether an operation changes state from the operation's interface and purpose.

### Exceptions

Command-Query Separation is a design principle rather than an absolute prohibition.

Some APIs legitimately return information about an operation they perform, such as:

- a newly created object's identifier;
- the number of records changed;
- an operating system status code;
- an error or result describing whether the command succeeded; or
- a value that cannot reasonably be obtained separately without introducing race conditions or unnecessary work.

When combining mutation and returned information is necessary, make the behavior explicit in the function's name, interface, documentation, or established language conventions.

Avoid surprising side effects.

## Maintain One Level of Abstraction

Statements within a function should generally operate at a consistent level of abstraction.

Avoid mixing high-level business or workflow logic with low-level implementation details.

Prefer:

```text
prepare_release()
    validate_release()
    build_artifacts()
    generate_attestations()
    publish_release()
```

over:

```text
prepare_release()
    validate_release()
    mkdir(...)
    open(...)
    calculate_hash(...)
    encode_json(...)
    invoke_http_request(...)
```

The lower-level operations may be perfectly appropriate, but they usually belong behind functions whose names express why those operations are being performed.

A reader should be able to understand the primary flow of a function without first understanding every implementation detail beneath it.

## Make Side Effects Explicit

Functions should not unexpectedly modify state.

Potential side effects include:

- modifying global variables;
- changing files;
- changing environment variables;
- modifying passed objects or data structures;
- altering persistent storage;
- changing process state;
- performing network operations;
- creating external resources; and
- changing configuration.

When side effects are necessary, make them evident through naming, documentation, interfaces, or established conventions.

A function that appears to retrieve information should not unexpectedly modify the system as part of retrieving it.

## Use Descriptive Names

Names should describe purpose rather than implementation mechanics whenever practical.

Prefer names such as:

```text
load_configuration
validate_repository
calculate_checksum
publish_release
```

over vague names such as:

```text
process
handle
run
do_work
manage
```

A good function name should reduce the amount of implementation code a reader must inspect before understanding why the function exists.

Names should also communicate meaningful side effects when those effects would otherwise be surprising.

## Prefer Explicit Behavior

Code should favor clarity over cleverness.

Do not compress code merely to minimize line count.  Prefer structures whose behavior can be understood by a developer unfamiliar with the implementation.

Avoid requiring the reader to infer important behavior from:

- undocumented side effects;
- obscure language features;
- hidden global state;
- ambiguous return values;
- excessive nesting;
- implicit ordering dependencies; or
- unnecessarily dense expressions.

Concise code is useful when it remains clear.  Brevity is not itself a measure of quality.

## Keep Interfaces Focused

Functions should accept the information required to perform their responsibility and avoid unnecessary parameters.

A large or continually growing parameter list can indicate that:

- the function has multiple responsibilities;
- related data should be represented by a cohesive structure;
- internal implementation details are leaking through the interface; or
- the abstraction is incorrectly defined.

Do not create a data structure solely to reduce the apparent number of arguments.  The resulting abstraction should represent a meaningful concept.

Boolean arguments deserve particular scrutiny because calls such as:

```text
render_report(true, false)
```

provide little information about what the arguments mean.

Prefer explicit interfaces when practical.

## Keep Control Flow Understandable

Prefer straightforward control flow.

When possible:

- handle invalid or exceptional conditions early;
- minimize unnecessary nesting;
- keep the primary execution path visible;
- extract complex conditions into appropriately named functions or variables; and
- separate policy decisions from implementation mechanics.

A reader should be able to identify the major decisions and execution path without mentally simulating the entire function.

## Avoid Unnecessary Duplication

Do not maintain multiple independent implementations of the same rule or algorithm without a reason.

Duplication is particularly dangerous when the duplicated code represents:

- validation rules;
- security policy;
- business rules;
- configuration interpretation;
- compatibility behavior; or
- calculations that must remain consistent.

However, similar-looking code is not automatically the same abstraction.

Do not create premature abstractions merely to eliminate a few repeated lines.  Prefer duplication over an incorrect abstraction when the concepts are not genuinely the same.

## Comments Explain Why

Code should communicate what it does through its structure, names, and interfaces whenever practical.

Comments and documentation should provide information that the code cannot adequately communicate itself, particularly:

- why a decision was made;
- constraints affecting the implementation;
- non-obvious behavior;
- security considerations;
- compatibility requirements;
- external requirements;
- important assumptions; and
- references to ADRs or other governing documentation.

Do not use comments as a substitute for making unnecessarily confusing code understandable.

## Errors Are Part of the Interface

Error behavior should be deliberate.

A function should make failures visible according to the conventions of its language and project.

Do not silently ignore errors unless ignoring the error is intentional, safe, and evident from the surrounding context.

Error handling should preserve sufficient context to determine:

- what operation failed;
- why it failed, when known; and
- what the caller can reasonably do about the failure.

## Optimize for Reading

Code is generally read more often than it is written.

Optimize primarily for the developer who must understand the code later, including a developer who did not write it.

That developer may be:

- another contributor;
- a reviewer;
- an operator investigating an incident;
- an automated development agent; or
- the original author months or years later.

Prefer code whose purpose and behavior can be determined locally without requiring unnecessary exploration of the codebase.

## Guidance for Automated Agents

When generating, modifying, or reviewing code:

1. Identify the responsibility of each function being changed.
2. Avoid introducing functions with multiple independent responsibilities.
3. Separate state-changing commands from observational queries when practical.
4. Keep each function at a reasonably consistent level of abstraction.
5. Make side effects and state changes visible.
6. Prefer descriptive names over generic names.
7. Preserve straightforward control flow.
8. Avoid introducing unnecessary parameters or ambiguous Boolean arguments.
9. Remove duplication when the duplicated code represents the same underlying concept.
10. Do not create abstractions solely to eliminate superficial similarity.
11. Treat error behavior as part of the function's contract.
12. Prefer readability and inspectability over cleverness or minimal line count.
13. Preserve existing public interfaces and compatibility requirements unless the requested work explicitly changes them.
14. Follow repository governance, ADRs, and language-specific standards when they differ from this general guidance.
15. Do not expand the scope of a change merely to clean unrelated existing code.

When a requested implementation appears to conflict with these principles, prefer an implementation that satisfies both the requested behavior and this standard.  If a material conflict cannot be resolved without changing an established contract, architecture, or requirement, identify the conflict rather than silently changing that contract.

## Review Questions

When reviewing code, consider:

- Can I describe each function's responsibility in one concise statement?
- Does a function both ask a question and change state unexpectedly?
- Are important side effects evident?
- Does the function stay at a reasonably consistent level of abstraction?
- Do names describe intent?
- Is the primary control flow easy to follow?
- Are errors handled deliberately?
- Does duplicated code represent genuinely duplicated knowledge?
- Would extracting code create a meaningful abstraction or merely move lines elsewhere?
- Can another developer understand the reason for unusual implementation decisions?
- Is the code more complex than the problem requires?

These questions are heuristics.  They should support engineering judgment rather than replace it.

## Examples

Language-specific examples demonstrating applications of this standard are maintained separately:

- [Bash examples](../examples/general/clean-coding/bash.md)

Examples are illustrative rather than normative.  Where an example conflicts with this standard, this standard governs.

## Further Reading

The following sources provide additional background for the principles described in this standard:

- Robert C. Martin, *Clean Code: A Handbook of Agile Software Craftsmanship*.  In particular, see the material concerning functions, naming, comments, formatting, error handling, and software design principles.
- Bertrand Meyer, *Object-Oriented Software Construction*.  Meyer introduced the Command-Query Separation principle.
- Martin Fowler, "Command Query Separation."  Fowler provides a concise explanation of CQS, its purpose, and situations in which strict separation may not be desirable.
- Robert C. Martin's writings on the Single Responsibility Principle and the SOLID design principles.
- Architecture Decision Records maintained by the project for decisions that constrain or intentionally depart from general coding guidance.

## Summary

Prefer code that:

- does one thing at a time;
- separates questions from state changes;
- maintains consistent levels of abstraction;
- makes side effects visible;
- names things according to their purpose;
- favors explicit, readable behavior;
- handles errors deliberately; and
- minimizes the amount of context required to understand it.

Clean code is not code that conforms mechanically to a collection of rules.  It is code whose purpose, behavior, constraints, and consequences are readily understandable by the people and systems responsible for maintaining it.
