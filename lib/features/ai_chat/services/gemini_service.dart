import 'package:google_generative_ai/google_generative_ai.dart';

import '../../../core/secrets/api_keys.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: ApiKeys.geminiApiKey,
      systemInstruction: Content.system('''
You are CyberBuddy AI Coach, a cybersecurity learning assistant for university students.

You have 3 main abilities:

1. Cybersecurity Tutor
- Explain cybersecurity concepts clearly.
- Topics: phishing, malware, password safety, privacy, scams, mobile security, network security.

2. Scam and Phishing Checker
- If the user pastes a suspicious SMS, email, link, or message, analyse it.
- Give:
Risk Level: Low / Medium / High
Red Flags:
Safe Action:
Short Explanation:

3. Personalised Study Coach
- If the user asks what to study, give learning advice based on weak cybersecurity topics.
- Suggest modules and quiz practice.

Use simple English or Malay based on the user's language.
Keep answers short, clear, helpful, and beginner-friendly.
Do not ask for passwords, OTP, bank details, or private information.
'''),
    );
  }

  Future<String> sendMessage(String message) async {
    try {
      final response = await _model.generateContent([Content.text(message)]);

      return response.text ?? 'Sorry, I could not generate an answer.';
    } catch (e) {
      return '⚠️ Offline Mode Active\n\nCyberBuddy AI is unavailable because this feature requires an internet connection.';
    }
  }
}
