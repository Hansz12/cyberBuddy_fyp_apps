import 'package:flutter_bloc/flutter_bloc.dart';
import 'threat_checker_state.dart';

class ThreatCheckerCubit extends Cubit<ThreatCheckerState> {
  ThreatCheckerCubit() : super(const ThreatCheckerState());

  void updateInput(String value) {
    emit(state.copyWith(input: value, analysed: false));
  }

  void analyseThreat() {
    final text = state.input.toLowerCase().trim();

    int score = 0;
    final flags = <String>[];

    if (text.isEmpty) {
      emit(
        state.copyWith(
          riskScore: 0,
          verdict: "Please enter a URL, email, or message first.",
          flags: const [],
          analysed: true,
        ),
      );
      return;
    }

    if (text.contains("http://")) {
      score += 20;
      flags.add("Insecure link: uses HTTP instead of HTTPS.");
    }

    if (text.contains("maybank-secure") ||
        text.contains("secure-login") ||
        text.contains("verify-login") ||
        text.contains("-verify") ||
        text.contains("-secure")) {
      score += 30;
      flags.add(
        "Lookalike domain: this is NOT the official domain. Possible typosquatting.",
      );
    }

    if (text.contains("login") ||
        text.contains("verify") ||
        text.contains("password") ||
        text.contains("otp") ||
        text.contains("bank")) {
      score += 20;
      flags.add(
        "Sensitive request: asks for login, banking, password, or OTP action.",
      );
    }

    if (text.contains("urgent") ||
        text.contains("immediately") ||
        text.contains("24 hours") ||
        text.contains("locked") ||
        text.contains("suspended")) {
      score += 20;
      flags.add(
        "Pressure tactic: uses urgency, account lock, or suspension warning.",
      );
    }

    if (text.contains("redirect") ||
        text.contains("ref=") ||
        text.contains("sms") ||
        text.contains("alert")) {
      score += 17;
      flags.add(
        "Suspicious path/query: contains redirect or tracking-like parameters.",
      );
    }

    if (score > 100) score = 100;

    String verdict;
    if (score >= 70) {
      verdict = "🚨 High Risk — Likely Phishing";
    } else if (score >= 40) {
      verdict = "⚠️ Medium Risk — Be Careful";
    } else {
      verdict = "✅ Low Risk — No major red flags detected";
    }

    emit(
      state.copyWith(
        riskScore: score,
        verdict: verdict,
        flags: flags,
        analysed: true,
      ),
    );
  }

  void reset() {
    emit(const ThreatCheckerState());
  }
}
