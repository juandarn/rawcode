# rawcode installer for Codex (Windows)
# Usage: irm https://raw.githubusercontent.com/juandarn/rawcode/master/install-codex.ps1 | iex

$ErrorActionPreference = "Stop"

$Repo = "juandarn/rawcode"
$Target = Join-Path $env:USERPROFILE "AGENTS.md"
$Url = "https://raw.githubusercontent.com/$Repo/master/codex/AGENTS.md"
$TempFile = New-TemporaryFile

Write-Host "Installing rawcode for Codex..." -ForegroundColor Cyan

try {
    Invoke-WebRequest -UseBasicParsing $Url -OutFile $TempFile

    if (Test-Path $Target) {
        $TargetHash = (Get-FileHash $Target -Algorithm SHA256).Hash
        $TempHash = (Get-FileHash $TempFile -Algorithm SHA256).Hash

        if ($TargetHash -eq $TempHash) {
            Write-Host "rawcode for Codex is already up to date at $Target" -ForegroundColor Green
            return
        }

        $Backup = "$Target.rawcode.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
        Copy-Item $Target $Backup
        Write-Host "Backed up existing AGENTS.md to $Backup" -ForegroundColor Yellow
    }

    Move-Item $TempFile $Target -Force
    $TempFile = $null

    Write-Host ""
    Write-Host "rawcode for Codex installed successfully!" -ForegroundColor Green
    Write-Host "Location: $Target"
    Write-Host "Codex will use these defaults for repos under $env:USERPROFILE."
    Write-Host "Repo-local AGENTS.md files override the global one."
}
finally {
    if ($TempFile -and (Test-Path $TempFile)) {
        Remove-Item $TempFile -Force -ErrorAction SilentlyContinue
    }
}
