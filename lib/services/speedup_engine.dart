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
import '../models/audio_levels.dart';
import '../models/media_entry.dart';
import '../models/options.dart';
import '../models/processing_settings.dart';
import '../models/time_window.dart';
import '../state/log_store.dart';
import 'ffmpeg_runner.dart';
import 'fragment_planner.dart';

/// Where the run is, for the progress bar and the compact window.
@immutable
class RunProgress {
  const RunProgress({
    this.entryName = '',
    this.completed = 0,
    this.total = 0,
    this.position,
    this.speed,
    this.fraction,
  });

  /// File being worked on.
  final String entryName;

  /// Files finished so far, and how many there are in total.
  final int completed;
  final int total;

  /// Position reached inside the current file.
  final Duration? position;

  /// Encoding rate FFmpeg last reported.
  final double? speed;

  /// Progress through the current file, 0..1, or null when not yet known.
  final double? fraction;

  /// Progress across the whole queue, 0..1.
  double get queueFraction {
    if (total == 0) return 0;
    return ((completed + (fraction ?? 0)) / total).clamp(0.0, 1.0);
  }
}

/// What a single invocation of the engine is being asked to produce.
enum RunKind {
  /// The full file, written to the export folder.
  full,

  /// Detection only: measure the silences, encode nothing.
  analyze,

  /// A short sample, so the settings can be judged before a full run.
  preview,
}

/// Turns a queue of files into shortened copies of themselves.
///
/// The pipeline keeps the Electron app's shape: find the silences with
/// `silencedetect`, re-encode each stretch at its own rate, then stitch the
/// pieces back together with the concat demuxer. The arguments themselves come
/// from [FragmentPlanner]; what lives here is sequencing, progress and I/O.
class SpeedupEngine {
  SpeedupEngine({
    required FFmpegRunner runner,
    required LogStore log,
    required LocaleController locales,
    required void Function(RunProgress progress) onProgress,
  }) : _runner = runner,
       _log = log,
       _locales = locales,
       _onProgress = onProgress;

  final FFmpegRunner _runner;
  final LogStore _log;
  final LocaleController _locales;
  final void Function(RunProgress progress) _onProgress;

  /// Resolved on each use, so a language change mid-run is picked up by the
  /// lines logged after it.
  AppLocalizations get _s => _locales.strings;

  bool _stopRequested = false;
  MediaEntry? _current;

  bool get isStopping => _stopRequested;

  /// Asks the run to wind down and kills the FFmpeg process behind it.
  Future<void> stop() async {
    if (_stopRequested) return;
    _stopRequested = true;
    _log.error(_s.logStopping);
    await _runner.cancel();
  }

  /// Processes [entries] in order.
  ///
  /// [outputDirectoryFor] is asked per entry rather than given once, because
  /// the export folder can be set to follow each source file.
  ///
  /// [workingDirectory] holds the intermediate fragments. It is deliberately
  /// separate from the output: with the export folder following the source,
  /// there is no single output directory to put scratch space in.
  Future<void> run({
    required List<MediaEntry> entries,
    required ProcessingSettings settings,
    required String Function(MediaEntry entry) outputDirectoryFor,
    required String workingDirectory,
    RunKind kind = RunKind.full,
  }) async {
    _stopRequested = false;

    if (entries.isEmpty) {
      _log.warning(_s.logQueueEmpty);
      return;
    }

    final Directory workRoot = Directory(workingDirectory);
    try {
      await workRoot.create(recursive: true);
    } on FileSystemException catch (error) {
      _log.error(
        _s.logOutputDirError(
          workingDirectory,
          error.osError?.message ?? error.message,
        ),
      );
      return;
    }

    final int total = entries.length;
    for (final MediaEntry entry in entries) {
      entry.prepare();
    }

    for (int index = 0; index < total && !_stopRequested; index++) {
      final MediaEntry entry = entries[index];
      _current = entry;
      _emit(entry: entry, completed: index, total: total);

      await _processEntry(
        entry: entry,
        settings: settings,
        outputDirectory: outputDirectoryFor(entry),
        workRoot: workRoot,
        kind: kind,
        completed: index,
        total: total,
      );

      _current = null;
    }

    if (_stopRequested) {
      _emit(completed: 0, total: total);
      return;
    }

    _onProgress(RunProgress(completed: total, total: total, fraction: 0));
    _log.success(_s.logAllDone);
  }

