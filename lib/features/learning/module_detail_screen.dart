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
    switch (topic) {
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
      default:
        return const Color(0xFF2563EB);
    }
  }

  IconData _topicIcon(String topic) {
    switch (topic) {
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
      default:
        return Icons.security;
    }
  }

  List<String> _contentPoints(String content) {
    return content
        .split(".")
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  void _startQuiz(BuildContext context) {
    context.read<QuizCubit>().loadQuiz(module.id);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuizScreen()),
    );
  }

  Future<void> _completeModule(BuildContext context) async {
    context.read<LearningCubit>().completeModule(module.title);
    await context.read<HomeCubit>().gainXP(module.xpReward);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Module completed! +${module.xpReward} XP earned."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _topicColor(module.topic);
    final points = _contentPoints(module.content);

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
                      _topicIcon(module.topic),
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    module.title,
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
                        text: module.difficulty,
                        icon: Icons.bar_chart,
                      ),
                      const SizedBox(width: 8),
                      _HeaderChip(
                        text: "+${module.xpReward} XP",
                        icon: Icons.bolt,
                      ),
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
                      module.content,
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
                      children: const [
                        _LearningPoint(
                          text:
                              "Verify suspicious messages through official channels.",
                        ),
                        _LearningPoint(
                          text:
                              "Avoid sharing passwords, OTP, banking details, or private information.",
                        ),
                        _LearningPoint(
                          text:
                              "Report suspicious links, messages, or files when possible.",
                        ),
                      ],
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
                      onPressed: () => _startQuiz(context),
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
                      onPressed: module.completed
                          ? null
                          : () => _completeModule(context),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(
                        module.completed
                            ? "Module Completed"
                            : "Mark as Completed",
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0D1B3E),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF0D1B3E)),
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
