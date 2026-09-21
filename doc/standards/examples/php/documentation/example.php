<?php

declare(strict_types=1);

namespace Example\Documentation;

use InvalidArgumentException;
use RuntimeException;

/**
 * Represent a validated application configuration.
 *
 * Instances are immutable after construction.  The object owns its normalized
 * configuration values and does not retain a reference to the caller-supplied
 * input array.
 */
final class Configuration
{
    /**
     * Create a configuration from validated values.
     *
     * @param array<string, scalar|null> $values Normalized configuration values.
     */
    public function __construct(
        private readonly array $values,
    ) {
    }

    /**
     * Return a configuration value by key.
     *
     * The method distinguishes between a missing key and a key whose value is
     * explicitly null by requiring the caller to supply a default value.
     *
     * @param string $key Logical configuration key to read.
     * @param scalar|null $default Value returned when the key is absent.
     * @return scalar|null The stored value when present; otherwise $default.
     */
    public function get(string $key, string|int|float|bool|null $default = null): string|int|float|bool|null
    {
        return $this->values[$key] ?? $default;
    }
}

/**
 * Load and validate configuration from a PHP array.
 *
 * The function normalizes supported keys, rejects unsupported value shapes, and
 * returns a configuration object that owns its normalized data.  The caller's
 * input array is not modified.
 *
 * @param array<string, mixed> $input Untrusted configuration data to validate.
 * @return Configuration A validated configuration owned by the caller.
 * @throws InvalidArgumentException A key is empty or a value has an unsupported type.
 * @see Configuration
 */
function loadConfiguration(array $input): Configuration
{
    $normalized = [];

    foreach ($input as $key => $value) {
        if ($key === '') {
            throw new InvalidArgumentException('Configuration keys must not be empty.');
        }

        if (!is_scalar($value) && $value !== null) {
            throw new InvalidArgumentException(
                sprintf('Unsupported value type for configuration key "%s".', $key),
            );
        }

        $normalized[$key] = $value;
    }

    return new Configuration($normalized);
}

/**
 * Normalize a repository identifier for use as a lookup key.
 *
 * Leading and trailing whitespace is removed and the remaining identifier is
 * converted to lowercase.  Empty identifiers are rejected rather than silently
 * normalized to an unusable cache key.
 *
 * @param string $value Repository identifier supplied by the caller.
 * @return string Canonical lowercase repository identifier.
 * @throws InvalidArgumentException The identifier is empty after trimming.
 */
function normalizeRepositoryId(string $value): string
{
    $normalized = strtolower(trim($value));

    if ($normalized === '') {
        throw new InvalidArgumentException('Repository identifier must not be empty.');
    }

    return $normalized;
}

/**
 * Return the legacy default cache directory.
 *
 * @deprecated Use cacheDirectory() so callers can provide an explicit root.
 * @return string Absolute path to the legacy cache directory.
 * @see cacheDirectory()
 */
function legacyCacheDirectory(): string
{
    return '/var/cache/example';
}

/**
 * Build a cache directory beneath a caller-supplied root.
 *
 * The function performs no filesystem mutation.  It only returns the path the
 * caller may later create or use.
 *
 * @param string $root Absolute cache root.
 * @param string $namespace Logical namespace appended beneath the root.
 * @return string Absolute cache directory path.
 * @throws InvalidArgumentException The root is not absolute or the namespace is empty.
 */
function cacheDirectory(string $root, string $namespace): string
{
    if ($root === '' || $root[0] !== '/') {
        throw new InvalidArgumentException('Cache root must be an absolute path.');
    }

    $namespace = trim($namespace);
    if ($namespace === '') {
        throw new InvalidArgumentException('Cache namespace must not be empty.');
    }

    return rtrim($root, '/') . '/' . $namespace;
}

/**
 * Persist configuration as JSON.
 *
 * Existing files are replaced atomically by writing to a temporary file in the
 * destination directory and renaming it into place.  A successful return means
 * the final path contains the complete encoded document.
 *
 * @param Configuration $configuration Configuration to serialize.
 * @param string $path Destination path to replace.
 * @return void
 * @throws RuntimeException Encoding, writing, or replacement fails.
 */
function persistConfiguration(Configuration $configuration, string $path): void
{
    $directory = dirname($path);
    $temporary = tempnam($directory, 'config-');

    if ($temporary === false) {
        throw new RuntimeException('Unable to create temporary configuration file.');
    }

    try {
        $payload = json_encode($configuration, JSON_THROW_ON_ERROR | JSON_PRETTY_PRINT);
        if (file_put_contents($temporary, $payload . PHP_EOL) === false) {
            throw new RuntimeException('Unable to write temporary configuration file.');
        }

        if (!rename($temporary, $path)) {
            throw new RuntimeException('Unable to replace configuration file.');
        }
    } finally {
        if (is_file($temporary)) {
            @unlink($temporary);
        }
    }
}

/**
 * Default retry delays in milliseconds.
 *
 * @var list<int>
 */
const RETRY_DELAYS_MS = [100, 250, 500];