  Future<void> _processEntry({
    required MediaEntry entry,
    required ProcessingSettings settings,
    required String outputDirectory,
    required Directory workRoot,
    required RunKind kind,
    required int completed,
    required int total,
  }) async {
    _log.info(_s.logStarted(entry.name));

    if (!await File(entry.path).exists()) {
      _fail(entry, _s.logFileMissing(entry.name));
      return;
    }

    entry.duration ??= await _runner.probeDuration(entry.path);
    if (!entry.isProcessable) {
      _fail(entry, _s.ffmpegDurationError(entry.name));
      return;
    }

    // A preview examines one stretch of the file; everything else the whole of
    // it. Either way the rest of the pipeline works in absolute source
    // seconds, so only these bounds change.
    final TimeWindow window = kind == RunKind.preview
        ? TimeWindow.preview(
            mediaSeconds: entry.seconds,
            seconds: settings.previewSeconds.toDouble(),
          )
        : TimeWindow(start: 0, end: entry.seconds);

    final bool analysed = await _detectSilences(
      entry: entry,
      settings: settings,
      window: window,
      isPartial: kind == RunKind.preview,
      completed: completed,
      total: total,
    );
    if (!analysed || _stopRequested) return;

    if (!entry.hasSilences) {
      _log.info(_s.logNoSilenceDetected);
      entry.setStatus(EntryStatus.completed);
      return;
    }

    if (kind == RunKind.analyze) {
      entry.setStatus(
        EntryStatus.completed,
        detail: _percentageLabel(entry, window),
      );
      return;
    }

    // Each entry gets its own scratch directory, so a leftover from a previous
    // version or an interrupted run cannot poison this concatenation.
    final Directory workDir = Directory(
      p.join(workRoot.path, 'run_${DateTime.now().microsecondsSinceEpoch}'),
    );
    await workDir.create(recursive: true);

    try {
      if (!await _prepareOutputDirectory(entry, outputDirectory)) return;

      final List<String> fragments = await _exportFragments(
        entry: entry,
        settings: settings,
        window: window,
        workDir: workDir,
        completed: completed,
        total: total,
      );
      if (fragments.isEmpty) {
        if (!_stopRequested && entry.status != EntryStatus.failed) {
          _fail(entry, _s.logSkipNoSilences);
        }
        return;
      }

      final String? output = await _concatenate(
        entry: entry,
        settings: settings,
        fragments: fragments,
        workDir: workDir,
        outputDirectory: outputDirectory,
        suffix: kind == RunKind.preview ? _s.filePreviewSuffix : '',
        completed: completed,
        total: total,
      );
      if (output == null) return;

      entry
        ..setOutputPath(output)
        ..setStatus(
          EntryStatus.completed,
          detail: _percentageLabel(entry, window),
        );
      _log.success(
        kind == RunKind.preview
            ? _s.logPreviewReady(p.basename(output))
            : _s.logCompleted(p.basename(output)),
      );
    } finally {
      // Kept on failure: the fragments are the only evidence of what went
      // wrong, and the log says where they are.
      if (entry.status == EntryStatus.completed) {
        await _deleteQuietly(workDir);
      } else if (await workDir.exists()) {
        _log.info(_s.logFragmentsKept(workDir.path));
      }
    }
  }

  /// Creates the export folder, reporting rather than throwing when it cannot.
  Future<bool> _prepareOutputDirectory(
    MediaEntry entry,
    String directory,
  ) async {
    try {
      await Directory(directory).create(recursive: true);
      return true;
    } on FileSystemException catch (error) {
      _fail(
        entry,
        _s.logOutputDirError(
          directory,
          error.osError?.message ?? error.message,
        ),
      );
      return false;
    }
  }

  /// Runs `silencedetect` over [window] and stores the ranges on the entry.
  ///
  /// Returns false when the entry could not be analysed.
  /// Measures how loud [entry] is, and remembers it on the entry.
  ///
  /// Not part of a run: nothing is produced, the queue is not touched, and
  /// it can be asked for while choosing a threshold rather than before
  /// starting. Returns null when the file has no audio to measure.
  Future<AudioLevels?> measureLevels(MediaEntry entry) async {
    _log.info(_s.logMeasuring(entry.name));

    // Two records of the same output, because either can come up short.
    // astats prints its whole summary as the filter closes, and those lines
    // can still be in flight when the session reports itself finished: the
    // streamed ones may stop early, and the collected ones have been known
    // to arrive empty. Whichever has the figures is the one that answers.
    final List<String> streamed = <String>[];
    final FFmpegResult result = await _runner.run(
      FragmentPlanner.levelArguments(input: entry.path),
      collectOutput: true,
      onLine: streamed.add,
    );

    final List<String> collected = result.output.isEmpty
        ? const <String>[]
        : result.output.split('\n');

    final AudioLevels? levels =
        FragmentPlanner.parseLevels(collected) ??
        FragmentPlanner.parseLevels(streamed);

    if (levels == null) {
      _log.warning(_s.logMeasureFailed(entry.name));
      // What it did say, since what it did not say is the whole problem.
      // Kept short: the last few lines are where a filter's summary and a
      // decoder's complaint both end up.
      _log.warning(
        _s.logMeasureDetail(
          result.exitCode ?? -1,
          collected.length,
          streamed.length,
        ),
      );
      for (final String line in _tailOf(
        collected.isEmpty ? streamed : collected,
      )) {
        _log.warning(line);
      }
      if (result.failure != null) {
        _log.warning(result.failure!);
      }
      entry.setLevels(null);
      return null;
    }

    _log.info(
      _s.settingsNoiseMeasured(
        entry.name,
        levels.noiseFloorDb.round(),
        levels.rmsDb.round(),
      ),
    );
    entry.setLevels(levels);
    return levels;
  }

