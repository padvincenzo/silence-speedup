// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/locale_controller.dart';
import '../models/media_entry.dart';
import '../models/processing_settings.dart';
import '../services/app_paths.dart';

/// Where a finished file is written.
enum OutputMode {
  /// Into the folder the source file came from. The default: it is where the
  /// result is wanted most of the time, and it needs no setting up.
  alongsideSource,

  /// Into one folder chosen once, whatever the source.
  fixedDirectory,
}

/// Everything that survives a restart: where files go, the look of the app,
/// the language, and the processing settings.
///
/// The Electron app reset its settings on every launch and kept a `config.json`
/// next to the executable; persisting them here means a batch run can be
/// repeated tomorrow without redialling every slider.
class PreferencesStore extends ChangeNotifier {
  PreferencesStore._(
    this._prefs,
    this._locales,
    this._fixedDirectory,
    this._workingDirectory,
  );

  static const String keyLocale = 'locale';
  static const String _keyOutputMode = 'outputMode';
  static const String _keyOutputDirectory = 'outputDirectory';
  static const String _keyWorkingDirectory = 'workingDirectory';
  static const String _keyThemeMode = 'themeMode';
  static const String _keyEncodingDocked = 'encodingPanelDocked';
  static const String _keyEncodingGroups = 'encodingGroupsOpen';
  static const String _keySettings = 'processingSettings';

  final SharedPreferences _prefs;
  final LocaleController _locales;

  OutputMode _outputMode = OutputMode.alongsideSource;
  String _fixedDirectory;
  String _workingDirectory;
  ThemeMode _themeMode = ThemeMode.system;
  bool _encodingPanelDocked = true;
  Set<String> _openEncodingGroups = Set<String>.of(_defaultOpenGroups);
  ProcessingSettings _settings = const ProcessingSettings();

  /// The language pinned in a previous session, or null to follow the system.
  ///
  /// Read before the [LocaleController] exists, since the controller needs it
  /// to resolve the starting language before the first frame.
  static Locale? storedLocale(SharedPreferences prefs) {
    final String? languageCode = prefs.getString(keyLocale);
    return languageCode == null ? null : Locale(languageCode);
  }

  /// Loads persisted state, falling back to sane defaults for anything absent
  /// or corrupt.
  static Future<PreferencesStore> load({
    required SharedPreferences prefs,
    required LocaleController locales,
  }) async {
    final PreferencesStore store = PreferencesStore._(
      prefs,
      locales,
      prefs.getString(_keyOutputDirectory) ??
          await AppPaths.defaultOutputDirectory(),
      prefs.getString(_keyWorkingDirectory) ??
          await AppPaths.defaultWorkingDirectory(),
    );

    store._outputMode = OutputMode.values.firstWhere(
      (OutputMode mode) => mode.name == prefs.getString(_keyOutputMode),
      orElse: () => OutputMode.alongsideSource,
    );
    store._themeMode = _decodeThemeMode(prefs.getString(_keyThemeMode));
    store._encodingPanelDocked = prefs.getBool(_keyEncodingDocked) ?? true;
    final List<String>? groups = prefs.getStringList(_keyEncodingGroups);
    store._openEncodingGroups = groups == null
        ? Set<String>.of(_defaultOpenGroups)
        : groups.toSet();

    final String? rawSettings = prefs.getString(_keySettings);
    if (rawSettings != null) {
      try {
        store._settings = ProcessingSettings.fromJson(
          jsonDecode(rawSettings) as Map<String, dynamic>,
        );
      } catch (error) {
        debugPrint('Discarding unreadable processing settings: $error');
      }
    }

    return store;
  }

  OutputMode get outputMode => _outputMode;

  bool get exportsAlongsideSource =>
      _outputMode == OutputMode.alongsideSource;

  /// The folder used when [OutputMode.fixedDirectory] is active. Remembered
  /// even while exporting alongside the source, so toggling back is free.
  String get fixedDirectory => _fixedDirectory;

  /// Holds the intermediate fragments during a run.
  String get workingDirectory => _workingDirectory;

