// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

/// Compile-time flags that tell one distribution of the app from another.
///
/// The same source builds the release published on GitHub and the MSIX
/// package published on the Microsoft Store. The two are not allowed to
/// behave identically — see [kStoreBuild] — and the difference has to be
/// decided at compile time, because an app cannot ask at runtime how it was
/// installed with any confidence.
library;

/// True in a build destined for the Microsoft Store.
///
/// Set it with `--dart-define=STORE_BUILD=true`; every other build leaves it
/// false. What it turns off is the update check: a Store app must not look
/// for its own updates or send someone to download an executable elsewhere,
/// because the Store is the update mechanism. Everything else — the source
/// link, the licence notice GPLv3 requires, the issue tracker — stays, since
/// those are pages, not payloads.
const bool kStoreBuild = bool.fromEnvironment('STORE_BUILD');

/// The app's page in the Microsoft Store.
///
/// From 3.0.1 on, Windows releases are published there and not attached to
/// GitHub, so this is where a Windows build that came from GitHub sends
/// someone when a newer version exists. It is a page, not a payload, and
/// the Store does the installing.
const String kStorePageUrl = 'https://apps.microsoft.com/detail/9NJ11SB1S9P5';
