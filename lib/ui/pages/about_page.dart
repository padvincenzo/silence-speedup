// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../services/ffmpeg_runner.dart';
import '../../services/update_checker.dart';
import '../widgets/readable_width.dart';
import 'license_text_page.dart';
import 'licenses_page.dart';

/// Credits, the licence notice GPLv3 asks a program to display, and the
/// update check.
///
/// Laid out as an identity header followed by boxed sections. The information
/// here is read once and then never again, so it has to be scannable: each
/// block is a surface of its own with its own heading, and every line states
/// its colour explicitly rather than inheriting whatever a tile happens to
/// hand down.
class AboutPage extends StatelessWidget {
  const AboutPage({
    super.key,
    required this.version,
    required this.onOpenLink,
    this.update,
  });

  final String version;
  final void Function(String url) onOpenLink;
  final AvailableUpdate? update;

  static const String _repository =
      'https://github.com/padvincenzo/silence-speedup';
  static const String _issues = '$_repository/issues';
  static const String _donate = 'https://paypal.me/VincenzoPadula';

  /// A link as it is shown: the address without the part every address has.
  ///
  /// Derived from the link itself rather than written out beside it, which
  /// is how one of the three came to be showing its scheme and the other
  /// two not.
  static String _shown(String url) =>
      url.replaceFirst(RegExp('^https?://'), '');

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return ReadableWidth(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: <Widget>[
          _Identity(version: version, intro: strings.helpIntro),

          if (update != null)
            _UpdateBanner(
              title: strings.menuUpdate,
              detail: strings.updateAvailable(update!.version),
              action: update!.inStore
                  ? strings.updateOpenStore
                  : strings.updateDownload,
              onDownload: () => onOpenLink(update!.url),
            ),

          _Section(
            icon: Icons.favorite_outline,
            title: strings.helpCredits,
            children: <Widget>[
              _InfoRow(
                icon: Icons.memory,
                title: 'FFmpeg',
                badge: const _FFmpegVersion(),
                detail: strings.helpFfmpegNotice,
                link: 'https://ffmpeg.org/',
                linkHint: strings.aboutOpenInBrowser,
                onOpenLink: onOpenLink,
              ),
              _InfoRow(
                icon: Icons.flutter_dash,
                title: 'Flutter',
                detail: strings.aboutBuiltWith,
                link: 'https://flutter.dev/',
                linkHint: strings.aboutOpenInBrowser,
                onOpenLink: onOpenLink,
              ),
              _InfoRow(
                icon: Icons.brush_outlined,
                title: strings.helpIcons,
                detail: strings.helpIconsCredit,
                link: 'https://creazilla.com/',
                linkHint: strings.aboutOpenInBrowser,
                onOpenLink: onOpenLink,
              ),
              // Said plainly, and with the part a reader actually wants to
              // know: that "AI" here means how the code was written, not
              // something running inside the app or reading their files.
              _InfoRow(
                icon: Icons.auto_awesome_outlined,
                title: strings.aboutAiAssisted,
                detail: strings.aboutAiNotice,
                onOpenLink: onOpenLink,
              ),
            ],
          ),

          _Section(
            icon: Icons.gavel_outlined,
            title: strings.aboutLicenseSection,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      strings.aboutCopyright,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.helpGplNotice,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        OutlinedButton.icon(
                          // The app carries the text; asking a browser for
                          // it would be odd when every dependency's licence
                          // is readable here already.
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) =>
                                  const LicenseTextPage(),
                            ),
                          ),
                          icon: const Icon(Icons.article_outlined, size: 18),
                          label: Text(strings.helpReadLicense),
                        ),
                        OutlinedButton.icon(
                          // Our own page rather than showLicensePage: that one
                          // scrolls the app's name and version away and cannot
                          // be told not to.
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) =>
                                  LicensesPage(version: version),
                            ),
                          ),
                          icon: const Icon(Icons.list_alt, size: 18),
                          label: Text(strings.menuThirdPartyLicenses),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          _Section(
            icon: Icons.link,
            title: strings.menuReferences,
            children: <Widget>[
              _InfoRow(
                icon: Icons.code,
                title: strings.menuSourceCode,
                detail: _shown(_repository),
                link: _repository,
                linkHint: strings.aboutOpenInBrowser,
                onOpenLink: onOpenLink,
              ),
              _InfoRow(
                icon: Icons.bug_report_outlined,
                title: strings.menuIssue,
                detail: _shown(_issues),
                link: _issues,
                linkHint: strings.aboutOpenInBrowser,
                onOpenLink: onOpenLink,
              ),
              _InfoRow(
                icon: Icons.coffee_outlined,
                title: strings.menuDonate,
                detail: _shown(_donate),
                link: _donate,
                linkHint: strings.aboutOpenInBrowser,
                onOpenLink: onOpenLink,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The app's icon, name, version and one line about what it does.
class _Identity extends StatelessWidget {
  const _Identity({required this.version, required this.intro});

  final String version;
  final String intro;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Image.asset('assets/icons/icon.png', width: 64, height: 64),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Silence SpeedUp',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    // The version arrives from the package metadata a frame
                    // later than the page is first built.
                    if (version.isNotEmpty)
                      _Badge(
                        text: AppLocalizations.of(context).menuVersion(version),
                        prominent: true,
                      ),
                    const _Badge(text: 'GPLv3'),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  intro,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A heading and a boxed group of rows below it.
class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 16, 8),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 18, color: scheme.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        // A Material, so a row's ink is painted on the boxed surface itself
        // rather than hidden behind it, and clipped to the same corners.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Material(
            color: scheme.surfaceContainerLow,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: scheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}

/// One line of information, optionally opening a page in the browser.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onOpenLink,
    this.badge,
    this.link,
    this.linkHint,
  });

  final IconData icon;
  final String title;
  final String detail;
  final void Function(String url) onOpenLink;
  final Widget? badge;
  final String? link;
  final String? linkHint;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String? target = link;

    final Widget row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 22, color: scheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (badge != null) ...<Widget>[
                      const SizedBox(width: 8),
                      badge!,
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (target != null) ...<Widget>[
            const SizedBox(width: 12),
            Icon(Icons.open_in_new, size: 18, color: scheme.onSurfaceVariant),
          ],
        ],
      ),
    );

    if (target == null) return row;

    return Tooltip(
      message: linkHint ?? '',
      child: InkWell(onTap: () => onOpenLink(target), child: row),
    );
  }
}

