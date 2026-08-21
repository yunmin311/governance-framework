# render_harness.ps1 — 把仓内的 harness 模板按**当前这台机**渲染成安装副本
#
#   tools\render_harness.ps1                     # 干跑:只报会渲染成什么,不写任何东西
#   tools\render_harness.ps1 -Install            # 真装(自动备份原件)
#   tools\render_harness.ps1 -Install -Proxy "http://1.2.3.4:5678"
#   tools\render_harness.ps1 -Install -ProjectHash "E--"          # 精确发现失败时显式指定
#
# 为什么要它(别删):
#   仓里的 harness/ 是**模板**,不是安装副本。机器绑定的东西——项目根、库位置、
#   `@绝对路径` 的导入、代理真值、记忆主库的项目根名——都不该写死进 canonical source,
#   否则两台机器会互相改坏对方的 Desired State(D 要 @D:/CLAUDE.md,E 要 @E:/CLAUDE.md)。
#   `@path` 导入语法确实吃不了环境变量 —— **但渲染结果可以是字面路径,模板不必是。**
#
# 硬约束:
#   1) **变量定义来自 harness/manifest.yaml 的 render.vars**,本脚本里不写死任何项目名或路径。
#   2) **Secrets 只进安装副本,永不写回仓**。
#   3) 渲染后若仍残留 {{占位符}},**拒绝安装**并报出是哪一个 —— 宁可不装,也不装半成品。
#   4) **不猜**。`PROJECT_HASH` 精确匹配不到就是 UNKNOWN,要求显式 -ProjectHash;
#      绝不按盘符"猜一个"然后照常装 —— 猜错会静默指向不存在的记忆目录。
#   5) 本脚本只写安装副本位置,不碰仓里的任何文件。

param(
  [switch]$Install,
  [string]$Proxy,
  [string]$ProjectHash
)
$ErrorActionPreference = 'Stop'

# Kernel 与 Overlay 是两个根:
#   KERNEL_ROOT  = 这份脚本所在的框架根(工具住这儿)
#   OVERLAY_ROOT = 你的私有实例根(真 manifest / harness 模板 / memory / 个人 skill 住这儿)
# 两者可以重合(私有仓自带工具),也可以完全分开。**绝不要求把工具复制进 Overlay 才能工作。**
# 注意:项目根是 **Overlay 的兄弟**,不是 Kernel 的兄弟 —— 私有实例仓和各项目并排放。
$KERNEL_ROOT = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$HOMEDIR = $env:USERPROFILE
$CLAUDE  = Join-Path $HOMEDIR '.claude'
$CODEX   = Join-Path $HOMEDIR '.codex'

