# Linux

The Linux build comes from the same source as the Windows one. FFmpeg is
bundled the same way: `ffmpeg_kit_flutter_new` downloads its prebuilt
full-GPL libraries (x86_64 only) during the build, and they travel inside
the bundle. Nothing on the target system needs FFmpeg.

## Building from Windows

There is no need for a virtual machine. With Docker Desktop on the WSL 2
backend:

```powershell
.\installer\build-linux.ps1          # analyse, test, build, pack into dist\
.\installer\build-linux.ps1 smoke    # start it on a virtual display, photograph it
.\installer\build-linux.ps1 e2e      # process a sample video through the GUI
.\installer\build-linux.ps1 run      # show it on the Windows desktop through WSLg
.\installer\build-linux.ps1 shell    # a shell in the container
```

The image ([installer/linux/Dockerfile](../installer/linux/Dockerfile)) is
Ubuntu 22.04 with a pinned Flutter. It is deliberately not the newest
Ubuntu: a binary needs a glibc at least as new as the one it was linked
against, so an older base runs on more distributions.

The checkout is mounted read-only and copied into a volume of its own.
Building in the Windows checkout would rewrite `.dart_tool` with Linux paths
and break the Windows build that shares it.

`smoke` is the cheap check that a build is alive. It starts the bundle on
Xvfb, waits for the window, saves `dist/screenshots/queue.png`, and launches a
second copy to check that it leaves without opening a window. It also fails
if the plugin could not load the bundled FFmpeg, which is the failure a
window that opens fine would otherwise hide.

`e2e` does what a person would. It makes a thirty-second sample that
alternates two seconds of tone with three of silence, presses Ctrl+O, types
the path into the portal's file dialog, and presses Start. Then it measures
the output with `ffprobe` and fails unless it is clearly shorter. The screens
it passes through are saved as `dist/screenshots/e2e-*.png`. The system
`ffmpeg` it uses for the sample and the measurement is in the image only for
this; the app runs the copy in its bundle.

`run` is for looking at it yourself, with real drag and drop. WSLg draws
Linux windows on the Windows desktop, and Docker Desktop exposes its X server
to containers. The Windows Videos folder appears as `~/Videos`, so there is
something real to open and the results land where Windows can play them.

The first run is slow, because it downloads Flutter and the FFmpeg libraries.
The `silence-speedup-linux-work` and `-pub` volumes keep both for the next
run. `-Rebuild` rebuilds the image, for instance after raising the Flutter
version in the Dockerfile.

## Building on Linux

These are Flutter's own prerequisites, plus what the FFmpeg plugin adds and
`patchelf`. The codec libraries in the second line are what the plugin's
FFmpeg was linked against; the build copies them into the bundle, so they
have to be installed to be copied. They are Ubuntu 22.04's names, and the
[Dockerfile](../installer/linux/Dockerfile) is the list that is known to work.

```bash
sudo apt install clang cmake ninja-build pkg-config patchelf libgtk-3-dev libjson-glib-dev
sudo apt install libass9 libmp3lame0 libnuma1 libogg0 libopencore-amrnb0 libopus0 \
  libshine3 libsnappy1v5 libsoxr0 libspeex1 libtheora0 libtwolame0 libvidstab1.1 \
  libvo-amrwbenc0 libvorbis0a libvorbisenc2 libvpx7 libwebp7 libwebpmux3 \
  libx265-199 libxml2 libxvidcore4
flutter build linux --release
```

The result is `build/linux/x64/release/bundle/`. The whole folder is the
app: the FFmpeg libraries and everything they need sit in its `lib/`, with
`RUNPATH=$ORIGIN`, which is the work of
[linux/bundle-ffmpeg-libraries.sh](../linux/bundle-ffmpeg-libraries.sh). The
packed bundle has been checked on clean Ubuntu 24.04, Debian 12 and
Fedora 41 with nothing but GTK installed: no library missing, and FFmpeg
loads. That is a check of the libraries, not a run: the app has been used,
through `e2e`, only on the Ubuntu 22.04 it is built on.

## What differs from Windows

- **One copy at a time** rests on the session bus, not on a mutex. The GTK
  application is registered as unique (the template's
  `G_APPLICATION_NON_UNIQUE` is removed), so a second launch hands its
  activation to the first one and exits. The first one then presents the
  window it already has; see `my_application_activate` in
  [linux/runner/my_application.cc](../linux/runner/my_application.cc). Without
  a session bus, which in practice means only a bare container, the check
  does not happen.
- **File dialogs** come from the XDG desktop portal, which `file_picker`
  asks over the session bus. GNOME, KDE and the other full desktops run
  one. A bare window manager may not, and then the dialog cannot open.
  `lib/ui/file_dialogs.dart` catches that and says so: an exception from a
  button press would otherwise go nowhere, and the press would look
  ignored. Dragging files onto the window still works without it. A package
  should depend on `xdg-desktop-portal`.
- **The window icon** is read from the bundled `assets/icons/icon.png` until a
  package installs a desktop entry and a themed icon.

## Distribution

Not decided yet. The bundle is packed as a `.tar.gz`, which is enough to try
it but is not an installation: there is no desktop entry and no menu item.
The candidates are Flathub, which plays the role the Microsoft Store plays
on Windows and updates the app itself, and an AppImage published on the
GitHub releases. Whichever it is, the update notice in the app (see
`UpdateChecker`) only says that a newer version exists. It never downloads
anything.
