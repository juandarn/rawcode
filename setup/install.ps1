# rawcode installer for Claude Code (Windows)
#
# Safe install (recommended):
#   Invoke-WebRequest -Uri https://raw.githubusercontent.com/juandarn/rawcode/master/setup/install.ps1 -OutFile $env:TEMP\rawcode-install.ps1
#   Get-Content $env:TEMP\rawcode-install.ps1   # inspect first
#   & $env:TEMP\rawcode-install.ps1
#
# Quick install:
#   irm https://raw.githubusercontent.com/juandarn/rawcode/master/setup/install.ps1 | iex

$ErrorActionPreference = "Stop"

$Repo = "juandarn/rawcode"
$InstallDir = "$env:USERPROFILE\.claude\plugins\rawcode"
$VersionUrl = "https://raw.githubusercontent.com/$Repo/master/.claude-plugin/plugin.json"

# ── UI helpers ──────────────────────────────────────
function Write-Step { param($msg) Write-Host "  ▶ $msg" -ForegroundColor Cyan }
function Write-Ok   { param($msg) Write-Host "  ✔ $msg" -ForegroundColor Green }
function Write-Fail { param($msg) Write-Host "  ✘ $msg" -ForegroundColor Red }
function Write-Warn { param($msg) Write-Host "  ⚠ $msg" -ForegroundColor Yellow }

function Get-LocalVersion {
    $pj = "$InstallDir\.claude-plugin\plugin.json"
    if (Test-Path $pj) {
        $json = Get-Content $pj -Raw | ConvertFrom-Json
        return $json.version
    }
    return "none"
}

function Get-RemoteVersion {
    try {
        $json = Invoke-RestMethod -Uri $VersionUrl -TimeoutSec 5
        return $json.version
    } catch {
        return "unknown"
    }
}

# ── Banner ──────────────────────────────────────────
Write-Host ""
Write-Host "                                    _" -ForegroundColor Cyan
Write-Host "   _ __ __ ___      _____ ___   __| | ___" -ForegroundColor Cyan
Write-Host "  | '__/ _```` \ \ /\ / / __/ _ \ / _```` |/ _ \" -ForegroundColor Cyan
Write-Host "  | | | (_| |\ V  V / (_| (_) | (_| |  __/" -ForegroundColor Cyan
Write-Host "  |_|  \__,_| \_/\_/ \___\___/ \__,_|\___|" -ForegroundColor Cyan
Write-Host ""
Write-Host "  OpenCode philosophy for Claude Code" -ForegroundColor DarkGray
Write-Host "  concise · root-cause · minimal · secure · verified" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""

# ── Mode detection (install vs update) ──────────────
$LocalVer = Get-LocalVersion
$Mode = "install"

if ($LocalVer -ne "none") {
    $RemoteVer = Get-RemoteVersion

    if ($LocalVer -eq $RemoteVer -and $RemoteVer -ne "unknown") {
        Write-Ok "rawcode v$LocalVer is already up to date"
        Write-Host ""
        exit 0
    }

    $Mode = "update"
    if ($RemoteVer -ne "unknown") {
        Write-Step "Updating rawcode v$LocalVer → v$RemoteVer"
    } else {
        Write-Step "Updating rawcode v$LocalVer → latest"
    }
    Write-Host ""
}

# ── Prerequisites ───────────────────────────────────
Write-Step "Checking prerequisites..."

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Fail "git not found. Install git and try again."
    exit 1
}
Write-Ok "git found"

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Warn "claude CLI not found — install it: https://claude.ai/code"
} else {
    Write-Ok "claude CLI found"
}

Write-Host ""

# ── Plugin directory ────────────────────────────────
$PluginDir = "$env:USERPROFILE\.claude\plugins"
if (-not (Test-Path $PluginDir)) {
    New-Item -ItemType Directory -Path $PluginDir -Force | Out-Null
}

# ── Backup existing installation ────────────────────
$BackupDir = $null
if (Test-Path $InstallDir) {
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $BackupDir = "$InstallDir.backup.$timestamp"
    Write-Warn "Backing up current installation"
    Move-Item $InstallDir $BackupDir
}

# ── Clone ───────────────────────────────────────────
Write-Step "Downloading rawcode..."

$spinChars = @('⠋','⠙','⠹','⠸','⠼','⠴','⠦','⠧','⠇','⠏')
$job = Start-Job -ScriptBlock {
    param($r, $d)
    git clone --depth 1 "https://github.com/$r.git" $d 2>$null
} -ArgumentList $Repo, $InstallDir

$i = 0
while ($job.State -eq 'Running') {
    Write-Host -NoNewline "`r  $($spinChars[$i % $spinChars.Length]) Cloning repository..." -ForegroundColor Cyan
    Start-Sleep -Milliseconds 80
    $i++
}
Write-Host "`r                                          `r" -NoNewline
Receive-Job $job -ErrorAction SilentlyContinue | Out-Null
Remove-Job $job

if (-not (Test-Path $InstallDir)) {
    Write-Fail "Download failed. Check your internet connection."
    if ($BackupDir -and (Test-Path $BackupDir)) {
        Move-Item $BackupDir $InstallDir
        Write-Warn "Previous version restored"
    }
    exit 3
}
Write-Ok "Repository cloned"

# ── Cleanup ─────────────────────────────────────────
Remove-Item -Recurse -Force "$InstallDir\.git" -ErrorAction SilentlyContinue
Write-Ok "Scripts configured"

# ── Verify installation ────────────────────────────
$InstalledVer = Get-LocalVersion
if ((Test-Path "$InstallDir\agents\rawcode.md") -and (Test-Path "$InstallDir\settings.json")) {
    Write-Ok "Installation verified"
} else {
    Write-Fail "Installation incomplete — files missing"
    exit 4
}

# ── Clean old backups (keep last 2) ────────────────
$backups = Get-ChildItem "$PluginDir\rawcode.backup.*" -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending
if ($backups.Count -gt 2) {
    $backups | Select-Object -Skip 2 | ForEach-Object {
        Remove-Item $_.FullName -Recurse -Force
    }
    Write-Ok "Old backups cleaned"
}

# ── Done ────────────────────────────────────────────
Write-Host ""
Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""

if ($Mode -eq "update") {
    Write-Host "  rawcode updated to v$InstalledVer!" -ForegroundColor Green
} else {
    Write-Host "  rawcode v$InstalledVer installed!" -ForegroundColor Green
}

Write-Host ""
Write-Host "  Get started:" -ForegroundColor DarkGray
Write-Host "    $ claude" -NoNewline -ForegroundColor White
Write-Host "    # rawcode loads automatically" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Update:" -ForegroundColor DarkGray
Write-Host "    irm https://raw.githubusercontent.com/juandarn/rawcode/master/setup/install.ps1 | iex" -ForegroundColor White
Write-Host ""
Write-Host "  Uninstall:" -ForegroundColor DarkGray
Write-Host "    & `"$env:USERPROFILE\.claude\plugins\rawcode\setup\uninstall.sh`"" -ForegroundColor White
Write-Host ""
