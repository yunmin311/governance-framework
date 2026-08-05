# Governance templates

## Project registry

```yaml
project_id:
project_name:
status: UNKNOWN
priority:
device_id:
path_alias:
resolved_path:
path_verified_at:
canonical_charter: {type: "", path: "", version: "", verified_at: ""}
current_state_source:
current_spec_source:
design_baseline_source:
report_source:
dialogues: []
skills: []
frozen_items: []
known_conflicts: []
unknowns: []
evidence: []
```

## Dialogue identity card

```yaml
dialogue_id:
dialogue_name:
platform:
project_id:
level:
status: UNKNOWN
purpose:
primary_responsibility: UNKNOWN
secondary_responsibilities: []
out_of_scope: []
reports_to:
required_reading: []
allowed_write_targets: []
forbidden_write_targets: []
authority:
  can_explore: false
  can_execute: false
  can_approve: false
  can_freeze: false
  can_modify_charter: false
  can_create_skill_candidate: false
  can_delete: false
evidence: []
known_conflicts: []
retention_decision: UNKNOWN
migration_status: NOT_STARTED
```

## Decision record

Record ID, date, proposer, decision-maker, project, authority source, previous state, new state, decision, reason, evidence, impact, rejected options, synchronization targets, canonical files to update, rollback, and execution status.

## Incident report

Record incident ID, detection time, affected projects/dialogues, quarantined range, last trusted point, trusted source/version, device/path checks, conflicts, confirmed facts, probable causes, hypotheses, recovery actions, evidence, remaining impact, exit conditions, and required user decision.

