# ADR-003: Treat Configuration Files as Trusted Executable Input

Date: 2026-09-21

## Status

Accepted

## Context

Configuration files are currently sourced as Bash, which is a deliberate
compatibility surface and a code-execution trust boundary.  The existing control
flow can also discard explicit `--config` choices and allow later configuration
loading to obscure caller intent.

## Decision

Configuration files remain trusted executable Bash and must never be described as
inert data.  Operators must not source configuration from untrusted sources.

Configuration precedence, highest to lowest, is:

1. command-line values;
2. pre-existing environment variables;
3. the selected configuration file; and
4. built-in defaults.

Explicit `-c` / `--config` paths are considered before automatic discovery.
If explicit paths were supplied and none is readable, fail instead of falling
back silently.

Without explicit configuration, retain the documented discovery order: current
directory public then dotfile, containing Git repository root public then dotfile,
then HOME public then dotfile.  Source at most one configuration file per scan.

## Alternatives Considered

Replacing sourced configuration with dotenv-style parsing was deferred because it
can break valid existing Bash configuration.  Allowing config files to override
CLI values and silently ignoring missing explicit files were rejected as
surprising and difficult to audit.

## Consequences

The current trust boundary remains explicit while precedence becomes deterministic
and testable.  Any future inert configuration format requires a separate
compatibility decision.
