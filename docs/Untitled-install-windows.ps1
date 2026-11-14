# Untitled Desktop - one-file installer for Windows (PowerShell).
# Usage:  powershell -ExecutionPolicy Bypass -File Untitled-install-windows.ps1
#   or:   powershell -c "irm https://untitled-aa.pages.dev/Untitled-install-windows.ps1 | iex"
# Requires NOTHING from the user: no git, no admin, nothing pre-installed.
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$RepoUrl = "https://github.com/vxsxxn/aa/archive/refs/heads/untitled.zip"
$Dest    = Join-Path $HOME "untitled"

Write-Host ""
Write-Host "Untitled Desktop installer" -ForegroundColor Gray

# 1. Get the code (zip download - no git needed) ---------------------------
if (Test-Path (Join-Path $Dest "scripts\Aa_desktop.py")) {
  Write-Host ""
  Write-Host "Untitled is already in $Dest - skipping download." -ForegroundColor Gray
} elseif (Test-Path (Join-Path $Dest ".git")) {
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

# 4. App icon -----------------------------------------------------------------
# Used by the shortcuts so Untitled looks like a program, not a script.
$Icon = Join-Path $Dest "untitled.ico"
try { Invoke-WebRequest -Uri "https://untitled-aa.pages.dev/untitled.ico" -OutFile $Icon -UseBasicParsing } catch { }

# 5. Launcher shortcut so it shows up in the Start Menu and Desktop -----------
# Launches pythonw.exe directly: real window, no console box, no re-download.
$Pyw = Join-Path $Dest ".venv\Scripts\pythonw.exe"
if (-not (Test-Path $Pyw)) { $Pyw = Join-Path $Dest ".venv\Scripts\python.exe" }
$Wsh = New-Object -ComObject WScript.Shell
foreach ($folder in @(
    [Environment]::GetFolderPath("Desktop"),
    (Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"))) {
  if (-not $folder) { continue }
  $lnk = $Wsh.CreateShortcut((Join-Path $folder "Untitled.lnk"))
  $lnk.TargetPath = $Pyw
  $lnk.Arguments = "scripts\Aa_desktop.py"
  $lnk.WorkingDirectory = $Dest
  $lnk.Description = "Untitled Desktop"
  if (Test-Path $Icon) { $lnk.IconLocation = $Icon }
  $lnk.Save()
}
# Console fallback for debugging (kept, but not what the shortcuts use).
$Launcher = Join-Path $Dest "Untitled.cmd"
@"
@echo off
cd /d "%~dp0"
set "PATH=%USERPROFILE%\.local\bin;%PATH%"
uv run --frozen scripts/Aa_desktop.py
"@ | Set-Content -Path $Launcher -Encoding ASCII

Write-Host ""
Write-Host "Added an 'Untitled' shortcut to your Desktop and Start Menu." -ForegroundColor Gray

# 6. Launch --------------------------------------------------------------------
Write-Host "Starting Untitled (app window opens - paste your OpenRouter API key in Settings)" -ForegroundColor Gray
if (Test-Path (Join-Path $Dest ".venv\Scripts\pythonw.exe")) {
  Start-Process -FilePath $Pyw -ArgumentList "scripts\Aa_desktop.py" -WorkingDirectory $Dest
} else {
  uv run --frozen scripts/Aa_desktop.py
}
