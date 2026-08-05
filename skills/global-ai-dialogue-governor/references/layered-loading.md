# Layered governance loading

## Purpose

Load only the rules required for the current device, project, role, and task while preserving one canonical source for each fact.

## Layer contract

| Layer | Answers | May contain | Must not contain |
|---|---|---|---|
| Governance core | What is never bypassed? | authority, evidence, state, gates, incidents | machine paths, project implementation |
| User profile | How does this user work? | durable preferences and delegation style | temporary project facts |
| Machine profile | What is true on this device? | paths, project bindings, installed platforms, verified permissions | portable universal rules |
| Project adapter | Where is the project truth and who owns what? | stable project ID, canonical source, roles, gates, loading contract | machine paths or a copied project constitution |
| Project canonical source | What is true inside this project? | architecture, product constraints, file ownership | cross-project authority changes |
| Role/task context | What may happen now? | scopes, Spec, baseline, output, approver | permanent rule changes |

## Resolution procedure

1. Resolve `governance_root` from an actual package, repository, or user-provided path.
2. Verify the core and user profile are readable and record their version/state.
3. Match the current device to one machine instance. If none exists, use the neutral template in discovery mode.
4. Resolve a stable `project_id`; do not derive identity from the first adapter found.
5. Resolve `project_bindings[project_id]` on the current device. Re-discover this path after moving computers.
6. Read `projects/instances/<project_id>.adapter.yaml` and verify its remote and rule path against the current binding.
7. Read the project canonical source in full when it governs the requested action.
8. Declare the active role and task scopes before any write.

## Project admission states

- `DISCOVERED`: a candidate project was found.
- `BOUND`: this machine has a candidate local path.
- `VERIFIED`: the binding, adapter, remote, and canonical rule source match.
- `GOVERNED`: the user authorized the project to use this governance system.

Do not treat discovery as authorization. A missing adapter produces a candidate from `projects/project-adapter.template.yaml`; it never reuses another project's identity.

## Missing and conflict handling

- Missing core or user profile: stop governance writes; report the package incomplete.
- Missing machine instance: discovery only; create a candidate from verified observations, never copy an old instance.
- Missing project binding: read-only discovery; rebuild only the current machine's binding from remote and rule-file evidence.
- Missing project adapter: read-only inventory; propose an adapter without copying project rules or another project adapter.
- Missing project canonical source: stop dependent project writes and mark `UNKNOWN`.
- Adapter/source version mismatch: record both versions and compare; do not silently select one.
- Project rule conflicts with the governance core: apply the higher authority and request the correct Approver.

## One-canonical-source check

Before creating a new rule file, ask:

1. Does a canonical source already exist?
2. Can this file be an adapter, generated copy, or pointer instead?
3. Who edits it, and what prevents two copies from evolving?

If two files would both be edited for the same fact, the design is invalid. Keep the rule in one source and make the other file a tested loading entry.

## Minimum-context examples

- Ordinary QUICK task: `runtime/00-entry.md` + `runtime/01-core-rules.md` + `runtime/02-user-runtime-profile.md` only; do not open the full charter or user profile (see `runtime/router.yaml`).
- New computer: core + user profile + machine template + discovery launcher.
- Normal project task: core + user profile + machine instance + project adapter + project canonical + task.
- Design task: normal project set + current design baseline + method Skill.
- Incident: core + machine instance + affected adapters/canonical sources + evidence logs; do not load unrelated projects.

## Exit evidence

Report the resolved root, layers actually read, versions, inaccessible layers, conflicts, active mode, permitted action, and next safe step.
