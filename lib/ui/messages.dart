// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:flutter/material.dart';

/// The messenger of the body's own Scaffold.
///
/// Messages go there rather than to the window's Scaffold, because that one
/// has the Start button and anchors a floating snack bar above it. The body
/// has no button of its own, so a message can be laid against the bottom of
/// it — which is the line the button sits on.
final GlobalKey<ScaffoldMessengerState> bodyMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// The queue's Start button, so a message can be laid out beside it.
///
/// A global key rather than something handed down: there is one window, one
/// queue and one such button, and the alternative is threading a key through
/// every widget that might ever have something to say.
final GlobalKey startButtonKey = GlobalKey();

/// Room left between the message and the button.
const double _kGap = 12;

/// Distance a floating snack bar and the button both keep from the bottom.
///
/// [kFloatingActionButtonMargin] is what the button uses, and matching it is
/// what puts the two at the same height.
const double _kBottom = kFloatingActionButtonMargin;

/// Says something briefly, beside the Start button rather than under it.
///
/// A floating snack bar takes the full width and pushes the button up out of
/// its own corner. Neither is wanted: the button is the one thing on the
/// screen that must not move, and a sentence does not need the whole window.
/// So the message stops short of the button, and sits at its level.
void showAppMessage(BuildContext context, String message) {
  final ScaffoldMessengerState messenger =
      bodyMessengerKey.currentState ?? ScaffoldMessenger.of(context);
  messenger.showSnackBar(
    SnackBar(content: Text(message), margin: _marginBeside(context)),
  );
}

EdgeInsets _marginBeside(BuildContext context) {
  const EdgeInsets fallback = EdgeInsets.fromLTRB(16, 0, 16, _kBottom);

  // Absent on every screen that has no Start button, and during the frame
  // in which the queue is being built.
  final BuildContext? button = startButtonKey.currentContext;
  if (button == null) return fallback;

  final RenderObject? render = button.findRenderObject();
  if (render is! RenderBox || !render.hasSize) return fallback;

  final double windowWidth = MediaQuery.sizeOf(context).width;
  final double buttonLeft = render.localToGlobal(Offset.zero).dx;
  final double right = windowWidth - buttonLeft + _kGap;

  // A message needs somewhere to be. If the button leaves it less than this
  // much, it goes back to using the whole width and letting the button rise.
  const double leastUseful = 220;
  if (windowWidth - right - 16 < leastUseful) return fallback;

  return EdgeInsets.fromLTRB(16, 0, right, _kBottom);
}
