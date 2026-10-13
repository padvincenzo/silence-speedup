<#
.SYNOPSIS
    Builds Silence SpeedUp for Windows and packages it with Inno Setup.

.DESCRIPTION
    Reads the version from pubspec.yaml so it is stated in exactly one place,
    runs the Flutter release build unless -SkipBuild is given, then compiles
    installer\silence-speedup.iss into dist\.

    The whole Release folder is packaged, not just the executable: the bundled
    FFmpeg libraries sit beside it and the app will not start without them.

.PARAMETER SkipBuild
    Package whatever is already in build\windows\x64\runner\Release.

.PARAMETER IsccPath
    Path to Inno Setup's command-line compiler, when it is not on PATH and not
    in one of the usual install locations.

.EXAMPLE
    .\installer\build-installer.ps1
#>
[CmdletBinding()]
param(
    [switch] $SkipBuild,
    [string] $IsccPath
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$releaseDir = Join-Path $projectRoot 'build\windows\x64\runner\Release'
$script = Join-Path $PSScriptRoot 'silence-speedup.iss'
$distDir = Join-Path $projectRoot 'dist'

# --- Version -----------------------------------------------------------------
# Single source of truth: pubspec.yaml, where the version is a plain x.y.z
# whose patch number rises with every build. Anything after a '+' is dropped
# anyway, since Inno Setup will not take it.
$pubspec = Join-Path $projectRoot 'pubspec.yaml'
$versionLine = Select-String -Path $pubspec -Pattern '^version:\s*(.+)$' | Select-Object -First 1
if (-not $versionLine) { throw "No version found in $pubspec" }
$version = $versionLine.Matches[0].Groups[1].Value.Trim().Split('+')[0]
Write-Host "Version: $version"

# --- Locate ISCC -------------------------------------------------------------
if (-not $IsccPath) {
    $candidates = @(
        (Get-Command 'ISCC.exe' -ErrorAction SilentlyContinue).Source,
        "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
    )
    $IsccPath = $candidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
}
if (-not $IsccPath) {
    throw "Inno Setup 6 not found. Install it (winget install --id JRSoftware.InnoSetup --source winget) or pass -IsccPath."
}
Write-Host "Inno Setup: $IsccPath"

# --- Flutter build -----------------------------------------------------------
if (-not $SkipBuild) {
    Write-Host 'Building the Windows release...'
    Push-Location $projectRoot
    try {
        & flutter build windows --release
        if ($LASTEXITCODE -ne 0) { throw "flutter build windows failed ($LASTEXITCODE)" }
    }
    finally {
        Pop-Location
    }
}

if (-not (Test-Path (Join-Path $releaseDir 'silence_speedup.exe'))) {
    throw "No build found in $releaseDir. Run without -SkipBuild."
}

# The app encodes exclusively with libx264; without that DLL every export
# fails at the first fragment, so catch it here rather than in a bug report.
if (-not (Get-ChildItem $releaseDir -Filter 'libx264*.dll' -ErrorAction SilentlyContinue)) {
    throw "libx264 is missing from $releaseDir - the FFmpeg build is not the full-GPL one."
}

# --- Package -----------------------------------------------------------------
New-Item -ItemType Directory -Force -Path $distDir | Out-Null
& $IsccPath "/DAppVersion=$version" $script
if ($LASTEXITCODE -ne 0) { throw "Inno Setup failed ($LASTEXITCODE)" }

$installer = Join-Path $distDir "SilenceSpeedUp-$version-windows-x64-setup.exe"
$sizeMb = [math]::Round((Get-Item $installer).Length / 1MB, 1)
Write-Host ''
Write-Host "Installer: $installer ($sizeMb MB)"
