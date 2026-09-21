# AWK Documentation Standard

This document defines the normative source-documentation standard for maintained
AWK files in projects that adopt it.  The standard deliberately prefers verbose,
explanatory documentation.  Source brevity is not a goal when brevity would
force a future maintainer to infer intent, contracts, assumptions, failure
semantics, state ownership, portability constraints, security boundaries, or
architectural relationships from executable code alone.

This standard is modeled after the documentation approach used for maintained
Bash projects and is intentionally compatible with the `awk-doxygen` tooling
model.  The syntax and structure described here are requirements, not examples
of a general style that may be replaced with something merely similar.

AWK has a substantially different execution model from Bash.  Functions have
real return values rather than shell-style exit statuses, variables are created
through use rather than declarations, function-local variables are commonly
represented by omitted formal parameters, and much program behavior lives in
`BEGIN`, `END`, and pattern/action rules rather than named functions.  This
standard therefore preserves the documentation philosophy of the Bash model
while defining AWK-specific contracts rather than mechanically copying Bash
semantics.

Maintainers should not reduce source documentation merely to optimize release
size.  If a project produces stripped, generated, or minified consumer
artifacts, that distribution policy is separate from the maintained
source-documentation standard.  Prefer thorough, detailed, in-depth commentary
over brevity.  The goal is for the work to be accessible, readable, and
maintainable while targeting developers with basic AWK competence.

Pay particular attention to assumptions and preconditions.  Consider that the
reader may be a human new to the project or an AI/LLM operating with focused
context that may not retain the complete project history or the consequences of
prior decisions.

## Language and Portability Floor

Unless governing project documentation states otherwise, maintained AWK source
covered by this standard should be documented as portable AWK rather than as a
specific implementation such as GNU awk, mawk, or BusyBox awk.

When source depends on implementation-specific behavior or extensions, the
relevant documentation must identify that dependency explicitly.  Do not
describe code as portable AWK when correctness actually depends on an
implementation-specific feature.

Examples of portability-sensitive concerns include:

* implementation-specific built-in variables or functions;
* implementation-specific regular-expression behavior;
* implementation-specific command-line options;
* implementation-specific array behavior;
* implementation-specific namespace or indirect-call features;
* multibyte and locale behavior;
* non-portable uses of `getline`, redirection, or process control; and
* assumptions about which `awk` implementation `/usr/bin/awk` or the user's
  `PATH` selects.

Portability claims are part of the interface contract and must be documented
with the same care as input and output behavior.

## Comment Syntax

Doxygen documentation lines begin with exactly two hash characters:

```awk
## @file lib/example.awk
## @brief Provides an example capability.
## @details
## This module exists to preserve a specific contract.  The details explain why
## the capability belongs here, how callers should use it, and what assumptions
## future changes must preserve.
```

Use ordinary single-hash comments for narrow implementation annotations that are
not intended to become part of generated reference documentation.  Prefer
Doxygen comments whenever the material helps explain an interface, invariant,
module responsibility, non-obvious decision, maintenance constraint,
portability assumption, data-shape contract, state transition, or security
boundary.

The project does not use another Doxygen comment dialect in maintained AWK
source.  Do not replace these blocks with `#**`, `##<`, or another convention
without an architectural decision that explicitly changes the `awk-doxygen`
integration.

Lines in documentation commentary should be limited to 80 characters or less,
except for unbreakable content such as long URLs or literal values whose form is
part of the contract.

## Relationship to awk-doxygen

`awk-doxygen` is the designated Doxygen filter for projects adopting this
standard.  It converts intentionally documented AWK constructs into a
Doxygen-friendly intermediate representation.  The generated representation is
an indexing target for Doxygen; it is not intended to be compiled or executed.

The tooling model is documentation-led rather than parser-led.  The filter
should recognize only the subset of AWK structure required to associate
explicit Doxygen blocks with functions, documented variables, `BEGIN`/`END`
blocks, and pattern/action rules.  It must not claim to be a complete AWK parser.

The structural vocabulary defined by this standard includes:

