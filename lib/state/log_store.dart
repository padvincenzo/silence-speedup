// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:flutter/foundation.dart';

enum LogLevel { info, success, warning, error }

@immutable
class LogLine {
  const LogLine(this.timestamp, this.level, this.message);

  final DateTime timestamp;
  final LogLevel level;
  final String message;
}

/// The console behind the terminal button, replacing the Electron `Shell`.
///
/// Capped so a long batch of noisy FFmpeg warnings cannot grow without bound.
class LogStore extends ChangeNotifier {
  static const int maxLines = 2000;

  final List<LogLine> _lines = <LogLine>[];
  bool _visible = false;

  List<LogLine> get lines => List<LogLine>.unmodifiable(_lines);

  bool get visible => _visible;

  bool get isEmpty => _lines.isEmpty;

  void toggleVisible() {
    _visible = !_visible;
    notifyListeners();
  }

  void show() {
    if (_visible) return;
    _visible = true;
    notifyListeners();
  }

  void info(String message) => _add(LogLevel.info, message);

  void success(String message) => _add(LogLevel.success, message);

  void warning(String message) => _add(LogLevel.warning, message);

  void error(String message) => _add(LogLevel.error, message);

  void clear() {
    if (_lines.isEmpty) return;
    _lines.clear();
    notifyListeners();
  }

  void _add(LogLevel level, String message) {
    _lines.add(LogLine(DateTime.now(), level, message));
    if (_lines.length > maxLines) {
      _lines.removeRange(0, _lines.length - maxLines);
    }
    notifyListeners();
  }
}
