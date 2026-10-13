<#
.SYNOPSIS
    Builds Silence SpeedUp for the Microsoft Store and packs it as an MSIX.

.DESCRIPTION
    Makes a release build with STORE_BUILD=true, which compiles out the update
    check (a Store app is updated by the Store), then packs the whole Release
    folder with the msix tool, using msix_config in pubspec.yaml. The result
    goes into dist\ for uploading in Partner Center.

    The package is not signed here: the Store signs what it publishes. It is
    therefore not installable by double-clicking, and it is not meant to be.

    The version is pubspec.yaml's x.y.z, which the tool turns into the
    x.y.z.0 the Store requires. The Store refuses a version it has already
    seen, so raise the patch number first, as for every build.

.PARAMETER SkipBuild
    Pack whatever is already in build\windows\x64\runner\Release. Only safe if
    that build was made with STORE_BUILD=true.

.EXAMPLE
    .\installer\build-msix.ps1
#>
[CmdletBinding()]
param(
    [switch] $SkipBuild
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$releaseDir = Join-Path $projectRoot 'build\windows\x64\runner\Release'
$distDir = Join-Path $projectRoot 'dist'

$pubspec = Join-Path $projectRoot 'pubspec.yaml'
$versionLine = Select-String -Path $pubspec -Pattern '^version:\s*(.+)$' | Select-Object -First 1
if (-not $versionLine) { throw "No version found in $pubspec" }
$version = $versionLine.Matches[0].Groups[1].Value.Trim().Split('+')[0]
Write-Host "Version: $version (package $version.0)"

Push-Location $projectRoot
try {
    if (-not $SkipBuild) {
        Write-Host 'Building the Store release...'
        & flutter build windows --release --dart-define=STORE_BUILD=true
        if ($LASTEXITCODE -ne 0) { throw "flutter build windows failed ($LASTEXITCODE)" }
    }

    if (-not (Test-Path (Join-Path $releaseDir 'silence_speedup.exe'))) {
        throw "No build found in $releaseDir. Run without -SkipBuild."
    }
    # As in build-installer.ps1: without libx264 every export fails.
    if (-not (Get-ChildItem $releaseDir -Filter 'libx264*.dll' -ErrorAction SilentlyContinue)) {
        throw "libx264 is missing from $releaseDir - the FFmpeg build is not the full-GPL one."
    }

    New-Item -ItemType Directory -Force -Path $distDir | Out-Null
    $name = "SilenceSpeedUp-$version-store"
    # The build above is the one to pack: letting the tool build again would
    # drop the STORE_BUILD define.
    & dart run msix:create --store --build-windows false `
        --output-path $distDir --output-name $name
    if ($LASTEXITCODE -ne 0) { throw "msix:create failed ($LASTEXITCODE)" }
}
finally {
    Pop-Location
}

$package = Join-Path $distDir "$name.msix"
$sizeMb = [math]::Round((Get-Item $package).Length / 1MB, 1)
Write-Host ''
Write-Host "Store package: $package ($sizeMb MB)"
Write-Host 'Upload it in Partner Center; the Store signs it.'
