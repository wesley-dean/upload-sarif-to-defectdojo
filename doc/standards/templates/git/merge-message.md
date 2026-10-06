# Squash or Merge Message Reference

<!-- This is a Markdown reference for humans and automated agents.  Hosting
platforms vary in how merge messages are configured.  Standards adoption does not
change repository merge settings automatically. -->

```text
<highest-significance Conventional Commit title>

[optional integration summary]

[optional trailers]
```

<!-- The title must preserve the highest semantic significance of the complete
pull request.  A later fix, documentation change, or test commit must not reduce
an earlier feature or breaking-change classification. -->

<!-- When squash merging, prefer the reviewed pull-request title as the final
target-branch commit title when repository tooling supports it. -->

<!-- Use the optional integration summary when the final commit needs durable
context that would otherwise exist only in the pull-request discussion.  Summarize
the integrated outcome, important migration information, or material security and
compatibility consequences. -->

<!-- Do not copy untrusted issue titles, labels, comments, or generated metadata
mechanically into release-significance fields. -->

<!-- Verify the final title and message before completing the merge when the
hosting platform may rewrite them. -->
