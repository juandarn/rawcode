# opencode-style installer for Claude Code (Windows)
# Usage: irm https://raw.githubusercontent.com/juandarn/opencode-style/master/install.ps1 | iex

$ErrorActionPreference = "Stop"

$Repo = "juandarn/opencode-style"
$InstallDir = "$env:USERPROFILE\.claude\plugins\opencode-style"

Write-Host "Installing opencode-style plugin..." -ForegroundColor Cyan

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
Write-Host "opencode-style installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Usage:" -ForegroundColor Yellow
Write-Host "  claude                                  # plugin loads automatically"
Write-Host "  claude --agent opencode-style:coder     # full OpenCode mode"
Write-Host ""
Write-Host "Available commands:" -ForegroundColor Yellow
Write-Host "  /opencode-style:review     Review code changes"
Write-Host "  /opencode-style:explore    Explore the codebase"
Write-Host "  /opencode-style:fix        Fix a bug (root-cause)"
Write-Host "  /opencode-style:summarize  Summarize session"
Write-Host "  /opencode-style:compact    Compact context"
Write-Host "  /opencode-style:status     Project dashboard"
Write-Host "  /opencode-style:diff       Formatted diff"
