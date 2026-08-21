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
  # /XD _roots: never let the primary mirror delete the per-root archives below.
  robocopy $liveMem $repoMem /MIR /XD (Join-Path $repoMem '_roots') /NFL /NDL /NJH /NJS /NP | Out-Null
  Assert-Robocopy

  # ---- per-root archive (added 2026-08-19) ----------------------------------
  # Claude Code keys auto-memory by working directory, so a machine ends up with
  # SEVERAL memory stores, one per project root. On 2026-08-19 this machine had 7
  # of them holding 127 files, while only the primary ('D--', 31 files) was ever
  # synced -- 96 files had no backup at all and Codex could not see them.
  # They are NOT merged into the flat primary store: the roots overlap by exactly
  # one filename (MEMORY.md, each root's own index), so a flat merge would clobber
  # indexes. Archive each root separately; merging is a content decision for later.
  $projRoot = Join-Path $env:USERPROFILE '.claude\projects'
  $archived = 0
  if (Test-Path $projRoot) {
    foreach ($d in (Get-ChildItem $projRoot -Directory)) {
      if ($d.Name -eq $ProjectHash) { continue }          # primary already mirrored flat
      $m = Join-Path $d.FullName 'memory'
      if (-not (Test-Path $m)) { continue }
      if (-not (Get-ChildItem $m -Filter *.md -ErrorAction SilentlyContinue)) { continue }
      $dest = Join-Path $repoMem "_roots\$($d.Name)"
      New-Item -ItemType Directory -Force -Path $dest | Out-Null
      robocopy $m $dest /MIR /NFL /NDL /NJH /NJS /NP | Out-Null
      Assert-Robocopy
      $archived++
    }
  }

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
  $t = (Get-ChildItem $repoMem -Recurse -File -Filter *.md).Count
  git add memory
  git commit -m "memory sync: snapshot from $ProjectHash machine (+$archived archived roots)"
  git push
  Write-Output "done: primary=$n files (flat), total incl. _roots archive=$t md files, $archived extra roots archived. Pushed."
}

if ($Pull) {
  if (-not (Test-Path $repoMem)) { throw "repo\memory not found (did you 'git pull' first?): $repoMem" }
  New-Item -ItemType Directory -Force -Path $liveMem | Out-Null
  # /E: copy in (incl. subdirs), overwrite; NO delete, so a stale repo can't wipe newer local memory
  # /XD _roots: the per-root archive is restored separately below, it must not land inside the primary store
  robocopy $repoMem $liveMem /E /XD (Join-Path $repoMem '_roots') /NFL /NDL /NJH /NJS /NP | Out-Null
  Assert-Robocopy
  $n = (Get-ChildItem $liveMem -File).Count
  Write-Output "pulled $n memory files (primary) -> $liveMem"

  # ---- restore the per-root archives too (added 2026-08-19) -----------------
  # Without this, -Pull silently restores only the primary store and every other
  # working directory comes up on the new machine with no memory at all -- which
  # is exactly the gap that left 96 files unbacked in the first place.
  $rootsDir = Join-Path $repoMem '_roots'
  $restored = 0
  if (Test-Path $rootsDir) {
    foreach ($d in (Get-ChildItem $rootsDir -Directory)) {
      $dest = Join-Path $env:USERPROFILE ".claude\projects\$($d.Name)\memory"
      New-Item -ItemType Directory -Force -Path $dest | Out-Null
      robocopy $d.FullName $dest /E /NFL /NDL /NJH /NJS /NP | Out-Null
      Assert-Robocopy
      $restored++
      Write-Output "  restored root '$($d.Name)' -> $dest"
    }
  }
  Write-Output "restored $restored additional working-directory memory stores."
  Write-Output "NOTE: project-root folder names are derived from the working directory (e.g. 'D--' for D:\). If your projects live on different paths on this machine, the restored folder names will not match -- rename them to the new machine's roots before they take effect."
  Write-Output "now restart Claude Code (or open a new conversation) so it reloads MEMORY.md."
}
