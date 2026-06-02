---
name: golang-code-review
description: Golang code review skill for providing feedback on code changes.
disable-model-invocation: true
---

When reviewing, organize feedback by priority:

- Must fix: Issues that will cause bugs or break conventions
- Should fix: Redundant code, naming issues, test correctness
- High level: Design questions or approach problems
- Nit: Style preferences, minor improvements

Each item should include a concise writeup of the problem and use the format <problem summary>
(<filepath>:<line>): <problem detail>. Include a code example of the change if appropriate after
the detail.

All functionality should have test coverage where possible and use the
"github.com/shoenig/test/must" library and be table driven where appropriate.
