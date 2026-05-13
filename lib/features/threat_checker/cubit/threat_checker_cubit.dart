import 'package:flutter_bloc/flutter_bloc.dart';

import 'threat_checker_state.dart';

class ThreatCheckerCubit extends Cubit<ThreatCheckerState> {
  ThreatCheckerCubit() : super(const ThreatCheckerState());

  void updateInput(String value) {
    emit(
      state.copyWith(
        input: value,
        analysed: false,
        riskScore: 0,
        riskLevel: '',
        verdict: '',
        explanation: '',
        safetyTip: '',
        flags: const [],
      ),
    );
  }

  void analyseThreat() {
    final rawInput = state.input.trim();
    final text = rawInput.toLowerCase();

    int score = 0;
    final flags = <String>[];

    if (text.isEmpty) {
      emit(
        state.copyWith(
          riskScore: 0,
          riskLevel: 'UNKNOWN',
          verdict: 'Please enter a URL, email, or message first.',
          explanation:
              'CyberBuddy needs suspicious content to analyse before generating a risk result.',
          safetyTip:
              'Paste a suspicious link, email, SMS, or message before pressing Analyse.',
          flags: const [],
          analysed: true,
        ),
      );
      return;
    }

    // 1. Unsafe protocol
    if (text.contains('http://')) {
      score += 20;
      flags.add(
        'Insecure protocol: The link uses HTTP instead of HTTPS, which means the connection may not be secure.',
      );
    }

    // 2. Lookalike / typosquatting domain patterns
    final lookalikePatterns = [
      'maybank-secure',
      'secure-login',
      'verify-login',
      'account-verify',
      'login-verify',
      '-verify',
      '-secure',
      'mybank',
      'paypa1',
      'g00gle',
      'faceb00k',
    ];

    if (lookalikePatterns.any(text.contains)) {
      score += 30;
      flags.add(
        'Lookalike domain: The domain appears to imitate a trusted service, which is a common phishing technique.',
      );
    }

    // 3. Banking / credential related keywords
    final sensitiveKeywords = [
      'login',
      'verify',
      'password',
      'otp',
      'pin',
      'bank',
      'account',
      'credential',
      'security update',
      'confirm identity',
    ];

    if (sensitiveKeywords.any(text.contains)) {
      score += 20;
      flags.add(
        'Sensitive request: The content asks for login, banking, password, OTP, or account verification action.',
      );
    }

    // 4. Urgency / fear tactic
    final urgencyKeywords = [
      'urgent',
      'immediately',
      '24 hours',
      'locked',
      'suspended',
      'blocked',
      'final warning',
      'act now',
      'limited time',
    ];

    if (urgencyKeywords.any(text.contains)) {
      score += 20;
      flags.add(
        'Pressure tactic: The message creates urgency or fear to make users act quickly without thinking.',
      );
    }

    // 5. Suspicious query/path
    final suspiciousQueryPatterns = [
      'redirect',
      'ref=',
      'sms',
      'alert',
      'token=',
      'session=',
      'auth=',
      'verify=',
      'confirm=',
    ];

    if (suspiciousQueryPatterns.any(text.contains)) {
      score += 15;
      flags.add(
        'Suspicious URL path/query: The content contains redirect, tracking, token, or verification parameters.',
      );
    }

    // 6. Reward / scam bait
    final rewardKeywords = [
      'free gift',
      'giveaway',
      'winner',
      'prize',
      'claim now',
      'cash reward',
      'bonus',
      'refund',
      'crypto',
      'investment',
    ];

    if (rewardKeywords.any(text.contains)) {
      score += 15;
      flags.add(
        'Reward bait: The message uses prize, money, investment, or giveaway wording that is commonly used in scams.',
      );
    }

    // 7. Shortened URLs
    final shortenedUrls = [
      'bit.ly',
      'tinyurl',
      't.co/',
      'goo.gl',
      'is.gd',
      'cutt.ly',
      'shorturl',
    ];

    if (shortenedUrls.any(text.contains)) {
      score += 15;
      flags.add(
        'Shortened URL: Short links can hide the real destination and are often abused in phishing attacks.',
      );
    }

    // 8. Suspicious file attachment keywords
    final attachmentKeywords = [
      '.apk',
      '.exe',
      '.scr',
      '.bat',
      '.zip',
      'download attachment',
      'install app',
    ];

    if (attachmentKeywords.any(text.contains)) {
      score += 20;
      flags.add(
        'Suspicious attachment/app: The message may encourage downloading a file or installing an app.',
      );
    }

    // 9. Official domain safety reduction
    final trustedDomains = [
      'maybank2u.com.my',
      'cimbclicks.com.my',
      'rhbgroup.com',
      'google.com',
      'microsoft.com',
      'apple.com',
      'facebook.com',
      'instagram.com',
    ];

    if (trustedDomains.any(text.contains)) {
      score -= 20;
      flags.add(
        'Trusted domain indicator: The content contains a known official domain, but users should still verify the full link carefully.',
      );
    }

    score = score.clamp(0, 100);

    String riskLevel;
    String verdict;
    String explanation;
    String safetyTip;

    if (score >= 70) {
      riskLevel = 'HIGH RISK';
      verdict = '🚨 High Risk — Likely Phishing';
      explanation =
          'This content contains multiple phishing indicators such as unsafe links, sensitive requests, urgency tactics, or suspicious domain patterns.';
      safetyTip =
          'Do not click the link or enter any personal information. Open the official website or app manually instead.';
    } else if (score >= 40) {
      riskLevel = 'MEDIUM RISK';
      verdict = '⚠️ Medium Risk — Be Careful';
      explanation =
          'This content contains some suspicious indicators. It may not be confirmed phishing, but it should be verified before taking action.';
      safetyTip =
          'Check the sender, domain name, and message wording. Avoid sharing passwords, OTP, or banking details.';
    } else {
      riskLevel = 'LOW RISK';
      verdict = '✅ Low Risk — No major red flags detected';
      explanation =
          'No strong phishing indicators were detected based on the current rule-based analysis.';
      safetyTip =
          'Still stay cautious. Only trust links from official sources and avoid entering sensitive information through unknown links.';
    }

    if (flags.isEmpty) {
      flags.add(
        'No major suspicious pattern was detected by the current analysis rules.',
      );
    }

    emit(
      state.copyWith(
        riskScore: score,
        riskLevel: riskLevel,
        verdict: verdict,
        explanation: explanation,
        safetyTip: safetyTip,
        flags: flags,
        analysed: true,
      ),
    );
  }

  void reset() {
    emit(const ThreatCheckerState());
  }
}
