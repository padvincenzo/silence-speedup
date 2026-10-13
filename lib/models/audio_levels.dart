// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:flutter/foundation.dart';

/// How loud a file is, measured rather than guessed.
///
/// The noise threshold has to sit above whatever hiss a recording has under
/// it and below the speech, and neither of those numbers is knowable by
/// looking at the file name. These two are what FFmpeg reports about the
/// audio, and they turn the threshold from a guess into a choice between two
/// known values.
@immutable
class AudioLevels {
  const AudioLevels({required this.noiseFloorDb, required this.rmsDb});

  /// The quiet under the sound: the level of the stretches with nothing in
  /// them, in decibels below full scale.
  final double noiseFloorDb;

  /// The overall level of the file, which for a recording of someone
  /// talking is roughly the level of the talking.
  final double rmsDb;

  /// True when the two are far enough apart to choose between.
  ///
  /// A recording whose noise is as loud as its speech cannot be split by a
  /// threshold at all, and offering a number for it would be a pretence.
  bool get isUsable => rmsDb - noiseFloorDb >= 6;

  /// A threshold halfway between the hiss and the speech.
  ///
  /// Halfway in decibels, which is halfway in the sense that matters: the
  /// scale is logarithmic, and the ear hears it that way too.
  int get suggestedThresholdDb => ((noiseFloorDb + rmsDb) / 2).round();
}