* `@file` for file-level documentation;
* `@fn` for named AWK functions;
* `@param` for caller-supplied function parameters;
* `@local` for conventional omitted formals used as function-local storage;
* `@var` for significant documented global variables or arrays; and
* `@rule` for named documentation identities assigned to AWK rules, including
  `BEGIN`, `END`, and ordinary pattern/action rules.

Ordinary Doxygen commands such as `@brief`, `@details`, `@returns`, `@retval`,
`@note`, `@warning`, `@see`, `@par`, `@code`, and `@endcode` retain their normal
role unless this standard defines a more specific AWK interpretation.

`@local` and `@rule` are AWK-source structural directives.  They exist so the
filter can preserve AWK semantics without pretending that conventional locals
are ordinary public parameters or that anonymous rules are named source-level
functions.  The generated Doxygen representation may suppress or translate
these directives as necessary.

When `@fn`, `@var`, or `@rule` is used, the documented identity must agree with
the construct being documented according to the validation rules established by
`awk-doxygen`.  Documentation identity is part of the maintained-source
contract, not decorative prose.

Where practical, the filter should preserve source line correspondence so that
Doxygen diagnostics and generated references remain close to the original AWK
locations.  Tooling should favor one-for-one line translation over expanding
short source blocks into substantially longer generated structures.

## File Blocks

Every maintained AWK source file must contain a file-level Doxygen block near
the start of the file:

```awk
## @file lib/redaction.awk
## @brief Provides the core redaction pipeline.
## @details
## Explain the module's responsibility, state ownership, security boundary,
## interactions with record processing, and assumptions future changes must
## preserve.
```

If the file is directly executable and governing project policy requires a
shebang, the shebang may precede the Doxygen block:

```awk
#!/usr/bin/awk -f
## @file bin/example.awk
## @brief Processes example input records.
## @details
## Explain why the program exists, the expected record stream, output contract,
## and portability assumptions.
```

A shebang is not required merely because a file contains AWK.  Source intended
to be invoked with `awk -f file.awk` may begin directly with the Doxygen file
block.  The project must not invent a shebang requirement in the documentation
standard when execution policy belongs elsewhere.

The file details must explain the module's responsibility, its relationship to
neighboring modules or invoking shell code, important global state it owns,
record-processing assumptions, and constraints that affect safe modification.
A useful file block answers "why does this AWK program or module exist?" as well
as "what functions and rules does it contain?"

When applicable, the file block should identify:

* the expected input-record model;
* assumptions about `FS`, `RS`, `OFS`, `ORS`, or other built-in variables;
* whether input is expected on standard input, named files, or both;
* whether `ARGV` is inspected or modified;
* whether `ENVIRON` participates in configuration;
* whether output is intended for another machine-readable stage;
* whether output ordering is significant;
* whether global arrays or counters carry state across records;
* whether `BEGIN` or `END` establishes or finalizes important invariants;
* whether the program executes subprocesses or writes files; and
* which AWK implementation or portability floor is required.

Security-sensitive modules must explicitly identify the boundary they enforce
and link to governing ADRs when that context materially improves review.

## Function Blocks

All maintained AWK functions must use the following vocabulary as applicable:

```awk
## @fn example_lookup(name)
## @brief Looks up a named example.
## @details
## Explain the contract, assumptions, side effects, global state interaction,
## and why the function exists.  Describe non-obvious behavior and interactions
## with other functions or rules.
##
## @param name Logical name to look up.
## @local value Scratch value used while resolving the lookup.
##
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## A diagnostic may be written when the request is invalid.
##
## @returns The matching string, or the empty string when no match exists.
##
## @par Examples
## @code
## value = example_lookup("demo")
## @endcode
function example_lookup(name,    value) {
  # implementation
}
```

Document caller-supplied parameters in declaration order.  Document conventional
locals after the caller-supplied parameters and mark them with `@local` rather
than `@param`.

`@details` should explain the function's contract, meaningful preconditions,
state dependencies, side effects, failure behavior, and non-obvious invariants.
For functions whose behavior depends on record context, identify which built-in
values such as `$0`, `NF`, `NR`, `FNR`, `FILENAME`, `FS`, or `RS` are read or
modified.

