class ApiConfig {
  /// Gemini API Key pre AI funkcie (email generátor, smart OCR)
  ///
  /// Získajte kľúč na: https://aistudio.google.com/app/apikey
  ///
  /// Nastavenie:
  /// 1. Vytvorte .env súbor v koreňovom priečinku
  /// 2. Pridajte: GEMINI_API_KEY=AIzaSy...váš_kľúč
  /// 3. Spustite: flutter run --dart-define=GEMINI_API_KEY=\$(cat .env | grep GEMINI_API_KEY | cut -d '=' -f2)
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Kontrola či je Gemini API kľúč nakonfigurovaný
  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;

  /// Gemini model pre generovanie textu
  static const String geminiModel = 'gemini-pro';
}