function Norm($p) { if (-not $p) { return '' } ; return $p.ToString().Replace('\','/') }

function Resolve-OverlayRoot($kernelRoot) {
  if ($env:GOV_OVERLAY) {
    if (Test-Path $env:GOV_OVERLAY) { return @{ root=(Resolve-Path $env:GOV_OVERLAY).Path; source='GOV_OVERLAY' } }
    return @{ root=$null; source='GOV_OVERLAY 指向的路径不存在' }
  }
  if (Test-Path (Join-Path $kernelRoot 'overlay.yaml')) { return @{ root=$kernelRoot; source='self(本仓自身就是 overlay)' } }
  $p = Split-Path $kernelRoot -Parent
  $cand = @(Get-ChildItem $p -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path (Join-Path $_.FullName 'overlay.yaml') })
  if ($cand.Count -eq 1) { return @{ root=$cand[0].FullName; source='同级 overlay.yaml' } }
  if ($cand.Count -eq 0) { return @{ root=$null; source='没找到 overlay' } }
  return @{ root=$null; source='歧义'; candidates=@($cand | ForEach-Object { $_.FullName }) }
}

$ov = Resolve-OverlayRoot $KERNEL_ROOT
if (-not $ov.root) {
  Write-Output ("Overlay = UNKNOWN({0})" -f $ov.source)
  if ($ov.candidates) {
    Write-Output "  同级有多个 overlay.yaml,**不许挑一个**:"
    $ov.candidates | ForEach-Object { Write-Output ("    " + $_) }
  }
  Write-Output "  显式指定后再来:setx GOV_OVERLAY `"<你的私有实例根>`"(新开终端生效)"
  Write-Output "  或在私有实例根下放一个 overlay.yaml 标记(空文件即可)。"
  exit 1
}
$REPO    = $ov.root
$PARENT  = Split-Path $REPO -Parent
$MANIFEST = Join-Path $REPO 'harness\manifest.yaml'
Write-Output ("== 根 ==")
Write-Output ("  Kernel  : {0}" -f $KERNEL_ROOT)
Write-Output ("  Overlay : {0}  (解析来源:{1})" -f $REPO, $ov.source)
Write-Output ""

if (-not (Test-Path $MANIFEST)) { Write-Output "Overlay 里没有 harness\manifest.yaml —— 它是安装清单与变量定义的唯一事实源。先从 Kernel 的 harness\manifest.template.yaml 拷一份来填。"; exit 1 }
$manText = [IO.File]::ReadAllText($MANIFEST, [Text.Encoding]::UTF8)

# ---------- 1. 从 manifest 读变量定义(不在脚本里写死) ----------
$varDefs = @()
foreach ($line in ($manText -split "`r?`n")) {
  if ($line -match '^\s{4}([A-Z_]+):\s*\{\s*from:\s*([a-z\-]+)\s*(?:,\s*name:\s*([^\s},]+)\s*)?\}') {
    $varDefs += [pscustomobject]@{ Name=$Matches[1]; From=$Matches[2]; Arg=$Matches[3] }
  }
}
if (-not $varDefs.Count) { Write-Output "manifest 的 render.vars 里没读到变量定义,先补上再跑。"; exit 1 }

# ---------- 2. 解析器 ----------
function Resolve-Var($def) {
  switch ($def.From) {
    'sibling-git-repos' {
      if ($env:GOV_PROJECT_ROOTS) { $r = @($env:GOV_PROJECT_ROOTS -split ';' | Where-Object { $_ }) }
      else { $r = @(Get-ChildItem $PARENT -Directory -ErrorAction SilentlyContinue |
                    Where-Object { Test-Path (Join-Path $_.FullName '.git') } |
                    ForEach-Object { $_.FullName }) }
      return (($r | ForEach-Object { "'" + (Norm $_).ToLower() + "'" }) -join ',')
    }
    'sibling' {
      $d = Join-Path $PARENT $def.Arg
      if (Test-Path $d) { return (Norm $d) } else { return '' }
    }
    'file-in-parent' {
      $f = Join-Path $PARENT $def.Arg
      if (Test-Path $f) { return (Norm $f) } else { return '' }
    }
    'memory-root-match' {
      if ($ProjectHash) { return $ProjectHash }          # 显式指定优先
      $repoIndex = Join-Path $REPO 'memory\MEMORY.md'
      $projRoot  = Join-Path $CLAUDE 'projects'
      if ((Test-Path $repoIndex) -and (Test-Path $projRoot)) {
        $want = (Get-FileHash $repoIndex -Algorithm MD5).Hash
        $hits = @()
        foreach ($d in (Get-ChildItem $projRoot -Directory -ErrorAction SilentlyContinue)) {
          $m = Join-Path $d.FullName 'memory\MEMORY.md'
          if ((Test-Path $m) -and ((Get-FileHash $m -Algorithm MD5).Hash -eq $want)) { $hits += $d.Name }
        }
        if ($hits.Count -eq 1) { return $hits[0] }
        # 0 个 = 找不到;>1 个 = 有歧义。两种都不猜。
      }
      return ''
    }
    'secret' {
      if ($Proxy) { return $Proxy }
      $cur = Join-Path $CLAUDE 'settings.json'
      if (Test-Path $cur) {
        try {
          $c = [IO.File]::ReadAllText($cur,[Text.Encoding]::UTF8) | ConvertFrom-Json
          if ($c.env -and $c.env.HTTP_PROXY -and $c.env.HTTP_PROXY -notmatch '^\{\{') { return $c.env.HTTP_PROXY }
        } catch {}
      }
      return ''
    }
    default { return '' }
  }
}

$map = @{}
$unresolved = @()
Write-Output "== 按 manifest.render.vars 解析这台机的事实 =="
foreach ($d in $varDefs) {
  $v = Resolve-Var $d
  $map['{{' + $d.Name + '}}'] = $v
  $shown = if ($d.From -eq 'secret') { if ($v) { '已取到(值不打印,属 Secrets)' } else { 'UNKNOWN' } }
           elseif ($v) { if ($v.Length -gt 70) { $v.Substring(0,70) + '…' } else { $v } }
           else { 'UNKNOWN' }
  Write-Output ("  {0,-26} <- {1,-18} {2}" -f $d.Name, $d.From, $shown)
  if (-not $v) { $unresolved += $d }
}
Write-Output ""

# 精确发现失败 -> 明确报 UNKNOWN 并要求显式指定,不静默选择
foreach ($u in $unresolved) {
  $how = switch ($u.From) {
    'memory-root-match' { "记忆主库根名精确匹配失败(0 个或多个候选)。**不猜**,请显式指定:-ProjectHash '<根名>'(形如 D--,即工作目录 D:\ 对应的目录名)" }
    'secret'            { "Secrets 仓里没有,也没从现有安装副本继承到。请显式传:-Proxy 'http://<ip>:<port>'" }
    default             { "本机没有 $($u.Arg)。若这台机确实没有,请先在模板里删掉引用它的那一段再渲染" }
  }
  Write-Output ("  WARN  {0} = UNKNOWN —— {1}" -f $u.Name, $how)
}
if ($unresolved.Count) { Write-Output "" }

# ---------- 3. 渲染 ----------
# 安装目标同样从 manifest 的 install 段读,渲染器不自己列第二份。
# 只取 src 在 harness/ 下的文件条目(目录类如 skills/ 是整份拷贝,不走渲染)。
$targets = @()
$curSrc = $null
foreach ($ln in ($manText -split "`r?`n")) {
  if ($ln -match '^\s*-\s*src:\s*(\S+)\s*$') { $curSrc = $Matches[1]; continue }
  if ($ln -match '^\s*dst:\s*(\S+)\s*$' -and $curSrc) {
    $d = $Matches[1]
    if ($curSrc -like 'harness/*' -and $curSrc -notlike '*/') {
      $abs = $d -replace '^~', [regex]::Escape($HOMEDIR) -replace '\\\\','\'
      $abs = $d.Replace('~', $HOMEDIR).Replace('/','\')
      $targets += @{ src = $curSrc.Replace('/','\'); dst = $abs }
    }
    $curSrc = $null
  }
}
if (-not $targets.Count) { Write-Output "manifest 的 install 段里没读到 harness/ 下的渲染目标。"; exit 1 }

$bad = @()
foreach ($t in $targets) {
  $srcPath = Join-Path $REPO $t.src
  if (-not (Test-Path $srcPath)) { continue }
  $out = [IO.File]::ReadAllText($srcPath, [Text.Encoding]::UTF8)
  foreach ($k in $map.Keys) { if ($map[$k]) { $out = $out.Replace($k, [string]$map[$k]) } }
  $left = [regex]::Matches($out, '\{\{[A-Z_]+\}\}') | ForEach-Object { $_.Value } | Sort-Object -Unique
  $t.rendered = $out
  if ($left.Count) { $bad += ("{0} -> 未解析: {1}" -f $t.src, ($left -join ', ')) }
  Write-Output ("  {0,-42} {1}" -f $t.src, $(if($left.Count){"✗ 残留 " + ($left -join ',')}else{"✓ 全部解析"}))
}

if ($bad.Count) {
  Write-Output ""
  Write-Output "有占位符没解析出来,**拒绝安装**(宁可不装,也不装半成品):"
  $bad | ForEach-Object { Write-Output ("  - " + $_) }
  exit 1
}

if (-not $Install) { Write-Output ""; Write-Output "干跑结束,什么都没写。确认无误后加 -Install。"; exit 0 }

# ---------- 4. 安装(先备份) ----------
foreach ($t in $targets) {
  if (-not $t.rendered) { continue }
  if (Test-Path $t.dst) { Copy-Item $t.dst ($t.dst + ".bak-render") -Force }
  New-Item -ItemType Directory -Force -Path (Split-Path $t.dst -Parent) | Out-Null
  [IO.File]::WriteAllText($t.dst, $t.rendered, [Text.UTF8Encoding]::new($false))
  Write-Output ("  装好 {0}" -f $t.dst)
}
Write-Output ""
Write-Output "完成。仓内模板未被修改(Secrets 只进了安装副本)。接着跑 tools\doctor.ps1 复验。"