/// A pill carrying a short value beside a title.
class _Badge extends StatelessWidget {
  const _Badge({required this.text, this.prominent = false});

  final String text;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: prominent
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: prominent ? scheme.onPrimaryContainer : scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// The update notice, shown only when the check found a newer release.
class _UpdateBanner extends StatelessWidget {
  const _UpdateBanner({
    required this.title,
    required this.detail,
    required this.action,
    required this.onDownload,
  });

  final String title;
  final String detail;
  final String action;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.system_update_alt, color: scheme.onTertiaryContainer),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onTertiaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: onDownload,
            icon: const Icon(Icons.download, size: 18),
            label: Text(action),
          ),
        ],
      ),
    );
  }
}

/// Reports the FFmpeg build actually embedded in this app.
class _FFmpegVersion extends StatefulWidget {
  const _FFmpegVersion();

  @override
  State<_FFmpegVersion> createState() => _FFmpegVersionState();
}

class _FFmpegVersionState extends State<_FFmpegVersion> {
  late final Future<String?> _version = FFmpegKitRunner.version();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _version,
      builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
        final String value = switch (snapshot.connectionState) {
          ConnectionState.done => snapshot.data ?? '—',
          _ => '…',
        };
        return _Badge(text: value);
      },
    );
  }
}
