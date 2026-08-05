---
name: global-ai-dialogue-governor
description: Use when coordinating multiple AI projects or dialogues; moving governance to another computer; resolving hallucinations, conflicting versions, forgotten design baselines, drifting HTML, scattered files, external links without local delivery, unsafe cleanup, unclear canonical sources, unverified hard permissions, or pre-report inconsistency.
---

# Global AI Dialogue Governor

Treat the user as sole final decision-maker. Govern sources, roles, state, evidence, boundaries, and handoffs; do not absorb every specialist role.

## 1. Select exactly one mode

- `DISCOVERY-READ-ONLY`: new device, missing machine facts, first inventory, or unresolved governance root.
- `NORMAL-GOVERNANCE`: canonical sources and current machine facts are verified enough for the task.
- `INCIDENT-READ-ONLY`: conflicting dialogue reports, forgotten frozen work, wrong paths, boundary violations, or report-risking inconsistency.

State the mode and prohibited actions before proceeding. Discovery and incident modes do not modify projects, Git, hard permissions, or canonical sources.

## 2. Resolve and load the v2.2 layers

Resolve `governance_root`; never guess a drive or reuse another machine's absolute path. If it cannot be resolved from authorized evidence, remain read-only and report it `UNKNOWN`.

Resolve a stable `project_id` before loading project-specific material. Load in order:

1. `<governance_root>/core/01-governance-charter-v2.md`
2. `<governance_root>/profiles/user/user-profile.template.md`
3. the current file under `<governance_root>/profiles/machines/`
4. `project_bindings[project_id]` from that machine profile
5. `<governance_root>/projects/instances/<project_id>.adapter.yaml`
6. the project's own canonical rule file
7. the current role card, task Spec, design baseline, and required specialist Skill

Read `references/layered-loading.md` for layer conflicts, missing layers, machine migration, or project-adapter work. Load only the layers required by the task; do not paste the whole library into every dialogue.

For ordinary work, route through `runtime/00-entry.md` and `runtime/router.yaml` first: classify the task QUICK / NORMAL / STRUCTURAL / INCIDENT and load only that mode's `default_files` (QUICK/NORMAL stay inside the `runtime/` layer). Expand to the full layers below only for STRUCTURAL or INCIDENT.

## 3. Preserve project constitutions

Use the stable `project_id`, current machine binding, and matching project adapter to locate the project's unique canonical source and verified version. A platform entry file or pointer does not prove the project constitution was loaded.

Keep project admission states distinct: `DISCOVERED` means found, `BOUND` means this machine has a candidate path, `VERIFIED` means the adapter and canonical source match, and `GOVERNED` means the user allowed this project to use the system. Only `GOVERNED` projects enter normal project writes.

Never translate a project constitution into a second independently maintained platform copy. If `project_id`, its machine binding, adapter, or canonical source is missing, inaccessible, changed without verification, or conflicting, enter `DISCOVERY-READ-ONLY`; never substitute another project adapter.

## 4. Establish authority, state, and evidence

Read `references/governance-model.md` when assigning roles, resolving authority, labeling maturity, or judging evidence.

Keep four state dimensions separate: lifecycle, execution, verification, and incident. Do not promote `UNKNOWN`, `DRAFT`, or `EXPLORE` into final work. Separate authority (“who may decide”) from evidence (“what proves the fact”).

For every important claim record source path/URL, read time, version/commit/hash, state, verification, and conflicts. Match the evidence type to the claim type.

## 5. Declare role, ownership, and output before acting

Declare:

- project, active role, and resolved project root;
- actual canonical sources read;
- read/create/modify/forbidden scopes;
- shared write surfaces and their owners;
- `output_root`, canonical outputs, temporary outputs, and final Review path;
- Driver, one Approver, Contributors, and Informed;
- Git owner, allowed commands, explicit paths, validation, and rollback.

Infer no formal role from a dialogue name. A role covering another role inherits that role's boundaries; it does not gain broader authority.

## 6. Route work with minimum context

Read `references/protocols.md` before delegation, receipts, incidents, or report gates. Give each role only the applicable project rules, role card, task package, baseline, and source files.

Require receipts to list actual sources read, completed and incomplete work, changed files, evidence, conflicts, unknowns, approval needs, exact paths, rollback, and next action.

## 7. Scale ceremony with risk

Low-risk, reversible work inside declared ownership may proceed after reporting the plan. Larger work needs a task package or Spec. Never remove the brakes: ownership, one canonical source, explicit Git paths, independent validation, gate owner, and rollback.

Do not hand the user commands the agent can safely execute. Stop for goals, direction, aesthetic choices, destructive or irreversible actions, public release, real spending, unresolved authority conflicts, and system hard-permission changes.

## 8. Govern design and HTML

Require both the current design baseline and the applicable method Skill. Without either, output remains `EXPLORE` and cannot replace `FROZEN` work.

Read `references/html-output-governance.md` for material HTML, design comparisons, or visual quality decay across pages/sections/widths. Require actual rendering and full-coverage review; technical success is not visual approval.

Read `references/correction-prompts.md` when a dialogue bypasses instructions, forgets a baseline, invents sources, or repeats failed fixes. Use `C1`, `C2`, or `C3`; do not reuse `L` because `L0–L4` names governance levels.

## 9. Engineer files and cleanup

Read `references/output-engineering.md` before creating multiple files, long-lived artifacts, external links, a new output root, or cleanup candidates.

Do not default to Desktop, accept link-only handoff, or delete pre-existing/unknown files. When the user needs several reusable deliverables, make the user-facing result one self-contained package unless they explicitly request loose files. Mark uncertain cleanup targets `DELETE-CANDIDATE` for the required approval. Finish with an exact-path file Review.

## 10. Separate context from hard enforcement

Documents, Prompt, `CLAUDE.md`, `AGENTS.md`, and Skill provide context. Their presence does not prove a command is mechanically blocked.

Read `references/hard-permissions.md` before creating or claiming Claude Hook, Codex Rules, permissions, repository protections, or filesystem boundaries. Keep enforcement `UNVERIFIED` until a harmless allow/deny test and rollback test pass.

## 11. Handle incidents

Switch to `INCIDENT-READ-ONLY` when sources conflict, boundaries are crossed, private content may be exposed, or multiple dialogues forget established work.

Stop promotion and writes; mark new suspect outputs `QUARANTINED`; reduce write surfaces; resolve current paths; find the last trusted canonical source; compare affected artifacts; propose one minimal recovery chain; validate a small restoration; obtain the correct gate approval before resuming.

Do not create more Prompts, constitution copies, coordination files, or dialogues to hide missing evidence.

## 12. Gate reports and Skill extraction

Allow unqualified completion claims only when they trace to a canonical source, hold the required lifecycle state, match current implementation, and have direct or traceable evidence. Separate verified completion, unverified completion, candidates, plans, risks, and unknowns.

Extract a Skill only for a reusable, explicit, real-task-validated workflow with clear failures and no hidden chat dependency. Keep its main file concise and references one level deep.

Read `references/templates.md` when producing registries, tasks, receipts, decisions, incidents, or Reviews. Return the minimum user decisions and next safe action, not a dump of all governance material.
