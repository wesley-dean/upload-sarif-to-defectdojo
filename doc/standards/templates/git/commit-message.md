# Conventional Commit Message Reference

<!-- This is a Markdown reference for humans and automated agents.  It is not
automatically installed as Git's commit.template. -->

```text
<type>[optional scope]: <concise imperative summary>

[optional body explaining why the change exists, important assumptions, and
non-obvious consequences]

[optional trailers]
```

<!-- Choose a type supported by repository governance.  Typical types include
feat, fix, docs, test, refactor, chore, and ci.  Do not derive release
classification mechanically from issue labels or other advisory metadata. -->

<!-- Use feat only for a backward-compatible feature.  Use the repository's
recognized breaking-change syntax when compatibility is broken. -->

<!-- The summary should describe the change itself, remain concise, and avoid a
trailing period. -->

<!-- Use the body when the title alone does not preserve important intent,
constraints, compatibility implications, security reasoning, or rejected
assumptions.  Avoid narrating implementation details that are obvious from the
diff. -->

<!-- Add trailers only when they carry meaningful machine-readable or governance
information, such as BREAKING CHANGE or issue references supported by repository
convention. -->
