"""Demonstrate the Python documentation standard.

This module is illustrative rather than normative.  It shows representative
module, class, property, function, generator, context-manager, asynchronous, raw
string, exception, and intentionally unannotated documentation forms using the
canonical Python documentation standard.
"""

from collections.abc import AsyncIterator, Iterator
from contextlib import contextmanager
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Record:
    """Represent one validated record.

    Instances are immutable value objects owned by the caller after construction.

    :param value: Canonical record value.
    """

    value: str


class Repository:
    """Represent access to a repository while its resources are valid.

    Instances expose repository state for the lifetime established by the caller.
    This example class does not perform real I/O; it exists only to demonstrate
    documentation structure.
    """

    def __init__(self, root: Path) -> None:
        """Initialize repository access for ``root``.

        :param root: Repository root represented by this instance.
        """
        self._root = root

    @property
    def root(self) -> Path:
        """Return the repository root represented by this instance."""
        return self._root


def normalize_key(value: str) -> str:
    """Normalize a lookup key.

    Leading and trailing whitespace is removed before the value is converted to
    lowercase.  The returned string does not alias mutable caller state.

    :param value: Untrusted key supplied by the caller.
    :returns: Lowercase normalized key suitable for lookup.
    :raises ValueError: The normalized value would be empty.

    Example::

        normalized = normalize_key(" Demo ")
    """
    normalized = value.strip().lower()
    if not normalized:
        raise ValueError("value must contain non-whitespace characters")
    return normalized


def iter_records(path: Path) -> Iterator[Record]:
    """Yield validated records from ``path``.

    Iteration is lazy.  The file is opened when iteration begins and is closed
    when iteration ends or the generator is finalized.

    :param path: Input file containing one record per line.
    :yields: Validated records in source order.
        Blank lines are ignored rather than emitted as empty records.
    :raises OSError: The input cannot be opened or read.
    :raises ValueError: A non-blank record cannot be normalized.
    """
    with path.open("r", encoding="utf-8") as stream:
        for line in stream:
            if line.strip():
                yield Record(normalize_key(line))


@contextmanager
def opened_repository(path: Path) -> Iterator[Repository]:
    """Yield repository access for the duration of a context.

    The yielded object remains valid only until the context exits.  Cleanup runs
    whether the context body succeeds or raises.

    :param path: Repository root made available inside the context.
    :yields: Repository access valid for the lifetime of the context.
    """
    repository = Repository(path)
    try:
        yield repository
    finally:
        pass


async def iter_remote_records(source: str) -> AsyncIterator[Record]:
    """Yield records from an asynchronous source.

    This illustrative implementation emits no records.  A real implementation
    would document cancellation, timeout, resource ownership, and cleanup
    semantics appropriate to its transport.

    :param source: Logical remote source identifier.
    :yields: Validated records as they become available.
    """
    if source == "":
        return
    if False:
        yield Record(source)


def load_unannotated(path):
    """Load a configuration value from an intentionally unannotated interface.

    This example demonstrates the permitted type-field form for code whose
    interface intentionally lacks Python annotations.

    :param path: Filesystem path to read.
    :type path: pathlib.Path
    :returns: Text read from the requested file.
    :rtype: str
    :raises OSError: The file cannot be opened or read.
    """
    return path.read_text(encoding="utf-8")


def windows_pattern() -> str:
    r"""Return a regular-expression fragment containing literal backslashes.

    A raw docstring is appropriate here because the documentation itself contains
    backslashes whose literal spelling matters.

    :returns: Regular-expression fragment matching a Windows-style separator.
    """
    return r"\\"
