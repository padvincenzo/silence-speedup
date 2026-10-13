// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';

/// Width of the package list when the document sits beside it.
const double kLicensesListWidth = 360;

/// Below this the two panes will not both fit, and the document becomes a
/// page of its own instead.
const double kLicensesTwoPaneBreakpoint = 840;

/// How wide a licence is allowed to get.
///
/// Long lines are hard to read: past roughly this width the eye loses the
/// start of the next line, and a licence is already an unrewarding read.
const double kLicensesDocumentWidth = 760;

/// The licences of everything the app is built out of.
///
/// Flutter ships a `LicensePage`, and this replaces it — for one reason:
/// that page scrolls its own heading, the app's name and version, off the
/// top and never brings it back. Everything else here is deliberately the
/// same shape: the packages down the left, the document beside them, and a
/// single page with a route per package when the window is too narrow to
/// hold both.
class LicensesPage extends StatefulWidget {
  const LicensesPage({super.key, required this.version});

  /// Shown beside the name, and the reason this page is worth a route of its
  /// own: a licence list is evidence, and evidence needs to say what it is
  /// evidence about.
  final String version;

  @override
  State<LicensesPage> createState() => _LicensesPageState();
}

class _LicensesPageState extends State<LicensesPage> {
  late final Future<List<_Package>> _packages = _load();

  /// Package chosen in the two-pane layout. Null until something is picked,
  /// which the first package stands in for.
  String? _selected;

  /// Collects the registry into one entry per package name.
  ///
  /// A single [LicenseEntry] can cover several packages, and one package can
  /// carry several licences, so neither side is a plain list.
  static Future<List<_Package>> _load() async {
    final Map<String, List<LicenseEntry>> byPackage =
        <String, List<LicenseEntry>>{};

    await for (final LicenseEntry entry in LicenseRegistry.licenses) {
      for (final String package in entry.packages) {
        byPackage.putIfAbsent(package, () => <LicenseEntry>[]).add(entry);
      }
    }

    final List<String> names = byPackage.keys.toList()
      ..sort((String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return names
        .map((String name) => _Package(name, byPackage[name]!))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);

    return Scaffold(
      body: FutureBuilder<List<_Package>>(
        future: _packages,
        builder: (BuildContext context, AsyncSnapshot<List<_Package>> snap) {
          final List<_Package>? packages = snap.data;

          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool twoPane =
                  constraints.maxWidth >= kLicensesTwoPaneBreakpoint;

              final Widget list = _PackageList(
                packages: packages,
                emptyMessage: strings.licensesEmpty,
                // Compact heading in the two-pane layout: the column is not
                // wide enough for the large one without eliding the version,
                // which is half the point of showing it.
                large: !twoPane,
                title: 'Silence SpeedUp ${widget.version}',
                subtitle: strings.menuThirdPartyLicenses,
                selected: twoPane ? _shown(packages)?.name : null,
                onSelected: (_Package package) {
                  if (twoPane) {
                    setState(() => _selected = package.name);
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) =>
                          _PackagePage(package: package),
                    ),
                  );
                },
              );

              if (!twoPane) return list;

              final _Package? shown = _shown(packages);
              return Row(
                children: <Widget>[
                  SizedBox(width: kLicensesListWidth, child: list),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: shown == null
                        ? const SizedBox.shrink()
                        : _DocumentPane(package: shown),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// The package the document pane is showing: the chosen one, or the first.
  _Package? _shown(List<_Package>? packages) {
    if (packages == null || packages.isEmpty) return null;
    return packages.firstWhere(
      (_Package package) => package.name == _selected,
      orElse: () => packages.first,
    );
  }
}

/// One package and the licences that apply to it.
@immutable
class _Package {
  const _Package(this.name, this.entries);

  final String name;
  final List<LicenseEntry> entries;
}

/// The heading and the packages under it.
class _PackageList extends StatelessWidget {
  const _PackageList({
    required this.packages,
    required this.emptyMessage,
    required this.large,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onSelected,
  });

  /// Null while the registry is still being read.
  final List<_Package>? packages;
  final String emptyMessage;
  final bool large;
  final String title;
  final String subtitle;
  final String? selected;
  final ValueChanged<_Package> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<_Package>? all = packages;

    return CustomScrollView(
      slivers: <Widget>[
        _Heading(title: title, subtitle: subtitle, large: large),
        if (all == null)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (all.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _Empty(message: emptyMessage),
          )
        else
          SliverList.separated(
            itemCount: all.length + 1,
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              if (index == all.length) {
                return _Count(label: strings.licensesPackages(all.length));
              }
              final _Package package = all[index];
              return ListTile(
                selected: package.name == selected,
                selectedTileColor: scheme.secondaryContainer,
                selectedColor: scheme.onSecondaryContainer,
                title: Text(package.name),
                subtitle: Text(strings.licensesCount(package.entries.length)),
                trailing: selected == null
                    ? const Icon(Icons.chevron_right)
                    : null,
                onTap: () => onSelected(package),
              );
            },
          ),
      ],
    );
  }
}

/// The document, framed and held to a readable width.
class _DocumentPane extends StatelessWidget {
  const _DocumentPane({required this.package});

  final _Package package;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return SingleChildScrollView(
      // Keyed on the package, so picking another one starts at the top of it
      // rather than wherever the last document had been left.
      key: ValueKey<String>(package.name),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: kLicensesDocumentWidth,
          ),
          child: Material(
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: scheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    package.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    strings.licensesCount(package.entries.length),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _LicenseText(package: package),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The heading that shrinks into the bar instead of scrolling away.
class _Heading extends StatelessWidget {
  const _Heading({
    required this.title,
    required this.subtitle,
    this.large = true,
  });

  final String title;
  final String subtitle;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // The subtitle rides in the title slot so that both shrink together; it
    // is dropped from the collapsed bar, where there is room for the name
    // and the version and nothing else.
    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );

    return large
        ? SliverAppBar.large(pinned: true, title: content)
        : SliverAppBar.medium(pinned: true, title: content);
  }
}

/// Reports how much the list holds, under the list.
class _Count extends StatelessWidget {
  const _Count({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
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

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
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

/// The document as its own page, for a window too narrow for two panes.
class _PackagePage extends StatelessWidget {
  const _PackagePage({required this.package});

  final _Package package;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          _Heading(
            title: package.name,
            subtitle: strings.licensesCount(package.entries.length),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: kLicensesDocumentWidth,
                  ),
                  child: _LicenseText(package: package),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Every licence of one package, laid out as the registry describes it.
class _LicenseText extends StatelessWidget {
  const _LicenseText({required this.package});

  final _Package package;

  /// Indent step the registry's paragraph levels are drawn with.
  static const double _indent = 12;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface,
      height: 1.45,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < package.entries.length; i++) ...<Widget>[
          // A rule between licences, never above the first one.
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(height: 1),
            ),
          for (final LicenseParagraph paragraph
              in package.entries[i].paragraphs)
            Padding(
              padding: EdgeInsets.only(
                left: paragraph.indent == LicenseParagraph.centeredIndent
                    ? 0
                    : paragraph.indent * _indent,
                top: 8,
              ),
              child: Text(
                paragraph.text,
                textAlign: paragraph.indent == LicenseParagraph.centeredIndent
                    ? TextAlign.center
                    : TextAlign.start,
                style: style,
              ),
            ),
        ],
      ],
    );
  }
}
