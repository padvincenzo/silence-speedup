// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/media_entry.dart';
import '../format.dart';

/// Which stretch of a video the timeline is showing.
///
/// Separate from the widget, and pure: zooming and panning are arithmetic on
/// two numbers, and arithmetic is worth testing without a gesture in the way.
///
/// The view is a window rather than a scaled-up drawing. A tenth of a second
/// in an hour-long video needs about a thousandfold magnification to be worth
/// looking at, and a canvas a thousand times the width of the window is not a
/// thing to ask a compositor for.
class SilenceTimelineController extends ChangeNotifier {
  SilenceTimelineController({required this.sourceSeconds})
    : _span = math.max(sourceSeconds, minimumSpan);

  /// Length of the whole video.
  final double sourceSeconds;

  double _start = 0;
  double _span;

  /// Shortest stretch the view will narrow to.
  ///
  /// Two seconds across the width. The detector reports in steps of
  /// `kSilenceDurationStep`, a twentieth of a second, and at this span that
  /// step is still a fiftieth of the width — enough to see and to aim at.
  /// Closer than this the view stops being a timeline and becomes a
  /// microscope: one pause, and no idea what is around it.
  static const double minimumSpan = 2;

  /// How much of a revealed range's own length to show around it.
  static const double _revealContext = 6;

  double get start => _start;

  double get span => _span;

  double get end => _start + _span;

  /// True when the whole video is on screen.
  bool get isFit => _span >= _limit;

  double get _limit => math.max(sourceSeconds, minimumSpan);

  /// Puts the whole video back on screen.
  void fit() {
    _start = 0;
    _span = _limit;
    notifyListeners();
  }

  /// Multiplies the visible span by [factor], holding [anchor] still.
  ///
  /// [anchor] is a fraction of the width — 0.5 for the middle, or where the
  /// pointer is when zooming with the wheel, so the frame under the cursor
  /// stays under the cursor.
  void zoom(double factor, {double anchor = 0.5}) {
    final double focus = _start + _span * anchor;
    _span = (_span * factor).clamp(minimumSpan, _limit);
    _start = focus - _span * anchor;
    _clamp();
    notifyListeners();
  }

  /// Slides the window by [seconds].
  void panSeconds(double seconds) {
    _start += seconds;
    _clamp();
    notifyListeners();
  }

  /// Puts [seconds] in the middle of the view, as far as the ends allow.
  void centreOn(double seconds) {
    _start = seconds - _span / 2;
    _clamp();
    notifyListeners();
  }

  /// Frames one range, with some of the video around it for context.
  void reveal(SilenceRange range) {
    _span = math.min(
      math.max(range.duration * _revealContext, minimumSpan),
      _limit,
    );
    _start = range.start + range.duration / 2 - _span / 2;
    _clamp();
    notifyListeners();
  }

  void _clamp() {
    _span = _span.clamp(minimumSpan, _limit);
    _start = _start.clamp(0.0, math.max(0.0, sourceSeconds - _span));
  }
}

/// The source as a track, with the silences marked on it.
///
/// Zoomable, because the numbers that matter are small: a pause of a tenth of
/// a second decides whether a sentence keeps its breath, and at whole-video
/// scale it is less than a pixel wide. The wheel pans, Ctrl and the wheel
/// zoom where the pointer is, dragging pans, and the strip underneath always
/// shows the whole video with the visible part marked on it, so it is
/// possible to be zoomed in without being lost.
class SilenceTimeline extends StatelessWidget {
  const SilenceTimeline({
    super.key,
    required this.ranges,
    required this.controller,
  });

  final List<SilenceRange> ranges;
  final SilenceTimelineController controller;

