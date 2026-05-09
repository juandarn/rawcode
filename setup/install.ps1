# rawcode installer for Claude Code (Windows)
# Usage: irm https://raw.githubusercontent.com/juandarn/rawcode/master/setup/install.ps1 | iex

$ErrorActionPreference = "Stop"

$Repo = "juandarn/rawcode"
$InstallDir = "$env:USERPROFILE\.claude\plugins\rawcode"

Write-Host "rawcode installer" -ForegroundColor Cyan
Write-Host "=================" -ForegroundColor Cyan

# Check prerequisites
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Error: git is required. Install git and try again." -ForegroundColor Red
    exit 1
}

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host "Warning: claude CLI not found. Install Claude Code first: https://claude.ai/code" -ForegroundColor Yellow
}

# Ensure plugin directory exists
$PluginDir = "$env:USERPROFILE\.claude\plugins"
if (-not (Test-Path $PluginDir)) {
    New-Item -ItemType Directory -Path $PluginDir -Force | Out-Null
}

# Backup existing installation
if (Test-Path $InstallDir) {
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $BackupDir = "$InstallDir.backup.$timestamp"
    Write-Host "Backing up existing installation to $BackupDir"
    Move-Item $InstallDir $BackupDir
}

# Clone
Write-Host "Installing rawcode..."
git clone --depth 1 "https://github.com/$Repo.git" $InstallDir 2>$null

# Remove .git from plugin dir
Remove-Item -Recurse -Force "$InstallDir\.git" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "rawcode installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Usage:" -ForegroundColor Yellow
Write-Host "  claude    # rawcode loads automatically"
Write-Host ""
Write-Host "Philosophy: concise, root-cause, minimal, secure, verified."
