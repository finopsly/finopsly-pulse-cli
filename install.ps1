# Installs the FinOpsly CLI on Windows.
#
# Usage:
#   irm https://raw.githubusercontent.com/finopsly/finopsly-pulse-cli/main/install.ps1 | iex
#
# To install a specific version, download and run with a parameter instead:
#   $script = irm https://raw.githubusercontent.com/finopsly/finopsly-pulse-cli/main/install.ps1
#   Invoke-Expression "& { $script } -Version v1.2.0"
param(
    [string]$Version = "latest"
)

$ErrorActionPreference = "Stop"

$repo = "finopsly/finopsly-pulse-cli"
$installDir = if ($env:FINOPSLY_INSTALL_DIR) { $env:FINOPSLY_INSTALL_DIR } else { "$env:LOCALAPPDATA\FinOpsly\bin" }

$arch = if ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture -eq [System.Runtime.InteropServices.Architecture]::Arm64) {
    "arm64"
} else {
    "amd64"
}

$archiveName = "finopsly_windows_$arch.zip"

if ($Version -eq "latest") {
    $url = "https://github.com/$repo/releases/latest/download/$archiveName"
    $checksumsUrl = "https://github.com/$repo/releases/latest/download/checksums.txt"
} else {
    $url = "https://github.com/$repo/releases/download/$Version/$archiveName"
    $checksumsUrl = "https://github.com/$repo/releases/download/$Version/checksums.txt"
}

$tmpDir = Join-Path $env:TEMP ([System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $tmpDir | Out-Null
try {
    $zipPath = Join-Path $tmpDir "finopsly.zip"
    Write-Host "Downloading $url"
    Invoke-WebRequest -Uri $url -OutFile $zipPath

    Write-Host "Verifying checksum"
    $checksumsPath = Join-Path $tmpDir "checksums.txt"
    Invoke-WebRequest -Uri $checksumsUrl -OutFile $checksumsPath

    $expectedSum = $null
    foreach ($line in Get-Content $checksumsPath) {
        $parts = $line -split '\s+', 2
        if ($parts.Length -eq 2 -and $parts[1].Trim() -eq $archiveName) {
            $expectedSum = $parts[0].ToLower()
            break
        }
    }
    if (-not $expectedSum) {
        throw "No checksum entry found for $archiveName in checksums.txt"
    }

    $actualSum = (Get-FileHash -Path $zipPath -Algorithm SHA256).Hash.ToLower()
    if ($actualSum -ne $expectedSum) {
        throw "Checksum mismatch for $archiveName (expected $expectedSum, got $actualSum)"
    }

    Expand-Archive -Path $zipPath -DestinationPath $tmpDir -Force

    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    Move-Item -Path (Join-Path $tmpDir "finopsly.exe") -Destination (Join-Path $installDir "finopsly.exe") -Force

    Write-Host "Installed finopsly to $installDir\finopsly.exe"

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $pathEntries = $userPath -split ";"
    if ($pathEntries -notcontains $installDir) {
        $newPath = if ($userPath) { "$userPath;$installDir" } else { $installDir }
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        $env:Path = "$env:Path;$installDir"
        Write-Host "Added $installDir to your user PATH — restart your terminal for it to take effect in new sessions."
    }

    & (Join-Path $installDir "finopsly.exe") version
} finally {
    Remove-Item -Recurse -Force $tmpDir
}
