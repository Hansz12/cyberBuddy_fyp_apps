class ApiKeys {
  /// Inject this when building/running the app instead of committing a secret.
  /// Example: --dart-define=GEMINI_API_KEY=your_key
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  static bool get hasGeminiApiKey => geminiApiKey.trim().isNotEmpty;
}
