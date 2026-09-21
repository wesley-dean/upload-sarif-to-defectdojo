# PHP Documentation Standard

This document defines the normative source-documentation standard for maintained
PHP files in projects that adopt it.  The standard deliberately prefers verbose,
explanatory documentation.  Source brevity is not a goal when brevity would force
a future maintainer to infer intent, contracts, assumptions, failure semantics,
state ownership, compatibility constraints, security boundaries, or architectural
relationships from executable code alone.

This standard is Doxygen-first.  Maintained PHP documentation must be written so
that Doxygen can consume it directly without a translation filter.  Compatibility
with phpDocumentor is desirable when it does not weaken, contradict, or complicate
the Doxygen contract.  Where Doxygen and phpDocumentor expectations differ,
Doxygen takes precedence.

The preferred authoring style is therefore the common subset of PHPDoc-style
DocBlocks and Doxygen commands.  The goal is one maintained documentation block
that Doxygen can consume natively and that phpDocumentor can also understand in
ordinary cases.

## Precedence

Repository-specific requirements, accepted Architecture Decision Records (ADRs),
documented public interfaces, compatibility requirements, security requirements,
and project-specific PHP standards take precedence over this standard.

Do not perform unrelated documentation rewrites or refactoring solely to bring
existing code into compliance unless that work is part of the requested scope.

## Tooling Priority

The tooling priority for this standard is:

1. Doxygen compatibility is required.
2. phpDocumentor compatibility is preferred when it does not conflict with
   Doxygen.
3. If a documentation construct has materially different meanings or syntax in
   the two systems, use the Doxygen-compatible form.

No PHP documentation filter is required by this standard.  Maintained PHP source
must remain directly consumable by Doxygen.

Do not maintain parallel Doxygen and phpDocumentor blocks for the same element.
One DocBlock is the maintained source of truth.

## DocBlock Syntax

Use PHPDoc/Javadoc-style documentation blocks:

```php
/**
 * Describe the documented element.
 */
```

Use a concise summary followed by a blank line and substantive details when more
explanation is required:

```php
/**
 * Load and validate application configuration.
 *
 * Explain the boundary owned by this function, validation policy, caller-visible
 * failure behavior, side effects, and assumptions that callers must preserve.
 */
```

Projects using Doxygen with this standard should enable:

```ini
JAVADOC_AUTOBRIEF = YES
```

This permits the first sentence of a Javadoc-style DocBlock to serve as the brief
description while subsequent prose serves as the detailed description.  It also
avoids requiring Doxygen-only `@brief` or `@details` commands in ordinary PHP
DocBlocks.

Documentation lines should normally remain within the project's configured line
length.  When no stricter project rule exists, prefer 80-character documentation
lines where practical.  Long URLs, literal values, generated identifiers, and
other unbreakable content may exceed that limit.

## Baseline Tag Vocabulary

The baseline documentation vocabulary should remain within the shared,
well-understood PHPDoc/Doxygen subset wherever practical.

The preferred core tags are:

```text
@param
@return
@throws
@var
@see
@deprecated
```

Other tags may be used when Doxygen supports the intended semantics and the tag is
materially useful.  phpDocumentor-specific tags are not automatically prohibited,
but they are outside the baseline standard unless a project-specific requirement
justifies them.

Do not add a tag merely because one documentation engine recognizes it.  The tag
must communicate information that belongs in the maintained contract.

## Functions and Methods

Maintained public and non-trivial functions and methods must document their
interface and non-obvious behavior sufficiently for a caller to use them without
reading the implementation.

A complete function DocBlock should generally look like:

```php
/**
 * Load and validate application configuration.
 *
 * Reads the requested configuration document and validates it before returning
 * an application configuration object.  The function does not modify the source
 * file.
 *
 * @param string $path Path to the configuration document.
 * @param bool $strict Whether unknown configuration keys are rejected.
 * @return Configuration Validated configuration owned by the caller.
 * @throws InvalidArgumentException The path or configuration is invalid.
 * @throws RuntimeException The configuration cannot be read.
 */
function loadConfiguration(string $path, bool $strict = true): Configuration
{
    // implementation
}
```

Document parameters in signature order when practical.

### Parameters

