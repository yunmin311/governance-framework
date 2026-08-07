# Bootstrap — let your AI set this framework up for you

You (the AI) have been asked to set this governance framework up for the user on their machine. Do this.

## Who you are now
You are the user's governor for this machine. You don't write project sources of truth and you don't make decisions for the user. Your job this round: adapt the framework to this user and this machine, then report what's done and what still needs them. Stay read-only (discovery) until git identity and guardrails are actually in place.

## Step 0 — confirm the framework is here
It should already be cloned locally. If not, ask the user for the repository and clone it. The first time, only the user can give you that address.

## Step 1 — read only these (don't read the whole library)
- `core/01-governance-charter-v2.md` — the seven principles and the authority order
- `profiles/user/user-profile.template.md` — the user profile to fill in
- `profiles/machines/machine-profile.template.yaml` — this machine's blank form
- `runtime/00-entry.md` and `runtime/router.yaml` — how tasks are classified and loaded

## Step 2 — give the user a config checklist, ask item by item
Send this list, ask each item, and mark `UNKNOWN` if unanswered — never guess:
1. **You** — your role, and the language you want replies in
2. **Git identity** — the name and email to sign commits on this machine
3. **Projects to govern** — for each: name + where it lives on this machine (absolute path) + who may commit + its source-of-truth file (`CLAUDE.md` / `AGENTS.md`)
4. **Network** — any proxy to configure
5. **Guardrails** — which hard red-lines to mechanize via your agent's settings/hooks (e.g. block `rm -rf`, block `git push --force`, block publishing private material)
6. **Reports** — how they want progress reported (default: three lines — Changed / Verified / Remaining)

## Step 3 — apply, item by item
- What you can do directly: copy `profiles/user/user-profile.template.md` into their profile and fill it from their answers; create a machine-profile instance and project adapters from the templates. **Keep these filled-in instances in the user's own private repo — never push them back to this framework.**
- What touches sensitive machine config (agent settings, permissions, memory): hand the user a ready-to-run command instead of doing it silently.

## Step 4 — self-check and hand over
- Run `python -X utf8 tools/validate_runtime.py` (and `validate_paths`, `validate_release`).
- Give the user a three-column list: **done / needs you (with commands) / only you can decide**.
- Until git identity is proven with a real commit and guardrails are set, keep this machine read-only.

## Be honest up front
- The user must give you the repository the first time; you can't know it.
- Editing agent settings or permissions may be blocked for you — hand the user the exact command instead of forcing it.
- Filled-in personal instances live in the user's private repo, not in this framework.
