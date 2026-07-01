# rawcode as a Gentle AI extension — architecture & merge plan

rawcode does **not** rebuild spec-driven development or TDD. Gentle AI (the
gentleman-programming skill set: `sdd-*`, `_shared/`, engram, the Gentleman
output style) already does that well. rawcode plugs into it as an **extension**:
it contributes the pieces Gentle AI doesn't have, and reuses everything it does.

## Works standalone OR as an extension

rawcode has **no hard dependency** on Gentle AI. Installed alone, its persona,
guardrails, `bench/`, and the strict TDD gate all work. Installed alongside
Gentle AI, its skills follow the same conventions and compose with `sdd-*`
instead of duplicating them — degrading gracefully either way.

## TDD is strict by default

TDD is on for every code change, enforced mechanically by the `tdd-gate` Stop
hook — not left to the model's goodwill. It is skipped only when the user
explicitly signals urgency ("urgent", "hotfix", "skip tdd") or drops a
`.rawcode-no-tdd` marker. The gate blocks at most once per turn, so it nudges
without ever looping.

## What each side owns

| Concern | Owned by | rawcode's role |
|---------|----------|----------------|
| SDD flow (explore→…→archive) | **Gentle AI** (`sdd-*` skills) | reuse as-is; never duplicate |
| Memory / artifacts | **Gentle AI** (engram / openspec) | reuse; write rawcode artifacts under the same convention |
| Communication persona | **Gentle AI** (Gentleman output style) | leave it alone — rawcode is a *coding* discipline, not a chat persona |
| Concise/root-cause/honest **coding** discipline | **rawcode** | the output-style + prompt (exists) |
| Safety guardrails (block `.env`/locks/migrations, read-before-write, commit hygiene) | **rawcode** | the hooks (exist) |
| Quantitative quality gate (pass@1 A/B, token deltas) | **rawcode** | `bench/` (exists) |
| Mechanical TDD enforcement | **rawcode** | new: a TDD-gate hook + `rc-tdd` skill |
| "Don't guess — verify the source" discipline | **rawcode** | prompt rule (exists) |

## Integration surface (how it plugs in)

rawcode follows the **exact gentleman conventions** so its pieces are first-class
in the ecosystem:

- **Skill format:** `skills/<name>/SKILL.md` with the gentleman frontmatter
  (`name`, `description`, `disable-model-invocation`, `user-invocable`, `license`,
  `metadata: {author, version}`), and the orchestrator-gate/delegate pattern.
- **Artifacts:** any rawcode artifact persists under the same key convention
  (`sdd/{change-name}/{artifact-type}` in engram, or `openspec/…`), so `sdd-verify`
  and friends can find it. No new backend.
- **Skill registry:** rawcode's skills register in `.atl/skill-registry.md` /
  engram like every other skill, so the orchestrator resolves them.

### Concrete extension points

1. **`sdd-apply` runs under rawcode discipline** — when Gentle AI implements a
   task, the rawcode output-style/persona supplies the "minimal, root-cause,
   no-false-done, verify-the-source" coding rules. Documented as a compose step,
   not a fork of `sdd-apply`.
2. **TDD gate** — a hook that blocks a "done" claim on a change with a test
   target until a test actually ran. Complements `sdd-apply`'s strict-TDD mode
   with mechanical enforcement (the model can't self-certify).
3. **`rc-bench` as a verify tool** — `sdd-verify` (or the user) can call rawcode's
   `bench/` to get a real pass@1 / token-delta number instead of a vibe.
4. **Guardrails always-on** — rawcode's PreToolUse hooks protect every session,
   SDD or not.

## Why an extension, not a fork

- **No duplication, no drift.** One SDD implementation to maintain (Gentle AI's).
- **rawcode stays honest to its identity** — it's still "a coding discipline you
  can ignore," now composable with a planning framework when you want one.
- **The benchmark evidence holds** — the minimal persona is untouched; we only
  add opt-in gates around it.

## Merge plan (phased, each a tested PR)

- **Phase 1 (this PR):** `skills/rc-tdd/SKILL.md` (gentleman-format TDD loop),
  the TDD-gate hook, `plugin.json` declaring skills + the new hook, bats coverage,
  and this doc. Composes with `sdd-apply`; duplicates nothing.
- **Phase 2:** `rc-bench` skill wrapping `bench/` as a callable verify tool;
  document the `sdd-verify` compose step.
- **Phase 3:** a short `docs/COMPOSE.md` cookbook — "using rawcode + Gentle AI
  together" (install order, which output-style, how the TDD gate interacts with
  strict-TDD mode).
- **Phase 4:** publish rawcode to the same marketplace/registry so `sdd-*` and
  `rc-*` sit side by side.

## Open decisions

1. Command prefix `rc-*` (recommended) so rawcode skills are visually distinct
   from `sdd-*`.
2. Does the TDD gate run as `Stop` (block end-of-turn) or `PostToolUse` on a
   completion signal? Default: `Stop`, scoped to sessions that touched code.
3. When both the Gentleman and rawcode output styles exist, which is active is
   the user's choice — rawcode never overrides it (learned from the install).
