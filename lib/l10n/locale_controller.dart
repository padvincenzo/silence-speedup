// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'gen/app_localizations.dart';

/// Decides which language the app speaks.
///
/// By default it follows the operating system and falls back to English when
/// the system language is not one the app supports. A user can pin a language,
/// in which case the system stops deciding until they choose to follow it
/// again.
///
/// It also holds a [AppLocalizations] instance that is not tied to a
/// [BuildContext]: the processing engine and the stores log translated
/// messages from deep inside async work, where no context is available.
class LocaleController extends ChangeNotifier with WidgetsBindingObserver {
  LocaleController._(this._preferred, this._active, this._strings);

  /// Used when the system asks for a language the app does not have.
  static const Locale fallbackLocale = Locale('en');

  static List<Locale> get supportedLocales => AppLocalizations.supportedLocales;

  Locale? _preferred;
  Locale _active;
  AppLocalizations _strings;

  /// The language the user pinned, or null while the app follows the system.
  Locale? get preferredLocale => _preferred;

  /// The language actually in use.
  Locale get activeLocale => _active;

  /// True while the system decides.
  bool get followsSystem => _preferred == null;

  /// Translations for code that has no [BuildContext]. Widgets should use
  /// `AppLocalizations.of(context)` instead, so they rebuild on a change.
  AppLocalizations get strings => _strings;

  /// Resolves the starting language and loads its catalogue. Call once, before
  /// the first frame, so nothing renders in the wrong language.
  static Future<LocaleController> create({Locale? preferred}) async {
    final Locale active = resolve(preferred);
    final LocaleController controller = LocaleController._(
      isSupported(preferred) ? preferred : null,
      active,
      await AppLocalizations.delegate.load(active),
    );
    WidgetsBinding.instance.addObserver(controller);
    return controller;
  }

  /// Returns [preferred] when the app supports it, otherwise the first system
  /// language it does support, otherwise English.
  ///
  /// [systemLocales] defaults to what the platform reports; it is a parameter
  /// so the resolution order can be tested without a real platform.
  static Locale resolve(Locale? preferred, {List<Locale>? systemLocales}) {
    if (isSupported(preferred)) return _match(preferred!)!;

    // The platform list is the user's own ordered preference, so the first
    // entry the app supports is the best available answer.
    final List<Locale> candidates =
        systemLocales ?? PlatformDispatcher.instance.locales;
    for (final Locale candidate in candidates) {
      final Locale? matched = _match(candidate);
      if (matched != null) return matched;
    }
    return fallbackLocale;
  }

  static bool isSupported(Locale? locale) =>
      locale != null && _match(locale) != null;

  /// Matches on language only: `it_CH` should still get Italian.
  static Locale? _match(Locale locale) {
    for (final Locale supported in supportedLocales) {
      if (supported.languageCode == locale.languageCode) return supported;
    }
    return null;
  }

  /// Pins a language, or pass null to go back to following the system.
  Future<void> setPreferred(Locale? locale) async {
    _preferred = isSupported(locale) ? _match(locale!) : null;
    await _activate(resolve(_preferred));
  }

  /// The system language changed while the app was running.
  @override
  void didChangeLocales(List<Locale>? locales) {
    // A pinned language wins; the system no longer gets a say.
    if (_preferred != null) return;
    _activate(resolve(null));
  }

  Future<void> _activate(Locale locale) async {
    if (locale != _active) {
      _active = locale;
      _strings = await AppLocalizations.delegate.load(locale);
    }
    // Notified even when the language did not change, because switching
    // between "pinned to English" and "following a system that is English"
    // still has to update the menu.
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
