# Re-render the hand-drawn diagram SVGs to PNG at their EXACT SVG size.
#
# Each PNG is rendered at 2x device scale, with zero page margin and a
# transparent background, so the PNG matches the SVG's own viewBox exactly.
# Rendering into a window larger than the SVG leaves a white strip on the
# right/bottom that shows up as a white frame in GitHub's dark mode -- this
# script avoids that by sizing the window to each SVG's width/height.
#
# Requires Microsoft Edge (headless). Run from anywhere:
#   powershell -File tools/render_diagrams.ps1
$ErrorActionPreference = 'Stop'

$root   = Split-Path -Parent $PSScriptRoot      # repo root (this script lives in tools/)
$assets = Join-Path $root 'docs\assets'
$work   = Join-Path $env:TEMP ('render-diagrams-' + $PID)
New-Item -ItemType Directory -Force -Path $work | Out-Null

$edge = @(
  'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
  'C:\Program Files\Microsoft\Edge\Application\msedge.exe'
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $edge) { throw 'Microsoft Edge not found (needed to render SVG -> PNG).' }

Get-ChildItem (Join-Path $assets '*.svg') | ForEach-Object {
  $svg = Get-Content -Raw -Encoding UTF8 $_.FullName
  if ($svg -notmatch 'width="(\d+)"\s+height="(\d+)"') { throw "no width/height in $($_.Name)" }
  $w = [int]$Matches[1]; $h = [int]$Matches[2]

  $html = '<!doctype html><html><head><meta charset="utf-8">' +
          '<style>html,body{margin:0;padding:0;background:transparent}svg{display:block}</style>' +
          "</head><body>$svg</body></html>"
  $htmlPath = Join-Path $work ($_.BaseName + '.html')
  Set-Content -Path $htmlPath -Value $html -Encoding UTF8

  $outPath = Join-Path $assets ($_.BaseName + '.png')
  $uri = ([System.Uri]$htmlPath).AbsoluteUri
  & $edge '--headless=new' '--disable-gpu' '--hide-scrollbars' `
          '--force-device-scale-factor=2' '--default-background-color=00000000' `
          "--window-size=$w,$h" "--user-data-dir=$work\udd" `
          "--screenshot=$outPath" $uri | Out-Null

  '{0,-26} {1}x{2} SVG -> {3}x{4} PNG' -f $_.Name, $w, $h, ($w * 2), ($h * 2)
}

Remove-Item -Recurse -Force $work -ErrorAction SilentlyContinue
