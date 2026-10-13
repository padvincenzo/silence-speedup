# Publishing to the Microsoft Store

The GitHub release stays the primary one, built by
[installer/build-installer.ps1](../installer/build-installer.ps1). The Store is
a second channel for the same source, packaged as MSIX.

**Nothing here is built yet.** This file records what is already in place and
what is still missing, so the first packaging run is a matter of filling in
three identity fields rather than working out what the Store wants.

## What is already prepared

| Piece | Where | Note |
| --- | --- | --- |
| Package configuration | `msix_config` in [pubspec.yaml](../pubspec.yaml) | Inert until the `msix` tool is added; identity fields commented out |
| Store logo source | [installer/msix/logo.png](../installer/msix/logo.png) | 1024x1024, rendered from `assets/icons/icon.svg`; the tool derives every tile size from it |
| Version scheme | `version:` in pubspec | Plain `x.y.z`, patch raised every build, so the MSIX version is `x.y.z.0` — see below |
| Store build flag | [lib/build_config.dart](../lib/build_config.dart) | `--dart-define=STORE_BUILD=true` compiles out the update check |
| Executable metadata | [windows/runner/Runner.rc](../windows/runner/Runner.rc) | Real product name, company and copyright, which certification looks at |

## What is still needed

1. **A Partner Center account** and a reserved app name. Reserving the name
   produces the three values the package is identified by, and a package whose
   values do not match the reservation is rejected at submission:
   - `identity_name` — e.g. `12345VincenzoPadula.SilenceSpeedUp`
   - `publisher` — the full `CN=...` subject of the certificate the Store
     issues to the account
   - `publisher_display_name` — already set to `Vincenzo Padula`

   Fill them into `msix_config` and uncomment `store: true`.

2. **The packaging tool**:

   ```powershell
   dart pub add --dev msix
   ```

3. **A packaging run**, from a release build made with the Store flag:

   ```powershell
   flutter build windows --release --dart-define=STORE_BUILD=true
   dart run msix:create --store
   ```

   The tool packages the whole `build\windows\x64\runner\Release` folder, which
   is what carries the FFmpeg DLLs — the app does not start without them.

   Check on the first run that `capabilities: ''` is accepted. The app needs
   none: FFmpeg is bundled, files come from folders the user picks, and a Store
   build never opens a socket.

## Things that decide the shape of the package

### The Store signs it, so there is no certificate to buy

Store submissions are signed by Microsoft with the account's own certificate,
which is also what makes the heuristic antivirus warnings on the unsigned
GitHub build a non-issue for Store users. A certificate is only needed to
sideload an MSIX outside the Store.

### A Store build must not check for updates

Store apps are updated by the Store. Looking for a newer release and offering
to download an executable is what `STORE_BUILD=true` removes, through
`UpdateChecker.enabled` — a test covers the switched-off case. The source
link, the issue tracker and the licence notice stay: those are pages, not
payloads.

### Versions must rise, and end in zero

MSIX versions have four components and the Store requires the last one to be
`0`; it also refuses a version it has already seen. A plain `x.y.z` in pubspec
becomes `x.y.z.0`, and since the patch number is raised for every build (see
[CLAUDE.md](../CLAUDE.md)), successive packages always sort correctly. Do not
add an `msix_version` to `msix_config`: it would be a second place to
remember, and the tool derives it from `version:` on its own.

### Full trust, not a sandbox

This is a packaged Win32 app, not a UWP one. It keeps full access to the
user's files, which is what lets it read a video from anywhere and write the
result beside it. Two consequences already hold in the code and should stay
that way:

- nothing is written into the install folder, which is read-only under MSIX;
- the scratch space is the system temp folder, resolved by `AppPaths`, never a
  path relative to the executable.

### The GPL and the Store can coexist, with conditions

FFmpeg is bundled under the GPLv3, so the packaged app is a GPL work. Shipping
it through the Store is allowed — other GPL applications are there — but the
obligations travel with it:

- the licence notice the app shows in About has to stay, and the full GPLv3
  text has to remain in the package;
- the corresponding source must be offered, which the GitHub repository does,
  and the Store listing should link it;
- the listing must not claim rights over the app that the GPL does not permit.

Do not add anything to a Store build that is not in the public source: a
private difference between the two channels would break the licence.
