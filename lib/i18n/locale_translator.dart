import 'dart:ui';

/// LocaleTranslator is used to translate the locale name to the locale code and vice versa
class LocaleTranslator {
  static final Map<String, String> _translation = {
    "ca": "Català",
    "es": "Español",
    "en": "English",
  };

  /// Returns the locale name from the locale code
  static String getLocaleName(Locale locale) {
    return _translation[locale.languageCode] ?? locale.languageCode;
  }

  /// Returns the locale code from the locale name
  static Locale getLocale(String localeName) {
    String code = _translation.keys.firstWhere(
        (key) => _translation[key] == localeName,
        orElse: () => "en");
    return Locale(code);
  }
}
