# Squash or Merge Message Example

```text
feat: add deterministic provenance manifest

Add a release-side provenance manifest containing the source commit, release tag,
and archive digest.  Preserve the existing archive name and deterministic content
contract.

Closes #42
```

The integrated title retains the feature-level significance of the complete pull
request even if its development history also contained `fix:`, `test:`, and
`docs:` commits.