### Caller Parameters and Conventional Locals

Portable AWK does not have a dedicated local-variable declaration.  A common
portable convention is to place parameters that callers are expected to omit
after additional spacing in the function parameter list:

```awk
function parse(line, separator,    fields, count) {
```

Syntactically, `fields` and `count` are function parameters.  Semantically, the
program intends them as local storage because normal callers omit them.

This standard distinguishes these roles explicitly:

```awk
## @param line Record to parse.
## @param separator Field separator.
## @local fields Scratch array populated while parsing.
## @local count Number of fields discovered.
function parse(line, separator,    fields, count) {
```

`@param` means the value is part of the caller-visible interface.  `@local`
means the formal parameter is intentionally omitted by normal callers and is
used as function-local storage.

The spacing convention may improve human readability, but spacing itself is not
an AWK semantic boundary.  Documentation and tooling must not claim otherwise.
The `@param` / `@local` distinction records intended interface semantics.

A caller that explicitly supplies a value for a documented `@local` is relying
on behavior outside the documented public contract unless project governance
states otherwise.

### Local Arrays

AWK arrays can be passed to functions, and a conventional omitted formal may be
used as a local array.  Document the intended shape and lifecycle when that
matters:

```awk
## @local parts Scratch array containing split fields for the current call.
```

Do not imply that AWK provides automatic block scope or automatic array cleanup.
If correctness depends on `delete array[index]`, `delete array`, or recreating an
empty scratch array by convention, explain that behavior.

### STDIN, STDOUT, and STDERR

Every maintained function must contain exactly one `@par STDIN`, one
`@par STDOUT`, and one `@par STDERR`.

These paragraphs document direct stream interaction performed by the function,
not the AWK program's overall record-processing environment.

```awk
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## One normalized record is written when validation succeeds.
## @par STDERR
## A diagnostic is written when the record cannot be normalized.
```

Most helper functions do not independently read standard input because AWK's
main execution engine reads records before invoking pattern/action code.  State
that explicitly rather than silently omitting the contract.

If a function uses `getline`, document the actual input source and its effect on
AWK record state.  A bare `getline` can affect `$0`, `NF`, `NR`, or `FNR`
depending on form and implementation semantics.  Do not summarize such behavior
merely as "reads input."

For STDERR, document the redirection mechanism used by the supported portability
floor when material.  Do not claim that a particular pseudo-device path is
portable unless project governance establishes it.

### Using @returns and @retval

`@returns` documents the value produced by the AWK `return` statement, or the
absence of a meaningful return value.

```awk
## @returns The normalized key.
```

A function that intentionally returns a boolean-like numeric value may document
discrete return meanings with `@retval`:

```awk
## @returns A numeric truth value.
## @retval 1 The supplied value is valid.
## @retval 0 The supplied value is invalid.
```

In this standard, `@retval` refers to discrete AWK function return values.  It
does not refer to the AWK process exit status.

This distinction is important because AWK functions and the AWK process have
separate contracts.  `return 1` returns `1` to the AWK caller.  `exit 1`
terminates processing with a process-level status.  Documentation must not
conflate the two.

If a function has no meaningful return value, say so explicitly:

```awk
## @returns No meaningful value; callers use the function for its side effects.
```

Do not use `@returns` to describe text written by `print` or `printf`.  That is
the STDOUT contract.

### Process Exit Behavior

If a function may execute `exit`, that is a material control-flow side effect
and must be documented in `@details` or a dedicated `@par Process Exit` section.

For example:

```awk
## @par Process Exit
## Terminates the AWK program with status 65 when configuration is malformed.
```

Do not document process exit statuses with function `@retval` directives.

Process-level exit behavior associated with `BEGIN`, ordinary rules, or `END`
should be documented on the relevant rule or at file level.

### Side Effects and Global State

AWK functions can read and modify global variables without declarations.  Any
material caller-visible or program-visible side effect must be documented.

Examples include:

