# doctor.ps1 — 这台机器缺什么?一条命令给答案。
#
#   tools\doctor.ps1              # 体检,输出报告
#   tools\doctor.ps1 -Deep        # 额外跑三校验(慢一些)
#   tools\doctor.ps1 -Quiet       # 只输出有问题的项
#
# 两条硬约束(改的人注意):
#   1) **只读**。doctor 永远不写任何文件、不改配置、不提交。发现问题只报告和给命令,不自己动手。
#   2) **不写死本机路径**。仓根从脚本自身位置推导,家目录从 $env:USERPROFILE 取,
#      兄弟仓从仓根的上级目录扫。换一台机器直接能跑。
#
# 状态含义:
#   OK      = 已验证没问题
#   DRIFT   = 装了但和仓里的正本不一致(仓是正本,本机是安装副本)
#   MISSING = 该有的没有
#   WARN    = 不致命但要知道
#   SKIP    = 这台机器上不适用 / 依赖的工具没装

param([switch]$Deep, [switch]$Quiet, [string]$ProjectHash = 'D--')
$ErrorActionPreference = 'Continue'

$REPO = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$HOMEDIR = $env:USERPROFILE
$CLAUDE = Join-Path $HOMEDIR '.claude'
$CODEX  = Join-Path $HOMEDIR '.codex'
$PARENT = Split-Path $REPO -Parent

$script:rows = @()
function Add-Row($section, $item, $status, $detail, $fix) {
  $script:rows += [pscustomobject]@{ Section=$section; Item=$item; Status=$status; Detail=$detail; Fix=$fix }
}
function Hash-Of($p) {
  if (-not (Test-Path $p)) { return $null }
  return (Get-FileHash $p -Algorithm MD5).Hash
}
function Compare-Installed($section, $label, $repoRel, $installed, $fixHint) {
  $src = Join-Path $REPO $repoRel
  if (-not (Test-Path $src))       { Add-Row $section $label 'MISSING' "仓里没有源:$repoRel" '把本机现状收进仓,或确认这项是否已废弃'; return }
  if (-not (Test-Path $installed)) { Add-Row $section $label 'MISSING' "本机没装:$installed" $fixHint; return }
  if ((Hash-Of $src) -eq (Hash-Of $installed)) { Add-Row $section $label 'OK' '与仓一致' '' }
  else { Add-Row $section $label 'DRIFT' "本机与仓不一致(仓=$repoRel)" $fixHint }
}

# ---------- A 根基 ----------
Add-Row 'A 根基' '治理仓' $(if (Test-Path (Join-Path $REPO '.git')) { 'OK' } else { 'MISSING' }) $REPO '这份 doctor 必须放在治理仓的 tools\ 下才能定位正本'

$fw = Join-Path $PARENT 'governance-framework'
if (Test-Path $fw) { Add-Row 'A 根基' '公开框架仓' 'OK' $fw '' }
else { Add-Row 'A 根基' '公开框架仓' 'WARN' "同级没有 governance-framework" '只影响对外发布,不影响本机干活' }

$cc = Get-Command claude -ErrorAction SilentlyContinue
if ($cc) { Add-Row 'A 根基' 'Claude Code' 'OK' $cc.Source '' }
else { Add-Row 'A 根基' 'Claude Code' 'MISSING' '找不到 claude 命令' 'npm install -g @anthropic-ai/claude-code@latest;装完要重开终端刷 PATH' }

if (Test-Path $CODEX) { Add-Row 'A 根基' 'Codex' 'OK' $CODEX '' }
else { Add-Row 'A 根基' 'Codex' 'SKIP' '这台机没有 ~/.codex' '' }

