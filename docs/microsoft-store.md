# Publishing to the Microsoft Store

The Windows version is sold in the Microsoft Store:
[Silence SpeedUp](https://apps.microsoft.com/detail/9NJ11SB1S9P5), Store ID
`9NJ11SB1S9P5`. It is a convenience, signed and updated by the Store, and a
way to support the project. It is not the only way to get the app. GitHub
releases keep the free, unsigned Inno Setup installer
([installer/build-installer.ps1](../installer/build-installer.ps1)), and the
source builds on its own.

The two channels are the same app, and they have to stay that way. A Store
build differs only by `STORE_BUILD=true`, which switches the update check off.
The update notice in the GitHub build points to the GitHub release, never to
the Store.

## Identity

These are the values Partner Center issued when the name was reserved. The
package has to match them exactly, or the submission is rejected:

| Field | Value |
| --- | --- |
| `Package/Identity/Name` | `VincenzoPadula.SilenceSpeedUp` |
| `Package/Identity/Publisher` | `CN=3C55752B-AFD7-44A0-AAF6-D30799DC1103` |
| `PublisherDisplayName` | `Vincenzo Padula` |
| Package Family Name | `VincenzoPadula.SilenceSpeedUp_w2h1dsagyjgq8` |
| Store ID | `9NJ11SB1S9P5` |

The first three are in `msix_config` in [pubspec.yaml](../pubspec.yaml). The
app does not use the Store ID: only the README links the Store page.

## Listing

The Store asks for a privacy policy URL. It is
<https://www.vincenzopadula.it/silence-speedup-privacy-policy/>, in Italian
and English. It describes what the code does, so it has to change whenever
that does: a new network call, or anything new written to disk.

## Building a package

```powershell
.\installer\build-msix.ps1
```

This makes a release build with `--dart-define=STORE_BUILD=true` and packs
the whole `build\windows\x64\runner\Release` folder with the `msix` tool,
which is a dev dependency. The result is
`dist\SilenceSpeedUp-<version>-store.msix`, for uploading in Partner Center.
The script packs its own build rather than letting the tool build again,
because that would drop the Store flag.

The package is not signed, because the Store signs what it publishes. It
cannot be installed by double-clicking, and it is not meant to be.

The first package, 3.0.0, has been checked: its manifest carries the
identity above, version `3.0.0.0`, x64, English and Italian, and
`runFullTrust` as its only capability. All the FFmpeg DLLs are inside,
`libx264` included, and so is the licence text.

## What is in place


| Piece | Where | Note |
| --- | --- | --- |
| Package configuration | `msix_config` in [pubspec.yaml](../pubspec.yaml) | Identity filled in, `store: true` |
| Store logo source | [installer/msix/logo.png](../installer/msix/logo.png) | 1024x1024, rendered from `assets/icons/icon.svg`; the tool derives every tile size from it |
| Version scheme | `version:` in pubspec | Plain `x.y.z`, patch raised every build, so the MSIX version is `x.y.z.0` — see below |
| Store build flag | [lib/build_config.dart](../lib/build_config.dart) | `--dart-define=STORE_BUILD=true` compiles out the update check |
| Executable metadata | [windows/runner/Runner.rc](../windows/runner/Runner.rc) | Real product name, company and copyright, which certification looks at |

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