  static const double _trackHeight = 56;
  static const double _rulerHeight = 22;
  static const double _minimapHeight = 18;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${_at(controller.start)}  →  ${_at(controller.end)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed:
                      controller.span <= SilenceTimelineController.minimumSpan
                      ? null
                      : () => controller.zoom(0.5),
                  icon: const Icon(Icons.zoom_in),
                  iconSize: 20,
                  visualDensity: VisualDensity.compact,
                  tooltip: strings.silencesZoomIn,
                ),
                IconButton(
                  onPressed: controller.isFit ? null : () => controller.zoom(2),
                  icon: const Icon(Icons.zoom_out),
                  iconSize: 20,
                  visualDensity: VisualDensity.compact,
                  tooltip: strings.silencesZoomOut,
                ),
                IconButton(
                  onPressed: controller.isFit ? null : controller.fit,
                  icon: const Icon(Icons.fit_screen_outlined),
                  iconSize: 20,
                  visualDensity: VisualDensity.compact,
                  tooltip: strings.silencesFit,
                ),
              ],
            ),
            const SizedBox(height: 4),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double width = constraints.maxWidth;

                return Listener(
                  onPointerSignal: (PointerSignalEvent event) {
                    if (event is! PointerScrollEvent) return;
                    _handleScroll(event, width);
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragUpdate: (DragUpdateDetails details) =>
                        controller.panSeconds(
                          -details.delta.dx * controller.span / width,
                        ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        SizedBox(
                          height: _trackHeight,
                          child: CustomPaint(
                            painter: _TrackPainter(
                              ranges: ranges,
                              start: controller.start,
                              span: controller.span,
                              track: scheme.surfaceContainerHighest,
                              silence: scheme.primary,
                              border: scheme.outlineVariant,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: _rulerHeight,
                          child: CustomPaint(
                            painter: _RulerPainter(
                              start: controller.start,
                              span: controller.span,
                              ink: scheme.onSurfaceVariant,
                              textStyle: theme.textTheme.labelSmall!.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            // The whole video, always, with the visible part marked: zoomed
            // in far enough to see a tenth of a second, everything else is
            // off screen, and this is what says where you are. It is also
            // the scrollbar: the marked part can be dragged, and a press
            // outside it jumps there.
            _Minimap(
              ranges: ranges,
              controller: controller,
              height: _minimapHeight,
            ),
          ],
        );
      },
    );
  }

  /// The wheel pans; with Ctrl held it zooms where the pointer is.
  void _handleScroll(PointerScrollEvent event, double width) {
    final bool zooming = HardwareKeyboard.instance.isControlPressed;
    if (zooming) {
      final double anchor = width <= 0
          ? 0.5
          : (event.localPosition.dx / width).clamp(0.0, 1.0);
      controller.zoom(event.scrollDelta.dy > 0 ? 1.25 : 0.8, anchor: anchor);
      return;
    }
    controller.panSeconds(event.scrollDelta.dy * controller.span / _panDivisor);
  }

  /// A wheel notch moves the view by a fixed share of what it shows.
  static const double _panDivisor = 500;

  static String _at(double seconds) =>
      formatDuration(Duration(milliseconds: (seconds * 1000).round()));
}

/// The whole video as a strip, and the scrollbar for the track above it.
class _Minimap extends StatefulWidget {
  const _Minimap({
    required this.ranges,
    required this.controller,
    required this.height,
  });

  final List<SilenceRange> ranges;
  final SilenceTimelineController controller;
  final double height;

  @override
  State<_Minimap> createState() => _MinimapState();
}

class _MinimapState extends State<_Minimap> {
  /// Where inside the window the drag started, in seconds from its middle.
  ///
  /// Grabbing the marked part moves it from wherever it was taken hold of,
  /// the way a scrollbar thumb does; pressing outside it centres on the
  /// press first, so a click jumps.
  double _grip = 0;

  double _seconds(double dx, double width) {
    if (width <= 0) return 0;
    return (dx / width).clamp(0.0, 1.0) * widget.controller.sourceSeconds;
  }

  void _press(double dx, double width) {
    final SilenceTimelineController view = widget.controller;
    final double at = _seconds(dx, width);
    final bool inside = at >= view.start && at <= view.end;
    _grip = inside ? at - (view.start + view.span / 2) : 0;
    if (!inside) view.centreOn(at);
  }

  void _move(double dx, double width) {
    widget.controller.centreOn(_seconds(dx, width) - _grip);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;

        return MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (TapDownDetails details) =>
                _press(details.localPosition.dx, width),
            onHorizontalDragStart: (DragStartDetails details) =>
                _press(details.localPosition.dx, width),
            onHorizontalDragUpdate: (DragUpdateDetails details) =>
                _move(details.localPosition.dx, width),
            child: SizedBox(
              height: widget.height,
              child: CustomPaint(
                painter: _MinimapPainter(
                  ranges: widget.ranges,
                  sourceSeconds: widget.controller.sourceSeconds,
                  start: widget.controller.start,
                  span: widget.controller.span,
                  track: scheme.surfaceContainerHighest,
                  silence: scheme.primary.withValues(alpha: 0.45),
                  window: scheme.primary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Maps a stretch of the source onto a width.
class _Window {
  const _Window(this.start, this.span, this.width);

  final double start;
  final double span;
  final double width;

  double x(double seconds) => (seconds - start) / span * width;
}

class _TrackPainter extends CustomPainter {
  const _TrackPainter({
    required this.ranges,
    required this.start,
    required this.span,
    required this.track,
    required this.silence,
    required this.border,
  });

  final List<SilenceRange> ranges;
  final double start;
  final double span;
  final Color track;
  final Color silence;
  final Color border;

  /// Narrowest a silence may be drawn.
  ///
  /// Only reached at whole-video scale; it is what makes a short pause
  /// visible enough to be worth zooming into.
  static const double _minimumBlock = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final RRect body = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(8),
    );
    canvas.drawRRect(body, Paint()..color = track);

    if (span > 0) {
      final _Window window = _Window(start, span, size.width);
      canvas.save();
      canvas.clipRRect(body);

      final Paint fill = Paint()..color = silence;
      for (final SilenceRange range in ranges) {
        final double left = window.x(range.start);
        final double right = window.x(range.end);
        if (right < 0 || left > size.width) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            left,
            0,
            math.max(right - left, _minimumBlock),
            size.height,
          ),
          fill,
        );
      }

      canvas.restore();
    }

    canvas.drawRRect(
      body,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      old.ranges != ranges ||
      old.start != start ||
      old.span != span ||
      old.silence != silence;
}

/// Tick marks, at whatever interval the current zoom can label.
class _RulerPainter extends CustomPainter {
  const _RulerPainter({
    required this.start,
    required this.span,
    required this.ink,
    required this.textStyle,
  });

  final double start;
  final double span;
  final Color ink;
  final TextStyle textStyle;

  /// Steps worth labelling, coarsest last.
  static const List<double> _steps = <double>[
    0.1,
    0.25,
    0.5,
    1,
    2,
    5,
    10,
    15,
    30,
    60,
    120,
    300,
    600,
    900,
    1800,
    3600,
  ];

  /// Room a label needs before the next one may start.
  static const double _labelRoom = 64;

  @override
  void paint(Canvas canvas, Size size) {
    if (span <= 0 || size.width <= 0) return;

    final double perSecond = size.width / span;
    final double step = _steps.firstWhere(
      (double candidate) => candidate * perSecond >= _labelRoom,
      orElse: () => _steps.last,
    );

    final Paint tick = Paint()
      ..color = ink
      ..strokeWidth = 1;

    double time = (start / step).ceilToDouble() * step;
    while (time <= start + span) {
      final double x = (time - start) * perSecond;
      canvas.drawLine(Offset(x, 0), Offset(x, 4), tick);

      final TextPainter label = TextPainter(
        text: TextSpan(text: _label(time, step), style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      // Nudged inwards at the edges so a label is never half off the strip.
      final double left = (x - label.width / 2).clamp(
        0.0,
        math.max(0.0, size.width - label.width),
      );
      label.paint(canvas, Offset(left, 6));

      time += step;
    }
  }

  /// Tenths only when the ticks are closer together than a second.
  static String _label(double seconds, double step) {
    final Duration position = Duration(milliseconds: (seconds * 1000).round());
    if (step >= 1) return formatDuration(position);
    final int tenths = (position.inMilliseconds.remainder(1000) / 100).round();
    return '${formatDuration(position)}.$tenths';
  }

  @override
  bool shouldRepaint(_RulerPainter old) =>
      old.start != start || old.span != span || old.ink != ink;
}

/// The whole video in one thin strip, with the visible part outlined.
class _MinimapPainter extends CustomPainter {
  const _MinimapPainter({
    required this.ranges,
    required this.sourceSeconds,
    required this.start,
    required this.span,
    required this.track,
    required this.silence,
    required this.window,
  });

  final List<SilenceRange> ranges;
  final double sourceSeconds;
  final double start;
  final double span;
  final Color track;
  final Color silence;
  final Color window;

  @override
  void paint(Canvas canvas, Size size) {
    if (sourceSeconds <= 0) return;

    final RRect body = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(4),
    );
    canvas.drawRRect(body, Paint()..color = track);

    canvas.save();
    canvas.clipRRect(body);

    final _Window whole = _Window(0, sourceSeconds, size.width);
    final Paint fill = Paint()..color = silence;
    for (final SilenceRange range in ranges) {
      final double left = whole.x(range.start);
      final double right = whole.x(range.end);
      canvas.drawRect(
        Rect.fromLTWH(left, 0, math.max(right - left, 1), size.height),
        fill,
      );
    }

    // What the track above is showing. At whole-video scale it covers
    // everything, which is the honest picture.
    final double from = whole.x(start);
    final double to = whole.x(start + span);
    canvas.drawRect(
      Rect.fromLTRB(from, 0, to, size.height),
      Paint()..color = window.withValues(alpha: 0.18),
    );
    canvas.drawRect(
      Rect.fromLTRB(from + 0.5, 0.5, to - 0.5, size.height - 0.5),
      Paint()
        ..color = window
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_MinimapPainter old) =>
      old.ranges != ranges ||
      old.sourceSeconds != sourceSeconds ||
      old.start != start ||
      old.span != span;
}