Use one `@param` tag for each meaningful documented parameter.

The preferred form is:

```text
@param Type $name Description.
```

For example:

```text
@param string $path Filesystem path interpreted relative to the project root.
```

Doxygen explicitly supports PHP-style parameter documentation containing the type
before the parameter name.  This form is also conventional PHPDoc and is therefore
preferred even when the native PHP signature already carries a type declaration.

This duplication is intentional.  The DocBlock type participates in the
structured documentation contract and may express useful PHPDoc forms that differ
from or refine the native declaration, such as documented collection element
semantics or pseudo-types.  The DocBlock must not contradict the executable PHP
signature.

Parameter descriptions should explain meaning that the type alone cannot express,
including as applicable:

- allowed values or ranges;
- units;
- sentinel meanings such as `null`;
- mutability and ownership;
- whether an object or array may be modified;
- path interpretation;
- encoding assumptions;
- ordering requirements;
- callback lifecycle; and
- security-sensitive interpretation.

### Return Values

Use `@return` for meaningful return values:

```text
@return Configuration Validated configuration owned by the caller.
```

Prefer the form:

```text
@return Type Description.
```

The description must explain semantics rather than merely repeating the type.
Document ownership, aliasing, special values, ordering, normalization, or other
caller-visible behavior when those details matter.

For functions that intentionally return no meaningful value, use the PHPDoc/Doxygen
form appropriate to the project's PHP compatibility floor, typically:

```text
@return void
```

Do not invent a return contract for procedures whose useful behavior consists of
side effects.

### Exceptions

Use `@throws` for exceptions that form part of the meaningful caller-visible
contract:

```text
@throws InvalidArgumentException The supplied identifier is invalid.
@throws RuntimeException The external service cannot be reached.
```

Document exceptions callers are expected to understand, handle, or treat as part
of the stable interface.  Do not enumerate every implementation-level throwable
that could theoretically escape.

When an exception from a dependency intentionally propagates unchanged, describe
that behavior when it is part of the supported interface rather than inventing a
wrapper exception solely for documentation consistency.

## Types in DocBlocks

Native PHP type declarations remain authoritative for executable behavior.
DocBlock types must agree with them.

Unlike the Python standard, this standard intentionally retains type information
inside `@param`, `@return`, and `@var` tags because Doxygen's PHP parameter syntax
supports the phpDocumentor-style type form directly and because PHPDoc-aware tools
commonly rely on those fields.

Where a DocBlock type conveys information that PHP's native type system does not
express conveniently, document it precisely.  Examples may include collection
element types, constrained shapes, pseudo-types, or meaningful union forms when
those forms are accepted by the project's tooling.

Do not use a richer DocBlock type to contradict a native declaration.  If the
source signature and DocBlock disagree, treat the disagreement as a defect to
investigate.

## Variables, Properties, and Constants

Use `@var` when a property, constant-like value, or significant variable requires
structured type or semantic documentation:

```php
/**
 * Cache of repository metadata keyed by normalized repository identifier.
 *
 * @var array<string, RepositoryMetadata>
 */
private array $cache = [];
```

Do not document every local variable merely to increase documentation volume.
Document state whose ownership, lifecycle, units, mutability, compatibility role,
or security meaning is not self-evident.

For public properties, explain caller-visible mutation and lifecycle semantics.
For constants, explain units, compatibility meaning, sentinel semantics, or other
non-obvious interpretation.

## Classes, Interfaces, Traits, and Enums

Maintained public classes, interfaces, traits, and enums should have DocBlocks
that explain the abstraction they represent and the contract they establish.

Class documentation should address as applicable:

- responsibility and architectural role;
- important invariants;
- owned resources and mutable state;
- lifecycle and cleanup requirements;
- extension and inheritance expectations;
- concurrency assumptions;
- public properties whose meaning is not obvious;
- security boundaries; and
- relationships with relevant ADRs or specifications.

Interface documentation should describe the behavioral contract implementers must
preserve rather than merely repeating method names.

Trait documentation should explain the behavior and assumptions introduced into a
consuming class, including required methods, properties, or initialization order.

Enum documentation should explain domain meaning and any compatibility promises
associated with cases or backing values.

