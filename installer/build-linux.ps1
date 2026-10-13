<#
.SYNOPSIS
    Builds, smoke-tests or runs Silence SpeedUp for Linux, from Windows, in Docker.

.DESCRIPTION
    Builds the image in installer\linux the first time, then runs one command
    in it. The checkout is mounted read-only and copied into a volume inside
    the container, so the Windows build's .dart_tool is never touched.

    build   analyse, test, build the release bundle and pack it into dist\
    smoke   start the bundle on a virtual display, photograph it into
            dist\screenshots, and check that a second copy does not open
    e2e     process a sample video through the GUI (Ctrl+O, the file
            dialog, Start) and check the result came out shorter
    run     show the bundle on the Windows desktop through WSLg, with the
            Windows Videos folder as ~/Videos
    shell   a shell in the container's copy of the source

    Needs Docker Desktop on the WSL 2 backend. The first build downloads
    Flutter and the prebuilt FFmpeg libraries and is slow; later ones reuse
    them from named volumes.

.PARAMETER Command
    One of build, smoke, e2e, run, shell. Defaults to build.

.PARAMETER Rebuild
    Rebuild the image, for instance after changing the Flutter version.

.EXAMPLE
    .\installer\build-linux.ps1
    .\installer\build-linux.ps1 smoke
    .\installer\build-linux.ps1 run
#>
[CmdletBinding()]
param(
    [ValidateSet('build', 'smoke', 'e2e', 'run', 'shell')]
    [string] $Command = 'build',
    [switch] $Rebuild
)

$ErrorActionPreference = 'Stop'

# Docker reports progress on stderr. Windows PowerShell turns stderr from a
# native command into an error record whenever it is redirected, and 'Stop'
# makes that fatal, so `build-linux.ps1 2>&1 | Tee-Object` would die on the
# first progress line. Docker is judged by its exit code instead.
function Invoke-Docker {
    $ErrorActionPreference = 'Continue'
    & docker @args 2>&1 | ForEach-Object { "$_" }
    if ($LASTEXITCODE -ne 0) { throw "docker $($args[0]) failed" }
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$distDir = Join-Path $projectRoot 'dist'
$image = 'silence-speedup-linux'

New-Item -ItemType Directory -Force $distDir | Out-Null

# Listed rather than inspected: inspect reports a missing image on stderr,
# which Windows PowerShell turns into a terminating error under 'Stop'.
$imageExists = [bool] (docker image ls -q $image)
if ($Rebuild -or -not $imageExists) {
    Invoke-Docker build -t $image (Join-Path $PSScriptRoot 'linux')
}

$arguments = @(
    'run', '--rm',
    '-v', "${projectRoot}:/src:ro",
    '-v', "${distDir}:/out",
    # The copy of the source, its build directory and the FFmpeg download
    # survive between runs here, which is what makes a second build quick.
    '-v', 'silence-speedup-linux-work:/work',
    '-v', 'silence-speedup-linux-pub:/home/builder/.pub-cache'
)

if ($Command -eq 'run') {
    # WSLg's X server, as Docker Desktop exposes it to containers.
    $arguments += @(
        '-v', '/run/desktop/mnt/host/wslg/.X11-unix:/tmp/.X11-unix',
        '-v', '/run/desktop/mnt/host/wslg:/mnt/wslg',
        '-e', 'DISPLAY=:0',
        '-e', 'PULSE_SERVER=/mnt/wslg/PulseServer',
        # The portal picks its GTK backend for the file dialogs by this.
        '-e', 'XDG_CURRENT_DESKTOP=GNOME',
        # Windows' Videos folder as ~/Videos, so there is something real to
        # open, and the results land where Windows can play them.
        '-v', "$([Environment]::GetFolderPath('MyVideos')):/home/builder/Videos"
    )
}
if ($Command -eq 'shell') {
    $arguments += '-it'
}

$arguments += @($image, $Command)
if ($Command -eq 'shell') {
    # Interactive: left attached to the console rather than piped.
    docker @arguments
} else {
    Invoke-Docker @arguments
}
