import 'package:flutter_bloc/flutter_bloc.dart';
import 'threat_checker_state.dart';

class ThreatCheckerCubit extends Cubit<ThreatCheckerState> {
  ThreatCheckerCubit() : super(const ThreatCheckerState());

  void updateInput(String value) {
    emit(state.copyWith(input: value));
  }

  void analyseThreat() {
    final text = state.input.toLowerCase().trim();

    int score = 0;
    final flags = <String>[];

    if (text.isEmpty) {
      emit(
        state.copyWith(
          riskScore: 0,
          verdict: "Please enter a message or URL first.",
          flags: const [],
          analysed: true,
        ),
      );
      return;
    }

    if (text.contains("http://")) {
      score += 25;
      flags.add("Uses insecure HTTP instead of HTTPS.");
    }

    if (text.contains("urgent") ||
        text.contains("immediately") ||
        text.contains("verify now") ||
        text.contains("before 11:59")) {
      score += 20;
      flags.add("Uses urgency to pressure the user.");
    }

    if (text.contains("password") ||
        text.contains("otp") ||
        text.contains("login") ||
        text.contains("bank")) {
      score += 20;
      flags.add("Requests or relates to sensitive information.");
    }

    if (text.contains("free") ||
        text.contains("prize") ||
        text.contains("claim") ||
        text.contains("reward")) {
      score += 15;
      flags.add("Uses reward or prize bait.");
    }

    if (text.contains(".net") ||
        text.contains(".xyz") ||
        text.contains("-verify") ||
        text.contains("-secure")) {
      score += 20;
      flags.add("Contains suspicious or lookalike domain pattern.");
    }

    if (score > 100) score = 100;

    String verdict;
    if (score >= 70) {
      verdict = "High Risk — Likely Phishing";
    } else if (score >= 40) {
      verdict = "Medium Risk — Be Careful";
    } else {
      verdict = "Low Risk — No major red flags detected";
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