## Side Effects

Material side effects must be documented in descriptive prose when they are part
of the caller-visible contract or materially affect maintenance.

Examples include:

- modifying caller-supplied arrays or objects;
- changing process-global or static state;
- modifying session state;
- reading or writing files;
- database operations;
- network requests;
- subprocess execution;
- logging or audit output;
- cache mutation;
- lock acquisition; and
- modifying external services or resources.

A function that appears observational should not hide mutation merely because the
mutation is technically allowed by PHP.

## Deprecated Interfaces

Use `@deprecated` when an interface remains available but should no longer be used:

```php
/**
 * Resolve the legacy repository identifier.
 *
 * @deprecated Use normalizeRepositoryIdentifier() instead.
 */
```

When practical, explain the supported replacement and any migration constraint.
Do not use deprecation documentation as a substitute for actual compatibility or
removal policy.

## Cross-References

Use `@see` for references that materially help a maintainer or caller understand
the documented element:

```text
@see RepositoryPolicy
@see normalizeRepositoryIdentifier()
```

Prefer references that remain meaningful in generated documentation.  Do not add
large lists of loosely related symbols merely to increase connectivity.

## Tags Outside the Baseline

phpDocumentor supports tags beyond the baseline used by this standard, including
forms such as `@property`, `@property-read`, `@property-write`, `@method`, `@api`,
`@internal`, `@uses`, and `@used-by`.

These tags are not part of the baseline standard merely because phpDocumentor
recognizes them.  Use them only when:

1. the project has a concrete need for the semantic contract;
2. Doxygen supports the intended representation adequately, or the tag remains
   harmless and visible under the project's Doxygen configuration; and
3. repository-specific governance permits the additional vocabulary.

When a phpDocumentor convention conflicts with Doxygen's interpretation, Doxygen
wins.

Likewise, avoid introducing Doxygen-only commands into ordinary PHP DocBlocks when
an equivalent shared PHPDoc form communicates the same contract.  Doxygen-only
commands may be used when no adequate shared form exists and the documentation
benefit justifies the reduced phpDocumentor compatibility.

## Examples

Examples are strongly preferred for public, parsing, transformation, security,
serialization, persistence, database, network, configuration, or otherwise
non-trivial interfaces.

Keep examples readable in the source and useful in generated Doxygen output.
Do not manufacture a second test suite inside comments.

If an example relies on omitted setup, make that omission explicit rather than
presenting incomplete code as directly executable.

## Security-Sensitive Documentation

For parsing, validation, authentication, authorization, redaction,
serialization, filesystem, subprocess, database, network, persistence, and
output code, DocBlocks should make it possible for a reviewer to answer questions
such as:

- what untrusted or sensitive state the callable receives or accesses;
- how input is interpreted;
- what validation occurs before use;
- whether values can reach logs, files, databases, subprocesses, network services,
  or other sinks;
- whether failure can expose original sensitive input;
- whether returned objects retain or alias sensitive state;
- whether temporary files, caches, or sessions retain information after use;
- what concurrency assumptions affect protection;
- which exceptions distinguish validation failure from infrastructure failure;
- what platform or library assumptions affect the security promise; and
- which ADR establishes the relevant security boundary when applicable.

Do not use documentation to imply stronger runtime protection than PHP or the
implementation actually provides.

## Document Intent, Not Syntax

Avoid DocBlocks or comments that merely restate executable syntax.

Prefer documentation that explains why a value or operation exists, what contract
it preserves, what invariant it represents, or why a seemingly unusual
implementation is necessary.

If code and documentation disagree, treat the disagreement as a defect to
investigate.  Do not automatically rewrite the documentation to match current
code; the code may be the part that drifted from the intended contract.

## Relationship to ADRs

DocBlocks own implementation-level and caller-facing intent.  ADRs own durable
architectural reasoning, promises, non-promises, compatibility decisions,
security boundaries, failure models, rejected alternatives, and accepted
tradeoffs.

Source documentation may link to an ADR when a local implementation exists
specifically to satisfy an architectural constraint.

Do not copy an entire ADR into a DocBlock.  Do not invent historical rationale
when no source supports it.

## Generated Reference Documentation

