// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

/// The keys the app answers to.
///
/// Declared here rather than at the place they are bound, because a menu item
/// that advertises a shortcut and the binding that implements it have to agree
/// — and they are in different files. Change one of these and both follow.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Add one or more videos to the queue.
const SingleActivator kOpenFilesShortcut = SingleActivator(
  LogicalKeyboardKey.keyO,
  control: true,
);

/// Add every video in a folder.
const SingleActivator kOpenFolderShortcut = SingleActivator(
  LogicalKeyboardKey.keyO,
  control: true,
  shift: true,
);

/// Stop the run in progress.
const SingleActivator kStopShortcut = SingleActivator(
  LogicalKeyboardKey.keyD,
  control: true,
);

/// Show or hide the encoding settings.
const SingleActivator kEncodingSettingsShortcut = SingleActivator(
  LogicalKeyboardKey.comma,
  control: true,
);

/// Leave.
const SingleActivator kQuitShortcut = SingleActivator(
  LogicalKeyboardKey.keyQ,
  control: true,
);
