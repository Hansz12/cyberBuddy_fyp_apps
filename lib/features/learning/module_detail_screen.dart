import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../home/cubit/home_cubit.dart';
import '../quiz/cubit/quiz_cubit.dart';
import '../quiz/quiz_screen.dart';
import 'cubit/learning_cubit.dart';
import 'cubit/learning_state.dart';

class ModuleDetailScreen extends StatelessWidget {
  final LearningModule module;

  const ModuleDetailScreen({super.key, required this.module});

  Color _topicColor(String topic) {
    switch (topic.toLowerCase()) {
      case "phishing":
        return const Color(0xFFEF4444);
      case "password":
        return const Color(0xFF10B981);
      case "social":
        return const Color(0xFF7C3AED);
      case "malware":
        return const Color(0xFFF59E0B);
      case "privacy":
        return const Color(0xFFD946EF);
      case "scam":
        return const Color(0xFF2563EB);
      case "mobile":
        return const Color(0xFF38BDF8);
      case "network":
        return const Color(0xFF0EA5E9);
      case "ethics":
        return const Color(0xFF8B5CF6);
      case "banking":
        return const Color(0xFF0284C7);
      default:
        return const Color(0xFF2563EB);
    }
  }

  IconData _topicIcon(String topic) {
    switch (topic.toLowerCase()) {
      case "phishing":
        return Icons.phishing;
      case "password":
        return Icons.lock;
      case "social":
        return Icons.psychology;
      case "malware":
        return Icons.bug_report;
      case "privacy":
        return Icons.visibility;
      case "scam":
        return Icons.attach_money;
      case "mobile":
        return Icons.phone_android;
      case "network":
        return Icons.wifi;
      case "ethics":
        return Icons.groups;
      case "banking":
        return Icons.account_balance;
      default:
        return Icons.security;
    }
  }

  List<String> _contentPoints(String content, String title) {
    final cleaned = content.trim();

    if (cleaned.isEmpty) {
      return [
        "Understand the main cybersecurity risk related to $title.",
        "Identify warning signs before taking any action.",
        "Apply safe digital behaviour in real-life situations.",
      ];
    }

    final points = cleaned
        .split(".")
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (points.isEmpty) {
      return [
        "Understand the main cybersecurity risk related to $title.",
        "Identify warning signs before taking any action.",
        "Apply safe digital behaviour in real-life situations.",
      ];
    }

    return points;
  }

  List<String> _actionPoints(String topic) {
    switch (topic.toLowerCase()) {
      case "phishing":
        return [
          "Check sender address and URL before clicking any link.",
          "Open official websites manually instead of using suspicious links.",
          "Report phishing emails or messages when possible.",
        ];
      case "password":
        return [
          "Use strong and unique passwords for each account.",
          "Avoid using birthdays, names, or repeated passwords.",
          "Enable multi-factor authentication whenever possible.",
        ];
      case "malware":
        return [
          "Avoid downloading cracked apps or unknown APK files.",
          "Install apps only from trusted stores or official websites.",
          "Keep your operating system and apps updated.",
        ];
      case "privacy":
        return [
          "Review app permissions before allowing access.",
          "Avoid sharing personal information publicly online.",
          "Use privacy settings to limit who can view your data.",
        ];
      case "banking":
        return [
          "Never share OTP, TAC, PIN, or banking password.",
          "Verify banking links through the official app or website.",
          "Contact the bank using official customer service numbers.",
        ];
      default:
        return [
          "Verify suspicious messages through official channels.",
          "Avoid sharing passwords, OTP, banking details, or private information.",
          "Report suspicious links, messages, or files when possible.",
        ];
    }
  }

  void _startQuiz(BuildContext context, LearningModule currentModule) {
    if (currentModule.id.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Module ID not found.")));
      return;
    }

    context.read<QuizCubit>().loadQuiz(currentModule.id);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuizScreen()),
    );
  }

  Future<void> _completeModule(
    BuildContext context,
    LearningModule currentModule,
  ) async {
    if (currentModule.completed) return;

    await context.read<LearningCubit>().completeModule(currentModule.id);
    await context.read<HomeCubit>().gainXP(currentModule.xpReward);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Module completed! +${currentModule.xpReward} XP earned.",
          ),
        ),
      );

      Navigator.pop(context);
    }
  }

  LearningModule _getLatestModule(BuildContext context) {
    final modules = context.watch<LearningCubit>().state.modules;

    try {
      return modules.firstWhere((m) => m.id == module.id);
    } catch (_) {
      return module;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentModule = _getLatestModule(context);

    final color = _topicColor(currentModule.topic);

    final overviewText = currentModule.content.trim().isEmpty
        ? "This module helps you learn important cybersecurity practices related to ${currentModule.title.toLowerCase()}."
        : currentModule.content;

    final points = _contentPoints(
      currentModule.content,
      currentModule.title.toLowerCase(),
    );

    final actions = _actionPoints(currentModule.topic);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D1B3E), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.white,
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: color.withOpacity(0.4)),
                    ),
                    child: Icon(
                      _topicIcon(currentModule.topic),
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentModule.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _HeaderChip(
                        text: currentModule.difficulty,
                        icon: Icons.bar_chart,
                      ),
                      const SizedBox(width: 8),
                      _HeaderChip(
                        text: "+${currentModule.xpReward} XP",
                        icon: Icons.bolt,
                      ),
                      if (currentModule.completed) ...[
                        const SizedBox(width: 8),
                        const _HeaderChip(
                          text: "Completed",
                          icon: Icons.check_circle,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                children: [
                  _InfoCard(
                    title: "Module Overview",
                    child: Text(
                      overviewText,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _InfoCard(
                    title: "Key Learning Points",
                    child: Column(
                      children: points.take(5).map((point) {
                        return _LearningPoint(text: point);
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _InfoCard(
                    title: "What You Should Do",
                    child: Column(
                      children: actions.map((point) {
                        return _LearningPoint(text: point);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _startQuiz(context, currentModule),
                      icon: const Icon(Icons.quiz),
                      label: const Text("Start Module Quiz"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: currentModule.completed
                          ? null
                          : () => _completeModule(context, currentModule),
                      icon: Icon(
                        currentModule.completed
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                      ),
                      label: Text(
                        currentModule.completed
                            ? "Module Completed"
                            : "Mark as Completed",
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: currentModule.completed
                            ? const Color(0xFF10B981)
                            : const Color(0xFF0D1B3E),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: currentModule.completed
                              ? const Color(0xFF10B981)
                              : const Color(0xFF0D1B3E),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String text;
  final IconData icon;

  const _HeaderChip({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF38BDF8), size: 15),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LearningPoint extends StatelessWidget {
  final String text;

  const _LearningPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
