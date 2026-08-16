# Transport the personal governance memory between THIS machine's Claude Code
# auto-memory and the private repo, so it can move across machines by git.
#
#   tools\sync_memory.ps1 -Push   # snapshot this machine's live memory INTO repo\memory, then commit + push
#   tools\sync_memory.ps1 -Pull   # copy repo\memory INTO this machine (use on a fresh machine after `git pull`)
#
# Model = single-writer-push-then-pull, same as the repos: the machine you just
# worked on Pushes; the other machine Pulls before working. Never edit both live.
#
# Claude Code keys auto-memory by the working directory. On D:\ that folder is
# ~/.claude/projects/D--/memory. If your projects live on another drive, pass
# -ProjectHash (e.g. 'C--' for C:\).
param(
  [switch]$Push,
  [switch]$Pull,
  [string]$ProjectHash = 'D--'
)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$repoMem  = Join-Path $repoRoot 'memory'
$liveMem  = Join-Path $env:USERPROFILE ".claude\projects\$ProjectHash\memory"

function Assert-Robocopy { if ($LASTEXITCODE -ge 8) { throw "robocopy failed (exit $LASTEXITCODE)" } }

if (-not ($Push -or $Pull)) { throw 'Choose a direction: -Push (machine -> repo) or -Pull (repo -> machine).' }

if ($Push) {
  if (-not (Test-Path $liveMem)) { throw "live memory not found: $liveMem" }
  New-Item -ItemType Directory -Force -Path $repoMem | Out-Null
  # /MIR: make repo\memory an exact mirror of live (so deletions propagate too)
  robocopy $liveMem $repoMem /MIR /NFL /NDL /NJH /NJS /NP | Out-Null
  Assert-Robocopy
  Set-Location $repoRoot
  # change-guard: if the mirror didn't actually change, do nothing (keeps auto-push a quiet no-op)
  if (-not (git status --porcelain -- memory)) {
    Write-Output "memory unchanged since last sync -- nothing to push."
    return
  }
  # single-writer pen check (opt-in): don't commit/push unless THIS machine holds the pen.
  # Enforces only when both OWNER (repo root) and .gov-machine (this machine) exist;
  # otherwise (public users, or gate not set up) it's a no-op -- backward compatible.
  # Fail-safe: memory is mirrored locally but NOT committed, so a non-pen machine can't
  # create a divergent auto-commit while the other machine holds the pen.
  $ownerFile = Join-Path $repoRoot 'OWNER'
  $govFile   = Join-Path $repoRoot '.gov-machine'
  if ((Test-Path $ownerFile) -and (Test-Path $govFile)) {
    $penOwner = ((Get-Content $ownerFile -TotalCount 1) -replace '^OWNER:\s*','').Trim()
    $penMe    = (Get-Content $govFile   -TotalCount 1).Trim()
    if ($penOwner -and $penMe -and ($penOwner -ne $penMe)) {
      Write-Output "single-writer: pen held by [$penOwner], this machine is [$penMe] -- memory mirrored locally, NOT committed/pushed (hand off OWNER to sync)."
      return
    }
  }
  $n = (Get-ChildItem $repoMem -File).Count
  git add memory
  git commit -m "memory sync: snapshot from $ProjectHash machine"
  git push
  Write-Output "done: $n memory files synced to the private repo and pushed."
}

if ($Pull) {
  if (-not (Test-Path $repoMem)) { throw "repo\memory not found (did you 'git pull' first?): $repoMem" }
  New-Item -ItemType Directory -Force -Path $liveMem | Out-Null
  # /E: copy in (incl. subdirs), overwrite; NO delete, so a stale repo can't wipe newer local memory
  robocopy $repoMem $liveMem /E /NFL /NDL /NJH /NJS /NP | Out-Null
  Assert-Robocopy
  $n = (Get-ChildItem $liveMem -File).Count
  Write-Output "pulled $n memory files -> $liveMem"
  Write-Output "now restart Claude Code (or open a new conversation) so it reloads MEMORY.md."
}
