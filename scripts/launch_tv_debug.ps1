param(
    [int]$Port = 9222
)

$ErrorActionPreference = 'Stop'

Write-Host "=== TradingView CDP Launcher (AI BRIDGE) ===" -ForegroundColor Cyan

# 1. MSIX install lookup (most Windows installs from tradingview.com/desktop now use MSIX)
$exe = $null
$pkg = Get-AppxPackage -Name 'TradingView.Desktop' -ErrorAction SilentlyContinue
if ($pkg) {
    $candidate = Join-Path $pkg.InstallLocation 'TradingView.exe'
    if (Test-Path $candidate) {
        $exe = $candidate
        Write-Host "Found via MSIX: $exe"
    }
}

# 2. Fallback to classic install paths
if (-not $exe) {
    $candidates = @(
        "$env:LOCALAPPDATA\TradingView\TradingView.exe",
        "$env:ProgramFiles\TradingView\TradingView.exe",
        "${env:ProgramFiles(x86)}\TradingView\TradingView.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { $exe = $c; Write-Host "Found at: $exe"; break }
    }
}

if (-not $exe) {
    Write-Host "TradingView not found." -ForegroundColor Red
    Write-Host "Checked: MSIX (Get-AppxPackage), LOCALAPPDATA, Program Files."
    Write-Host "If installed elsewhere, launch manually:" -ForegroundColor Yellow
    Write-Host "  Start-Process '<path>\TradingView.exe' '--remote-debugging-port=$Port'"
    exit 1
}

# Stop any running instances so the CDP flag takes effect on a fresh launch
$running = Get-Process TradingView -ErrorAction SilentlyContinue
if ($running) {
    Write-Host "Stopping $($running.Count) existing TradingView process(es)..."
    $running | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

Write-Host "Launching with --remote-debugging-port=$Port..."
Start-Process -FilePath $exe -ArgumentList "--remote-debugging-port=$Port"

Write-Host "Waiting for CDP on port $Port..." -NoNewline
$ok = $false
for ($i = 0; $i -lt 20; $i++) {
    Start-Sleep -Seconds 1
    Write-Host "." -NoNewline
    try {
        Invoke-WebRequest -Uri "http://localhost:$Port/json/version" -UseBasicParsing -TimeoutSec 2 | Out-Null
        $ok = $true
        break
    } catch { }
}
Write-Host ""

if ($ok) {
    Write-Host "CDP ready at http://localhost:$Port" -ForegroundColor Green
    Write-Host "You can now use Claude Code with the tradingview MCP server." -ForegroundColor Green
} else {
    Write-Host "CDP port $Port did not respond within 20 seconds." -ForegroundColor Red
    exit 1
}
