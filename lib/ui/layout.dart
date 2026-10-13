// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

/// Measurements shared by parts of the interface that sit beside each other.
library;

/// Height of the strip directly under the app bar: the queue's toolbar, and
/// the encoding panel's title bar.
///
/// The same on both, because on a wide window they are side by side and the
/// rule under each one is at eye level with the other. They were built out
/// of their own padding and came out four pixels apart, which is exactly the
/// kind of difference that is invisible until it is seen and then cannot be
/// unseen. It matches the app bar above them.
const double kHeaderStripHeight = 64;
