// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'dart:io';

import 'package:flutter/foundation.dart';

/// True where `window_manager`, drag-and-drop and a native menu bar apply.
///
/// Android is a supported target for the FFmpeg layer already; the desktop
/// chrome is what the mobile UI will have to replace.
final bool isDesktop =
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