* modifying a global scalar or array;
* changing `FS`, `OFS`, `RS`, `ORS`, or another built-in variable;
* changing `$0` or an individual field;
* invoking `sub()` or `gsub()` without an explicit target;
* writing to files or pipes;
* calling `close()` on resources;
* consuming additional input through `getline`;
* mutating `ARGV` or `ENVIRON`; and
* terminating processing with `exit`.

A dedicated section is appropriate when the side effects are significant:

```awk
## @par Side Effects
## Updates the global `seen` array and increments `accepted_count`.
```

For security-sensitive functions, `@details` must explain important
preconditions, ordering assumptions, data exposure boundaries, and values that
must never be emitted.

## Variables and Arrays

AWK variables are created through use rather than explicit declarations.  The
documentation standard therefore does not require a fictitious declaration line
for every documented value.

Document significant global variables and arrays whose meaning, lifecycle,
ownership, or public compatibility role is not self-evident.  Typical candidates
include:

* configuration values;
* global counters;
* registries;
* lookup tables;
* security-sensitive state;
* cross-record state;
* state shared between `BEGIN`, ordinary rules, functions, and `END`; and
* variables whose value participates in a stable external contract.

Use `@var` for significant documented globals:

```awk
## @var record_count
## @brief Number of accepted input records.
## @details
## This global counter is initialized in BEGIN and incremented only after a
## record passes validation.
```

For arrays, document key and value semantics:

```awk
## @var cache
## @brief Maps normalized keys to cached values.
## @details
## Keys are lowercase normalized identifiers.  Values are the exact strings
## emitted by the lookup stage.  Entries persist for the lifetime of the AWK
## process.
```

Do not document every temporary global merely because AWK lacks a declaration
keyword.  Documentation volume should preserve reasoning rather than create
noise that obscures important state.

### Variable Type Claims

AWK scalar values can participate in numeric and string contexts.  Avoid
pretending that a scalar has a stronger static type than the language provides.

Prefer descriptions such as:

```text
Numeric count of accepted records.
String containing the normalized identifier.
Boolean-like numeric value: 1 for true and 0 for false.
```

over fictitious language types.

Arrays are semantically distinct from scalars and should be documented as arrays
when significant.

### Global Versus Local Ownership

Because AWK lacks lexical local declarations in portable code, documentation is
important for ownership.  When a global name is intentionally shared between
rules and functions, identify its owner and allowed mutation points.

When an omitted formal is used as local storage, document it with `@local`
rather than `@var`.

## BEGIN, END, and Pattern/Action Rules

A substantial portion of AWK behavior exists outside named functions.  This
standard uses `@rule` to assign stable documentation identities to these
constructs without pretending they are AWK functions.

### BEGIN Rules

Document consequential `BEGIN` blocks with a stable rule identity:

```awk
## @rule initialize
## @brief Initializes parsing configuration and global state.
## @details
## Establishes the field separator and initializes counters before the first
## input record is processed.
BEGIN {
  FS = ":"
  record_count = 0
}
```

The rule name is documentation metadata.  It is not an AWK identifier and does
not change runtime behavior.

Document assumptions established by `BEGIN` that later functions or rules rely
upon.  If command-line assignments may override values, explain precedence.

### END Rules

Document consequential `END` blocks similarly:

```awk
## @rule summarize
## @brief Emits the final processing summary.
## @details
## Reads counters accumulated by ordinary rules and writes one summary record.
END {
  print record_count
}
```

Document whether `END` executes after early `exit`, whether its output is always
produced, and what global state it expects to remain valid when those details
matter to the program contract.

### Ordinary Pattern/Action Rules

Use `@rule` for ordinary pattern/action rules whose role deserves maintained
reference documentation:

