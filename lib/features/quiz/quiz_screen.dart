import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../home/cubit/home_cubit.dart';
import 'cubit/quiz_cubit.dart';
import 'cubit/quiz_state.dart';

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  Map<String, dynamic> _q(QuizState state) => state.currentQuestion;

  int _correctIndex(QuizState state) => _q(state)['correctIndex'] ?? 0;

  List<dynamic> _options(QuizState state) => _q(state)['options'] ?? [];

  String _question(QuizState state) => _q(state)['question'] ?? '';

  String _scenario(QuizState state) => _q(state)['scenario'] ?? '';

  String _explanation(QuizState state) => _q(state)['explanation'] ?? '';

  String _topic(QuizState state) => _q(state)['topic'] ?? 'cyber';

  String _moduleId(QuizState state) => _q(state)['moduleId'] ?? 'general';

  String _difficulty(QuizState state) => _q(state)['difficulty'] ?? 'beginner';

  int _xp(QuizState state) {
    final value = _q(state)['xpReward'];
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  String _getTopicKey(String topic, String moduleId) {
    final lower = topic.toLowerCase();

    if (lower.contains("phishing")) return "phishing";
    if (lower.contains("password")) return "password";
    if (lower.contains("social")) return "social";
    if (lower.contains("malware")) return "malware";
    if (lower.contains("privacy")) return "privacy";
    if (lower.contains("scam")) return "scam";
    if (lower.contains("mobile")) return "mobile";
    if (lower.contains("network")) return "network";
    if (lower.contains("ethics")) return "ethics";
    if (lower.contains("banking")) return "banking";

    return moduleId.trim().isEmpty ? "general" : moduleId;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuizCubit, QuizState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFFF1F5F9),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.questions.isEmpty) {
          return Scaffold(
            backgroundColor: const Color(0xFFF1F5F9),
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("📭", style: TextStyle(fontSize: 46)),
                      const SizedBox(height: 12),
                      const Text(
                        "No quiz questions found",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "This module may not have active questions yet.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Back"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        if (state.isFinished) {
          return _QuizResultScreen(state: state);
        }

        final correctIndex = _correctIndex(state);
        final options = _options(state);
        final selectedIndex = state.selectedIndex;
        final isCorrect = selectedIndex == correctIndex;

        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
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
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          ...List.generate(state.questions.length, (index) {
                            final active = index <= state.currentIndex;

                            return Expanded(
                              child: Container(
                                margin: const EdgeInsets.only(right: 5),
                                height: 5,
                                decoration: BoxDecoration(
                                  color: active
                                      ? const Color(0xFF38BDF8)
                                      : Colors.white24,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            "${state.currentIndex + 1}/${state.questions.length}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        " ${_topic(state).toUpperCase()} · ${_difficulty(state).toUpperCase()}",
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _question(state),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
                    children: [
                      if (_scenario(state).trim().isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("💬", style: TextStyle(fontSize: 24)),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  '"${_scenario(state)}"',
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 14,
                                    height: 1.35,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      ...List.generate(options.length, (index) {
                        return _OptionCard(
                          letter: String.fromCharCode(65 + index),
                          text: options[index].toString(),
                          index: index,
                          selectedIndex: selectedIndex,
                          correctIndex: correctIndex,
                          isAnswered: state.isAnswered,
                          onTap: () {
                            context.read<QuizCubit>().selectAnswer(index);
                          },
                        );
                      }),

                      if (state.isAnswered) ...[
                        const SizedBox(height: 14),
                        _ExplanationBox(
                          isCorrect: isCorrect,
                          explanation: _explanation(state),
                        ),
                        const SizedBox(height: 14),
                        _XpBox(isCorrect: isCorrect, xp: _xp(state)),
                      ],
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.selectedIndex == null
                          ? null
                          : () {
                              if (!state.isAnswered) {
                                context.read<QuizCubit>().submitAnswer();
                              } else {
                                context.read<QuizCubit>().nextQuestion();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFE2E8F0),
                        disabledForegroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        state.isAnswered
                            ? state.currentIndex == state.questions.length - 1
                                  ? "Finish quiz →"
                                  : "Next question →"
                            : "Submit answer",
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String letter;
  final String text;
  final int index;
  final int? selectedIndex;
  final int correctIndex;
  final bool isAnswered;
  final VoidCallback onTap;

  const _OptionCard({
    required this.letter,
    required this.text,
    required this.index,
    required this.selectedIndex,
    required this.correctIndex,
    required this.isAnswered,
    required this.onTap,
  });

  Color get _borderColor {
    if (!isAnswered) {
      return selectedIndex == index
          ? const Color(0xFF2563EB)
          : const Color(0xFFE2E8F0);
    }

    if (index == correctIndex) return const Color(0xFF10B981);
    if (index == selectedIndex) return const Color(0xFFEF4444);

    return const Color(0xFFE2E8F0);
  }

  Color get _backgroundColor {
    if (!isAnswered) {
      return selectedIndex == index ? const Color(0xFFEFF6FF) : Colors.white;
    }

    if (index == correctIndex) return const Color(0xFFECFDF5);
    if (index == selectedIndex) return const Color(0xFFFEF2F2);

    return Colors.white;
  }

  Color get _letterBgColor {
    if (!isAnswered) {
      return selectedIndex == index
          ? const Color(0xFF2563EB)
          : const Color(0xFFEFF6FF);
    }

    if (index == correctIndex) return const Color(0xFF10B981);
    if (index == selectedIndex) return const Color(0xFFEF4444);

    return const Color(0xFFEFF6FF);
  }

  Color get _letterTextColor {
    if (!isAnswered) {
      return selectedIndex == index ? Colors.white : const Color(0xFF2563EB);
    }

    if (index == correctIndex || index == selectedIndex) return Colors.white;

    return const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isAnswered ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _borderColor, width: 1.4),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _letterBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    color: _letterTextColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplanationBox extends StatelessWidget {
  final bool isCorrect;
  final String explanation;

  const _ExplanationBox({required this.isCorrect, required this.explanation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCorrect ? "✓ Correct answer!" : "✕ Not quite.",
            style: TextStyle(
              color: isCorrect
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            explanation.isEmpty
                ? "Review the scenario carefully and choose the safest cybersecurity action."
                : explanation,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _XpBox extends StatelessWidget {
  final bool isCorrect;
  final int xp;

  const _XpBox({required this.isCorrect, required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isCorrect ? " Question answered correctly" : " Keep learning",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            isCorrect ? "+$xp\nXP" : "+0\nXP",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF38BDF8),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizResultScreen extends StatelessWidget {
  final QuizState state;

  const _QuizResultScreen({required this.state});

  String _getTopicKey(Map<String, dynamic> question) {
    final topic = (question['topic'] ?? '').toString().toLowerCase();
    final moduleId = (question['moduleId'] ?? 'general').toString();

    if (topic.contains("phishing")) return "phishing";
    if (topic.contains("password")) return "password";
    if (topic.contains("social")) return "social";
    if (topic.contains("malware")) return "malware";
    if (topic.contains("privacy")) return "privacy";
    if (topic.contains("scam")) return "scam";
    if (topic.contains("mobile")) return "mobile";
    if (topic.contains("network")) return "network";
    if (topic.contains("ethics")) return "ethics";
    if (topic.contains("banking")) return "banking";

    return moduleId.trim().isEmpty ? "general" : moduleId;
  }

  @override
  Widget build(BuildContext context) {
    final percentage = ((state.score / state.questions.length) * 100).round();
    final earnedXp = state.earnedXp;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const Spacer(),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D1B3E), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    const Text("🎉", style: TextStyle(fontSize: 52)),
                    const SizedBox(height: 12),
                    const Text(
                      "Quiz Completed",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Score: ${state.score}/${state.questions.length} · $percentage%",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "+$earnedXp XP earned",
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (earnedXp > 0) {
                      await context.read<HomeCubit>().gainXP(earnedXp);
                    }

                    for (int i = 0; i < state.questions.length; i++) {
                      final question = state.questions[i];
                      final isCorrect = i < state.answerResults.length
                          ? state.answerResults[i]
                          : false;

                      await context.read<HomeCubit>().recordQuizAnswer(
                        _getTopicKey(question),
                        isCorrect,
                      );
                    }

                    await context.read<HomeCubit>().recordQuizCompleted(
                      totalQuestions: state.questions.length,
                      correctAnswers: state.score,
                    );

                    context.read<QuizCubit>().resetQuiz();

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Back to Learning"),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