  /// The last few non-empty lines, for a failure that has to be explained
  /// by someone who was not there.
  static List<String> _tailOf(List<String> lines) {
    final List<String> kept = lines
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList();
    return kept.length <= 8 ? kept : kept.sublist(kept.length - 8);
  }

  Future<bool> _detectSilences({
    required MediaEntry entry,
    required ProcessingSettings settings,
    required TimeWindow window,
    required bool isPartial,
    required int completed,
    required int total,
  }) async {
    entry.setStatus(EntryStatus.analyzing);

    final List<double> starts = <double>[];
    final List<double> ends = <double>[];

    final FFmpegResult result = await _runner.run(
      FragmentPlanner.detectArguments(
        input: entry.path,
        settings: settings,
        window: isPartial ? window : null,
      ),
      onLine: (String line) {
        for (final RegExpMatch match
            in FragmentPlanner.silencePattern.allMatches(line)) {
          final double? value = double.tryParse(match.group(2)!);
          if (value == null) continue;
          if (match.group(1) == 'start') {
            starts.add(value);
          } else {
            ends.add(value);
          }
        }
        _reportFfmpegLine(line);
      },
      onProgress: (FFmpegProgress progress) => _emit(
        entry: entry,
        completed: completed,
        total: total,
        position: Duration(
          milliseconds:
              (window.start * 1000).round() + progress.position.inMilliseconds,
        ),
        speed: progress.speed,
        fraction: progress.position.inMilliseconds / 1000.0 / window.duration,
      ),
    );

    if (result.cancelled || _stopRequested) return false;

    if (!result.succeeded) {
      _fail(entry, _s.logSkipNoSilences, detail: result.failure);
      return false;
    }

    final SilenceParseResult parsed = FragmentPlanner.buildRanges(
      starts: starts,
      ends: ends,
      margin: settings.silenceMargin,
      from: window.start,
      to: window.end,
    );

    if (parsed.boundariesMismatched) {
      _fail(entry, _s.logDataError);
      return false;
    }

    entry.setSilences(parsed.ranges, detectedWith: settings);

    if (entry.hasSilences) {
      _log.info(_s.logSilencePercentage(_silenceShare(entry, window) * 100));
    }
    return true;
  }

  /// Encodes every stretch of [window] at its own rate.
  ///
  /// Returns an empty list when the run was stopped or a fragment failed.
  Future<List<String>> _exportFragments({
    required MediaEntry entry,
    required ProcessingSettings settings,
    required TimeWindow window,
    required Directory workDir,
    required int completed,
    required int total,
  }) async {
    entry.setStatus(EntryStatus.exporting);

    final String extension = entry.outputExtensionFor(settings.outputFormat);
    final List<Fragment> plan = FragmentPlanner.plan(
      silences: entry.silences,
      from: window.start,
      to: window.end,
      dropSilence: settings.dropsSilence,
    );
    final List<String> written = <String>[];

    for (int i = 0; i < plan.length && !_stopRequested; i++) {
      final Fragment fragment = plan[i];
      final String output = p.join(
        workDir.path,
        'f_${i.toString().padLeft(6, '0')}.$extension',
      );
      final SpeedOption speed = fragment.speed(settings);

      final FFmpegResult result = await _runner.run(
        FragmentPlanner.exportArguments(
          input: entry.path,
          output: output,
          fragment: fragment,
          settings: settings,
        ),
        onLine: _reportFfmpegLine,
        onProgress: (FFmpegProgress progress) {
          // FFmpeg reports output time; scale it back up by the rate to land
          // on a position in the source file.
          final double sourceSeconds =
              fragment.start +
              progress.position.inMilliseconds / 1000.0 * speed.factor;
          _emit(
            entry: entry,
            completed: completed,
            total: total,
            position: Duration(milliseconds: (sourceSeconds * 1000).round()),
            speed: progress.speed,
            fraction: (sourceSeconds - window.start) / window.duration,
          );
        },
      );

      if (result.cancelled || _stopRequested) return const <String>[];

      if (!result.succeeded) {
        _log.warning(_s.logFragmentError(fragment.start, fragment.end));
        _fail(entry, _s.statusFailed, detail: result.failure);
        return const <String>[];
      }

      written.add(output);
    }

    return _stopRequested ? const <String>[] : written;
  }

