import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../home/cubit/home_cubit.dart';
import 'cubit/threat_checker_cubit.dart';
import 'cubit/threat_checker_state.dart';

class ThreatCheckerScreen extends StatelessWidget {
  const ThreatCheckerScreen({super.key});

  Color _riskColor(int score) {
    if (score >= 70) return const Color(0xFFEF4444);
    if (score >= 40) return const Color(0xFFF97316);
    return const Color(0xFF10B981);
  }

  String _riskSubtitle(int score) {
    if (score >= 70) return "Do NOT click or share this link";
    if (score >= 40) return "Verify first before clicking";
    return "No strong phishing pattern found";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: BlocBuilder<ThreatCheckerCubit, ThreatCheckerState>(
          builder: (context, state) {
            return ListView(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF991B1B), Color(0xFFDC2626)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "🔍 Threat Checker",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Paste any suspicious URL, email or message to analyse",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "PASTE SUSPICIOUS CONTENT",
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.7,
                              ),
                            ),
                            const SizedBox(height: 10),

                            TextField(
                              minLines: 4,
                              maxLines: 6,
                              onChanged: context
                                  .read<ThreatCheckerCubit>()
                                  .updateInput,
                              style: const TextStyle(
                                fontFamily: "monospace",
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    "http://maybank-secure-verify.com/login?redirect=confirm&ref=sms_alert",
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  context
                                      .read<ThreatCheckerCubit>()
                                      .analyseThreat();

                                  if (state.input.trim().isNotEmpty) {
                                    context.read<HomeCubit>().gainXP(10);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  "🔍 Analyse now",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      if (state.analysed)
                        _ResultCard(
                          score: state.riskScore,
                          verdict: state.verdict,
                          subtitle: _riskSubtitle(state.riskScore),
                          color: _riskColor(state.riskScore),
                          flags: state.flags,
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final int score;
  final String verdict;
  final String subtitle;
  final Color color;
  final List<String> flags;

  const _ResultCard({
    required this.score,
    required this.verdict,
    required this.subtitle,
    required this.color,
    required this.flags,
  });

  @override
  Widget build(BuildContext context) {
    final progress = score / 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.09),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verdict,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              const Text(
                "Risk level",
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                "$score /100",
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            color: color,
            backgroundColor: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(20),
          ),

          const SizedBox(height: 18),

          const Text(
            "WHY IT WAS FLAGGED",
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),

          const SizedBox(height: 10),

          if (flags.isEmpty)
            _FlagTile(
              icon: "✅",
              text: "No major phishing indicators were detected.",
            )
          else
            ...flags.map(
              (flag) => _FlagTile(
                icon: flag.toLowerCase().contains("domain")
                    ? "🌐"
                    : flag.toLowerCase().contains("path")
                    ? "🔗"
                    : flag.toLowerCase().contains("urgent") ||
                          flag.toLowerCase().contains("pressure")
                    ? "⏰"
                    : "⚠️",
                text: flag,
              ),
            ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              "Safety tip: Never enter passwords, OTP, or banking details through links received in messages. Always open the official app or website manually.",
              style: TextStyle(
                color: Color(0xFF1E3A8A),
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlagTile extends StatelessWidget {
  final String icon;
  final String text;

  const _FlagTile({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final parts = text.split(":");

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 13,
                  height: 1.35,
                ),
                children: [
                  if (parts.length > 1)
                    TextSpan(
                      text: "${parts.first}: ",
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  TextSpan(
                    text: parts.length > 1 ? parts.sublist(1).join(":") : text,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
