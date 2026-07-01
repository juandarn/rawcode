---
name: rc-tdd
description: "Enforce a red → green → refactor TDD loop for a change. Trigger: implementing a behavior change where a test can define done. Composes with Gentle AI's sdd-apply."
user-invocable: true
license: MIT
metadata:
  author: rawcode
  version: "1.0"
  extends: gentle-ai
---

## Purpose

A rawcode extension for Gentle AI. It turns "add X" into a verifiable loop so
that *done* means a test passed, not that code exists. It does not replace
`sdd-apply` — it supplies the discipline `sdd-apply` runs under.

## When to use

- Implementing or fixing a behavior that a test can pin down.
- Any `sdd-apply` task whose success criterion is checkable by code.

Skip for pure refactors with existing coverage, config, or docs.

## The loop

1. **Define done.** Restate the task as a failing test. "Fix the bug" → "write a
   test that reproduces it." "Add validation" → "write a test for invalid input."
   State the success criterion in one line before touching implementation.
2. **Red.** Write the smallest test that fails for the right reason. Run it.
   Confirm it fails, and that the failure message is the one you expect — not an
   import or syntax error masquerading as a red.
3. **Green.** Write the minimum code to pass. No speculative abstraction, no
   handling for cases no test demands.
4. **Refactor.** Clean up with the test green. Re-run after every change.
5. **Verify honestly.** Run the test and quote the real result. If you did not
   run it, say so — never report green you did not see.

## Rules (rawcode discipline)

- One behavior per loop. Don't batch unrelated changes into one red-green.
- The test is the contract: if the test is wrong, fix the test first, visibly.
- Match the project's existing test framework and layout — detect it, don't impose one.
- No stub or `TODO` left passing as done.

## Compose with Gentle AI

- Under `sdd-apply`: each task in `tasks.md` enters this loop; check the task off
  only when its test is green.
- Persist nothing new — the task list and its status live wherever the active
  SDD artifact store already keeps them (`engram` / `openspec`).
- Honors strict-TDD mode: if the project's `sdd-init` marked `strict_tdd: true`,
  this loop is mandatory, not optional.
