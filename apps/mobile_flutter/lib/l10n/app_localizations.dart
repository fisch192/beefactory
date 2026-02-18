import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'de.dart' as de_translations;
import 'it.dart' as it_translations;

/// Simple localization provider using SharedPreferences-backed language selection.
class AppLocalizations extends ChangeNotifier {
  static const String _prefKey = 'user_language';

  final SharedPreferences _prefs;
  late String _locale;
  late Map<String, String> _strings;

  AppLocalizations(this._prefs) {
    _locale = _prefs.getString(_prefKey) ?? 'de';
    _strings = _locale == 'it' ? it_translations.it : de_translations.de;
  }

  String get locale => _locale;

  /// Look up a translation by key. Returns the key itself if not found.
  String tr(String key) => _strings[key] ?? key;

  /// Switch locale and persist the choice.
  Future<void> setLocale(String locale) async {
    if (locale == _locale) return;
    _locale = locale;
    _strings = locale == 'it' ? it_translations.it : de_translations.de;
    await _prefs.setString(_prefKey, locale);
    notifyListeners();
  }

  /// Convenience: read from context without listening.
  static AppLocalizations of(BuildContext context) =>
      context.read<AppLocalizations>();

  /// Convenience: read from context with listening (rebuilds on change).
  static AppLocalizations watch(BuildContext context) =>
      context.watch<AppLocalizations>();
}
