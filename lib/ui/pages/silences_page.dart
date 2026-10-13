// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../l10n/labels.dart';
import '../../models/media_entry.dart';
import '../../models/processing_settings.dart';
import '../../services/fragment_planner.dart';
import '../../state/preferences_store.dart';
import '../../state/process_store.dart';
import '../format.dart';
import '../widgets/silence_timeline.dart';

/// What the detection found in one video, drawn.
///
/// A percentage in the queue says how much of a file is silence; it does not
/// say whether the silences are three long pauses or four hundred gaps
/// between words, and those want different settings. This shows where they
/// fall, what the run will do to each one, and how long the result will be.
///
/// A route rather than a second window: Flutter desktop has one window — the
/// compact strip shrinks this one rather than opening another — and a
/// timeline wants the full width anyway.
class SilencesPage extends StatefulWidget {
  const SilencesPage({super.key, required this.entry});

  final MediaEntry entry;

  @override
  State<SilencesPage> createState() => _SilencesPageState();
}

class _SilencesPageState extends State<SilencesPage> {
  /// Held by the page rather than the timeline, so a row of the list can
  /// point the view at its own range.
  late final SilenceTimelineController _view = SilenceTimelineController(
    sourceSeconds: widget.entry.seconds,
  );

  /// Whether the list has been scrolled off its top.
  ///
  /// What the rows slide under is the block above them, not the app bar, so
  /// that block is what lifts. An AppBar reacts to any scroll notification
  /// that reaches it, whether or not the content is passing beneath it —
  /// which is why this page tells it not to.
  bool _listScrolled = false;

  void _handleListScroll(ScrollNotification notification) {
    if (notification.depth != 0) return;
    final bool scrolled = notification.metrics.extentBefore > 0;
    if (scrolled == _listScrolled) return;
    setState(() => _listScrolled = scrolled);
  }

  @override
  void dispose() {
    _view.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The entry is listened to directly rather than through a provider: this
    // is a route of its own, so there is no queue row above it to inherit
    // from, and a re-detection started from here has to redraw the page.
    return ListenableBuilder(
      listenable: widget.entry,
      builder: (BuildContext context, Widget? child) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final MediaEntry entry = widget.entry;
    final AppLocalizations strings = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    final ProcessingSettings settings = context
        .watch<PreferencesStore>()
        .settings;

    final List<SilenceRange> ranges = entry.silences;
    final ProcessingSettings? detectedWith = entry.detectedWith;
    final bool stale =
        detectedWith != null && !detectedWith.detectsLike(settings);

    return Scaffold(
      appBar: AppBar(
        // Nothing scrolls under it: the list is below a fixed block, and it
        // is that block's business to show the seam.
        notificationPredicate: (ScrollNotification _) => false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              strings.silencesTitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      // The timeline never scrolls away: it is what the list is about, and
      // pointing a row at it is pointless if the pointing goes off screen.
      // Only the list moves.
      body: ranges.isEmpty
          ? _Empty(message: strings.silencesEmpty)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // A shadow at rest would be a shadow over nothing, so the
                // seam is a line until the rows start passing under it. The
                // elevation is animated by Material itself, which is what
                // makes it arrive as a fade rather than a jump.
                Material(
                  color: theme.colorScheme.surface,
                  surfaceTintColor: Colors.transparent,
                  shadowColor: theme.colorScheme.shadow,
                  elevation: _listScrolled ? 3 : 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (stale) _StaleNotice(entry: entry),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: SilenceTimeline(
                          ranges: ranges,
                          controller: _view,
                        ),
                      ),
                      _Figures(entry: entry, settings: settings),
                      const SizedBox(height: 12),
                      _ListHeader(entry: entry),
                      if (!_listScrolled) const Divider(height: 1),
                    ],
                  ),
                ),
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification notification) {
                      _handleListScroll(notification);
                      return false;
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 24),
                      itemCount: ranges.length,
                      itemBuilder: (BuildContext context, int index) =>
                          _RangeTile(
                            index: index,
                            range: ranges[index],
                            settings: settings,
                            onReveal: () => _view.reveal(ranges[index]),
                          ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// The numbers worth knowing before starting a run.
class _Figures extends StatelessWidget {
  const _Figures({required this.entry, required this.settings});

  final MediaEntry entry;
  final ProcessingSettings settings;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);

    final double output = FragmentPlanner.outputSeconds(
      silences: entry.silences,
      sourceSeconds: entry.seconds,
      settings: settings,
    );
    final double saved = (entry.seconds - output).clamp(0, entry.seconds);
    final double? share = entry.silenceRatio;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        children: <Widget>[
          _Figure(
            label: strings.silencesTotal,
            value: _duration(entry.silenceSeconds),
          ),
          if (share != null)
            _Figure(
              label: strings.silencesShare,
              value: strings.silencesPercent(share * 100),
            ),
          _Figure(label: strings.silencesOutput, value: _duration(output)),
          _Figure(label: strings.silencesSaved, value: _duration(saved)),
        ],
      ),
    );
  }

  static String _duration(double seconds) =>
      formatDuration(Duration(milliseconds: (seconds * 1000).round()));
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Says how many ranges the list below holds.
///
/// Not a group that opens and closes any more: the list is the substance of
/// the page, and a page whose substance starts folded away asks to be
/// unfolded every single time.
class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.entry});

  final MediaEntry entry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: <Widget>[
          Icon(Icons.list_alt, size: 18, color: scheme.primary),
          const SizedBox(width: 12),
          // No total here: it is one of the figures three lines above, and
          // saying it twice on one screen only invites them to disagree.
          Expanded(
            child: Text(
              strings.silencesRanges(entry.silences.length),
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One detected silence.
///
/// A widget of its own because this is where per-range editing will go —
/// nudging a boundary, or excluding one range from the run. `setSilences`
/// already accepts a replacement list, so that is a matter of building the
/// controls, not of changing the model.
class _RangeTile extends StatelessWidget {
  const _RangeTile({
    required this.index,
    required this.range,
    required this.settings,
    required this.onReveal,
  });

  final int index;
  final SilenceRange range;
  final ProcessingSettings settings;

  /// Frames this range on the timeline above. A tenth of a second is under a
  /// pixel wide at whole-video scale, so a row is often the only way to find
  /// the one being read about.
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return InkWell(
      onTap: onReveal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: <Widget>[
            Tooltip(
              message: strings.silencesReveal,
              child: const Icon(Icons.center_focus_weak, size: 16),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 32,
              child: Text(
                '${index + 1}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Text(
                '${_at(range.start)}  →  ${_at(range.end)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ),
            Text(
              strings.settingsSecondsValue(range.duration),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 12),
            // What the run will do to this one, in the same words the settings
            // use for it.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                speedText(settings.silenceSpeed, strings),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _at(double seconds) =>
      formatDuration(Duration(milliseconds: (seconds * 1000).round()));
}

/// Says the drawing no longer matches the settings, and offers to fix it.
class _StaleNotice extends StatelessWidget {
  const _StaleNotice({required this.entry});

  final MediaEntry entry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool running = context.watch<ProcessStore>().isRunning;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.update, size: 18, color: scheme.onTertiaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              strings.silencesStale,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onTertiaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: running
                ? null
                : () => context.read<ProcessStore>().analyze(entry),
            child: Text(strings.silencesRedetect),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
