class LanguageConstants {
  // Single source of truth for all language mappings
  static const Map<String, String> supportedLanguages = {
    'en': '🇬🇧 English',
    'fr': '🇫🇷 French',
    'es': '🇪🇸 Spanish',
    'de': '🇩🇪 German',
    'pt': '🇵🇹 Portuguese',
    'it': '🇮🇹 Italian',
    'zh': '🇨🇳 Chinese',
    'ar': '🇸🇦 Arabic',
    'hi': '🇮🇳 Hindi',
    'ja': '🇯🇵 Japanese',
    'ko': '🇰🇷 Korean',
    'sw': '🇰🇪 Swahili',
    'ha': '🇳🇬 Hausa',
    'yo': '🇳🇬 Yoruba',
    'ig': '🇳🇬 Igbo',
    'am': '🇪🇹 Amharic',
    'rw': '🇷🇼 Kinyarwanda',
    'tn': '🇿🇦 Setswana',
    'zu': '🇿🇦 Zulu',
  };

  // Get language name without flag emoji
  static String getLanguageName(String code) {
    final fullName = supportedLanguages[code] ?? 'Unknown';
    // Remove flag emoji (first 3 characters: flag + space)
    final parts = fullName.split(' ');
    if (parts.length > 1) {
      parts.removeAt(0); // remove the flag
      return parts.join(' '); // rejoin the rest as name
    }
    return fullName;
  }

  // Get flag emoji only
  static String getLanguageFlag(String code) {
    final fullName = supportedLanguages[code] ?? '🌍 Unknown';
    return fullName.substring(0, 2); // Just the flag emoji
  }

  // Get full display name (flag + name)
  static String getFullDisplayName(String code) {
    return supportedLanguages[code] ?? '🌍 Unknown';
  }

  // Get list of language codes
  static List<String> get languageCodes => supportedLanguages.keys.toList();

  // Check if language code is supported
  static bool isSupported(String code) => supportedLanguages.containsKey(code);
}