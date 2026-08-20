# Feature catalog

Everything this framework gives you, in one place — the reference companion to the README (which is the short pitch). Many details a user-facing README can't hold live here. Kept current as features land.

## 1. Governance kernel (`core/`)
- Seven principles: you decide · documents outrank chat memory · one canonical per fact · prove the source then state the fact · exploration is not decision · not in the record is not done · the governor governs, it does not rule.
- Four state dimensions kept apart: lifecycle / execution / verification / incident.
- Authority order and gates for irreversible, structural, and public actions.

## 2. Minimal-loading runtime (`runtime/`)
- One entry file classifies every task into QUICK / NORMAL / STRUCTURAL / INCIDENT.
- A router loads only the files a mode needs; the always-loaded layer is capped (<= 8,000 non-whitespace characters).
- `GOV-*` load-bearing rules, each traceable back to the charter.
- A three-line receipt (Changed / Verified / Remaining) closes every file-changing task; ordinary conversation adds no template, and governance tasks carry at most a one-line run-status header.

## 3. The governor skill (`skills/global-ai-dialogue-governor`)
- Picks exactly one mode and states what is off-limits in it.
- Declares role, ownership, canonical sources, and Git paths before touching anything.
- Scales ceremony with risk; hard-stops for goals, irreversible actions, public release, real spending, and hard-permission changes.
- Self-correction: brakes on its own drift (GOV-013), redirects out-of-remit questions (GOV-014), replies in your language (GOV-015), and reuses before building from scratch (GOV-016).

## 4. The growth-secretary skill (`skills/growth-secretary`)
- Four-tier memory (conversation -> atom -> scenario -> persona) as plain markdown.
- Period review (week / month / custom range): evidence first — per-repo git counts, session stats, deliverables verified in place; memory is an index, never the source of current state.
- Three delivery forms: internal review, outward-facing work report (factual prose, anti-rhetoric rules, multi-round drafting), and a visual dashboard following the approved visual-records baseline.
- Proposes what is worth remembering; you approve before anything enters your profile.
- Cross-agent access: a portable memory pointer any agent (Claude / Codex / ...) can adopt, with a per-agent placement table.
- `tools/sync_memory.ps1` ships with the framework: moves the shared memory store between machines and agents (single-writer push-then-pull). Agent memory is keyed by working directory, so one machine grows several separate stores — the sync mirrors the primary one flat and archives every other root under `memory/_roots/<root>/`, because the roots collide on their index files and must not be flat-merged.
- Visual records: turn a review or memory into charts.
- **Usage accounting** (`skills/growth-secretary/tools/`): `usage_stats.mjs` walks the local session transcripts (recursively — subagent transcripts live one level down and are easy to miss) and aggregates tokens, models, main-thread vs subagent split, MCP servers, plugins, skill invocations and built-in tool counts; `render_usage.mjs` renders that into a single self-contained HTML dashboard. Local files only: no network, no account API.
- The dashboard weighs token classes by price rather than raw count, because the two answers differ: raw volume makes cache writes look dominant, while price-weighting shows re-reading the context each turn is the real cost. Optimising resident rules is a rounding error next to keeping a single conversation's context from growing without bound.
- Code-memory sub-mode: activates only on code work.

## 5. Guardrails you can mechanize (`adapters/`, `templates/`)
- A pattern for hard red-lines via your agent's settings and hooks: block destructive commands, block publishing private material into a public repo, keep projects isolated from each other.
- Templates: opening declaration, task package, receipt, decision record.

