# Output Engineering

Use before creating multiple files, long-lived artifacts, external links, a new output root, or cleanup candidates.

## Choose placement from evidence

Inspect the canonical project, repository instructions, existing folders, build rules, write authority, and path compatibility. Propose two or three viable strategies:

- `NATIVE`: reuse the project's existing structure;
- `DIALOGUE-WORKSPACE`: isolate working files inside an approved project location;
- `CENTRAL-DELIVERY`: use an authorized cross-project output root;
- `EXTERNAL-PLATFORM`: register link-only platform artifacts and snapshots.

Do not create a parallel folder tree when equivalent project locations exist.

## Declare scope

Require:

```yaml
resolved_project_root:
output_strategy:
output_root:
read_scope: []
create_scope: []
modify_scope: []
forbidden_scope: []
canonical_outputs: []
temporary_outputs: []
naming_policy:
review_path:
cleanup_policy:
rollback_point:
```

Read authority does not imply modify authority. Existing or unknown files never become temporary by inference.

## Naming and Chinese paths

Preserve established Chinese paths when tools can use them reliably. Prefer ASCII-safe names for scripts, build directories, dependency paths, and cross-platform synchronization. Keep Chinese human titles in manifests or final documents. Report compatibility failures; never silently redirect output to Desktop.

## Approval boundary

Proceed after reporting the plan only for non-overwriting creation inside an authorized scope. Request user approval before changing a long-lived root, restructuring or moving existing files, replacing a canonical source, bulk generation with pollution risk, or cleaning pre-existing content.

## Final file Review

List exact paths/URLs, purpose, state, version, canonical relationship, open method, sources, changes, verification, unknowns, rollback, and next safe action. Register external-link ownership, access, timestamp, local index, and snapshot status.

Only delete files created during the current task that were predeclared temporary, reproducible, and unreferenced. Everything else becomes `DELETE-CANDIDATE` pending user approval.

## User-facing package contract

When a reusable delivery contains several files, the 桌面交付结果 is **一个自包含压缩包**:

1. Put `00-从这里开始` at the package root.
2. Put prompts or launchers in one launcher folder.
3. Put all PDFs in one PDF folder and all editable documents in one editable-document folder.
4. Include a Manifest or Review that distinguishes current, reference, and historical material.
5. 只将完成的压缩包复制到桌面。

只有当用户明确要求某个文件位于包外时，才创建桌面散落副本。ZIP 加重复启动器、PDF 或 DOCX 不算完整交付；它会制造竞争入口并削弱复用。
