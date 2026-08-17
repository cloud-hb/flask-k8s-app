# check_port.ps1
# Cross‑platform (Windows) DevOps‑friendly port checker.
#
# Features:
#  - Shows: ProcessName, PID, UserName, BindAddress, State, FullCommand, Container/Svc
#  - Highlights: localhost only vs all interfaces
#  - Distinguishes: LISTEN vs other states
#  - Optional: Docker container name if docker is available
# 
# Run in PowerShell (as Administrator for full visibility)
# Usage: .\check_port.ps1 <port>
# Example: .\check_port.ps1 8080
#

param (
    [Parameter(Mandatory = $true)]
    [int]$Port
)

# Helper: classify bind address
function Get-BindClass {
    param([string]$Address)
    if ($Address -eq '0.0.0.0' -or $Address -eq '::') {
        return 'all_interfaces'
    } elseif ($Address -eq '127.0.0.1' -or $Address -eq '::1' -or $Address -eq '[::1]') {
        return 'localhost_only'
    } else {
        return 'other'
    }
}

# Helper: get full command line via WMI/CIM
function Get-FullCommand {
    param([int]$Pid)
    try {
        $proc = Get-CimInstance Win32_Process -Filter "ProcessId = $Pid" -ErrorAction Stop
        return $proc.CommandLine
    } catch {
        return 'unknown'
    }
}

# Helper: try resolve Docker container name for this port
function Try-ResolveContainer {
    param([int]$Port)
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        $container = docker ps --format 'table {{.Names}}`t{{.Ports}}' 2>$null |
            Where-Object { $_ -match ":$Port" } |
            Select-Object -First 1 |
            ForEach-Object { ($_ -split "`t")[0] }
        if ($container) {
            return $container
        }
    }
    return '-'
}

$connections = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue

if (-not $connections) {
    Write-Host "Port $Port is NOT in use (no TCP entries found)."
    exit 0
}

$results = foreach ($conn in $connections) {
    $pid = $conn.OwningProcess
    $process = Get-Process -Id $pid -ErrorAction SilentlyContinue

    $processName  = if ($process) { $process.ProcessName } else { 'Unknown' }
    $userName     = if ($process) { $process.UserName } else { 'Unknown' }
    $localAddress = $conn.LocalAddress
    $state        = $conn.State

    $bindClass    = Get-BindClass -Address $localAddress
    $bindDisplay  = switch ($bindClass) {
        'all_interfaces'   { "all_interfaces ($localAddress)" }
        'localhost_only'   { "localhost_only ($localAddress)" }
        default            { "other ($localAddress)" }
    }

    $fullCommand  = Get-FullCommand -Pid $pid
    $container    = Try-ResolveContainer -Port $Port

    [pscustomobject]@{
        ProcessName   = $processName
        PID           = $pid
        UserName      = $userName
        BindAddress   = $bindDisplay
        State         = $state
        ContainerSvc  = $container
        FullCommand   = $fullCommand
    }
}

# Display as a table
$results | Format-Table -AutoSize -Property ProcessName, PID, UserName, BindAddress, State, ContainerSvc, FullCommand

Write-Host "Summary by process:"
$results | Group-Object -Property ProcessName | ForEach-Object {
    Write-Host "  - $($_.Name) : $($_.Count) entry/entries"
}