# ---------- B Desired State 漂移 ----------
# 三份**模板渲染**出来的文件不做哈希比对:仓里是模板(带 {{占位符}}),本机是按本机渲染的产物,
# 两者本来就不该相同。改验两件事:模板在不在、安装副本里有没有没解析掉的占位符。
# (2026-08-20:此前用哈希比对,逼得每台机去改 canonical source,多机会互相改坏。)
function Check-Rendered($label, $tplRel, $installed, $fixHint) {
  $tpl = Join-Path $REPO $tplRel
  if (-not (Test-Path $tpl))       { Add-Row 'B 配置' $label 'MISSING' "仓里没有模板:$tplRel" '把本机现状收进仓当模板'; return }
  if (-not (Test-Path $installed)) { Add-Row 'B 配置' $label 'MISSING' "本机没装:$installed" $fixHint; return }
  $txt = [IO.File]::ReadAllText($installed, [Text.Encoding]::UTF8)
  $left = [regex]::Matches($txt, '\{\{[A-Z_]+\}\}') | ForEach-Object { $_.Value } | Sort-Object -Unique
  if ($left.Count) { Add-Row 'B 配置' $label 'DRIFT' ("安装副本里有没解析的占位符:" + ($left -join ', ')) $fixHint }
  else { Add-Row 'B 配置' $label 'OK' '模板在仓、安装副本已完整渲染' '' }
}
Check-Rendered '全局 CLAUDE.md'  'harness\claude\global-CLAUDE.md'      (Join-Path $CLAUDE 'CLAUDE.md')     'tools\render_harness.ps1 -Install(按本机渲染,别手改安装副本,更别去改仓里的模板)'
Check-Rendered '全局 settings'   'harness\claude\settings.desired.json' (Join-Path $CLAUDE 'settings.json') 'tools\render_harness.ps1 -Install;缺代理加 -Proxy'
Compare-Installed 'B 配置' 'statusline.js'  'harness\claude\statusline.js'   (Join-Path $CLAUDE 'statusline.js') '从 harness\claude\statusline.js 拷到 ~\.claude\(这份不含机器绑定,仍是逐字节一致)'
if (Test-Path $CODEX) {
  Check-Rendered 'Codex AGENTS.md' 'harness\codex\global-AGENTS.md' (Join-Path $CODEX 'AGENTS.md') 'tools\render_harness.ps1 -Install'
}

