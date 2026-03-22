# rawcode installer for Claude Code (Windows)
# Usage: irm https://raw.githubusercontent.com/juandarn/rawcode/master/install.ps1 | iex

$ErrorActionPreference = "Stop"

$Repo = "juandarn/rawcode"
$InstallDir = "$env:USERPROFILE\.claude\plugins\rawcode"

Write-Host "Installing rawcode plugin..." -ForegroundColor Cyan

# Clean previous install
if (Test-Path $InstallDir) {
    Write-Host "Updating existing installation..."
    Remove-Item -Recurse -Force $InstallDir
}

# Clone
if (Get-Command git -ErrorAction SilentlyContinue) {
    git clone --depth 1 "https://github.com/$Repo.git" $InstallDir 2>$null
} else {
    Write-Host "Error: git is required. Install git and try again." -ForegroundColor Red
    exit 1
}

# Remove .git from plugin dir
Remove-Item -Recurse -Force "$InstallDir\.git" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "rawcode installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Usage:" -ForegroundColor Yellow
Write-Host "  claude                                  # plugin loads automatically"
Write-Host "  claude --agent rawcode:coder     # full OpenCode mode"
Write-Host ""
Write-Host "Available commands:" -ForegroundColor Yellow
Write-Host "  /rawcode:review     Review code changes"
Write-Host "  /rawcode:explore    Explore the codebase"
Write-Host "  /rawcode:fix        Fix a bug (root-cause)"
Write-Host "  /rawcode:summarize  Summarize session"
Write-Host "  /rawcode:compact    Compact context"
Write-Host "  /rawcode:status     Project dashboard"
Write-Host "  /rawcode:diff       Formatted diff"
