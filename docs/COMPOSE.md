# Using rawcode with Gentle AI

rawcode works on its own, but it's built to compose with the gentleman-programming
stack (SDD skills, engram, the Gentleman output style). This is the cookbook.

## Install order

1. Keep your Gentle AI setup as-is (SDD skills, engram, Gentleman output style).
2. Add rawcode as a plugin:
   ```bash
   claude plugin marketplace add juandarn/rawcode
   claude plugin install rawcode@rawcode
   ```
3. That's it. rawcode's guardrails and the TDD gate load automatically. Nothing
   about your Gentle AI config changes.

## Which output style is active?

They share one slot — only one output style runs at a time.

- Want the **Gentleman** mentor persona for chat? Keep it. rawcode still gives you
  guardrails, the TDD gate, and `bench/`; use `rc-tdd` when you want its coding loop.
- Want the **rawcode** terse coding persona? `/output-style rawcode`. Switch back
  with `/output-style Gentleman` any time. rawcode never changes this for you.

## During an SDD change

| SDD phase | rawcode composes by |
|-----------|---------------------|
| `sdd-apply` | implementing each task through the `rc-tdd` red→green→refactor loop; the TDD gate blocks a "done" with untested code |
| `sdd-verify` | running `rc-bench` for a real pass@1 / token number, and letting the guardrails enforce safety |
| any phase | the "don't guess — verify the source" and "no false done" rules apply to every edit |

rawcode never writes SDD artifacts of its own — task lists, specs, and reports
stay in whatever store SDD already uses (`engram` / `openspec`).

## Turning the TDD gate off for a change

The gate is strict by default. Skip it when you mean to:

- Say it in the prompt: "urgent", "hotfix", or "skip tdd".
- Or drop a marker in the repo: `touch .rawcode-no-tdd` (remove it to re-enable).

## Standalone (no Gentle AI)

Everything above still works without the SDD skills installed: the persona,
guardrails, TDD gate, and `bench/` have no dependency on them. `rc-tdd` and
`rc-bench` are self-contained skills.
