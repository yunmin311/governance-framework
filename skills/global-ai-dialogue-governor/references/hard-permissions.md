# Hard permissions and enforcement evidence

## Core distinction

Context tells an agent what it should do. Mechanical enforcement determines what the runtime permits it to do. A rule written in a document is not evidence that a forbidden operation will be blocked.

| Control | Context or enforcement | Claim allowed before test |
|---|---|---|
| Prompt / Skill | context | agent was instructed |
| `CLAUDE.md` / `AGENTS.md` | context | file was loaded only with evidence |
| Claude Hook | enforcement candidate | `UNVERIFIED` |
| Codex Rules | enforcement candidate | `UNVERIFIED` |
| Codex permissions | enforcement candidate | `UNVERIFIED` |
| filesystem ACL / repository protection | external enforcement | actual tested scope only |

## Prioritize these tripwires

- design roles and child agents cannot run Git write commands;
- a role cannot write another project or another role's canonical files;
- private/company material cannot enter a public repository;
- deletion, force-push, remote changes, and history rewrite require their gate;
- machine instances, credentials, and tokens cannot enter portable releases.

## Safe rollout

1. Record the platform/version, configuration path, target role, forbidden pattern, and rollback.
2. Use a temporary repository or disposable directory; do not test against live project data.
3. Run one harmless command that should be allowed and record the result.
4. Run one harmless command that should be denied and record the result.
5. Remove or disable the rule, verify rollback, then restore only the validated configuration.
6. Mark the exact control `VERIFIED`; leave untested controls `UNVERIFIED`.

## Platform routing

### Claude

Use `CLAUDE.md` or verified imports for context. Use Hook for supported tool-call blocking. Do not claim a Hook key or event name from memory; verify current platform behavior before changing machine configuration.

### Codex

Use layered `AGENTS.md` and Skills for context. Use Rules for command-pattern controls and permissions for filesystem/tool boundaries when supported. A text pointer in `AGENTS.md` is not a reliable import unless the active harness demonstrates it.

### Generic chat

No local enforcement is available. Treat all Prompt rules as context only and move risky execution to a controlled tool environment or human gate.

## Evidence record

For every control record:

```yaml
control_id: stable-name
platform: claude-or-codex
version: observed-version
scope: role-and-path
configuration_source: exact-path
allowed_test: command-and-result
denied_test: command-and-result
rollback_test: command-and-result
verification: VERIFIED-or-UNVERIFIED
verified_at: ISO-8601
```

## Failure behavior

If the denied action succeeds, stop and mark the control `FAILED`; do not add broader live restrictions while debugging. If the allowed action is blocked, roll back and narrow the rule. If platform documentation and observed behavior disagree, observed behavior governs the machine record and the discrepancy remains open.