## 6. Portability across machines and models
- Two layers: the reusable method (travels unchanged) and the machine facts (rediscovered on each machine).
- **Harness desired state**: keep the *source* that generates your agent configuration, not just the installed copy. Four states are kept apart — desired (in git), observed (per-machine profile), runtime (never migrated), secrets (never in git) — so an auto-accumulated command allowlist or a session cache can't masquerade as configuration worth carrying.
- **Templates, not per-machine edits** (`harness/manifest.template.yaml`, `tools/render_harness.ps1`): the repo holds `{{PLACEHOLDER}}` templates; the renderer produces an installed copy with literal values for the machine it runs on. So two machines never overwrite each other's desired state — machine A renders `@A:/rules.md`, machine B renders `@B:/rules.md`, and the canonical source stays one file. An `@import` can't read an environment variable, but the *rendered output* is literal, so the template doesn't have to be. Secrets are injected into the installed copy only and never travel back into git. If any placeholder fails to resolve the renderer **refuses to install** rather than shipping a half-configured machine, and identifiers it cannot determine exactly — such as which memory root is yours — are reported `UNKNOWN` and must be passed explicitly. It never falls back to guessing from a drive letter: a wrong guess points somewhere that doesn't exist and then fails silently.
- **One source of truth for what must exist**: `harness/manifest.yaml` declares both the install targets and the expected hook set, each hook carrying a stable `id` and a `match` string. The renderer and the doctor both read it; neither keeps its own copy, because two lists drift apart and nothing tells you that they have.
- **`tools/doctor.ps1`**: one read-only command reports what a machine is missing or has drifted from — repos, agent install, global instructions, statusline, hooks, skills (missing / drifted / **present locally with no source in the repo**), memory (primary store plus per-root archives), per-repo git identity, remote protocol, unpushed commits, branch-protection rules, and optionally the validators. It never writes; every finding carries the command that fixes it. Deriving every path from its own location, it runs unchanged on a fresh machine.
- The doctor is **template-aware**: for files produced by rendering it does not compare hashes — the repo holds a template and the machine holds a rendered copy, so they are *supposed* to differ. It checks that the template exists and that the installed copy contains **no unresolved `{{PLACEHOLDER}}`**. It also verifies the expected hook set by identity, reporting anything **missing or duplicated**, using the list declared in the manifest rather than one of its own. Checking hook *count* is not enough: a bulk replace can overwrite one hook's body with another's, leaving the count intact, the file valid, and two hard guardrails silently gone.
- Deliberately not shipped: an installer. A half-finished `bootstrap` leaves a machine looking configured while its real state is unknown; a half-finished doctor still pays for itself, because reporting is useful even when incomplete.
- Cross-machine memory transport with a single-writer push-then-pull discipline.
- A new-machine runbook so a bare machine can be brought up step by step.

## 7. Per-project inbox (`templates/project-INBOX.md`)
- One file per project — `.governance/INBOX.md` — carrying only what a future session or the human must not lose: blocked, needs-user, resume-later.
- Deliberately one file and no more: no per-project state / roles / decisions files. A project's real state already lives in its git history, tests and spec; a second state system only drifts away from the first.
- Agent-to-agent chatter belongs in the harness's native task and message primitives, not here. Anything the human must actually decide is promoted to the single global inbox.
- `tools/project_attach_inbox.ps1` attaches it idempotently — re-running never appends a second copy, and `-WhatIf` shows what it would touch before it touches anything.

## 8. Engineering that holds it together (`tools/`, `migration/`)
- Three validators, 21 checks, gating every change.
- Rule traceability: every runtime rule pinned to its source in the charter.
- A generated, scrubbed public layer whose build fails if any personal identifier leaks in.
- Three independent version axes: governance spec / engineering wiring / release package.

## 9. Two rules that keep the governance layer from growing
- **Volume budget**: adding one thing means looking for one to remove. The goal is a thinner governance layer over time, not a more complete one.
- **The rule-of-three gate**: a single mistake, a new idea, or a theoretically possible problem does not justify a new rule / skill / hook / state file. Wait until the *same* mechanical failure has actually happened three or more times and a mechanism would measurably cut recurrence. Judgement calls (taste, architecture quality, whether a search was thorough) get a skill or a reviewer, never a hook. Capabilities the harness already provides natively do not get rebuilt.

---

Building your own instance? Keep your own copy of this catalog — it captures the decisions and details a README can't. See `BOOTSTRAP.md` to get started.
