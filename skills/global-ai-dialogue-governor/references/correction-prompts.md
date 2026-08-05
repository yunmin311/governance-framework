# Correction Levels

Use this reference when a dialogue hallucinates, bypasses instructions, forgets a baseline, drifts visually, or fails the same correction repeatedly.

## Select one level

| Observable condition | Level | Required result |
|---|---|---|
| One bounded defect; sources and baseline remain known | `CORRECT-IN-PLACE` | Repair only the named scope and prove no collateral change |
| Cross-module drift, tail-quality decay, or repeated failed local fixes | `BASELINE-RESET` | Stop expansion, reload sources, classify every target, rebuild noncompliant areas |
| Fabricated access, authority bypass, false approval, or canonical overwrite risk | `INCIDENT-READ-ONLY` | Quarantine, stop writes, recover the last trusted chain, request user approval |

When uncertain, request a read-only diagnostic: current role, actual sources read, baseline/version, files touched, rendered scope, unknowns, differences, and recommended level.

## Escalation

- Escalate C1 to C2 when drift crosses modules or persists after one repair.
- Escalate at least one level after the same failure survives two rounds.
- Escalate directly to C3 for fabricated sources or authority violations.
- Never let the dialogue self-exit C3.

## Binding constraints

- Freeze unaffected areas during C1.
- Preserve a comparison candidate and reload the baseline during C2.
- Stop write, move, delete, merge, approve, freeze, and unfreeze actions during C3.
- Missing evidence becomes `UNKNOWN`; missing rendering becomes `UNVERIFIED`.
- Self-review never grants `APPROVED` or `FROZEN` status.

Use the full copy-ready prompts in `launchers/AI跑偏时-三级纠偏提示词.txt` when the package is accessible.