  /// Stitches the fragments together without re-encoding.
  Future<String?> _concatenate({
    required MediaEntry entry,
    required ProcessingSettings settings,
    required List<String> fragments,
    required Directory workDir,
    required String outputDirectory,
    required String suffix,
    required int completed,
    required int total,
  }) async {
    entry.setStatus(EntryStatus.concatenating);

    final File listFile = File(p.join(workDir.path, 'list.txt'));
    await listFile.writeAsString(
      fragments.map(FragmentPlanner.concatListEntry).join('\n'),
      flush: true,
    );

    final String output = await _resolveOutputPath(
      directory: outputDirectory,
      fileName: entry.outputNameFor(settings.outputFormat, suffix: suffix),
      source: entry.path,
    );

    final FFmpegResult result = await _runner.run(
      FragmentPlanner.concatArguments(listPath: listFile.path, output: output),
      onLine: _reportFfmpegLine,
      onProgress: (FFmpegProgress progress) => _emit(
        entry: entry,
        completed: completed,
        total: total,
        position: progress.position,
        speed: progress.speed,
        fraction: 1,
      ),
    );

    if (result.cancelled || _stopRequested) return null;

    if (!result.succeeded) {
      _fail(entry, _s.logConcatenationError, detail: result.failure);
      return null;
    }

    return output;
  }

  /// Picks a free name rather than overwriting.
  ///
  /// The Electron app passed `-y` and clobbered whatever was already there.
  /// That matters more now that the export folder can follow the source file:
  /// keeping the original container would otherwise write over the input.
  Future<String> _resolveOutputPath({
    required String directory,
    required String fileName,
    required String source,
  }) async {
    final String stem = p.basenameWithoutExtension(fileName);
    final String extension = p.extension(fileName);

    String candidate = p.join(directory, fileName);
    int suffix = 1;
    while (await File(candidate).exists() || p.equals(candidate, source)) {
      candidate = p.join(directory, '$stem ($suffix)$extension');
      suffix++;
    }
    return candidate;
  }

  /// Share of [window] detected as silence.
  double _silenceShare(MediaEntry entry, TimeWindow window) {
    if (window.duration <= 0) return 0;
    return (entry.silenceSeconds / window.duration).clamp(0.0, 1.0);
  }

  void _emit({
    MediaEntry? entry,
    required int completed,
    required int total,
    Duration? position,
    double? speed,
    double? fraction,
  }) {
    _onProgress(
      RunProgress(
        entryName: entry?.name ?? '',
        completed: completed,
        total: total,
        position: position,
        speed: speed,
        fraction: fraction?.clamp(0.0, 1.0),
      ),
    );
  }

  /// Surfaces the FFmpeg chatter worth reading and drops the rest.
  void _reportFfmpegLine(String line) {
    if (_stopRequested) return;
    if (line.contains('silence_start') ||
        line.contains('silence_end') ||
        line.startsWith('[silencedetect') ||
        line.startsWith('frame=') ||
        line.startsWith('size=') ||
        line.contains('Press [q] to stop')) {
      return;
    }
    if (RegExp(
      r'error|failed|invalid|unable',
      caseSensitive: false,
    ).hasMatch(line)) {
      _log.warning(line);
    } else {
      debugPrint('ffmpeg: $line');
    }
  }

  void _fail(MediaEntry entry, String message, {String? detail}) {
    entry.setStatus(EntryStatus.failed, detail: message);
    _log.error(
      detail == null || detail.isEmpty ? message : '$message — $detail',
    );
  }

  String _percentageLabel(MediaEntry entry, TimeWindow window) =>
      _s.statusSilenceShare(_silenceShare(entry, window) * 100);

  Future<void> _deleteQuietly(Directory directory) async {
    try {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } on FileSystemException catch (error) {
      debugPrint('Could not remove ${directory.path}: $error');
    }
  }

  /// Marks the entry the user stopped on, so its row does not stay spinning.
  void markInterrupted() {
    _current?.setStatus(EntryStatus.interrupted);
    _current = null;
  }
}