$setPath = Join-Path $CLAUDE 'settings.json'
if (Test-Path $setPath) {
  try {
    $set = [IO.File]::ReadAllText($setPath, [Text.Encoding]::UTF8) | ConvertFrom-Json
    $hookEvents = @()
    if ($set.hooks) { $hookEvents = $set.hooks.PSObject.Properties.Name }
    if ($hookEvents.Count -gt 0) { Add-Row 'B 配置' 'hooks' 'OK' ("已装事件:" + ($hookEvents -join ', ')) '' }
    else { Add-Row 'B 配置' 'hooks' 'MISSING' 'settings.json 里没有 hooks 段' '照 harness\claude\settings.desired.json 的 hooks 段补回' }

    # 按**语义身份**点名预期钩子:少一条、或某条被复制成两份,都要报。
    # 2026-08-20 血的教训:一次批量替换把「版权红线」「跨项目隔离」两条 deny 覆盖成了
    # 「HTML 设计红线」的副本 —— 钩子个数没变、可移植性没问题、源==安装副本,
    # 于是当时的 doctor 一路全绿,而两道硬红线其实已经没了。只数数量、只比哈希都抓不到这种。
    #
    # 清单**从 harness/manifest.yaml 的 hooks 段读**,doctor 自己不维护第二份 ——
    # 两份清单必然各自漂移,而漂了没人知道,那就又回到"看着全绿其实已经坏了"。
    $EXPECTED_HOOKS = @()
    $manPath = Join-Path $REPO 'harness\manifest.yaml'
    if (Test-Path $manPath) {
      # 字段顺序无关:先按 id 收集,读完再挑出带 match 的。
      $acc = [ordered]@{}; $curId = $null
      foreach ($ln in ([IO.File]::ReadAllText($manPath,[Text.Encoding]::UTF8) -split "`r?`n")) {
        if ($ln -match '^\s*-\s*id:\s*(\S+)')      { $curId = $Matches[1]; if (-not $acc[$curId]) { $acc[$curId] = @{ id=$curId } }; continue }
        if (-not $curId) { continue }
        if ($ln -match '^\s*match:\s*(.+?)\s*$')   { $acc[$curId]['need'] = $Matches[1] }
        if ($ln -match '^\s*purpose:\s*(.+?)\s*$') { $acc[$curId]['why']  = $Matches[1] }
      }
      foreach ($k in $acc.Keys) { if ($acc[$k]['need']) { $EXPECTED_HOOKS += $acc[$k] } }
    }
    if (-not $EXPECTED_HOOKS.Count) {
      Add-Row 'B 配置' '预期钩子集合' 'MISSING' 'harness\manifest.yaml 里没有带 match 的 hooks 声明' '在 manifest 的 hooks 段给每条钩子写 id + match(稳定特征串);这是唯一事实源,别让 doctor 自己列'
    }
    $allCmds = @()
    foreach ($ev in @($set.hooks.PSObject.Properties.Value)) {
      foreach ($entry in @($ev)) { foreach ($h in @($entry.hooks)) { if ($h.command) { $allCmds += [string]$h.command } } }
    }
    $missing = @(); $dup = @()
    foreach ($e in $EXPECTED_HOOKS) {
      $n = @($allCmds | Where-Object { $_ -match [regex]::Escape($e.need) }).Count
      if ($n -eq 0) { $missing += ("{0}({1})" -f $e.id, $e.why) }
      elseif ($n -gt 1) { $dup += ("{0}×{1}" -f $e.id, $n) }
    }
    if ($missing.Count) { Add-Row 'B 配置' '预期钩子集合' 'MISSING' ("缺 " + ($missing -join '; ')) '从 harness\claude\settings.desired.json 重新渲染安装(tools\render_harness.ps1 -Install);别手工拼钩子' }
    elseif ($dup.Count) { Add-Row 'B 配置' '预期钩子集合' 'DRIFT' ("有重复(多半是被批量替换覆盖了):" + ($dup -join ', ')) '拿 settings.json.bak-* 对照,确认每条语义身份唯一,再重新渲染安装' }
    elseif ($EXPECTED_HOOKS.Count) { Add-Row 'B 配置' '预期钩子集合' 'OK' ("manifest 声明 {0} 条,安装副本齐、无重复" -f $EXPECTED_HOOKS.Count) '' }

    # 可移植性判的是**仓里的模板**,不是安装副本。
    # 安装副本本来就该含字面绝对路径(那是 render_harness.ps1 按本机渲染出来的结果),
    # 拿它来判会必然误报 —— 2026-08-20 第一版就这么误报过一次。
    # 模板里合法的写法只有两种:{{占位符}}(安装时渲染),或 $env 覆盖 + Test-Path 候选探测。
    $bad = @()
    $tplPath = Join-Path $REPO 'harness\claude\settings.desired.json'
    if (Test-Path $tplPath) {
      try { $tplSet = [IO.File]::ReadAllText($tplPath, [Text.Encoding]::UTF8) | ConvertFrom-Json } catch { $tplSet = $null }
      if ($tplSet -and $tplSet.hooks) {
        foreach ($grp in @($tplSet.hooks.PSObject.Properties.Value)) {
          foreach ($entry in @($grp)) {
            foreach ($h in @($entry.hooks)) {
              $cmd = [string]$h.command
              if (-not $cmd) { continue }
              # 先把占位符抠掉再看还有没有盘符
              $probe = [regex]::Replace($cmd, '\{\{[A-Z_]+\}\}', '')
              $hasDrive  = $probe -match '[A-Za-z]:[\\/]'
              $hasEnvOvr = $cmd -match '\$env:[A-Za-z_]\w*'
              $hasProbe2 = $cmd -match 'Test-Path'
              if ($hasDrive -and -not ($hasEnvOvr -and $hasProbe2)) {
                $bad += ($cmd.Substring(0, [Math]::Min(60, $cmd.Length)) + '…')
              }
            }
          }
        }
      }
    }
    if ($bad.Count) {
      Add-Row 'B 配置' '钩子可移植性' 'DRIFT' ("$($bad.Count) 个钩子写死了本机路径:" + (($bad | Select-Object -First 2) -join ' | ')) '换机后这些路径不存在,钩子会静默 exit 0、不报错也不干活。照 harness\claude\settings.desired.json 改成 $env:XXX 覆盖 + Test-Path 候选探测'
    } else { Add-Row 'B 配置' '钩子可移植性' 'OK' '所有钩子都走 env 覆盖 + 候选探测,换机可用' '' }

    if ($set.autoCompactEnabled -eq $true) { Add-Row 'B 配置' '自动压缩' 'OK' 'autoCompactEnabled=true' '' }
    else { Add-Row 'B 配置' '自动压缩' 'WARN' 'autoCompactEnabled 不是 true' '上下文重读是最大的 token 开销,建议开启' }

    if ($set.env -and $set.env.HTTP_PROXY -and $set.env.HTTP_PROXY -notmatch '^<') {
      Add-Row 'B 配置' '代理' 'OK' '已配(值不入仓,属 Secrets)' ''
    } else {
      Add-Row 'B 配置' '代理' 'WARN' 'settings.json 里没有可用的 HTTP_PROXY' '新机要手工填真值:仓里只有占位符'
    }
  } catch { Add-Row 'B 配置' 'settings.json' 'WARN' "解析失败:$($_.Exception.Message)" '' }
} else {
  Add-Row 'B 配置' 'settings.json' 'MISSING' "$setPath 不存在" '照 harness\claude\settings.desired.json 装,并把代理换成本机真值'
}