  ThemeMode get themeMode => _themeMode;

  /// Whether the encoding settings stay docked beside the queue on a window
  /// wide enough for both. Remembered, because it is a choice about how
  /// someone works rather than a passing state.
  bool get encodingPanelDocked => _encodingPanelDocked;

  /// Which groups of the encoding settings are open.
  ///
  /// Everything is closed to begin with except the speeds, which are what the
  /// app is for; a closed group still states what was changed inside it, so a
  /// fully closed panel is short without being uninformative. Remembered for
  /// the same reason the docking is: it is how someone has arranged their
  /// work, not a passing state.
  Set<String> get openEncodingGroups =>
      Set<String>.unmodifiable(_openEncodingGroups);

  static const Set<String> _defaultOpenGroups = <String>{'speed'};

  /// The language actually in use, whoever chose it.
  Locale get activeLocale => _locales.activeLocale;

  /// The pinned language, or null while the system decides.
  Locale? get preferredLocale => _locales.preferredLocale;

  bool get followsSystemLocale => _locales.followsSystem;

  ProcessingSettings get settings => _settings;

  /// Where [entry] should be written.
  String outputDirectoryFor(MediaEntry entry) =>
      exportsAlongsideSource ? p.dirname(entry.path) : _fixedDirectory;

  Future<void> setOutputMode(OutputMode mode) async {
    if (mode == _outputMode) return;
    _outputMode = mode;
    notifyListeners();
    await _prefs.setString(_keyOutputMode, mode.name);
  }

  /// Sets the fixed export folder, switching to it as well.
  Future<void> setFixedDirectory(String directory) async {
    final String trimmed = directory.trim();
    if (trimmed.isEmpty) return;

    _fixedDirectory = trimmed;
    _outputMode = OutputMode.fixedDirectory;
    notifyListeners();
    await _prefs.setString(_keyOutputDirectory, trimmed);
    await _prefs.setString(_keyOutputMode, _outputMode.name);
  }

  Future<void> setWorkingDirectory(String directory) async {
    final String trimmed = directory.trim();
    if (trimmed.isEmpty || trimmed == _workingDirectory) return;
    _workingDirectory = trimmed;
    notifyListeners();
    await _prefs.setString(_keyWorkingDirectory, trimmed);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _prefs.setString(_keyThemeMode, mode.name);
  }

  Future<void> setEncodingPanelDocked(bool docked) async {
    if (docked == _encodingPanelDocked) return;
    _encodingPanelDocked = docked;
    notifyListeners();
    await _prefs.setBool(_keyEncodingDocked, docked);
  }

  Future<void> setEncodingGroupOpen(String group, bool open) async {
    final bool changed = open
        ? _openEncodingGroups.add(group)
        : _openEncodingGroups.remove(group);
    if (!changed) return;

    notifyListeners();
    await _prefs.setStringList(
      _keyEncodingGroups,
      _openEncodingGroups.toList(),
    );
  }

  /// Pins [locale], or pass null to follow the system again.
  Future<void> setPreferredLocale(Locale? locale) async {
    await _locales.setPreferred(locale);
    notifyListeners();

    final Locale? pinned = _locales.preferredLocale;
    if (pinned == null) {
      await _prefs.remove(keyLocale);
    } else {
      await _prefs.setString(keyLocale, pinned.languageCode);
    }
  }

  Future<void> updateSettings(ProcessingSettings settings) async {
    _settings = settings;
    notifyListeners();
    await _prefs.setString(_keySettings, jsonEncode(settings.toJson()));
  }

  /// Puts every processing setting back to its shipped default.
  Future<void> resetSettings() => updateSettings(const ProcessingSettings());

  /// Restores the platform default working directory.
  Future<void> resetWorkingDirectory() async {
    await setWorkingDirectory(await AppPaths.defaultWorkingDirectory());
  }

  static ThemeMode _decodeThemeMode(String? name) {
    return ThemeMode.values.firstWhere(
      (ThemeMode mode) => mode.name == name,
      orElse: () => ThemeMode.system,
    );
  }
}
