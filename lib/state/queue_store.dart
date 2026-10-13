// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../l10n/gen/app_localizations.dart';
import '../l10n/locale_controller.dart';
import '../models/media_entry.dart';
import '../services/ffmpeg_runner.dart';
import 'log_store.dart';

/// The list of files waiting to be processed.
///
/// Entries are keyed by file name, so the same name cannot be queued twice —
/// they would otherwise collide in the export folder.
class QueueStore extends ChangeNotifier {
  QueueStore({
    required FFmpegRunner runner,
    required LogStore log,
    required LocaleController locales,
  }) : _runner = runner,
       _log = log,
       _locales = locales;

  final FFmpegRunner _runner;
  final LogStore _log;
  final LocaleController _locales;

  AppLocalizations get _s => _locales.strings;

  final List<MediaEntry> _entries = <MediaEntry>[];
  bool _locked = false;

  List<MediaEntry> get entries => List<MediaEntry>.unmodifiable(_entries);

  bool get isEmpty => _entries.isEmpty;

  /// False while a run is in progress: the queue must not change underneath it.
  bool get canImport => !_locked;

  /// Entries the engine can actually work on.
  List<MediaEntry> get processableEntries =>
      _entries.where((MediaEntry entry) => entry.isProcessable).toList();

  bool get hasProcessableEntries =>
      _entries.any((MediaEntry entry) => entry.isProcessable);

  void setLocked(bool locked) {
    if (_locked == locked) return;
    _locked = locked;
    notifyListeners();
  }

  /// Adds every supported file in [paths], skipping duplicates and anything
  /// the app cannot open. Returns how many were actually added.
  Future<int> addFiles(Iterable<String> paths) async {
    if (_locked) return 0;

    final List<MediaEntry> added = <MediaEntry>[];
    for (final String path in paths) {
      if (!MediaEntry.isSupported(path)) continue;

      final String name = p.basename(path);
      if (_entries.any((MediaEntry entry) => entry.name == name)) {
        _log.warning(_s.logAlreadyExists(name));
        continue;
      }

      final MediaEntry entry = MediaEntry(path);
      _entries.add(entry);
      added.add(entry);
    }

    if (added.isEmpty) return 0;

    notifyListeners();
    _log.info(_s.logFilesAdded(added.length));

    // Probing is per-file and independent, so let them all run at once rather
    // than making the last row in a long import wait for the first.
    await Future.wait(added.map(_probe));
    return added.length;
  }

  /// Adds the supported files sitting directly inside [directory].
  Future<int> addDirectory(String directory) async {
    if (_locked) return 0;
    final Directory folder = Directory(directory);
    if (!await folder.exists()) return 0;

    final List<String> paths = <String>[];
    await for (final FileSystemEntity entity in folder.list()) {
      if (entity is File) paths.add(entity.path);
    }
    paths.sort();
    return addFiles(paths);
  }

  void remove(MediaEntry entry) {
    if (_locked) return;
    if (_entries.remove(entry)) {
      entry.dispose();
      notifyListeners();
    }
  }

  void clear() {
    if (_locked || _entries.isEmpty) return;
    for (final MediaEntry entry in _entries) {
      entry.dispose();
    }
    _entries.clear();
    notifyListeners();
  }

  Future<void> _probe(MediaEntry entry) async {
    final Duration? duration = await _runner.probeDuration(entry.path);
    entry.duration = duration;
    if (duration == null) {
      entry.setStatus(EntryStatus.failed);
      _log.warning(_s.ffmpegDurationError(entry.name));
    } else {
      entry.setStatus(EntryStatus.ready);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    for (final MediaEntry entry in _entries) {
      entry.dispose();
    }
    _entries.clear();
    super.dispose();
  }
}
