// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:flutter/foundation.dart';

import '../l10n/gen/app_localizations.dart';
import '../l10n/locale_controller.dart';
import '../models/audio_levels.dart';
import '../models/media_entry.dart';
import '../services/app_paths.dart';
import '../services/ffmpeg_runner.dart';
import '../services/speedup_engine.dart';
import 'log_store.dart';
import 'preferences_store.dart';
import 'queue_store.dart';

/// Drives a run and exposes its progress to the UI.
///
/// Owns the [SpeedupEngine] and is the only thing that locks the queue, so the
/// UI never has to reason about who is allowed to change what.
class ProcessStore extends ChangeNotifier {
  ProcessStore({
    required FFmpegRunner runner,
    required QueueStore queue,
    required PreferencesStore preferences,
    required LogStore log,
    required LocaleController locales,
  }) : _queue = queue,
       _preferences = preferences,
       _log = log,
       _locales = locales {
    _engine = SpeedupEngine(
      runner: runner,
      log: log,
      locales: locales,
      onProgress: _handleProgress,
    );
  }

  final QueueStore _queue;
  final PreferencesStore _preferences;
  final LogStore _log;
  final LocaleController _locales;

  AppLocalizations get _s => _locales.strings;

  late final SpeedupEngine _engine;

  bool _running = false;
  bool _compactMode = false;
  RunProgress _progress = const RunProgress();
  MediaEntry? _lastPreview;

  bool get isRunning => _running;

  /// True while the window is shrunk to the slim progress strip.
  bool get compactMode => _compactMode;

  RunProgress get progress => _progress;

  bool _measuring = false;
  bool _measureFailed = false;

  bool get canStart => !_running && _queue.hasProcessableEntries;

  /// The entry whose preview finished most recently, so the UI can offer to
  /// play it. Cleared once read.
  MediaEntry? takeFinishedPreview() {
    final MediaEntry? entry = _lastPreview;
    _lastPreview = null;
    return entry;
  }

  /// Processes the whole queue.
  Future<void> start() =>
      _run(_queue.processableEntries, kind: RunKind.full);

  /// Measures the silences of one file without encoding anything, so detection
  /// settings can be judged before committing to a full run.
  Future<void> analyze(MediaEntry entry) =>
      _run(<MediaEntry>[entry], kind: RunKind.analyze);

  /// Produces a short sample of one file, run through the full pipeline.
  ///
  /// Only the sampled stretch is decoded, so this costs about what processing
  /// those seconds costs — no clip has to be cut out first.
  Future<void> preview(MediaEntry entry) async {
    await _run(<MediaEntry>[entry], kind: RunKind.preview);
    if (entry.outputPath != null) {
      _lastPreview = entry;
      notifyListeners();
    }
  }

  /// True while a file is being measured.
  bool get isMeasuring => _measuring;

  /// True when the last measurement asked for came back with nothing.
  ///
  /// Kept so the interface can say so: without it a measurement that found
  /// no levels simply put its own button back, which looks exactly like a
  /// press that never registered.
  bool get measureFailed => _measureFailed;

  /// Measures how loud [entry] is, so a noise threshold can be chosen
  /// against a reading rather than against nothing.
  ///
  /// Refused while a run is in progress: the encoder is busy, and a
  /// measurement is never urgent.
  Future<AudioLevels?> measure(MediaEntry entry) async {
    if (_running || _measuring) return null;
    _measuring = true;
    _measureFailed = false;
    notifyListeners();
    try {
      final AudioLevels? levels = await _engine.measureLevels(entry);
      _measureFailed = levels == null;
      return levels;
    } finally {
      _measuring = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    if (!_running) return;
    await _engine.stop();
    _engine.markInterrupted();
  }

  void setCompactMode(bool compact) {
    if (_compactMode == compact) return;
    _compactMode = compact;
    notifyListeners();
  }

  Future<void> _run(
    List<MediaEntry> entries, {
    required RunKind kind,
  }) async {
    if (_running) {
      _log.warning(_s.ffmpegAlreadyRunning);
      return;
    }
    if (entries.isEmpty) {
      _log.warning(_s.logQueueEmpty);
      return;
    }

    final String working = _preferences.workingDirectory;
    if (!await AppPaths.ensureDirectory(working)) {
      _log.error(_s.logOutputDirError(working, ''));
      return;
    }

    _running = true;
    _queue.setLocked(true);
    notifyListeners();

    try {
      await _engine.run(
        entries: entries,
        settings: _preferences.settings,
        outputDirectoryFor: _preferences.outputDirectoryFor,
        workingDirectory: working,
        kind: kind,
      );
    } finally {
      _running = false;
      _queue.setLocked(false);
      _compactMode = false;
      notifyListeners();
    }
  }

  void _handleProgress(RunProgress progress) {
    _progress = progress;
    notifyListeners();
  }
}
