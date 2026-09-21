# Python Documentation Standard

This document defines the normative source-documentation standard for maintained
Python files in projects that adopt it.  The standard deliberately prefers
verbose, explanatory documentation.  Source brevity is not a goal when brevity
would force a future maintainer to infer intent, contracts, assumptions, failure
semantics, state ownership, portability constraints, security boundaries, or
architectural relationships from executable code alone.

This standard follows the same documentation philosophy used for maintained Bash
and AWK projects while adopting Python-native docstrings as the maintained source
of truth.  It is intentionally compatible with Python documentation and linting
tools, including Pylint documentation checks, and with Doxygen reference
generation through the
[`python-doxygen`](https://github.com/wesley-dean/python-doxygen) input filter.

Python has a different documentation model from Bash and AWK.  Modules, classes,
functions, and methods expose runtime docstrings through `__doc__`; type
annotations carry machine-readable interface type information; exceptions form
part of the call contract; generators yield values; and decorators, descriptors,
context managers, asynchronous functions, protocols, and class inheritance
introduce Python-specific interface semantics.  This standard therefore preserves
the documentation philosophy of the other language standards without mechanically
copying their syntax.

Maintainers should not reduce source documentation merely to optimize package or
wheel size.  If a project strips docstrings, generates optimized artifacts, or
otherwise transforms maintained Python source for distribution, that distribution
policy is separate from the maintained source-documentation standard.

Prefer thorough, detailed, in-depth commentary over brevity.  The goal is for the
work to be accessible, readable, and maintainable while targeting developers with
basic Python competence.  Pay particular attention to assumptions and
preconditions.  Consider that the reader may be a human new to the project or an
AI/LLM operating with focused context that may not retain the complete project
history or the consequences of prior decisions.

## Precedence

Repository-specific requirements, accepted Architecture Decision Records (ADRs),
documented public interfaces, compatibility requirements, security requirements,
and project-specific Python standards take precedence over this standard.

Do not perform unrelated documentation rewrites or refactoring solely to bring
existing code into compliance unless that work is part of the requested scope.

## Maintained Source of Truth

Python docstrings are the maintained source of truth for generated API
reference documentation.

Do not maintain a second Doxygen-specific documentation block beside a Python
docstring.  Do not duplicate parameter, return, exception, or behavioral
contracts in separate comments merely to satisfy Doxygen.

The maintained source should remain idiomatic Python and should be consumable by
Python-native tooling without first passing through `python-doxygen`.

`python-doxygen` exists at the documentation-generation boundary.  It translates
the governed maintained docstring structure into a Doxygen-friendly
representation without changing Python into another source language.

Conceptually:

```text
maintained Python source
        |
        | PEP 257 docstrings
        | Sphinx/reStructuredText fields
        v
   python-doxygen
        |
        | Doxygen-compatible translated representation
        v
      Doxygen
```

The generated representation is derivative.  It is not a maintained source of
truth and must not be edited as though it were authoritative documentation.

## Docstring Syntax

Maintained Python documentation must use Python docstrings rather than Doxygen
comment blocks as the primary source of API documentation.

Use triple double quotes:

```python
"""Describe the documented object."""
```

For multi-line docstrings, use a concise summary line, a blank line, substantive
explanation, and a closing triple quote on its own line:

```python
def load_configuration(path: Path) -> Configuration:
    """Load and validate a configuration file.

    Explain why the operation exists, relevant preconditions, validation rules,
    side effects, failure semantics, and assumptions callers must preserve.
    """
```

Use raw triple-double-quoted docstrings when backslashes are intended literally
and would otherwise be interpreted by Python.

Docstrings should follow PEP 257 structural conventions unless repository-specific
policy establishes a stricter rule.

Documentation lines should normally remain within the project's configured line
length.  When no stricter project rule exists, prefer 80-character documentation
lines where practical.  Long URLs, literal values, generated identifiers, and
other unbreakable content may exceed that limit.

Do not use the Doxygen-specific `"""!` form in maintained source under this
standard.  Structured Doxygen conversion belongs to `python-doxygen`, not to a
second source dialect embedded in the Python program.

## Structured Documentation Fields

This standard uses Sphinx/reStructuredText field syntax for structured function
and method contracts.

Use:

```text
:param name: description
:returns: description
:raises ExceptionType: description
:yields: description
```

When type annotations are present and authoritative, do not repeat the same type
information in `:type:` or `:rtype:` fields merely to satisfy documentation
formatting.

Type hints and prose serve different purposes.  Annotations express the
machine-readable type contract.  Docstrings explain semantics, units, accepted
ranges, ownership, mutation, special values, ordering, failure behavior,
security interpretation, and other meaning that the type alone cannot express.

When a maintained interface intentionally lacks type annotations and type
information is necessary for a linter or generated documentation, a project may
use fields such as:

```text
:type name: str
:rtype: Configuration
```

Do not maintain duplicate type declarations when one authoritative annotation is
sufficient.

## Relationship to Python Linters

The documentation format must remain consumable by the project's configured
Python linters.

At minimum, maintained public modules, classes, functions, and methods should have
docstrings.  Projects that enable stricter documentation extensions may require
complete parameter, return, yield, and raised-exception documentation.

When Pylint is used, projects adopting this standard should configure compatible
docstring checking, including `pylint.extensions.docparams` when parameter,
return, yield, and exception contract checking is desired.  Projects may also
enable stricter docstring-style checks when those checks agree with this standard.

Documentation must agree with the executable signature.  Parameter names in
structured fields must match the actual parameter names.  Do not document
parameters that do not exist, omit meaningful public parameters, or preserve
stale names after a signature change.

A function that returns a meaningful value should document that value with
`:returns:`.  A generator should document yielded values with `:yields:`.
Caller-visible exceptions that form part of the function's meaningful contract
should be documented with `:raises` fields.

When a linter reports disagreement between code and documentation, treat the
mismatch as a defect to investigate.  Do not automatically rewrite the docstring
to match the current implementation; the implementation may be the part that has
drifted from the intended contract.

## Relationship to python-doxygen

[`python-doxygen`](https://github.com/wesley-dean/python-doxygen) is the designated
Doxygen input filter for projects adopting this standard when structured Doxygen
reference output is required.

The filter preserves Python as the filtered source language and translates only
the governed documentation forms at the Doxygen boundary.  It remains a
documentation translator rather than a replacement Python parser, type checker,
or linter, and it does not infer behavior absent from maintained source.

The implemented structured mappings are:

```text
:param name: description
    -> @param name description

:returns: description
    -> @return description

:raises ExceptionType: description
    -> @exception ExceptionType description

:yields: description
    -> dedicated Doxygen paragraph titled "Yields"

:type name: value
    -> dedicated Doxygen paragraph titled "Type of name"

:rtype: value
    -> dedicated Doxygen paragraph titled "Return type"
```

The `:type:` and `:rtype:` mappings preserve maintained type information for
intentionally unannotated interfaces.  `python-doxygen` does not decide whether a
type field is redundant with an annotation, reconcile conflicting type
information, or infer types from executable source.  Those responsibilities
remain with Python-native tooling and repository policy.

The `:yields:` mapping is deliberately distinct from `:returns:` so generated
reference documentation does not describe generator output as an ordinary
function return.

For example, maintained source such as:

```python
def load_configuration(path: Path) -> Configuration:
    """Load and validate configuration from ``path``.

    :param path: Configuration file to read.
    :returns: A validated configuration object.
    :raises ValueError: The configuration is invalid.
    """
```

is translated for Doxygen into a representation equivalent to:

```text
@param path Configuration file to read.
@return A validated configuration object.
@exception ValueError The configuration is invalid.
```

The filter supports standards-conforming ordinary triple-double-quoted docstrings,
raw `r"""..."""` and `R"""..."""` docstrings where literal backslashes are
required, deterministic one-line prose docstrings in governed documentation
positions, conventional multi-line `def`, `async def`, and `class` declaration
headers, and representative property, async-function, generator, context-manager,
and decorated-function forms without inferring decorator semantics.

Continuation prose following governed structured fields remains source-visible and
is preserved when Doxygen can retain the intended association.  Ordinary prose,
examples, notes, warnings, unsupported markup, and ambiguous source remain visible
rather than being assigned speculative semantics.

Most supported translations preserve physical line count.  The dedicated titled
paragraph representations for `:yields:`, `:type name:`, and `:rtype:` add one
physical output line per translated field.  This is a generated-representation
tradeoff and does not change the maintained-source contract.

Doxygen integrations that rely on `python-doxygen` translating commands inside
ordinary Python docstrings must configure:

```ini
PYTHON_DOCSTRING = NO
```

This causes Doxygen to interpret the translated commands structurally rather than
preserving the docstring body as preformatted text.

`python-doxygen` must not require maintainers to duplicate the same contract in
both Sphinx-style and Doxygen-style forms.

### Tooling Boundary

Conformance with this standard is defined by the maintained Python source, not by
whether `python-doxygen` performs semantic program analysis.

`python-doxygen` implements the Doxygen-facing structured documentation portion of
this standard.  Semantic validation of Python signatures, annotations, return
behavior, exception behavior, documentation/signature agreement, type correctness,
and decorator semantics remains the responsibility of Python-native tooling such
as Pylint and of repository-specific tests and policy.

The filter should continue to prefer visible pass-through or a false negative over
inventing source meaning it cannot establish safely.  Parser-boundary details,
diagnostics, generated representation, and release behavior are governed by the
`python-doxygen` repository's ADRs and regression tests.

## Module Docstrings

Every maintained Python module should contain a module docstring near the start of
the file, after any required shebang or encoding declaration and before imports.

For example:

```python
"""Provide configuration loading and validation.

This module owns the boundary between external configuration files and the
validated application configuration model.  It documents accepted formats,
validation policy, security assumptions, and the errors callers should expect.
"""
```

A useful module docstring explains why the module exists, not merely which names
it exports.

When applicable, describe:

- the module's responsibility and architectural role;
- important public classes, functions, or protocols;
- global state owned by the module;
- initialization behavior and import-time side effects;
- persistence, filesystem, network, environment, or subprocess interactions;
- thread, process, or asynchronous concurrency assumptions;
- important compatibility or portability constraints;
- security boundaries; and
- relevant ADRs or governing specifications.

Avoid import-time behavior that is surprising merely because it has been
documented.  Documentation explains a contract; it does not justify unnecessary
side effects.

## Function and Method Docstrings

Maintained functions and methods must document their interface and non-obvious
behavior sufficiently for a caller to use them without reading the implementation.

A complete function docstring should use the following structure as applicable:

```python
def load_configuration(path: Path, *, strict: bool = True) -> Configuration:
    """Load and validate configuration from ``path``.

    Explain the contract, important preconditions, validation policy, side
    effects, external interactions, and why the function exists.

    :param path: Filesystem path containing the configuration document.
    :param strict: Whether unknown configuration keys are rejected.
    :returns: A validated configuration object owned by the caller.
    :raises FileNotFoundError: The requested path does not exist.
    :raises PermissionError: The configuration cannot be read.
    :raises ValueError: The document is syntactically or semantically invalid.
    """
```

Document parameters in signature order when practical.  Keyword-only parameters
must be documented as part of the public interface.  Positional-only semantics,
variadic arguments, and meaningful default behavior must be explained when they
affect callers.

### Parameters

Use one `:param name:` field for each meaningful documented parameter.

Do not document `self` or `cls` as ordinary caller-supplied parameters unless a
specific repository convention requires it.

For `*args` and `**kwargs`, document the accepted contents and semantics rather
than merely saying "additional arguments":

```text
:param args: Additional path fragments joined in order.
:param kwargs: Keyword options forwarded only to the configured transport.
```

If arbitrary keyword arguments are constrained to a known set, document that set
or link to the authoritative contract.

A parameter description should explain semantics that the annotation does not,
including as applicable:

- allowed values or ranges;
- units;
- sentinel meanings such as `None`;
- mutability and ownership;
- whether the object may be modified in place;
- whether iteration consumes the value;
- whether a callback may be retained;
- whether a path may be relative;
- encoding assumptions;
- ordering requirements; and
- security-sensitive interpretation.

### Return Values

Use `:returns:` when a function returns a meaningful value.

```text
:returns: A normalized repository identifier suitable for cache lookup.
```

Do not repeat only the annotated type.  Explain the meaning and ownership of the
returned value, relevant special cases, and whether the returned object aliases
input or internal state.

A function that intentionally returns `None` and exists for side effects may omit
`:returns:` when project linter configuration permits it.  When explicit return
documentation is required, state the contract clearly.

If a function may return multiple semantic forms, document the conditions that
select them.  Prefer precise return types in annotations and avoid prose that hides
an unnecessarily ambiguous interface.

### Generators and Iterators

Functions that use `yield` should document yielded values with `:yields:` rather
than describing them as ordinary return values.

```python
def iter_records(path: Path) -> Iterator[Record]:
    """Yield validated records from ``path``.

    :param path: Input file containing newline-delimited records.
    :yields: Validated records in source order.
    :raises OSError: The input cannot be read.
    :raises ValueError: A record is malformed and strict parsing is enabled.
    """
```

Document whether iteration is lazy, whether the underlying resource remains open
between yields, whether iteration may produce side effects, whether partial
iteration is safe, and what cleanup occurs when iteration stops early.

For asynchronous generators, document cancellation and resource cleanup when
those semantics matter.

### Exceptions

Use one `:raises ExceptionType:` field for each exception that forms part of the
function's meaningful caller-visible contract.

```text
:raises ValueError: The supplied configuration violates validation rules.
:raises PermissionError: The requested file cannot be read.
```

Do not enumerate every implementation-level exception that could theoretically
escape.  Document exceptions callers are expected to understand, handle, or treat
as part of the stable interface.

If an exception from a dependency may intentionally propagate unchanged, describe
that behavior rather than inventing a new wrapper exception solely for
documentation consistency.

When a function translates one exception into another, document the caller-visible
exception and explain relevant context preservation when useful.

### Side Effects

Material side effects must be documented in the descriptive prose or in an
explicit section when the side effects deserve prominence.

Examples include:

- modifying a caller-supplied mutable object;
- changing module or process-global state;
- changing environment variables;
- writing files or persistent storage;
- creating or removing directories;
- performing network operations;
- invoking subprocesses;
- emitting logs, metrics, or audit records;
- acquiring locks;
- registering callbacks;
- caching data with process-lifetime effects; and
- modifying external resources.

A function that appears observational should not hide mutation merely because the
mutation is documented elsewhere.

## Class Docstrings

Every maintained public class must have a docstring that explains the abstraction
represented by the class, its responsibilities, important invariants, lifecycle,
and meaningful relationships with collaborators.

For example:

```python
class RepositoryCache:
    """Cache validated repository metadata.

    Instances own an in-memory mapping for one synchronization run.  The cache
    does not persist data across processes and is not safe for concurrent mutation
    without external synchronization.
    """
```

Class documentation should address as applicable:

- what concept the class represents;
- ownership of resources and mutable state;
- construction preconditions;
- lifecycle and cleanup requirements;
- thread, process, and async safety;
- equality, hashing, ordering, or identity semantics;
- public attributes or properties whose meaning is not self-evident;
- subclassing expectations and extension points; and
- important invariants.

Avoid documenting constructor parameters twice.  A project should choose one
maintained location for constructor parameter documentation when its linter checks
for duplicate constructor documentation.  Unless repository governance states
otherwise, document constructor-specific behavior in `__init__` and document the
class abstraction in the class docstring.

If `__init__` contains no behavior or contract beyond what the class docstring
already establishes and the project's linter configuration permits omission,
avoid duplicating prose solely to satisfy an imagined requirement.

## Properties and Descriptors

A property docstring should describe the semantic attribute exposed to callers,
including mutation or validation behavior when a setter exists.

```python
@property
def status(self) -> Status:
    """Return the current lifecycle status."""
```

Do not describe a property as a trivial getter when accessing it performs I/O,
expensive computation, caching, synchronization, or other meaningful side effects.

Descriptors should document binding, caching, mutation, and exception semantics
when those behaviors are not obvious from normal attribute access.

## Asynchronous Functions

Async function docstrings should document behavior that is materially different
from synchronous calls.

When applicable, identify:

- when work begins;
- whether cancellation is supported or deferred;
- what state remains after cancellation;
- timeout behavior;
- concurrency limits;
- ordering guarantees;
- synchronization primitives used at the interface boundary; and
- whether returned objects or callbacks are safe across event loops.

Do not describe an async function merely as "asynchronous" when the important
contract is resource ownership, cancellation, or concurrency behavior.

## Context Managers

Context managers should document resource acquisition, what becomes valid inside
the context, cleanup behavior, and exception handling.

For example:

```python
@contextmanager
def locked_repository(path: Path) -> Iterator[Repository]:
    """Yield a repository while holding its process lock.

    :param path: Repository root whose lock is acquired.
    :yields: Repository access valid while the lock is held.
    :raises TimeoutError: The lock cannot be acquired within the configured time.
    """
```

Document whether cleanup occurs when the body raises, whether exceptions are
suppressed, and whether the yielded value remains valid after context exit.

## Decorators

A decorator should document how it changes the wrapped callable's behavior and
interface.

Document as applicable:

- whether the wrapper preserves the original signature and metadata;
- added retry, caching, authorization, logging, or synchronization behavior;
- newly raised exceptions;
- altered return values;
- ordering requirements relative to other decorators; and
- whether decoration occurs at import time with side effects.

Use `functools.wraps` where appropriate, but do not rely on metadata preservation
to communicate semantic changes that callers need to know.

## Variables, Constants, and Attributes

Python type annotations and meaningful names often make local variables
self-documenting.  Do not add docstrings or comments to every local value merely
to increase documentation volume.

Document module-level constants, configuration values, registries, public class
attributes, security-sensitive state, caches, and other values whose meaning,
ownership, lifecycle, units, mutability, or compatibility role is not
self-evident.

Attribute docstrings may be used when supported by the project's documentation
tooling.  Ordinary comments are appropriate for local implementation intent that
is not part of generated API documentation.

## Type Annotations and Documentation

Type annotations are part of the interface but do not replace documentation.

Prefer annotations for machine-readable structure:

```python
def parse_manifest(path: Path) -> list[Dependency]:
```

and docstrings for semantic meaning:

```text
:param path: Manifest file interpreted relative to the physical project root.
:returns: Dependencies in manifest order after complete validation.
```

Document behavior that types cannot express reliably, including ordering,
ownership, normalization, validation, aliasing, security interpretation, and
failure semantics.

Do not contradict annotations in prose.  If the type contract and documented
behavior disagree, resolve the inconsistency rather than choosing whichever form
is more convenient for a tool.

## Examples

Examples are strongly preferred for public, parsing, transformation, security,
serialization, persistence, network, configuration, or otherwise non-trivial
interfaces.

Use reStructuredText-compatible examples that remain readable in the source:

```python
def normalize_key(value: str) -> str:
    """Normalize a lookup key.

    :param value: Untrusted key supplied by the caller.
    :returns: Lowercase normalized key suitable for lookup.

    Example::

        normalized = normalize_key("Demo")
    """
```

Examples should demonstrate intended use, not manufacture a second test suite
inside docstrings.

If an example relies on omitted setup, make that omission obvious rather than
presenting incomplete code as directly executable.

A fuller illustrative module is available at
[`standards/examples/python/documentation/example.py`](../examples/python/documentation/example.py).
The example is non-normative; this standard remains authoritative if the two ever
disagree.

## Security-Sensitive Documentation

For parsing, validation, authentication, authorization, redaction,
serialization, filesystem, subprocess, network, persistence, and output code,
docstrings should make it possible for a reviewer to answer questions such as:

- what untrusted or sensitive state the callable receives or accesses;
- how input is interpreted;
- what validation occurs before use;
- whether values can reach logs, files, subprocesses, network services, or other
  sinks;
- whether failure can expose original sensitive input;
- whether returned objects retain or alias sensitive state;
- whether temporary files or caches retain information after use;
- what concurrency assumptions affect protection;
- which exceptions distinguish validation failure from infrastructure failure;
- what platform or library assumptions affect the security promise; and
- which ADR establishes the relevant security boundary when applicable.

Do not use documentation to imply stronger runtime protection than Python or the
implementation actually provides.

Terms such as "private," "secure memory," "isolated," "sanitized," or "escaped"
must correspond to a real mechanism and an established contract.

## Document Intent, Not Syntax

Avoid comments or docstrings that merely restate executable syntax.

Do not write prose equivalent to "increment the counter" above:

```python
count += 1
```

Prefer documentation that explains why the counter exists, what invariant it
represents, why the increment occurs at that stage, or why a seemingly unusual
implementation is necessary.

If code and documentation disagree, treat the disagreement as a defect to
investigate.  Do not automatically rewrite the documentation to match current
code; the code may be the part that drifted from the intended contract.

## Relationship to ADRs

Docstrings own implementation-level and caller-facing intent.  ADRs own durable
architectural reasoning, promises, non-promises, compatibility decisions,
security boundaries, adversary and failure models, rejected alternatives, and
accepted tradeoffs.

Source documentation may link to an ADR when a local implementation exists
specifically to satisfy an architectural constraint.

Do not copy an entire ADR into a docstring.  Do not invent historical rationale
when no source supports it.  State uncertainty or add an ADR when a new
consequential decision is required.

A project's `doc/adr/README.md`, when present, provides a curated digest of
currently governing decisions and does not replace either the full ADR or local
source documentation.

## Generated Reference Documentation

Generated Doxygen output is derivative and is not a maintained source of truth.
The maintained Python source, type annotations, docstrings, and governing
repository documentation remain authoritative.

`python-doxygen` preserves Python source while making only the governed
translations required for Doxygen indexing and rendering.

The filter must not manufacture parameter types, exception guarantees, ownership
semantics, thread-safety promises, or other contracts absent from the maintained
source.

Projects may build, package, optimize, or strip maintained Python source for
distribution.  Those transformations must not become a reason to reduce the
quality of maintained source documentation.

## Guidance for Automated Agents

When generating, modifying, or reviewing Python source:

1. Preserve Python docstrings as the maintained documentation authority.
2. Use triple-double-quoted PEP 257-style docstrings.
3. Use Sphinx/reStructuredText fields for structured contracts.
4. Keep parameter names synchronized with the executable signature.
5. Prefer type annotations for machine-readable type information.
6. Do not duplicate annotated types in docstring fields without a concrete need.
7. Document meaningful return values with `:returns:`.
8. Document generator output with `:yields:` rather than `:returns:`.
9. Document caller-visible contract exceptions with `:raises ExceptionType:`.
10. Document side effects, state ownership, lifecycle, and resource behavior when
    they matter to callers or maintainers.
11. Document async cancellation, cleanup, and concurrency behavior when relevant.
12. Document security boundaries and untrusted-input interpretation explicitly.
13. Do not add Doxygen `@param`, `@return`, or `@exception` commands directly to
    maintained docstrings merely for generated documentation.
14. Assume `python-doxygen` performs the Doxygen translation step.
15. Do not maintain parallel Python-native and Doxygen-native documentation for
    the same callable.
16. Treat linter-reported documentation drift as a defect to investigate.
17. Respect accepted ADRs and repository-specific documentation rules.
18. Do not expand the requested scope merely to normalize unrelated docstrings.

## General Module Structure Pattern

A maintained Python module should generally follow this order where applicable:

1. optional governed shebang;
2. optional encoding declaration when actually required;
3. module docstring;
4. future imports;
5. standard-library imports;
6. third-party imports;
7. project imports;
8. documented module constants and state;
9. classes;
10. functions; and
11. executable entry-point logic, when applicable.

This is a documentation-oriented pattern, not a substitute for repository-specific
Python formatting or import-order standards.

## General Function Docstring Structure Pattern

A maintained public or non-trivial function or method should generally contain:

1. a one-line summary;
2. a blank line;
3. substantive details describing intent, assumptions, side effects, and
   non-obvious behavior;
4. a blank line;
5. zero or more `:param name:` fields in signature order;
6. one `:returns:` field when the callable returns meaningful data;
7. one `:yields:` field when the callable is a generator and yields meaningful
   data;
8. zero or more `:raises ExceptionType:` fields for caller-visible contract
   exceptions;
9. additional prose sections for side effects, lifecycle, concurrency, security,
   or compatibility when useful; and
10. an example when it materially improves understanding.

A callable should not document both `:returns:` and `:yields:` merely to satisfy a
pattern.  Use the field that reflects the executable contract.

## Review Standard

Review documentation with the same seriousness as executable code.  Ask whether
a maintainer unfamiliar with the current implementation could understand:

- the responsibility of each module and class;
- the contract of each public or non-trivial callable;
- parameter semantics beyond their type annotations;
- meaningful return or yield behavior;
- caller-visible exceptions;
- state ownership and mutation;
- resource lifecycle and cleanup;
- async cancellation and concurrency behavior when applicable;
- meaningful edge cases and failure modes;
- security-sensitive state and output boundaries;
- why non-obvious implementation choices exist;
- which architectural decisions constrain future changes;
- whether the docstring remains consumable by configured Python linters;
- whether `python-doxygen` can translate the structured fields without requiring
  a second maintained documentation dialect; and
- what the implementation explicitly does not guarantee.

There is no target docstring-to-code ratio.  The desired amount is "enough to
preserve the reasoning."  In infrastructure, security, parsing, and integration
code, that may mean substantially more prose than teams accustomed to terse
Python docstrings expect, and that is intentional.

## Structural Checklist

Before considering a maintained Python file adequately documented, verify as
applicable:

- the module contains a meaningful module docstring;
- public classes have docstrings describing their abstraction and lifecycle;
- public and non-trivial functions and methods have PEP 257-style docstrings;
- maintained docstrings use triple double quotes;
- structured contracts use Sphinx/reStructuredText fields;
- parameter names match the executable signature;
- meaningful parameters are documented in signature order where practical;
- meaningful return values use `:returns:`;
- generator output uses `:yields:`;
- caller-visible contract exceptions use `:raises ExceptionType:`;
- type annotations remain authoritative and are not duplicated without reason;
- side effects and external interactions are documented when material;
- resource ownership and cleanup are explicit where relevant;
- async cancellation and concurrency semantics are documented where relevant;
- security-sensitive code documents assumptions a future reviewer would otherwise
  have to infer;
- examples are present where they materially improve understanding;
- documentation agrees with accepted ADRs and repository-specific contracts;
- maintained source does not contain a second Doxygen-specific documentation
  block for the same object; and
- `python-doxygen` is treated as a translation boundary rather than a second
  documentation authority.