```awk
## @rule comment_lines
## @brief Ignores source comment records.
## @details
## Matches records whose first non-space character is `#`.  These records do
## not contribute to the accepted-record count.
/^[[:space:]]*#/ {
  next
}
```

The rule's documentation identity should describe its role rather than attempt
to reproduce the complete pattern text.

Document:

* what causes the rule to match;
* what state it reads and modifies;
* whether it emits output;
* whether it invokes `next`, `nextfile`, or `exit`;
* ordering relationships with other rules;
* whether earlier rules can modify `$0` or fields before this rule runs; and
* assumptions about default actions when an explicit action is absent.

### Pattern-Only and Action-Only Rules

AWK permits pattern-only rules and action-only rules.  Documentation must make
the implicit behavior explicit when it matters.

For a pattern without an action, identify that AWK's default action prints the
record.  For an action without a pattern, identify that the action runs for
every input record reaching that point.

Do not let concise AWK syntax hide a substantial output or control-flow
contract.

### Multiple BEGIN or END Blocks

When a program contains multiple `BEGIN` or `END` blocks, each documented block
must have a distinct `@rule` identity.  Documentation should explain ordering
dependencies when correctness relies on source order.

## Record and Field Semantics

AWK's implicit record model is part of many interfaces and should be documented
when non-trivial.

Relevant state includes:

* `$0`, the current record;
* `$1` through `$NF`, the current fields;
* `NF`;
* `NR` and `FNR`;
* `FILENAME`;
* `FS` and `OFS`;
* `RS` and `ORS`;
* `SUBSEP`; and
* implementation-specific record-related variables when explicitly supported.

If an operation changes a field and thereby reconstructs `$0`, document the
observable consequence when output formatting or exact record preservation
matters.

If `sub()` or `gsub()` omits its target and therefore operates on `$0`, document
that side effect when it is not obvious from the function or rule contract.

If behavior depends on a particular `FS` or `RS`, identify where that value is
established and whether callers may override it.

## Input Sources and getline

`getline` deserves explicit documentation because its forms have materially
different state and I/O behavior.

When a function or rule uses `getline`, document:

* whether input comes from the current input stream, a named file, or a command;
* whether the result replaces `$0` or is stored in another variable;
* whether `NR`, `FNR`, `NF`, or fields are affected;
* how end-of-file and read errors are distinguished;
* whether the source must be closed with `close()`;
* whether a subprocess is created; and
* portability assumptions associated with the selected form.

Do not summarize all `getline` usage as "reads another line."  The state effects
are part of the contract.

## Output, Files, Pipes, and close()

Document non-trivial output destinations and resource lifecycle.

For `print` or `printf` redirected to a file or pipe, explain:

* the destination;
* whether output appends or truncates;
* the data format;
* whether ordering matters;
* whether the destination name can be influenced by input;
* whether `close()` is required to bound open descriptors or restart commands;
* whether command execution crosses a security boundary; and
* what happens when output fails.

Do not describe a pipe command assembled from untrusted data as safe merely
because AWK invokes it indirectly.

## Regular Expressions

Document regex intent when the expression is central to a parser, validator,
redactor, security boundary, or externally visible matching contract.

Distinguish regex literals from dynamically constructed regex strings when that
difference affects escaping or interpretation.

When a regex is derived from data, document whether the data is intended to be
interpreted as regex syntax or literal text.  Do not call data "escaped" or
"literal" unless the implementation actually provides that guarantee.

Locale and multibyte assumptions must be documented when they affect character
classes, ranges, case conversion, length, matching, or substring behavior.

## String and Numeric Semantics

AWK values can carry string and numeric interpretations.  Documentation should
identify externally meaningful coercion behavior when correctness depends on
it.

Examples include:

* preserving leading zeroes;
* comparing version-like strings lexically rather than numerically;
* accepting numeric prefixes in otherwise textual input;
* converting empty strings to zero in numeric context;
* formatting numbers through `OFMT` or `CONVFMT`; and
* relying on exact textual round trips.

Do not imply strong static typing.  Document the semantic expectation and
observable behavior instead.

## ARGV, Command-Line Assignments, and ENVIRON

If AWK code interprets `ARGV`, command-line variable assignments, or `ENVIRON`,
document the configuration boundary explicitly.

For `ARGV`, identify whether entries are inspected, removed, replaced, or added.
Changing `ARGV` can alter which files AWK subsequently processes.

For command-line assignments such as:

```text
awk -v mode=strict -f program.awk input
```

or:

```text
awk -f program.awk mode=strict input
```

document timing and precedence when they matter.  Do not treat these forms as
interchangeable if initialization timing affects behavior.

For `ENVIRON`, identify the expected variable names, defaults, validation rules,
and whether values cross a security boundary.

## Process Execution and Security Boundaries

AWK can execute external commands through `system()` and command pipes.  These
operations create a materially different security boundary from ordinary text
processing.

Security-sensitive documentation should identify:

* which strings influence the command;
* whether command text is fixed or constructed;
* whether input can introduce shell syntax;
* whether a shell is involved;
* what output or exit information is consumed;
* whether the command is expected to mutate external state;
* what happens on failure; and
* which ADR governs the accepted risk or mitigation when appropriate.

Do not describe shell-command construction as escaped, quoted, or safe unless a
real mechanism establishes that property for the complete execution path.

## Security-Sensitive Documentation

For parsing, validation, redaction, transformation, output, subprocess, and file
handling code, comments should make it possible for a reviewer to answer
questions such as:

* what untrusted or sensitive state the function or rule receives;
* whether data is interpreted as text, regex syntax, file paths, or command text;
* whether values can reach STDOUT, STDERR, files, or subprocesses;
* what happens when validation or transformation fails;
* whether original input is emitted after failure;
* whether replacement text is interpreted;
* whether output structure can be changed by input;
* whether locale or multibyte behavior matters;
* what portability assumptions affect protection;
* whether global state can retain sensitive material across records; and
* which ADR establishes the relevant security promise.

Do not use comments to imply stronger runtime protection than AWK provides.
Terms such as "private," "secure memory," or "isolated" must not be used for
ordinary process variables or arrays unless a real mechanism supports the
claim.

## Examples

Examples are strongly preferred for public, parsing, transformation, redaction,
formatting, emission, configuration, or otherwise non-trivial interfaces.

Function examples should demonstrate AWK call syntax:

```awk
## @par Examples
## @code
## normalized = normalize_key(raw)
## @endcode
```

Rule examples may show representative input and output when that communicates
the contract better than executable syntax:

```awk
## @par Examples
## @code
## Input:  alpha:beta
## Output: alpha
## @endcode
```

Examples should demonstrate intended use, not manufacture a second test suite
inside comments.

## Internal Helpers

Projects may establish naming conventions for internal AWK helpers.  Such a
convention is not a privacy mechanism and is not a reason to omit documentation
from a security-critical or semantically important helper.

Document internal functions when their contract, assumptions, state mutation,
or failure behavior would otherwise need to be rediscovered from implementation.

## Document Intent, Not Syntax

Avoid comments such as "increment the counter" immediately above:

```awk
count++
```

Prefer comments that explain why the counter exists, why incrementing occurs at
that stage, what invariant the count represents, or why a seemingly unusual
implementation is necessary.

If code and documentation disagree, treat the disagreement as a defect to
investigate.  Do not automatically rewrite the comment to match current code;
the code may be the part that drifted from the intended contract.

## Relationship to ADRs

Doxygen documentation owns implementation-level intent.  ADRs own durable
architectural reasoning, promises, non-promises, compatibility and portability
decisions, adversary/failure models, rejected alternatives, and accepted
tradeoffs.

Source comments may link to an ADR when a local implementation exists
specifically to satisfy an architectural constraint.

Do not copy an entire ADR into source comments.  Do not invent historical
rationale when no source supports it.  State uncertainty or add an ADR when a
new consequential decision is required.

A project's `doc/adr/README.md`, when present, provides a curated digest of
currently governing decisions and does not replace either the full ADR or local
Doxygen contract.

## Generated Reference Documentation

Generated Doxygen output is derivative and is not a maintained source of truth.
The maintained AWK source and its governing documentation remain authoritative.

Projects may build, strip, package, or otherwise transform maintained AWK source
for distribution.  Those transformations must not become a reason to reduce the
quality of source documentation.

When `awk-doxygen` emits a pseudo-language representation for Doxygen, the
representation should preserve source intent while making only those structural
translations required for indexing.  It must not manufacture semantic certainty
that is absent from the maintained AWK source.

## General File Structure Pattern

A maintained AWK file should generally follow this order where applicable:

1. optional governed shebang;
2. `@file`;
3. `@brief` for the file;
4. substantive `@details` for the file;
5. `@author`, `@copyright`, `@see`, `@note`, and `@warning` as needed;
6. significant documented global variables and arrays;
7. functions;
8. documented `BEGIN` rules;
9. documented ordinary pattern/action rules; and
10. documented `END` rules.

Actual executable ordering may require `BEGIN`, rules, functions, or related
constructs to appear differently.  AWK does not require functions to precede
calls in source.  Preserve execution and readability requirements rather than
reordering merely to satisfy this illustrative structure.

## General Function Structure Pattern

1. `@fn`
2. `@brief`
3. `@details`
4. additional `@note`, `@warning`, `@see`, `@par Side Effects`, and
   `@par Process Exit` directives as needed
5. blank line
6. zero or more `@param` directives in caller-visible declaration order
7. zero or more `@local` directives in declaration order
8. blank line
9. exactly one `@par STDIN`
10. exactly one `@par STDOUT`
11. exactly one `@par STDERR`
12. blank line
13. exactly one `@returns`
14. zero or more `@retval` directives for discrete AWK return values
15. `@par Examples` when an example improves understanding
16. `@code`
17. example lines
18. `@endcode`

## General Rule Structure Pattern

1. `@rule`
2. `@brief`
3. `@details`
4. additional `@note`, `@warning`, `@see`, `@par Side Effects`, and
   `@par Process Exit` directives as needed
5. `@par STDOUT` and `@par STDERR` when the rule emits directly
6. `@par Examples` when useful
7. `@code`
8. representative input/output or usage lines
9. `@endcode`

Rule documentation should describe implicit record input in `@details`; rules do
not need a fictitious `@param` for `$0`.

## Review Standard

Review documentation with the same seriousness as executable code.  Ask whether
a maintainer unfamiliar with the current implementation could understand:

* the responsibility of each module;
* the contract of each function;
* which formals are caller parameters and which are conventional locals;
* important return-value semantics;
* direct STDIN, STDOUT, and STDERR behavior;
* process-exit behavior;
* global state ownership and mutation;
* record and field assumptions;
* `BEGIN`, `END`, and pattern/action responsibilities;
* meaningful edge cases and failure modes;
* portability and implementation-specific assumptions;
* regex, locale, and multibyte expectations when relevant;
* subprocess, file, and output security boundaries;
* why non-obvious implementation choices exist;
* which architectural decisions constrain future changes; and
* what the implementation explicitly does not guarantee.

There is no target comment-to-code ratio.  The desired amount is "enough to
preserve the reasoning."  In AWK programs with dense implicit behavior, this may
mean considerably more prose than teams accustomed to terse scripts expect, and
that is intentional.

## Structural Checklist

Before considering a maintained AWK file adequately documented, verify as
applicable:

* the file has `## @file`, `## @brief`, and substantive `## @details`;
* any shebang reflects actual project execution policy rather than an invented
  documentation requirement;
* portability assumptions and implementation-specific dependencies are explicit;
* all maintained functions have `@fn`, `@brief`, and `@details`;
* caller-supplied parameters are documented with `@param` in declaration order;
* conventional omitted-formal locals are documented with `@local` in declaration
  order;
* every function contains exactly one `@par STDIN`, one `@par STDOUT`, one
  `@par STDERR`, and one `@returns`;
* discrete function return values use `@retval` when that improves the contract;
* process exit behavior is not confused with AWK function return behavior;
* significant globals and arrays use `@var` where useful;
* significant `BEGIN`, `END`, and ordinary pattern/action rules use stable
  `@rule` identities where generated reference documentation adds value;
* global state ownership, record mutation, and built-in variable dependencies
  are documented when material;
* `getline`, file redirection, pipes, subprocesses, and `close()` semantics are
  documented when used materially;
* public or non-trivial functions contain an example when an example improves
  understanding;
* documentation blocks remain associated with the constructs consumed by
  `awk-doxygen`;
* and security-sensitive code documents assumptions a future reviewer would
  otherwise have to infer.
