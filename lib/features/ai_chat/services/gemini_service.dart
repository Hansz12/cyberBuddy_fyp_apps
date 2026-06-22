import 'package:google_generative_ai/google_generative_ai.dart';

import '../../../core/secrets/api_keys.dart';

/// Maintains one continuous Gemini conversation for the lifetime of a chat
/// screen. This is important for follow-up questions such as "why?" or
/// "explain that in Malay" to retain their context.
class GeminiService {
  late final GenerativeModel _model;
  late ChatSession _chat;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: ApiKeys.geminiApiKey,
      systemInstruction: Content.system('''
You are CyberBuddy AI Coach, a helpful AI assistant inside a mobile learning app.

You can answer general questions like a normal AI assistant, including:
- Study help
- Cybersecurity
- Technology
- Programming
- Mobile app development
- Productivity
- Simple explanations
- Writing assistance
- General knowledge

You should still be especially strong in cybersecurity learning because the app focuses on cybersecurity awareness for university students.

If the user asks about scam, phishing, malware, suspicious links, password safety, privacy, mobile security, or cyber threats, respond as a cybersecurity assistant and include:
Risk Level: Low / Medium / High
Red Flags:
Safe Action:
Short Explanation:

If the user asks what to study, act as a study coach and suggest clear learning steps.

Use simple English or Malay depending on the user's language.
Keep answers clear, friendly, and not too long.
Do not ask for passwords, OTP, bank details, or private information.
Do not help with harmful cyber activities, hacking other people, stealing accounts, bypassing security, or creating malware.
'''),
    );
    startNewConversation();
  }

  void startNewConversation() {
    _chat = _model.startChat();
  }

  Future<String> sendMessage(String message) async {
    // Capture this session so a later "Clear chat" cannot accidentally move
    // an in-flight request into a new conversation.
    final chat = _chat;

    try {
      final response = await chat.sendMessage(Content.text(message));
      return response.text?.trim().isNotEmpty == true
          ? response.text!.trim()
          : 'Sorry, I could not generate an answer. Please try again.';
    } catch (_) {
      return 'Sorry, CyberBuddy AI could not respond right now. Please check your connection and try again.';
    }
  }
}
