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
- A three-line receipt (Changed / Verified / Remaining) closes every task.

## 3. The governor skill (`skills/global-ai-dialogue-governor`)
- Picks exactly one mode and states what is off-limits in it.
- Declares role, ownership, canonical sources, and Git paths before touching anything.
- Scales ceremony with risk; hard-stops for goals, irreversible actions, public release, real spending, and hard-permission changes.
- Self-correction: brakes on its own drift (GOV-013), redirects out-of-remit questions (GOV-014), replies in your language (GOV-015), and reuses before building from scratch (GOV-016).

## 4. The growth-secretary skill (`skills/growth-secretary`)
- Four-tier memory (conversation -> atom -> scenario -> persona) as plain markdown.
- Weekly review: proposes what is worth remembering; you approve before anything enters your profile.
- Cross-agent access: a portable memory pointer any agent (Claude / Codex / ...) can adopt, with a per-agent placement table.
- Visual records: turn a review or memory into charts.
- Code-memory sub-mode: activates only on code work.

## 5. Guardrails you can mechanize (`adapters/`, `templates/`)
- A pattern for hard red-lines via your agent's settings and hooks: block destructive commands, block publishing private material into a public repo, keep projects isolated from each other.
- Templates: opening declaration, task package, receipt, decision record.

## 6. Portability across machines and models
- Two layers: the reusable method (travels unchanged) and the machine facts (rediscovered on each machine).
- `BOOTSTRAP.md`: tell your AI to set the framework up and it walks you through a short checklist.
- Cross-machine memory transport with a single-writer push-then-pull discipline.
- A new-machine runbook so a bare machine can be brought up step by step.

## 7. Engineering that holds it together (`tools/`, `migration/`)
- Three validators, 21 checks, gating every change.
- Rule traceability: every runtime rule pinned to its source in the charter.
- A generated, scrubbed public layer whose build fails if any personal identifier leaks in.
- Three independent version axes: governance spec / engineering wiring / release package.

---

Building your own instance? Keep your own copy of this catalog — it captures the decisions and details a README can't. See `BOOTSTRAP.md` to get started.
