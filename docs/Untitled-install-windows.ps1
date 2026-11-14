# Untitled Desktop - one-file installer for Windows (PowerShell).
# Usage:  powershell -ExecutionPolicy Bypass -File Untitled-install-windows.ps1
#   or:   powershell -c "irm https://untitled-aa.pages.dev/Untitled-install-windows.ps1 | iex"
$ErrorActionPreference = "Stop"

$RepoUrl = "https://github.com/vxsxxn/untitled.git"
$Branch  = "untitled"
$Dest    = Join-Path $HOME "untitled"

Write-Host ""
Write-Host "Untitled Desktop installer" -ForegroundColor Gray

# 1. Check prerequisites -------------------------------------------------
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Host "git is required. Install it with:  winget install --id Git.Git -e"
  Write-Host "(then re-open PowerShell and run this script again)"
  exit 1
}

# 2. Get the code ---------------------------------------------------------
if (Test-Path (Join-Path $Dest ".git")) {
  Write-Host ""
  Write-Host "Updating existing copy in $Dest" -ForegroundColor Gray
  git -C $Dest pull --ff-only
} else {
  Write-Host ""
  Write-Host "Downloading untitled into $Dest" -ForegroundColor Gray
  git clone --depth 1 --branch $Branch $RepoUrl $Dest
}

# 3. Make sure uv is available -------------------------------------------
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
  Write-Host ""
  Write-Host "Installing uv (small, local, user-level)" -ForegroundColor Gray
  Invoke-RestMethod https://astral.sh/uv/install.ps1 | Invoke-Expression
  $env:Path = "$env:USERPROFILE\.local\bin;$env:Path"
}

# 4. Set up Python environment -------------------------------------------
Set-Location $Dest
Write-Host ""
Write-Host "Setting up (first run downloads Python + packages - may take a few minutes)" -ForegroundColor Gray
uv sync --frozen

# 5. Launch ---------------------------------------------------------------
Write-Host "Starting Untitled Desktop (your browser will open - paste your OpenRouter API key in Settings)" -ForegroundColor Gray
uv run --frozen scripts/Aa_desktop.py
