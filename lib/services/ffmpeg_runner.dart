// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'dart:async';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/log.dart' as ffmpeg;
import 'package:ffmpeg_kit_flutter_new/media_information.dart';
import 'package:ffmpeg_kit_flutter_new/media_information_session.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';
import 'package:flutter/foundation.dart';

/// Live encoder telemetry for one FFmpeg invocation.
@immutable
class FFmpegProgress {
  const FFmpegProgress({required this.position, required this.speed});

  /// Position reached in the *output* stream.
  final Duration position;

  /// Encoding rate relative to real time, as FFmpeg reports it.
  final double speed;
}

/// Outcome of one FFmpeg invocation.
@immutable
class FFmpegResult {
  const FFmpegResult({
    required this.succeeded,
    required this.cancelled,
    this.exitCode,
    this.failure,
    this.output = '',
  });

  final bool succeeded;

  /// True when the run ended because the user asked it to stop.
  final bool cancelled;

  final int? exitCode;

  /// Platform-level failure reason, when FFmpeg never got to run.
  final String? failure;

  /// Everything FFmpeg logged, when the caller asked for it.
  ///
  /// Not the same as what reached `onLine`. Log messages are delivered
  /// asynchronously and a session can complete with some still in flight,
  /// so a filter that prints its findings at the end — `astats` does — can
  /// have the whole of its output arrive after the run is over. This is
  /// collected from the session itself, which waits for the stragglers.
  final String output;
}

/// The app's whole dependency on FFmpeg, expressed as three operations.
///
/// Keeping this an interface is what makes the Android port a matter of UI and
/// storage only: [FFmpegKitRunner] already works on every platform
/// `ffmpeg_kit_flutter_new` supports, and tests can substitute a fake without
/// touching a real encoder.
abstract class FFmpegRunner {
  /// Reads the duration of [path], or null when it cannot be determined.
  Future<Duration?> probeDuration(String path);

  /// Runs FFmpeg with [arguments], streaming log lines to [onLine] and encoder
  /// telemetry to [onProgress]. Completes when the process exits.
  ///
  /// Pass [collectOutput] when the answer is in what FFmpeg printed rather
  /// than in the file it wrote: the result then carries the session's whole
  /// log, waited for. It is off by default because a real encode logs a line
  /// per second and nothing reads them afterwards.
  Future<FFmpegResult> run(
    List<String> arguments, {
    void Function(String line)? onLine,
    void Function(FFmpegProgress progress)? onProgress,
    bool collectOutput = false,
  });

  /// Cancels whatever is running. Safe to call when nothing is.
  Future<void> cancel();
}

/// [FFmpegRunner] backed by `ffmpeg_kit_flutter_new`.
///
/// FFmpeg ships inside the plugin, so there is no binary to bundle by hand and
/// nothing for the user to configure — the Electron app's "set the path to
/// ffmpeg" preference has no equivalent here, by design.
class FFmpegKitRunner implements FFmpegRunner {
  /// Buffers partial log output so a regex never sees half a line.
  final StringBuffer _pending = StringBuffer();

  int? _sessionId;

  @override
  Future<Duration?> probeDuration(String path) async {
    try {
      final MediaInformationSession session =
          await FFprobeKit.getMediaInformation(path);
      final MediaInformation? information = session.getMediaInformation();
      final String? raw = information?.getDuration();
      if (raw == null) return null;
      final double? seconds = double.tryParse(raw);
      if (seconds == null || seconds <= 0) return null;
      return Duration(microseconds: (seconds * 1000000).round());
    } catch (error) {
      debugPrint('probeDuration failed for $path: $error');
      return null;
    }
  }

  @override
  Future<FFmpegResult> run(
    List<String> arguments, {
    void Function(String line)? onLine,
    void Function(FFmpegProgress progress)? onProgress,
    bool collectOutput = false,
  }) async {
    final Completer<FFmpegResult> completer = Completer<FFmpegResult>();
    _pending.clear();

    try {
      final FFmpegSession session = await FFmpegKit.executeWithArgumentsAsync(
        arguments,
        (FFmpegSession session) async {
          _flush(onLine);
          _sessionId = null;
          if (completer.isCompleted) return;
          final ReturnCode? code = await session.getReturnCode();
          // Asked from the session rather than accumulated from the
          // callback: the callback can still be owed the last messages when
          // the session completes, and this waits for them.
          final String output = collectOutput
              ? (await session.getAllLogsAsString() ?? '')
              : '';
          completer.complete(
            FFmpegResult(
              succeeded: ReturnCode.isSuccess(code),
              cancelled: ReturnCode.isCancel(code),
              exitCode: code?.getValue(),
              failure: await session.getFailStackTrace(),
              output: output,
            ),
          );
        },
        onLine == null ? null : (ffmpeg.Log log) => _consume(log, onLine),
        onProgress == null
            ? null
            : (Statistics statistics) => onProgress(
                FFmpegProgress(
                  position: Duration(milliseconds: statistics.getTime()),
                  speed: statistics.getSpeed(),
                ),
              ),
      );
      _sessionId = session.getSessionId();
    } catch (error) {
      _sessionId = null;
      return FFmpegResult(
        succeeded: false,
        cancelled: false,
        failure: error.toString(),
      );
    }

    return completer.future;
  }

  @override
  Future<void> cancel() async {
    final int? sessionId = _sessionId;
    try {
      if (sessionId == null) {
        await FFmpegKit.cancel();
      } else {
        await FFmpegKit.cancel(sessionId);
      }
    } catch (error) {
      debugPrint('FFmpeg cancel failed: $error');
    }
  }

  /// FFmpeg's log callback fires per `av_log` write, which is not reliably one
  /// line, so complete lines are cut out here and the remainder held back.
  void _consume(ffmpeg.Log log, void Function(String line) onLine) {
    _pending.write(log.getMessage());
    final String buffered = _pending.toString();
    if (!buffered.contains('\n')) return;

    final List<String> parts = buffered.split('\n');
    _pending
      ..clear()
      ..write(parts.removeLast());
    for (final String line in parts) {
      final String trimmed = line.trim();
      if (trimmed.isNotEmpty) onLine(trimmed);
    }
  }

  void _flush(void Function(String line)? onLine) {
    final String remainder = _pending.toString().trim();
    _pending.clear();
    if (remainder.isNotEmpty) onLine?.call(remainder);
  }

  /// Version banner of the bundled FFmpeg, for the About dialog.
  static Future<String?> version() async {
    try {
      return await FFmpegKitConfig.getFFmpegVersion();
    } catch (error) {
      debugPrint('getFFmpegVersion failed: $error');
      return null;
    }
  }
}
