/// API configuration for BizAgent.
///
/// SECURITY NOTE: All AI (Gemini) calls are routed through Firebase Cloud
/// Functions. No Gemini API key is embedded in the client app or APK.
/// The server-side key is managed via Firebase Functions config/secrets.
class ApiConfig {
  /// Whether AI features are available.
  /// Always true — calls go through authenticated Cloud Functions.
  static bool get hasGeminiKey => true;

  /// Gemini model identifier (informational; actual model selection is server-side).
  static const String geminiModel = 'gemini-2.0-flash';
}
