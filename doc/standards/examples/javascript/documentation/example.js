/**
 * Load and validate application configuration.
 *
 * Reads a configuration document and returns the validated application
 * configuration.  The function does not modify the source file.
 *
 * @param {string} path - Path to the configuration document.
 * @param {boolean} [strict=true] - Whether unknown keys are rejected.
 * @returns {Promise<Configuration>} Validated configuration owned by the caller.
 * @throws {TypeError} If `path` is not a non-empty string.
 */
async function loadConfiguration(path, strict = true) {
  return readAndValidateConfiguration(path, strict);
}

/**
 * Yield validated records in source order.
 *
 * Iteration is lazy.  Callers may stop before exhausting the source without
 * retaining the underlying reader.
 *
 * @param {Iterable<string>} lines - Source records to validate.
 * @yields {Record} Validated records in source order.
 */
function* iterRecords(lines) {
  for (const line of lines) {
    yield validateRecord(line);
  }
}
