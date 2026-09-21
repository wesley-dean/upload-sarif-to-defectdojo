# Welcome

We're so glad you're thinking about contributing to an open source project.
If you're unsure about anything, just ask -- or submit the issue
or pull request anyway. The worst that can happen is you'll be
politely asked to change something. We love all friendly contributions.

We encourage you to read this project's CONTRIBUTING policy
(you are here), its [LICENSE](LICENSE.md), and its [README](/README.md).

## Policies

We want to ensure a welcoming environment for all of our projects.
Our staff follow the
[TTS Code of Conduct](https://18f.gsa.gov/code-of-conduct/) and
all contributors should do the same.

## Engineering standards

Before submitting changes, review `AGENTS.md`, `doc/adr/README.md`, the
relevant ADRs, and applicable standards under `doc/standards/`.  Applicable
imported standards are governing requirements.  Do not silently deviate from
them or edit the imported standards locally.

## Reference documentation

Bash source documentation follows
`doc/standards/bash/documentation-standard.md`.  After preparing repository
dependencies, generate the reference site with:

```shell
make docs
```

Generated HTML under `doc/reference/` is ignored derivative output and should
not be committed.  Pull requests must leave documentation generation passing.

## Public domain

This project is in the public domain within the United States, and copyright
and related rights in the work worldwide are waived through the
[CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/).

All contributions to this project will be released under the CC0 dedication.
By submitting a pull request or issue, you are agreeing to comply with
this waiver of copyright interest.
