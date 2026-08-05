# Operating protocols

## Discovery protocol

1. Confirm device and authorized scope.
2. Inventory project roots and AI platforms.
3. Collect dialogue metadata.
4. Find project charters, specs, current state, design baselines, decisions, skills, and reports.
5. Register inaccessible sources.
6. Identify canonical-source candidates and conflicts.
7. Prioritize deeper reading.
8. Deliver a read-only inventory report.

## Task package

Include `task_id`, project, sender, receiver, objective, required reading, canonical sources, frozen constraints, allowed exploration, forbidden changes, expected output, target status, validation, approval owner, deadline, report target, and write authorization.

## Receipt

Require `task_id`, completion status, result status, documents read, unavailable documents, work completed, files changed, evidence, proposed decisions, knowledge or skill candidates, conflicts, unknowns, risks, approval needs, and next action.

## Incident protocol

```text
stop promotion
→ quarantine new outputs
→ list affected sources and dialogues
→ verify device paths and working directories
→ identify last trusted source/version
→ compare differences and impact
→ obtain required adjudication
→ restore canonical source
→ validate minimally
→ exit incident mode only after conditions pass
```

Check path changes, context compaction, old prompts, unloaded skills, stale local documentation, mixed maturity states, and missing independent verification before blaming model quality alone.

## Report gate

Check canonical origin, `APPROVED/FROZEN` status, current implementation match, evidence >= `E1`, absence of unresolved canonical conflict, accurate completed/in-progress/candidate/plan labels, current paths, and required approvals.

Return `PASS`, `CONDITIONAL`, or `FAIL` with the exact failed checks and safe wording.

## Retention protocol

- Keep core management, active execution, independent high-value capability, or unmigrated context.
- Merge responsibilities and reusable knowledge, not raw chat transcripts.
- Archive after decisions, tasks, artifacts, and successor ownership are migrated.
- Treat deletion as a candidate until target, backup, impact, recovery, and explicit user approval are documented.

## Context-minimization protocol

Give the global governor the global charter and registries. Give project managers their project charter and project state. Give executors an identity card, task package, and relevant sources. Give temporary dialogues only their task package and required attachments.

