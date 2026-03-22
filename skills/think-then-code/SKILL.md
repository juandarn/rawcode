---
name: think-then-code
description: Two-phase workflow — reason with Opus first, then code with Sonnet. Best for complex tasks.
---

Execute a two-phase workflow for the following task:

$ARGUMENTS

## Phase 1: Think (Opus)

Delegate to the `rawcode:think` agent to analyze the problem and create a detailed plan. The think agent uses Opus for deep reasoning and cannot modify files.

Wait for the plan before proceeding.

## Phase 2: Code (Sonnet)

Take the plan from Phase 1 and delegate to the `rawcode:code` agent to execute it. The code agent uses Sonnet for fast code writing.

After coding is complete, verify the changes work.