Generated Doxygen output is derivative and is not a maintained source of truth.
The maintained PHP source, native type declarations, DocBlocks, and governing
repository documentation remain authoritative.

No translation filter is part of the baseline PHP documentation architecture.
Doxygen consumes maintained PHP source directly.

Projects may additionally run phpDocumentor against the same maintained DocBlocks.
phpDocumentor output is secondary and must not drive source syntax away from the
Doxygen contract established by this standard.

## Guidance for Automated Agents

When generating, modifying, or reviewing PHP source:

1. Treat Doxygen compatibility as required.
2. Prefer the common PHPDoc/Doxygen subset when it communicates the needed
   contract.
3. Use `/** ... */` DocBlocks for generated API documentation.
4. Use summary-plus-description prose rather than Doxygen-only `@brief` and
   `@details` when the shared form is sufficient.
5. Assume Doxygen is configured with `JAVADOC_AUTOBRIEF = YES` when this standard
   is adopted.
6. Use `@param Type $name Description` for meaningful parameters.
7. Use `@return Type Description` for meaningful return values.
8. Use `@throws ExceptionType Description` for caller-visible contract
   exceptions.
9. Use `@var` for significant typed state when useful.
10. Use `@see` and `@deprecated` when they materially improve the contract.
11. Keep DocBlock types consistent with native PHP type declarations.
12. Document semantics beyond types, including units, ownership, mutation,
    normalization, special values, side effects, lifecycle, and failure behavior.
13. Do not create parallel Doxygen and phpDocumentor blocks.
14. Do not introduce phpDocumentor-specific tags merely because they exist.
15. If phpDocumentor and Doxygen conflict, follow Doxygen.
16. Respect accepted ADRs and repository-specific rules.
17. Do not expand requested scope merely to normalize unrelated DocBlocks.

## General Function DocBlock Pattern

A maintained public or non-trivial function or method should generally contain:

1. a concise summary sentence;
2. a blank line;
3. substantive prose describing intent, assumptions, side effects, and
   non-obvious behavior;
4. a blank line;
5. zero or more `@param` tags in signature order;
6. one `@return` tag when the callable returns meaningful data;
7. zero or more `@throws` tags for caller-visible contract exceptions;
8. additional prose or supported tags for lifecycle, security, compatibility, or
   cross-reference information when useful; and
9. an example when it materially improves understanding.

## Review Standard

Review documentation with the same seriousness as executable code.  Ask whether
a maintainer unfamiliar with the implementation could understand:

- the responsibility of each class, interface, trait, enum, and significant
  function;
- parameter semantics beyond the declared type;
- meaningful return behavior;
- caller-visible exceptions;
- state ownership and mutation;
- resource lifecycle and cleanup;
- external interactions and side effects;
- meaningful edge cases and failure modes;
- security-sensitive state and output boundaries;
- why non-obvious implementation choices exist;
- which architectural decisions constrain future changes;
- whether Doxygen can consume the DocBlock directly; and
- whether the chosen syntax remains reasonably compatible with phpDocumentor when
  doing so does not conflict with Doxygen.

There is no target comment-to-code ratio.  The desired amount is enough to
preserve the reasoning.

## Structural Checklist

Before considering maintained PHP adequately documented, verify as applicable:

- public classes, interfaces, traits, enums, functions, and non-trivial methods
  have meaningful DocBlocks;
- generated documentation uses `/** ... */` blocks;
- summary and detailed prose explain intent rather than restating syntax;
- meaningful parameters use `@param Type $name Description`;
- meaningful return values use `@return Type Description`;
- caller-visible contract exceptions use `@throws`;
- DocBlock types agree with native PHP declarations;
- significant state uses `@var` when structured documentation is useful;
- deprecated interfaces use `@deprecated` with migration guidance where practical;
- useful cross-references use `@see`;
- side effects and external interactions are documented when material;
- security-sensitive code documents assumptions a future reviewer would otherwise
  have to infer;
- repository-specific ADRs and contracts are respected;
- maintained source does not contain parallel Doxygen and phpDocumentor blocks;
- Doxygen compatibility is preserved; and
- phpDocumentor compatibility is retained where it does not conflict with the
  Doxygen-first contract.
