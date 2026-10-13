// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/log_store.dart';

/// The collapsible log pane, standing in for the Electron app's `Shell`.
///
/// Follows the tail as new lines arrive, unless the user has scrolled away to
/// read something further up.
class LogConsole extends StatefulWidget {
  const LogConsole({super.key, this.height = 180});

  final double height;

  @override
  State<LogConsole> createState() => _LogConsoleState();
}

class _LogConsoleState extends State<LogConsole> {
  final ScrollController _controller = ScrollController();
  int _lastLineCount = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _followTail() {
    if (!_controller.hasClients) return;
    // Only auto-scroll while the view is already near the bottom.
    final double distanceFromBottom =
        _controller.position.maxScrollExtent - _controller.offset;
    if (distanceFromBottom > 80) return;
    _controller.jumpTo(_controller.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    final LogStore log = context.watch<LogStore>();
    final List<LogLine> lines = log.lines;

    if (lines.length != _lastLineCount) {
      _lastLineCount = lines.length;
      WidgetsBinding.instance.addPostFrameCallback(
        (Duration _) => _followTail(),
      );
    }

    return Container(
      height: widget.height,
      width: double.infinity,
      color: const Color(0xFF14161A),
      child: Scrollbar(
        controller: _controller,
        child: ListView.builder(
          controller: _controller,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          itemCount: lines.length,
          itemBuilder: (BuildContext context, int index) =>
              _LogLineView(line: lines[index]),
        ),
      ),
    );
  }
}

class _LogLineView extends StatelessWidget {
  const _LogLineView({required this.line});

  final LogLine line;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (line.level) {
      LogLevel.info => const Color(0xFFD7DBE0),
      LogLevel.success => const Color(0xFF6EE7A0),
      LogLevel.warning => const Color(0xFFFFD166),
      LogLevel.error => const Color(0xFFFF8A8A),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: SelectableText.rich(
        TextSpan(
          children: <InlineSpan>[
            TextSpan(
              text: '[${_clock(line.timestamp)}] ',
              style: const TextStyle(color: Color(0xFF7A828C)),
            ),
            TextSpan(text: line.message, style: TextStyle(color: color)),
          ],
        ),
        style: const TextStyle(
          fontFamily: 'monospace',
          fontFamilyFallback: <String>['Consolas', 'Menlo', 'monospace'],
          fontSize: 12,
          height: 1.35,
        ),
      ),
    );
  }

  static String _clock(DateTime time) {
    final String hours = time.hour.toString().padLeft(2, '0');
    final String minutes = time.minute.toString().padLeft(2, '0');
    final String seconds = time.second.toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
