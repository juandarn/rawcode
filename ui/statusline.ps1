# rawcode powerline status line for Claude Code (Windows)
# PowerShell equivalent of statusline.sh

$InputData = $input | Out-String

if ([string]::IsNullOrWhiteSpace($InputData)) {
    Write-Host " rawcode " -NoNewline -BackgroundColor DarkRed -ForegroundColor White
    exit 0
}

try {
    $data = $InputData | ConvertFrom-Json
} catch {
    Write-Host " rawcode " -NoNewline -BackgroundColor DarkRed -ForegroundColor White
    exit 0
}

# Shorten model name
$Model = switch -Wildcard ($data.model) {
    "*opus*"   { "opus" }
    "*sonnet*" { "sonnet" }
    "*haiku*"  { "haiku" }
    default    { if ($data.model) { $data.model } else { "?" } }
}

# Context color
$Ctx = $data.contextPercent
if ($null -ne $Ctx) {
    if ($Ctx -ge 80) {
        $CtxColor = "Red"
    } elseif ($Ctx -ge 60) {
        $CtxColor = "Yellow"
    } else {
        $CtxColor = "Green"
    }
} else {
    $CtxColor = "Green"
}

# Git branch
$Branch = git branch --show-current 2>$null

# Build segments
Write-Host " rawcode " -NoNewline -BackgroundColor DarkRed -ForegroundColor White

if ($data.agentName) {
    Write-Host " @$($data.agentName) " -NoNewline -BackgroundColor DarkGray -ForegroundColor Cyan
}

if ($Model -ne "?") {
    Write-Host " $Model " -NoNewline -BackgroundColor Black -ForegroundColor White
}

if ($null -ne $Ctx) {
    Write-Host " ctx:${Ctx}% " -NoNewline -BackgroundColor Black -ForegroundColor $CtxColor
}

if ($data.totalCost) {
    Write-Host " `$$($data.totalCost) " -NoNewline -BackgroundColor Black -ForegroundColor Yellow
}

if ($Branch) {
    Write-Host " $Branch " -NoNewline -BackgroundColor Black -ForegroundColor Green
}

Write-Host ""
