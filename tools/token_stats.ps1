# token_stats.ps1 — aggregate Claude Code token usage from session transcripts (for the secretary review / heatmap).
#
#   tools\token_stats.ps1                       # project D--, full, readable table
#   tools\token_stats.ps1 -Since 2026-08-15     # only from a date
#   tools\token_stats.ps1 -Json                 # JSON (perDay/perSession/totals) for the dashboard
#   tools\token_stats.ps1 -ProjectHash C--      # project on another drive
#
# How: reads ~/.claude/projects/<hash>/*.jsonl; each assistant message's message.usage has
# input_tokens / output_tokens / cache_creation_input_tokens / cache_read_input_tokens.
# Aggregated per-session and per-day. cache_read is usually huge (context re-read each turn)
# but cheapest per token; output + cache_create + input are the "expensive new" tokens to optimize.
param([string]$ProjectHash='D--', [string]$Since='', [switch]$Json)
$ErrorActionPreference='Stop'
$proj = Join-Path $env:USERPROFILE ".claude\projects\$ProjectHash"
if (-not (Test-Path $proj)) { throw "project dir not found: $proj" }
$sinceDate = if ($Since) { [datetime]$Since } else { [datetime]'2000-01-01' }

function Get-MsgDate($o, $fallback) {
  try { if ($o.timestamp) { return ([datetime]::Parse([string]$o.timestamp, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind)).ToString('yyyy-MM-dd') } } catch {}
  return $fallback
}

$perDay = @{}       # 'yyyy-MM-dd' -> @(in,out,cc,cr,msgs)
$perSession = @{}   # sid8 -> @(in,out,cc,cr,msgs,mtime)
foreach ($f in Get-ChildItem $proj -Filter *.jsonl) {
  $sid = $f.Name.Substring(0,[Math]::Min(8,$f.Name.Length))
  $mt = $f.LastWriteTime.ToString('yyyy-MM-dd')
  $si=0;$so=0;$sc=0;$sr=0;$sn=0
  Get-Content $f.FullName | Where-Object { $_ -match '"output_tokens"' } | ForEach-Object {
    $o = $null; try { $o = $_ | ConvertFrom-Json } catch { return }
    $u = $o.message.usage
    if (-not $u) { return }
    $d = Get-MsgDate $o $mt
    $keep = $true
    try { $keep = ([datetime]$d -ge $sinceDate) } catch { $keep = $true }
    if (-not $keep) { return }
    $tin=[int]$u.input_tokens; $tout=[int]$u.output_tokens
    $tcc=[int]$u.cache_creation_input_tokens; $tcr=[int]$u.cache_read_input_tokens
    $si+=$tin;$so+=$tout;$sc+=$tcc;$sr+=$tcr;$sn++
    if (-not $perDay.ContainsKey($d)) { $perDay[$d]=@(0,0,0,0,0) }
    $perDay[$d][0]+=$tin;$perDay[$d][1]+=$tout;$perDay[$d][2]+=$tcc;$perDay[$d][3]+=$tcr;$perDay[$d][4]++
  }
  if ($sn -gt 0) { $perSession[$sid]=@($si,$so,$sc,$sr,$sn,$mt) }
}

$tin=0;$tout=0;$tcc=0;$tcr=0;$tn=0
foreach ($v in $perSession.Values) { $tin+=$v[0];$tout+=$v[1];$tcc+=$v[2];$tcr+=$v[3];$tn+=$v[4] }

if ($Json) {
  ([ordered]@{
    project=$ProjectHash; since=$Since
    totals=[ordered]@{ input=$tin; output=$tout; cache_create=$tcc; cache_read=$tcr; messages=$tn }
    perSession=$perSession; perDay=$perDay
  }) | ConvertTo-Json -Depth 6
} else {
  Write-Output ("=== token usage · {0}{1} ===" -f $ProjectHash, $(if($Since){" · since $Since"}else{""}))
  Write-Output ("TOTAL: output={0}  cache_create={1}  input={2}  cache_read={3}  (messages {4})" -f $tout,$tcc,$tin,$tcr,$tn)
  Write-Output "--- per session (output desc) ---"
  $perSession.GetEnumerator() | Sort-Object { -$_.Value[1] } | ForEach-Object {
    Write-Output ("  {0}  out={1} cc={2} in={3} cr={4} msgs={5}  {6}" -f $_.Key,$_.Value[1],$_.Value[2],$_.Value[0],$_.Value[3],$_.Value[4],$_.Value[5])
  }
  Write-Output "--- per day (heatmap source) ---"
  $perDay.GetEnumerator() | Sort-Object Name | ForEach-Object {
    Write-Output ("  {0}  out={1} cc={2} in={3} cr={4}" -f $_.Key,$_.Value[1],$_.Value[2],$_.Value[0],$_.Value[3])
  }
}
