#!/usr/bin/env pwsh
#
# check_docker_image_data.ps1
# Cross‑platform (Windows PowerShell / PowerShell Core) script to inspect a Docker image's filesystem.
#
# Features:
#  - Creates a temporary container from a given image
#  - Exports its filesystem to a tarball
#  - Exports the tarball into a directory for inspection
#  - Cleans up the container afterwards
#  - Optional "cleanup" mode to remove old temp containers and extracted dirs/tars
#
# Make script executable (PowerShell Core on Linux/macOS):
#   chmod +x check_docker_image_data.ps1
#
# Usage:
#   .\check_docker_image_data.ps1 [IMAGE]
#   .\check_docker_image_data.ps1 cleanup
#
# Examples:
#   .\check_docker_image_data.ps1
#   .\check_docker_image_data.ps1 username/flask-k8s-app:latest
#   .\check_docker_image_data.ps1 cleanup
#

$ErrorActionPreference = "Stop"

# If "cleanup" is passed as the first argument, run cleanup mode
if ($args.Count -gt 0 -and $args[0] -eq "cleanup") {
    Write-Host "Running cleanup: removing old temp containers and extracted filesystems..."

    # Remove containers whose names start with "tmp-inspect-"
    $containers = docker ps -a --format '{{.Names}}' | Where-Object { $_ -like "tmp-inspect-*" }
    foreach ($name in $containers) {
        Write-Host "Removing container: $name"
        docker rm -f $name *>$null | Out-Null
    }

    # Remove tar files matching the pattern: image-fs-tmp-inspect-*.tar
    $tarFiles = Get-ChildItem -Path . -Filter "image-fs-tmp-inspect-*.tar" -ErrorAction SilentlyContinue
    foreach ($f in $tarFiles) {
        Write-Host "Removing tar: $($f.Name)"
        Remove-Item -LiteralPath $f.FullName -Force
    }

    # Remove directories matching the pattern: image-fs-tmp-inspect-*
    $dirs = Get-ChildItem -Path . -Directory -Filter "image-fs-tmp-inspect-*" -ErrorAction SilentlyContinue
    foreach ($d in $dirs) {
        Write-Host "Removing directory: $($d.Name)"
        Remove-Item -LiteralPath $d.FullName -Recurse -Force
    }

    Write-Host "Cleanup complete."
    exit 0
}

# Default image if not provided
$image = if ($args.Count -gt 0) { $args[0] } else { "username/flask-k8s-app:latest" }

# Generate unique names to avoid collisions (timestamp + process id)
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$pidStr = [System.Diagnostics.Process]::GetCurrentProcess().Id
$containerName = "tmp-inspect-${timestamp}-${pidStr}"
$tarFile = "image-fs-${containerName}.tar"
$extractDir = "image-fs-${containerName}"

function Cleanup-Container {
    # Remove container if it exists
    $exists = docker ps -a --format '{{.Names}}' | Where-Object { $_ -eq $containerName }
    if ($exists) {
        docker rm -f $containerName *>$null | Out-Null
    }
}

trap {
    Cleanup-Container
}

Write-Host "Using image: $image"
Write-Host "Container name: $containerName"
Write-Host "Tar file: $tarFile"
Write-Host "Extract directory: $extractDir"

# Create (but don't start) a container from the image
docker create --name $containerName $image *>$null | Out-Null

# Export its filesystem to a tar
docker export $containerName > $tarFile

# Extract and browse
if (Test-Path $extractDir) {
    Remove-Item -Path $extractDir -Recurse -Force
}
New-Item -ItemType Directory -Path $extractDir | Out-Null

# Use tar from Git Bash, WSL, or Docker Desktop's bundled tar if available.
# On plain Windows without tar, you can use an external tool (e.g., 7z, GNU tar).
# Here we assume 'tar' is available in PATH.
tar -xf $tarFile -C $extractDir

Write-Host "Filesystem extracted to: $extractDir"
Write-Host "You can now inspect the contents, e.g.:"
Write-Host "  Get-ChildItem -Recurse '$extractDir'"
Write-Host ""
Write-Host "When done, you can either:"
Write-Host "  - Manually remove this run's artifacts:"
Write-Host "      Remove-Item -Recurse -Force '$extractDir', '$tarFile'"
Write-Host "  - Or run full cleanup for all old runs:"
Write-Host "      .\check_docker_image_data.ps1 cleanup"
Write-Host ""
Write-Host "Container will be removed automatically on exit."

# Normal exit: ensure container cleanup
Cleanup-Container