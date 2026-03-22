---
name: review
description: Review recent code changes for bugs, security issues, and quality problems
context: fork
agent: opencode-style:reviewer
---

Review the recent code changes in this project.

If "$ARGUMENTS" is provided, review that specific file or path:
$ARGUMENTS

Otherwise, review all uncommitted changes (staged and unstaged) using `git diff` and `git diff --staged`.

Follow the review checklist: Critical > Warning > Style. Focus on root causes.
