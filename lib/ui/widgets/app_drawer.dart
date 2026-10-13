// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../services/update_checker.dart';

/// The three places the app can be.
enum AppDestination { queue, settings, about }

/// Navigation and the app-level actions.
///
/// This replaces the Electron build's File / Media / View / Help menu bar. A
/// menu bar is a desktop-toolkit idiom that Material has no equivalent for, and
/// most of what was in it was not navigation at all: the queue actions belong
/// on the queue, and the settings belong on a settings page. What is left here
/// is where to go, and the handful of things that are about the application
/// rather than about the videos.
class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.destination,
    required this.onSelect,
    required this.onOpenLink,
    required this.onQuit,
    required this.version,
    this.update,
  });

  final AppDestination destination;
  final ValueChanged<AppDestination> onSelect;
  final void Function(String url) onOpenLink;
  final VoidCallback onQuit;
  final String version;
  final AvailableUpdate? update;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return NavigationDrawer(
      selectedIndex: destination.index,
      onDestinationSelected: (int index) {
        onSelect(AppDestination.values[index]);
        Navigator.of(context).maybePop();
      },
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 16, 16),
          child: Row(
            children: <Widget>[
              Image.asset('assets/icons/icon.png', width: 36, height: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Silence SpeedUp',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      strings.menuVersion(version),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        NavigationDrawerDestination(
          icon: const Icon(Icons.queue_music_outlined),
          selectedIcon: const Icon(Icons.queue_music),
          label: Text(strings.navQueue),
        ),
        // Not a tune icon: that one now belongs to the encoding panel, and
        // this page is the application's own settings.
        NavigationDrawerDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: Text(strings.navSettings),
        ),
        NavigationDrawerDestination(
          icon: Badge(
            isLabelVisible: update != null,
            child: const Icon(Icons.info_outline),
          ),
          selectedIcon: Badge(
            isLabelVisible: update != null,
            child: const Icon(Icons.info),
          ),
          label: Text(strings.navAbout),
        ),

        const Padding(
          padding: EdgeInsets.fromLTRB(28, 16, 28, 10),
          child: Divider(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
          child: Text(
            strings.navSection,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),

        _DrawerAction(
          icon: Icons.code,
          label: strings.menuSourceCode,
          leaves: true,
          onTap: () => onOpenLink(
            'https://github.com/padvincenzo/silence-speedup',
          ),
        ),
        _DrawerAction(
          icon: Icons.bug_report_outlined,
          label: strings.menuIssue,
          leaves: true,
          onTap: () => onOpenLink(
            'https://github.com/padvincenzo/silence-speedup/issues',
          ),
        ),
        _DrawerAction(
          icon: Icons.coffee_outlined,
          label: strings.menuDonate,
          leaves: true,
          onTap: () => onOpenLink('https://paypal.me/VincenzoPadula'),
        ),
        _DrawerAction(
          icon: Icons.power_settings_new,
          label: strings.menuQuit,
          onTap: onQuit,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// A drawer row that does something rather than going somewhere.
///
/// Deliberately not a [NavigationDrawerDestination]: those are indexed as
/// destinations, and selecting one would light it up as though the app had
/// navigated there.
class _DrawerAction extends StatelessWidget {
  const _DrawerAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.leaves = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// True for a row that opens a browser. Marked on the trailing edge, the
  /// same way the about page marks its links: a row that leaves the app
  /// should say so before it is pressed.
  final bool leaves;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          label,
          style: theme.textTheme.labelLarge,
        ),
        trailing: leaves
            ? Icon(
                Icons.open_in_new,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              )
            : null,
        shape: const StadiumBorder(),
        dense: true,
        onTap: onTap,
      ),
    );
  }
}
