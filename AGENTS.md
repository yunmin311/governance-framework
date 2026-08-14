# Repository Instructions

Any non-Claude agent (Codex or otherwise) working in this repository: this file is your entry point. It points to canonical sources; it does not duplicate them — when in doubt, the pointed-to file wins.

## Start here, every task

1. Read `runtime/00-entry.md` and classify the task **QUICK / NORMAL / STRUCTURAL / INCIDENT**.
2. Load only the files `runtime/router.yaml` lists for that mode (budget: ≤5 governance files, ~8,000 chars). A file existing does not mean you must read it.
3. The load-bearing rules are `runtime/01-core-rules.md` (**GOV-001…016**). The user runtime profile `runtime/02-user-runtime-profile.md` is the shared baseline every role inherits — do not invent your own reply style, questioning habits, or evidence rules on top of it.

## How to behave

- Reply in the **user's own language**, whatever language these documents are in (GOV-015).
- Plain conversation gets **no template**. The three-line engineering receipt (`Changed / Verified / Remaining`) is only for turns that actually modified files or code.
- Governance / routing / project-state tasks may open with at most one status line (`运行：<MODE> · <项目>｜角色｜依据｜动作`); never expand it into a full declaration.
- Before building anything new, search for an existing solution and say what you found and why you reuse / adapt / build (GOV-016 Reuse-First).
- Current project facts come from: project files / Git / tests > approved Spec or baseline > project adapter > registry > memory / old chats / handoffs — the last tier only locates evidence, it never alone proves current state (GOV-003).
- On your own drift: stop, locate it, repair the current facts and boundaries first; do not default to writing memories or new rules over a single mistake (GOV-013).

## Canonical sources

- Treat `docs/*.md`, `templates/*`, `skills/*`, and `launchers/*.txt` as canonical source artifacts.
- Treat `published/*`, `releases/*`, the Obsidian mirror, and Desktop copies as generated or distribution artifacts.
- Do not edit a generated copy without updating its canonical source and rebuilding all affected outputs.

## Git and safety

- Stage **explicit paths only** (never `git add -A` / `git add .`); one writer per repository at a time — cross-machine coordination is single-writer push-then-pull through the remote, never simultaneous edits.
- No history rewrite and no force-push without the user present and approving.
- Run the three validators before any push and keep them green:
  `python -X utf8 tools/validate_runtime.py` · `tools/validate_paths.py` · `tools/validate_release.py`
- Keep governance status `CANDIDATE` until the user explicitly approves the charter itself.
- Do not modify sibling repositories outside this repo's root while working here; concrete local paths live in this machine's profile under `profiles/machines/`, never in this file (it ships publicly).
- Do not delete pre-existing files, approved outputs, sources, receipts, or unknown files without explicit user approval.
- Before creating multiple files, declare `output_root`, file scope, canonical outputs, temporary outputs, and final Review location.

## Machine and memory

- Machine facts (paths, deployment state, per-machine hard permissions) live under `profiles/machines/` (instance files stay in your private repo) — rediscover them on a new machine, never copy another machine's.
- If this instance repository carries a `memory/` directory, read `memory/MEMORY.md` first — it is the shared cross-agent memory index; individual memory files are loaded on demand, not wholesale. Profile changes always need explicit user approval.

## Engineering-repo extras (not part of the portable framework layer)

- Build scripts (`build_v2_2_3_release`, handbook rendering, `verify_*_delivery`), DOCX/PDF re-render, Obsidian sync, and the official Skill validator run only in the engineering canonical repo — run them before release-affecting changes there; they do not ship with the portable framework.
