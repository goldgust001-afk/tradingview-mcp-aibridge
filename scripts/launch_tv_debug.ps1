param(
    [int]$Port = 9222
)

$ErrorActionPreference = 'Stop'

Write-Host "=== TradingView CDP Launcher (AI BRIDGE) ===" -ForegroundColor Cyan

# 1. MSIX install lookup (tradingview.com/desktop now ships as MSIX by default)
$pkg = Get-AppxPackage -Name 'TradingView.Desktop' -ErrorAction SilentlyContinue
$useMsix = $false
$exe = $null

if ($pkg) {
    $useMsix = $true
    Write-Host "Found via MSIX: $($pkg.PackageFullName)"
} else {
    # 2. Fallback to classic install paths
    $candidates = @(
        "$env:LOCALAPPDATA\TradingView\TradingView.exe",
        "$env:ProgramFiles\TradingView\TradingView.exe",
        "${env:ProgramFiles(x86)}\TradingView\TradingView.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { $exe = $c; Write-Host "Found at: $exe"; break }
    }
}

if (-not $useMsix -and -not $exe) {
    Write-Host "TradingView not found." -ForegroundColor Red
    Write-Host "Checked: MSIX (Get-AppxPackage), LOCALAPPDATA, Program Files."
    Write-Host "Install from https://www.tradingview.com/desktop/"
    exit 1
}

# Prerequisite check for MSIX: Developer Mode must be on or the Electron
# runtime inside the package is sandboxed enough to silently refuse opening
# the remote-debugging TCP port, even when the COM launch succeeds.
if ($useMsix) {
    $devKey = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' `
        -Name 'AllowDevelopmentWithoutDevLicense' -ErrorAction SilentlyContinue
    if (-not $devKey -or $devKey.AllowDevelopmentWithoutDevLicense -ne 1) {
        Write-Host "Developer Mode is OFF. MSIX TradingView will NOT open the CDP port until it is enabled." -ForegroundColor Red
        Write-Host "Enable it via: Settings -> Update and Security -> For developers -> Developer Mode: ON" -ForegroundColor Yellow
        Write-Host "(Windows 11: Settings -> Privacy and security -> For developers)" -ForegroundColor Yellow
        exit 1
    }
}

# Stop any running instances so the CDP flag takes effect on a fresh launch
$running = Get-Process TradingView -ErrorAction SilentlyContinue
if ($running) {
    Write-Host "Stopping $($running.Count) existing TradingView process(es)..."
    $running | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

Write-Host "Launching with --remote-debugging-port=$Port..."
if ($useMsix) {
    # MSIX apps in C:\Program Files\WindowsApps\ have restrictive ACLs that block
    # direct Start-Process. Microsoft's IApplicationActivationManager COM API is
    # the supported way to activate a packaged app with custom arguments.
    $manifest = Get-AppxPackageManifest $pkg
    $app = $manifest.Package.Applications.Application
    if ($app -is [array]) { $app = $app[0] }
    $aumid = "$($pkg.PackageFamilyName)!$($app.Id)"

    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class TVLauncher {
    [ComImport, Guid("2e941141-7f97-4756-ba1d-9decde894a3d"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IApplicationActivationManager {
        int ActivateApplication([MarshalAs(UnmanagedType.LPWStr)] string appUserModelId,
                                [MarshalAs(UnmanagedType.LPWStr)] string arguments,
                                int options, out uint processId);
    }
    [ComImport, Guid("45ba127d-10a8-46ea-8ab7-56ea9078943c")]
    public class ApplicationActivationManager { }
    public static uint Launch(string aumid, string args) {
        var mgr = (IApplicationActivationManager)(new ApplicationActivationManager());
        uint pid; int hr = mgr.ActivateApplication(aumid, args, 0, out pid);
        if (hr != 0) throw new Exception("ActivateApplication HRESULT: " + hr);
        return pid;
    }
}
"@ -ErrorAction Stop

    $launchedPid = [TVLauncher]::Launch($aumid, "--remote-debugging-port=$Port")
    Write-Host "Activated AUMID $aumid (PID $launchedPid)"
} else {
    Start-Process -FilePath $exe -ArgumentList "--remote-debugging-port=$Port"
}

# MSIX cold start is slow: the Electron main process can take 30-60s to finish
# initialization before the CDP listener comes up. Use 127.0.0.1 (not localhost)
# because DNS resolution adds noticeable delay on each failed attempt.
$timeoutSeconds = if ($useMsix) { 90 } else { 30 }
Write-Host "Waiting for CDP on port $Port (timeout ${timeoutSeconds}s)..." -NoNewline
$ok = $false
for ($i = 0; $i -lt $timeoutSeconds; $i++) {
    Start-Sleep -Seconds 1
    Write-Host "." -NoNewline
    try {
        Invoke-WebRequest -Uri "http://127.0.0.1:$Port/json/version" -UseBasicParsing -TimeoutSec 2 | Out-Null
        $ok = $true
        break
    } catch { }
}
Write-Host ""

if ($ok) {
    Write-Host "CDP ready at http://127.0.0.1:$Port" -ForegroundColor Green
    Write-Host "You can now use Claude Code with the tradingview MCP server." -ForegroundColor Green
} else {
    Write-Host "CDP port $Port did not respond within ${timeoutSeconds} seconds." -ForegroundColor Red
    if ($useMsix) {
        Write-Host "Confirm Developer Mode is ON and the TradingView window is fully loaded, then retry." -ForegroundColor Yellow
        Write-Host "If it still fails, try the classic (.exe) installer from https://www.tradingview.com/desktop/" -ForegroundColor Yellow
    }
    exit 1
}
