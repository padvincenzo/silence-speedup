// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../build_config.dart';

/// A release newer than the running build.
@immutable
class AvailableUpdate {
  const AvailableUpdate({
    required this.version,
    required this.title,
    required this.url,
  });

  /// Version as published, without a leading `v`.
  final String version;

  /// Release title from the feed.
  final String title;

  /// Page to send the user to.
  final String url;
}

/// Checks GitHub's releases feed for a newer version.
///
/// The Electron app compared versions by stripping the dots and parsing the
/// rest as one integer, which makes 2.1.0 look older than 2.0.10. This compares
/// the components properly instead.
class UpdateChecker {
  const UpdateChecker({
    this.feedUrl =
        'https://github.com/padvincenzo/silence-speedup/releases.atom',
    this.timeout = const Duration(seconds: 8),
    this.enabled = !kStoreBuild,
  });

  final String feedUrl;
  final Duration timeout;

  /// Whether to look at all. Off in a Store build, where the Store is what
  /// updates the app; the parameter exists so a test can say so too, without
  /// rebuilding with a different `--dart-define`.
  final bool enabled;

  static final RegExp _entryPattern = RegExp(
    r'<entry>(.*?)</entry>',
    dotAll: true,
  );
  static final RegExp _titlePattern = RegExp(r'<title>(.*?)</title>', dotAll: true);
  static final RegExp _linkPattern = RegExp(r'<link[^>]*href="([^"]+)"');
  static final RegExp _versionPattern = RegExp(r'(\d+(?:\.\d+)*)');

  /// Returns the newest release when it is ahead of [currentVersion], else
  /// null. Never throws: a failed check is not worth interrupting the app for,
  /// and it answers null without touching the network when [enabled] is false.
  Future<AvailableUpdate?> check(String currentVersion) async {
    if (!enabled) return null;

    try {
      final http.Response response = await http
          .get(Uri.parse(feedUrl))
          .timeout(timeout);
      if (response.statusCode != 200) return null;
      return readFeed(response.body, currentVersion);
    } catch (error) {
      debugPrint('Update check failed: $error');
      return null;
    }
  }

  /// The newest release in an Atom [feed] when it is ahead of
  /// [currentVersion], else null. Pure, so what the notice offers can be
  /// tested without a network.
  @visibleForTesting
  static AvailableUpdate? readFeed(String feed, String currentVersion) {
    final RegExpMatch? entry = _entryPattern.firstMatch(feed);
    if (entry == null) return null;

    final String block = entry.group(1)!;
    final String? title = _titlePattern.firstMatch(block)?.group(1)?.trim();
    if (title == null) return null;

    final String? latest = _versionPattern.firstMatch(title)?.group(1);
    if (latest == null) return null;

    if (compareVersions(latest, currentVersion) <= 0) return null;

    return AvailableUpdate(
      version: latest,
      title: title,
      url:
          _linkPattern.firstMatch(block)?.group(1) ??
          'https://github.com/padvincenzo/silence-speedup/releases',
    );
  }

  /// Compares dotted numeric versions, ignoring any pre-release suffix.
  /// Returns a negative number when [a] is older than [b].
  @visibleForTesting
  static int compareVersions(String a, String b) {
    final List<int> left = _components(a);
    final List<int> right = _components(b);
    for (int i = 0; i < left.length || i < right.length; i++) {
      final int l = i < left.length ? left[i] : 0;
      final int r = i < right.length ? right[i] : 0;
      if (l != r) return l - r;
    }
    return 0;
  }

  static List<int> _components(String version) {
    final String? digits = _versionPattern.firstMatch(version)?.group(1);
    if (digits == null) return const <int>[0];
    return digits
        .split('.')
        .map((String part) => int.tryParse(part) ?? 0)
        .toList();
  }
}
