# Governance model

## Authority order

1. User's explicit decision for the current matter.
2. Approved global charter.
3. Current project's canonical charter.
4. Frozen project decisions and current-state source.
5. Formal domain or design baseline.
6. Dialogue identity card or dialogue-level rules.
7. Current task spec.
8. Approved decision records.
9. Verified knowledge base.
10. Dialogue history.
11. AI inference.

Lower authority cannot overwrite higher authority. Escalate same-level conflicts to the user.

## Evidence levels

| Level | Meaning | Examples |
|---|---|---|
| `E0` | Direct current evidence | current file, working tree, database inspection, real run |
| `E1` | Traceable formal record | commit, test log, approved decision, versioned source |
| `E2` | Multiple independent corroborating sources | two sources pointing to the same fact |
| `E3` | Single-dialogue report | completion statement with limited evidence |
| `E4` | Memory, retelling, or inference | “I remember”, “probably”, “should be” |

Use at least `E1` for reportable completion claims. Prefer `E0` for current state.

## Maturity states

| State | Use |
|---|---|
| `UNKNOWN` | source or validity cannot be confirmed |
| `DRAFT` | unverified draft |
| `EXPLORE` | deliberately changeable exploration |
| `CANDIDATE` | complete candidate awaiting approval |
| `APPROVED` | authorized for use |
| `FROZEN` | protected; executors cannot alter |
| `DEPRECATED` | superseded former source |
| `ARCHIVED` | historical lookup only |

Use `QUARANTINED` as an incident flag in addition to a maturity state.

## Governance levels

- `L0`: user; final decision authority.
- `L1`: global governor; audit, routing, registry, conflict and report gates.
- `L2`: project management roles; govern one project.
- `L3`: professional execution roles; perform bounded domain work.
- `L4`: temporary task dialogues; return results and close.

## Canonical-source rules

- Preserve an existing project charter name; do not force a new `PROJECT_CHARTER.md`.
- Store locations and references in the global registry, not copied charter text.
- Mark DOCX/PDF/export copies as generated publications unless explicitly promoted.
- Record source path, version/hash, verification time, status, and known conflicts.

## Reserved user decisions

Require explicit user approval for deletion, irreversible moves, unfreezing, global-charter changes, project termination, major art-direction changes, dialogue merge/removal, and unresolved same-level canonical conflicts.

