/// Language Configuration for Dialogue Mode
/// 
/// Defines supported languages with their codes, names, and voice settings.
/// This configuration is shared between frontend and backend.
library;

/// Language model representing a supported language
class Language {
  final String code;
  final String name;
  final String nativeName;
  final String voice;
  final String flag;

  const Language({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.voice,
    required this.flag,
  });

  @override
  String toString() => 'Language($code: $name)';
}

/// List of supported languages for Dialogue Mode
/// 
/// These languages are supported by both:
/// - Gemini Live API for translation
/// - Text-to-Speech for voice output
const List<Language> supportedLanguages = [
  Language(
    code: 'en',
    name: 'English',
    nativeName: 'English',
    voice: 'en-US',
    flag: '🇺🇸',
  ),
  Language(
    code: 'ru',
    name: 'Russian',
    nativeName: 'Русский',
    voice: 'ru-RU',
    flag: '🇷🇺',
  ),
  Language(
    code: 'ka',
    name: 'Georgian',
    nativeName: 'ქართული',
    voice: 'ka-GE',
    flag: '🇬🇪',
  ),
  Language(
    code: 'es',
    name: 'Spanish',
    nativeName: 'Español',
    voice: 'es-ES',
    flag: '🇪🇸',
  ),
  Language(
    code: 'fr',
    name: 'French',
    nativeName: 'Français',
    voice: 'fr-FR',
    flag: '🇫🇷',
  ),
  Language(
    code: 'de',
    name: 'German',
    nativeName: 'Deutsch',
    voice: 'de-DE',
    flag: '🇩🇪',
  ),
  Language(
    code: 'it',
    name: 'Italian',
    nativeName: 'Italiano',
    voice: 'it-IT',
    flag: '🇮🇹',
  ),
  Language(
    code: 'pt',
    name: 'Portuguese',
    nativeName: 'Português',
    voice: 'pt-PT',
    flag: '🇵🇹',
  ),
  Language(
    code: 'zh',
    name: 'Chinese',
    nativeName: '中文',
    voice: 'zh-CN',
    flag: '🇨🇳',
  ),
  Language(
    code: 'ja',
    name: 'Japanese',
    nativeName: '日本語',
    voice: 'ja-JP',
    flag: '🇯🇵',
  ),
  Language(
    code: 'ko',
    name: 'Korean',
    nativeName: '한국어',
    voice: 'ko-KR',
    flag: '🇰🇷',
  ),
  Language(
    code: 'ar',
    name: 'Arabic',
    nativeName: 'العربية',
    voice: 'ar-SA',
    flag: '🇸🇦',
  ),
];

/// Get language by code
Language? getLanguageByCode(String code) {
  try {
    return supportedLanguages.firstWhere(
      (lang) => lang.code == code,
    );
  } catch (e) {
    return null;
  }
}

/// Check if language code is supported
bool isLanguageSupported(String code) {
  return supportedLanguages.any((lang) => lang.code == code);
}

/// Default L1 language (user's native language)
const String defaultL1Language = 'en';

/// Default L2 language (target language)
const String defaultL2Language = 'ru';

/// Language pair for Dialogue Mode
class LanguagePair {
  final Language l1;
  final Language l2;

  const LanguagePair({
    required this.l1,
    required this.l2,
  });

  /// Create from codes
  factory LanguagePair.fromCodes(String l1Code, String l2Code) {
    final l1 = getLanguageByCode(l1Code) ?? supportedLanguages.first;
    final l2 = getLanguageByCode(l2Code) ?? supportedLanguages[1];
    return LanguagePair(l1: l1, l2: l2);
  }

  /// Swap languages
  LanguagePair swap() => LanguagePair(l1: l2, l2: l1);

  @override
  String toString() => 'LanguagePair(${l1.code} ↔ ${l2.code})';
}
