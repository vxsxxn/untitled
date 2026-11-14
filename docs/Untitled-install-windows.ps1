# Untitled Desktop - one-file installer for Windows (PowerShell).
# Usage:  powershell -ExecutionPolicy Bypass -File Untitled-install-windows.ps1
#   or:   powershell -c "irm https://untitled-aa.pages.dev/Untitled-install-windows.ps1 | iex"
# Requires NOTHING from the user: no git, no admin, nothing pre-installed.
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$RepoUrl = "https://github.com/vxsxxn/untitled/archive/refs/heads/untitled.zip"
$Dest    = Join-Path $HOME "untitled"

Write-Host ""
Write-Host "Untitled Desktop installer" -ForegroundColor Gray

# 1. Get the code (zip download - no git needed) ---------------------------
if (Test-Path (Join-Path $Dest ".git")) {
  # old git-based install: keep using git if it exists
  Write-Host ""
  Write-Host "Updating existing copy in $Dest" -ForegroundColor Gray
  git -C $Dest pull --ff-only
} else {
  Write-Host ""
  Write-Host "Downloading untitled into $Dest" -ForegroundColor Gray
  $zip = Join-Path $env:TEMP "untitled-install.zip"
  Invoke-WebRequest -Uri $RepoUrl -OutFile $zip -UseBasicParsing
  $tmp = Join-Path $env:TEMP "untitled-extract"
  if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
  Expand-Archive -Path $zip -DestinationPath $tmp -Force
  $inner = Get-ChildItem $tmp -Directory | Select-Object -First 1
  if (-not $inner) { throw "Downloaded zip did not contain the expected folder." }
  if (Test-Path $Dest) { Remove-Item $Dest -Recurse -Force }
  Move-Item $inner.FullName $Dest
  Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item $zip -ErrorAction SilentlyContinue
}

# 2. Make sure uv is available (installs it itself, user-level) -------------
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
  Write-Host ""
  Write-Host "Installing uv (small, local, user-level)" -ForegroundColor Gray
  Invoke-RestMethod https://astral.sh/uv/install.ps1 | Invoke-Expression
  $env:Path = "$env:USERPROFILE\.local\bin;$env:Path"
}

# 3. Set up Python environment ----------------------------------------------
Set-Location $Dest
Write-Host ""
Write-Host "Setting up (first run downloads Python + packages - may take a few minutes)" -ForegroundColor Gray
uv sync --frozen

# 4. Launch -------------------------------------------------------------------
Write-Host "Starting Untitled Desktop (your browser will open - paste your OpenRouter API key in Settings)" -ForegroundColor Gray
uv run --frozen scripts/Aa_desktop.py
