# JavaScript Documentation Standard

This document defines the normative source-documentation standard for maintained
JavaScript files in projects that adopt it.  The standard deliberately prefers
verbose, explanatory documentation.  Source brevity is not a goal when brevity
would force a future maintainer to infer intent, contracts, assumptions, failure
semantics, state ownership, compatibility constraints, security boundaries, or
architectural relationships from executable code alone.

This standard uses JavaScript-native JSDoc comments as the maintained source of
truth.  It is intentionally compatible with JSDoc tooling and is designed to
support Doxygen reference generation through the
[`javascript-doxygen`](https://github.com/wesley-dean/javascript-doxygen) input
filter where translation is required.

The standard does not require maintainers to write a second Doxygen-specific
comment dialect beside JSDoc.  Maintained JavaScript should remain idiomatic
JavaScript, and compatibility translation belongs at the documentation-generation
boundary.

Prefer thorough, detailed commentary over terse tag-only documentation.  The goal
is for the source to remain understandable to a human new to the project and to an
AI/LLM operating with focused context that may not retain the complete project
history.

## Precedence

Repository-specific requirements, accepted Architecture Decision Records (ADRs),
documented public interfaces, compatibility requirements, security requirements,
and project-specific JavaScript standards take precedence over this standard.

Do not perform unrelated documentation rewrites or refactoring solely to bring
existing code into compliance unless that work is part of the requested scope.

## Maintained Source of Truth

JSDoc comments are the maintained source of truth for generated JavaScript API
reference documentation.

Do not maintain a second Doxygen-specific documentation block beside a JSDoc
comment.  Do not duplicate parameter, return, exception, yield, type, or behavioral
contracts merely to satisfy Doxygen.

The maintained source should remain consumable by JavaScript-native tooling without
first passing through `javascript-doxygen`.

`javascript-doxygen` exists at the documentation-generation boundary.  It may
translate governed JSDoc forms into a Doxygen-friendly representation without
changing JavaScript into another maintained source language.

Conceptually:

```text
maintained JavaScript source
        |
        | JSDoc comments
        v
 javascript-doxygen
        |
        | Doxygen-compatible translated representation
        v
      Doxygen
```

The generated representation is derivative.  It is not a maintained source of
truth and must not be edited as though it were authoritative documentation.

## JSDoc Comment Syntax

Documentation comments must use JSDoc-style blocks beginning with exactly `/**`:

```javascript
/**
 * Describe the documented element.
 */
```

Place a documentation block immediately before the declaration or element it
documents unless a specific JSDoc construct intentionally documents a virtual or
otherwise non-adjacent symbol.

Use a concise summary followed by a blank line and substantive explanatory prose
when more context is required:

```javascript
/**
 * Load and validate application configuration.
 *
 * Explain the boundary owned by this function, validation policy, caller-visible
 * failure behavior, side effects, and assumptions that callers must preserve.
 */
```

Documentation lines should normally remain within the project's configured line
length.  When no stricter project rule exists, prefer 80-character documentation
lines where practical.  Long URLs, literal values, generated identifiers, type
expressions, and other unbreakable content may exceed that limit.

Ordinary `/* ... */` comments and `//` comments are not substitutes for JSDoc when
an API element requires structured documentation.

## Baseline Tag Vocabulary

The baseline structured vocabulary should use standard JSDoc tags wherever
practical.  The core contract tags are:

```text
@param
@returns
@throws
@yields
@type
@typedef
@callback
@property
@see
@deprecated
```

Other standard JSDoc tags may be used when they communicate information that
belongs in the maintained contract.  Projects may establish narrower or broader
tag policies through repository-specific governance.

A tag should communicate information that belongs in the source contract.  Do not
add tags merely because a documentation engine recognizes them.

## Type Expressions

JSDoc type expressions must be enclosed in braces when a tag carries an explicit
type:

```text
{string}
{number}
{Configuration}
{Promise<Configuration>}
{Array<Record>}
{string|URL}
```

Use the project's established JSDoc type-expression conventions consistently.
The documentation type must not contradict the executable contract.

JavaScript's runtime does not enforce JSDoc types.  Static validation, where
required, belongs to configured JavaScript tooling such as TypeScript in
check-JavaScript mode, Closure tooling, ESLint plugins, or other project-specific
analysis.

This standard does not define TypeScript or TSDoc documentation.  A project whose
maintained source is TypeScript should adopt a TypeScript-specific documentation
standard rather than assuming this JavaScript standard applies unchanged.

## Functions and Methods

Maintained public and non-trivial functions and methods must document their
interface and non-obvious behavior sufficiently for a caller to use them without
reading the implementation.

A complete function JSDoc block should generally look like:

```javascript
/**
 * Load and validate application configuration.
 *
 * Reads the requested configuration document and validates it before returning
 * an application configuration object.  The function does not modify the source
 * file.
 *
 * @param {string} path - Path to the configuration document.
 * @param {boolean} [strict=true] - Whether unknown keys are rejected.
 * @returns {Promise<Configuration>} Validated configuration owned by the caller.
 * @throws {TypeError} If `path` is not a non-empty string.
 */
async function loadConfiguration(path, strict = true) {
    // implementation
}
```

Document parameters in declaration order when practical.

### Parameters

Use one `@param` tag for each meaningful documented parameter.

The canonical required-parameter form is:

```text
@param {Type} name - Description.
```

For example:

```text
@param {string} path - Filesystem path interpreted relative to the project root.
```

The type expression is enclosed in braces, followed by the parameter name, a
space-hyphen-space separator, and substantive description text.

The hyphen is part of the preferred maintained-source form because it clearly
separates the parameter declaration from descriptive prose and follows ordinary
JSDoc usage.

Optional parameters use square brackets around the parameter name:

```text
@param {boolean} [strict] - Whether unknown keys are rejected.
```

When a meaningful default belongs in the documentation contract, it may be
included in the bracketed name:

```text
@param {boolean} [strict=true] - Whether unknown keys are rejected.
```

Do not document a parameter as optional merely because the implementation happens
to tolerate `undefined`; optionality is part of the caller-visible contract.

Parameter descriptions should explain meaning that the type alone cannot express,
including as applicable:

- allowed values or ranges;
- units;
- sentinel meanings such as `null` or `undefined`;
- mutability and ownership;
- whether an object or array may be modified;
- path interpretation;
- encoding assumptions;
- ordering requirements;
- callback lifecycle;
- whether a callback may be retained or invoked asynchronously;
- whether an iterable is consumed; and
- security-sensitive interpretation.

Rest parameters should document the declared rest name and the semantics of the
collected values rather than merely saying "additional arguments."

Destructured parameters require enough documentation to make the caller-visible
shape clear.  Projects may use JSDoc property notation, a named `@typedef`, or
another standard JSDoc form when that communicates the contract more clearly than
an artificial synthetic parameter name.

### Return Values

Use `@returns` for meaningful return values:

```text
@returns {Configuration} Validated configuration owned by the caller.
```

The preferred form is:

```text
@returns {Type} Description.
```

Use `@returns` rather than `@return` in maintained source for consistency, even
though JSDoc recognizes both forms.

The description must explain semantics rather than merely repeat the type.  State
ownership, aliasing, special values, ordering, normalization, caching, laziness,
or other caller-visible behavior when those details matter.

For asynchronous functions, document the resolved value through an appropriate
promise type when type information is part of the maintained contract:

```text
@returns {Promise<Configuration>} Validated configuration owned by the caller.
```

Do not describe the promise itself as the useful result when callers primarily
care about its resolved value and rejection semantics.

A function with no meaningful return value may omit `@returns` unless
project-specific tooling requires explicit documentation.

### Exceptions and Rejections

Use `@throws` for caller-visible errors that form part of the meaningful contract:

```text
@throws {TypeError} If the supplied identifier is not a string.
@throws {RangeError} If the retry count is outside the supported range.
```

Document errors callers are expected to understand, handle, or treat as part of
the stable interface.  Do not enumerate every implementation-level exception that
could theoretically escape.

For asynchronous functions, document meaningful rejection conditions using the
project's established JSDoc convention.  When `@throws` is used to describe both
synchronous throws and promise rejection conditions, the prose must make the
distinction clear when callers need to know it.

### Generators and Yields

Generator functions should document yielded values with `@yields` rather than
misrepresenting them as ordinary return values:

```text
@yields {Record} Validated records in source order.
```

Document whether iteration is lazy, whether resources remain held between yields,
whether partial iteration is safe, what cleanup occurs when iteration stops early,
and how errors surface during iteration when those details matter.

## Objects, Properties, Typedefs, and Callbacks

Use `@typedef` when a named reusable documentation type improves clarity for
structured objects or conceptual values that do not have a dedicated runtime
class.

Use `@property` to document meaningful properties of a documented object type.

Use `@callback` for callback contracts that deserve a named reusable interface.
Callback documentation should describe parameter semantics, return behavior,
error handling, invocation timing, retention, repetition, and concurrency
expectations when those details matter.

Use `@type` when documenting the type of a value, property, constant, or other
symbol for which a type expression is part of the maintained contract.

Prefer named reusable types over repeatedly embedding long structural descriptions
when reuse materially improves readability.  Avoid creating a `@typedef` merely to
hide a small, obvious object shape used once.

## Classes and Constructors

Public classes must document the abstraction represented by the class, its
responsibilities, important invariants, lifecycle, and meaningful relationships
with collaborators.

Document constructor parameters using the ordinary `@param` rules when the
constructor accepts caller-supplied arguments.

Do not restate every method in a class-level comment.  Use the class documentation
to explain class-wide behavior that individual method comments cannot express,
such as:

- ownership of external resources;
- lifecycle and disposal requirements;
- mutability and thread or event-loop assumptions;
- caching behavior;
- persistence boundaries;
- security-sensitive state; and
- relationships with other abstractions.

## Modules and Files

Use standard JSDoc module and file documentation when module-level generated
reference documentation is useful to the project.

Module documentation should explain why the module exists, its architectural role,
important exports, shared state, initialization behavior, external interactions,
portability assumptions, and relevant security boundaries.

Do not use module tags merely to force a documentation generator into a preferred
layout.  Module documentation should correspond to an actual source-level or
architectural concept.

## Side Effects

Material side effects must be documented in descriptive prose or in another clear
project-standard form.

Examples include:

- modifying caller-supplied objects;
- changing module or process-global state;
- changing environment variables;
- writing files or persistent storage;
- performing network operations;
- invoking subprocesses;
- emitting logs, metrics, or audit records;
- registering or retaining callbacks;
- scheduling asynchronous work;
- acquiring locks or other shared resources; and
- modifying external resources.

Documentation explains a contract; it does not make an unnecessarily surprising
side effect acceptable.

## Relationship to `javascript-doxygen`

[`javascript-doxygen`](https://github.com/wesley-dean/javascript-doxygen) is the
designated Doxygen input-filter project for repositories adopting this standard
when Doxygen requires translation of maintained JSDoc syntax.

The filter must preserve JavaScript as the filtered source language and should
translate only governed documentation forms at the Doxygen boundary.  It is a
documentation translator, not a replacement JavaScript parser, type checker,
linter, or runtime analyzer.

The filter's implemented support boundary is governed by the
`javascript-doxygen` repository's accepted ADRs and executable regression tests.
Adoption of this standard does not imply that every valid JSDoc construct is
already translated by the filter.

When a JSDoc form is valid under this standard but unsupported by the current
filter, the filter should prefer visible pass-through or another explicitly
governed false-negative behavior over inventing source semantics it cannot
establish safely.

The filter must not require maintainers to duplicate the same documentation in
both JSDoc and Doxygen-specific forms.

### Initial Structured Translation Contract

The first structured form intended for `javascript-doxygen` support is the
canonical required-parameter syntax:

```text
@param {Type} name - Description.
```

The maintained source remains exactly that JSDoc form.  The filter repository is
responsible for governing and testing any Doxygen-facing representation it emits.
This standard deliberately does not make the generated representation part of the
maintained JavaScript source contract.

Optional/default parameters, return values, exceptions, yields, typedefs,
callbacks, properties, modules, inline tags, and more complex type-expression
forms remain valid JSDoc source constructs where allowed by this standard, but
filter support for them must be claimed only when `javascript-doxygen` has
corresponding executable evidence.

## Tooling Boundary

Conformance with this standard is defined by maintained JavaScript source, not by
whether `javascript-doxygen` performs semantic program analysis.

JavaScript-native tooling remains responsible for semantic checks such as
signature/documentation agreement, type consistency, unreachable or stale
contracts, callback misuse, and other source-language concerns.

When tooling reports disagreement between code and documentation, treat the
mismatch as a defect to investigate.  Do not automatically rewrite the comment to
match the current implementation; the implementation may be the part that has
drifted from the intended contract.

## Non-Goals

This standard does not require:

- converting JavaScript to C or C++ for Doxygen;
- maintaining parallel Doxygen comment blocks;
- inferring undocumented runtime behavior;
- validating arbitrary JSDoc type expressions in the Doxygen filter;
- implementing a complete ECMAScript parser in AWK;
- treating every JSDoc tag as mandatory; or
- applying this JavaScript standard unchanged to TypeScript.

## Review Checklist

When reviewing maintained JavaScript documentation, verify that:

- JSDoc comments begin with `/**` and are attached to the intended symbol;
- summaries explain purpose rather than restating names;
- public and non-trivial interfaces document caller-visible behavior;
- required parameters use `@param {Type} name - Description.` when a type is part
  of the documented contract;
- parameter names agree with executable declarations;
- optionality and defaults are documented only when they are part of the public
  contract;
- return, throw, and yield documentation describes semantics rather than types
  alone;
- material side effects, ownership, lifecycle, and security assumptions are
  visible;
- reusable object shapes and callbacks use appropriate JSDoc constructs;
- maintained source does not contain duplicate Doxygen-only documentation; and
- documentation claims remain consistent with executable behavior and repository
  governance.

## References

- JSDoc documentation: <https://jsdoc.app/>
- JSDoc getting started: <https://jsdoc.app/about-getting-started>
- Doxygen documentation: <https://www.doxygen.nl/manual/>
