# Repository Instructions

## Canonical sources

- Treat `docs/*.md`, `templates/*`, `skills/*`, and `launchers/*.txt` as canonical source artifacts.
- Treat `published/*`, `releases/*`, the Obsidian mirror, and Desktop copies as generated or distribution artifacts.
- Do not edit a generated copy without updating its canonical source and rebuilding all affected outputs.

## Safety

- Keep governance status `CANDIDATE` until the user explicitly approves the charter itself.
- Do not modify sibling repositories outside this repo's root while working here; the concrete local paths live in this machine's profile under `profiles/machines/instances/`, never in this file (it ships publicly).
- Do not delete pre-existing files, approved outputs, sources, receipts, or unknown files without explicit user approval.
- Before creating multiple files, declare `output_root`, file scope, canonical outputs, temporary outputs, and final Review location.

## Verification

- 便携校验（framework 内可直接跑，发布包也含）:
  - `python -X utf8 tools/validate_runtime.py`
  - `python -X utf8 tools/validate_paths.py`
  - `python -X utf8 tools/validate_release.py`
- 工程仓库专用（不随便携包发布，只在 Git 工程正本运行）: 构建脚本 `build_v2_2_3_release`、
  handbook 渲染与 `test_build_handbook`、`verify_delivery` 发布验收、DOCX/PDF 逐页重渲、
  Obsidian 同步、官方 Skill validator 校验。改动构建脚本或发布前在工程仓库跑这些，不属于 framework 便携层。
