# project_attach_inbox.ps1 — 给一个项目挂上极轻的 .governance/INBOX.md(§15)
#
#   tools\project_attach_inbox.ps1 -Path D:\some-project            # 挂上(已存在则跳过)
#   tools\project_attach_inbox.ps1 -Path D:\some-project -WhatIf    # 只看会做什么,不写
#   tools\project_attach_inbox.ps1 -Path D:\a,D:\b                  # 批量
#
# 设计约束(别改坏):
#   - **幂等**:重复跑不会覆盖已有内容,也不会追加第二份。已存在就报 SKIP。
#   - **只创建 INBOX.md 一个文件**。不默认建 STATE.yaml / PROJECT.yaml / HANDOFF.md /
#     ROLES.md / DECISIONS.md —— 项目的状态正本是 Git / 测试 / Spec / 项目文件本身,
#     不要在旁边立第二套状态系统。等某个项目真的证明需要,再单独加。
#   - 写别的项目的文件属于跨地盘动作,默认 -WhatIf 之外要由用户点头。

param(
  [Parameter(Mandatory=$true)][string[]]$Path,
  [switch]$WhatIf
)
$ErrorActionPreference = 'Stop'

$tpl = Join-Path $PSScriptRoot "..\templates\project-INBOX.md" | Resolve-Path -ErrorAction SilentlyContinue
if (-not $tpl) { throw "找不到模板 templates\project-INBOX.md" }
$body = [IO.File]::ReadAllText($tpl, [Text.Encoding]::UTF8)

foreach ($p in $Path) {
  if (-not (Test-Path $p)) { Write-Output ("MISS  {0}  (路径不存在)" -f $p); continue }
  $name = Split-Path $p -Leaf
  $dir  = Join-Path $p ".governance"
  $file = Join-Path $dir "INBOX.md"

  if (Test-Path $file) { Write-Output ("SKIP  {0}  (已有 .governance\INBOX.md)" -f $name); continue }
  if ($WhatIf)        { Write-Output ("WOULD {0}  → {1}" -f $name, $file); continue }

  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  # 占位符必须是纯 ASCII:PS 5.1 读无 BOM 的 .ps1 会按 GBK 解码,
  # 脚本里的中文字面量在运行时就已经是乱码,匹配不上 UTF-8 的模板(2026-08-19 实测踩到)。
  [IO.File]::WriteAllText($file, $body.Replace("{{PROJECT_NAME}}", $name), [Text.UTF8Encoding]::new($false))
  Write-Output ("ADD   {0}  → {1}" -f $name, $file)
}