# ---------- C skills ----------
$repoSkills = Join-Path $REPO 'skills'
$instSkills = Join-Path $CLAUDE 'skills'
if ((Test-Path $repoSkills) -and (Test-Path $instSkills)) {
  $rs = (Get-ChildItem $repoSkills -Directory).Name
  $is = (Get-ChildItem $instSkills -Directory).Name
  $miss = @($rs | Where-Object { $_ -notin $is })
  $extra = @($is | Where-Object { $_ -notin $rs })
  $drift = @()
  foreach ($s in ($rs | Where-Object { $_ -in $is })) {
    $a = Join-Path $repoSkills "$s\SKILL.md"; $b = Join-Path $instSkills "$s\SKILL.md"
    if ((Test-Path $a) -and (Test-Path $b) -and ((Hash-Of $a) -ne (Hash-Of $b))) { $drift += $s }
  }
  if ($miss.Count)  { Add-Row 'C skills' '本机缺 skill' 'MISSING' ($miss -join ', ') '从仓 skills\ 拷到 ~\.claude\skills\' }
  if ($extra.Count) { Add-Row 'C skills' '仓里没有源' 'MISSING' ($extra -join ', ') '**丢了就没了**:把它收进仓 skills\ 再提交' }
  if ($drift.Count) { Add-Row 'C skills' '内容不一致' 'DRIFT' ($drift -join ', ') '仓是正本:确认哪边新,回灌或重装,别两边各改各的' }
  if (-not ($miss.Count -or $extra.Count -or $drift.Count)) { Add-Row 'C skills' '全部 skill' 'OK' "$($rs.Count) 个,仓与本机一致" '' }
} else { Add-Row 'C skills' 'skills 目录' 'MISSING' '仓或本机缺 skills 目录' '' }

# ---------- D 记忆 ----------
# 记忆是**按工作目录分开存的**,一台机会有好几份。主库 = $ProjectHash 那个根(仓里扁平的那份),
# 其余各根存在 memory\_roots\<根>\。别再像第一版那样随便挑一个根来比,会比错(2026-08-19 踩到)。
$repoMem = Join-Path $REPO 'memory'
$machMem = Join-Path $CLAUDE "projects\$ProjectHash\memory"
$projRoot = Join-Path $CLAUDE 'projects'

# D-2 其余各根有没有进存档(96 份记忆曾经完全没备份)
if (Test-Path $projRoot) {
  $unbacked = @()
  foreach ($d in (Get-ChildItem $projRoot -Directory -ErrorAction SilentlyContinue)) {
    if ($d.Name -eq $ProjectHash) { continue }
    $m = Join-Path $d.FullName 'memory'
    if (-not (Test-Path $m)) { continue }
    $cnt = (Get-ChildItem $m -Filter *.md -ErrorAction SilentlyContinue).Count
    if ($cnt -eq 0) { continue }
    $arch = Join-Path $repoMem "_roots\$($d.Name)"
    if (-not (Test-Path $arch)) { $unbacked += "$($d.Name)($cnt 份)"; continue }
    if ((Get-ChildItem $arch -Filter *.md).Count -lt $cnt) { $unbacked += "$($d.Name)(存档不全)" }
  }
  if ($unbacked.Count) { Add-Row 'D 记忆' '其余各根存档' 'MISSING' ($unbacked -join ', ') 'tools\sync_memory.ps1 -Push(会顺带存档所有根)' }
  else { Add-Row 'D 记忆' '其余各根存档' 'OK' '所有工作目录的记忆都已存档进 memory\_roots\' '' }
}

if ((Test-Path $repoMem) -and (Test-Path $machMem)) {
  $rc = (Get-ChildItem $repoMem -Filter *.md).Count
  $mc = (Get-ChildItem $machMem -Filter *.md).Count
  $diff = @()
  foreach ($f in (Get-ChildItem $machMem -Filter *.md)) {
    $r = Join-Path $repoMem $f.Name
    if (-not (Test-Path $r)) { $diff += "仅本机:$($f.Name)" }
    elseif ((Hash-Of $r) -ne (Hash-Of $f.FullName)) { $diff += "不一致:$($f.Name)" }
  }
  if ($diff.Count) { Add-Row 'D 记忆' "主库($ProjectHash)" 'DRIFT' ("仓=$rc 本机=$mc;" + (($diff | Select-Object -First 5) -join '; ')) 'tools\sync_memory.ps1 -Push' }
  else { Add-Row 'D 记忆' "主库($ProjectHash)" 'OK' "$rc 份,与本机一致" '' }
} else { Add-Row 'D 记忆' "主库($ProjectHash)" 'MISSING' "找不到 $repoMem 或 $machMem" 'tools\sync_memory.ps1 -Push;若本机主根不是 D--,用 -ProjectHash 指定' }

# ---------- E Git 卫生 ----------
$repos = Get-ChildItem $PARENT -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path (Join-Path $_.FullName '.git') }

# 身份判据要通用:不点名任何具体域名(那等于把作者的雇主写进工具)。
# 做法是取**这批个人仓里最常见的那个邮箱**当基准,偏离基准的报出来让人确认。
# 这样既能抓到"个人仓误用了公司/学校邮箱",也能抓到"内网仓误用了个人邮箱",而且换个人用一样成立。
$personalEmails = @()
foreach ($r in $repos) {
  $u = (git -C $r.FullName remote get-url origin 2>$null)
  if ($u -match 'github\.com[:/]') { $e = (git -C $r.FullName config user.email); if ($e) { $personalEmails += $e } }
}
$baseline = ($personalEmails | Group-Object | Sort-Object Count -Descending | Select-Object -First 1).Name

foreach ($r in $repos) {
  $p = $r.FullName; $n = $r.Name
  $url = (git -C $p remote get-url origin 2>$null)
  if (-not $url) { Add-Row 'E Git' $n 'WARN' '没有 origin 远端' '本地仓,换机不会自动带走'; continue }
  $isPersonal = ($url -match 'github\.com[:/]')
  $email = (git -C $p config user.email)
  $problems = @()
  if ($isPersonal) {
    if ($url -like 'https://*') { $problems += 'origin 还是 https(若本机 git 的凭证助手不稳,推送会挂;建议改 ssh)' }
    if ($email -notmatch '@') { $problems += "身份未配" }
    elseif ($baseline -and $email -ne $baseline) { $problems += "身份 $email 与其余个人仓的基准 $baseline 不一致,确认是否用错了邮箱" }
  } else {
    if ($baseline -and $email -eq $baseline) { $problems += "这是非 GitHub 远端(多半是内网/公司仓),却用了个人仓的基准邮箱 $baseline" }
  }
  $dirty = (git -C $p status --porcelain | Measure-Object -Line).Lines
  $br = (git -C $p rev-parse --abbrev-ref HEAD 2>$null)
  $ahead = (git -C $p rev-list --count "origin/$br..$br" 2>$null)
  if ($ahead -and [int]$ahead -gt 0) { $problems += "领先远端 $ahead 个提交没推" }
  if ($problems.Count) { Add-Row 'E Git' $n 'WARN' (($problems -join ';') + " (未提交 $dirty)") '按上面逐条处理' }
  else { Add-Row 'E Git' $n 'OK' "$email · $br · 未提交 $dirty" '' }
}

# ---------- F 分支保护 ----------
# 检查哪些仓、属于谁,一律从 git remote 推导,不写死仓主名 —— 写死等于把作者的账号焊进工具,
# 换个人用就是错的(2026-08-19:原先写死 <your-github-user>,构建的泄漏闸因此拦下整个脚本,闸拦得对)。
$gh = Get-Command gh -ErrorAction SilentlyContinue
if ($gh) {
  $targets = @()
  foreach ($r in @($REPO, $fw)) {
    if (-not (Test-Path (Join-Path $r '.git'))) { continue }
    $u = (git -C $r remote get-url origin 2>$null)
    if ($u -match 'github\.com[:/]([^/]+)/([^/\s]+?)(\.git)?$') { $targets += , @($Matches[1], $Matches[2], (Split-Path $r -Leaf)) }
  }
  if (-not $targets.Count) { Add-Row 'F 保护' '分支保护' 'SKIP' '没有可解析的 GitHub 远端' '' }
  foreach ($t in $targets) {
    $owner = $t[0]; $repoName = $t[1]; $n = $t[2]
    $rules = (gh api "repos/$owner/$repoName/rules/branches/main" 2>$null)
    if ($rules) {
      $types = ($rules | ConvertFrom-Json | ForEach-Object { $_.type }) | Sort-Object -Unique
      $need = @('deletion','non_fast_forward','required_linear_history')
      $lack = @($need | Where-Object { $_ -notin $types })
      if ($lack.Count) { Add-Row 'F 保护' $n 'WARN' ("缺:" + ($lack -join ', ')) 'GitHub → Settings → Rules → Rulesets,补上这几条且 Bypass list 留空' }
      else { Add-Row 'F 保护' $n 'OK' '禁 force-push + 线性历史 + 禁删分支,三条齐' '' }
    } else { Add-Row 'F 保护' $n 'SKIP' '查不到(仓不存在或无权限)' '' }
  }
} else { Add-Row 'F 保护' 'gh CLI' 'SKIP' '没装 gh,跳过分支保护检查' 'winget install GitHub.cli,装完重开终端' }

# ---------- G 深检 ----------
if ($Deep) {
  Push-Location $REPO
  foreach ($v in @('validate_runtime.py','validate_paths.py','validate_release.py')) {
    $out = (python -X utf8 (Join-Path $REPO "tools\$v") 2>&1 | Out-String)
    if ($LASTEXITCODE -eq 0) { Add-Row 'G 校验' $v 'OK' '通过' '' }
    else { Add-Row 'G 校验' $v 'WARN' (($out -split "`n" | Where-Object { $_ -match 'FAIL' }) -join '; ') '先修校验再推' }
  }
  # 单元测试必须从仓根用 `python -m tools.<name>` 跑。
  # 用 `python tools\test_x.py` 会把 tools\ 而不是仓根放进 sys.path → ModuleNotFoundError: No module named 'tools',
  # 看起来像测试挂了、其实是调用方式错(2026-08-19 踩到,固化在此免得再判错)。
  foreach ($t in (Get-ChildItem (Join-Path $REPO 'tools') -Filter 'test_*.py')) {
    $mod = 'tools.' + [IO.Path]::GetFileNameWithoutExtension($t.Name)
    $out = (python -X utf8 -m $mod 2>&1 | Out-String)
    if ($LASTEXITCODE -eq 0) { Add-Row 'G 校验' $t.Name 'OK' '通过' '' }
    else { Add-Row 'G 校验' $t.Name 'WARN' (($out -split "`n" | Where-Object { $_ -match 'FAILED|Error' } | Select-Object -First 2) -join '; ') "从仓根跑 python -X utf8 -m $mod" }
  }
  Pop-Location
}

# ---------- 报告 ----------
$show = $script:rows
if ($Quiet) { $show = $script:rows | Where-Object { $_.Status -ne 'OK' } }
$sec = ''
foreach ($row in $show) {
  if ($row.Section -ne $sec) { $sec = $row.Section; Write-Output ''; Write-Output "== $sec ==" }
  Write-Output ("  {0,-7} {1,-18} {2}" -f $row.Status, $row.Item, $row.Detail)
  if ($row.Fix -and $row.Status -ne 'OK') { Write-Output ("          ↳ 怎么办:{0}" -f $row.Fix) }
}
$c = $script:rows | Group-Object Status | ForEach-Object { "$($_.Name)=$($_.Count)" }
Write-Output ''
Write-Output ("-- 合计:" + ($c -join '  ') + " --")
$bad = @($script:rows | Where-Object { $_.Status -eq 'MISSING' }).Count
if ($bad -gt 0) { Write-Output "有 $bad 项缺失,换机后先补这些。"; exit 1 }
Write-Output '没有缺失项。'
exit 0
