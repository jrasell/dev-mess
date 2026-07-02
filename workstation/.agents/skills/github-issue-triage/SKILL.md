---
name: github-issue-triage
description: GitHub project issue triage
disable-model-invocation: true
---

Keep all responses concise.

When triaging an issue for an application written in Golang, first determine whether the bug report
or feature request makes sense and is relevant to the codebase. Then respond using the format for
its type below. Each response items should be concise and to the point using a H4 markdown header.
## Gathering context

Before responding, collect the facts needed to fill in the sections below:

- Read the issue with `gh issue view <url-or-number> --comments` (title, body, labels, comments).
- Search related work with `gh issue list --search` and `gh pr list --search`.
- Confirm the affected version, then inspect the matching code in the local checkout for code links
  and originating PRs (`git log`, `git blame`).
- Note the reporter's environment: Go version, OS/arch, and application version.

Begin every response with a header line: issue number, title, link, and classification (bug /
feature request, and whether it is valid).

## Feature request

Respond with the following information:

- Related issues: the issue number and whether it is a duplicate or similar request
- Summary: why the request is or is not useful and related to the codebase
- Workaround: whether there is a way to work around the issue until it is resolved

## Bug report

Assess whether the bug is accurate. If it is legitimate, respond with:

- Reproduction: a minimal reproduction
- Related issues: the issue number and whether it is a duplicate or similar in nature
- Originating PRs: the source of potential regressions
- Code links: links to relevant code sections
- Workaround: whether there is a way to work around the issue until it is resolved

If the bug is not accurate, respond with:

- Assessment: why the reported behavior is not a bug (for example, expected behavior, user error,
  outdated version, or misread output)
- Evidence: code links or documentation that show the actual, intended behavior
- Clarification: any missing information needed to confirm the assessment, such as version, config,
  or reproduction steps
- Next steps: whether to close the issue, request more detail, or redirect to support or discussion
