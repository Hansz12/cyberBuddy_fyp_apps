import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../home/cubit/home_cubit.dart';
import 'cubit/quiz_cubit.dart';
import 'cubit/quiz_state.dart';

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  String _getTopicKey(String topic) {
    final lower = topic.toLowerCase();

    if (lower.contains("phishing")) return "phishing";
    if (lower.contains("password")) return "password";
    if (lower.contains("social")) return "social";

    return "phishing";
  }

  Color _optionBorderColor(QuizState state, int index) {
    if (!state.isAnswered) return const Color(0xFFE2E8F0);

    if (index == state.currentQuestion.correctIndex) {
      return const Color(0xFF10B981);
    }

    if (index == state.selectedIndex) {
      return const Color(0xFFEF4444);
    }

    return const Color(0xFFE2E8F0);
  }

  Color _optionBgColor(QuizState state, int index) {
    if (!state.isAnswered) return Colors.white;

    if (index == state.currentQuestion.correctIndex) {
      return const Color(0xFFECFDF5);
    }

    if (index == state.selectedIndex) {
      return const Color(0xFFFEF2F2);
    }

    return Colors.white;
  }

  Color _optionLetterColor(QuizState state, int index) {
    if (!state.isAnswered) return const Color(0xFF64748B);

    if (index == state.currentQuestion.correctIndex) {
      return const Color(0xFF10B981);
    }

    if (index == state.selectedIndex) {
      return const Color(0xFFEF4444);
    }

    return const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuizCubit, QuizState>(
      builder: (context, state) {
        if (state.questions.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.isFinished) {
          return _QuizResultScreen(state: state);
        }

        final question = state.currentQuestion;

        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
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

                      const SizedBox(height: 4),

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

                      const SizedBox(height: 18),

                      Text(
                        "🎧 ${question.topic.toUpperCase()} · ${question.difficulty.toUpperCase()}",
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        question.question,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
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
                                question.scenario,
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

                      ...List.generate(question.options.length, (index) {
                        return _OptionCard(
                          letter: String.fromCharCode(65 + index),
                          text: question.options[index],
                          backgroundColor: _optionBgColor(state, index),
                          borderColor: _optionBorderColor(state, index),
                          letterColor: _optionLetterColor(state, index),
                          onTap: () {
                            if (state.isAnswered) return;

                            final isCorrect = index == question.correctIndex;
                            final topicKey = _getTopicKey(question.topic);

                            context.read<HomeCubit>().updateTopicScore(
                              topicKey,
                              isCorrect,
                            );

                            context.read<QuizCubit>().answerQuestion(index);
                          },
                        );
                      }),

                      if (state.isAnswered) ...[
                        const SizedBox(height: 14),
                        _ExplanationBox(
                          isCorrect:
                              state.selectedIndex == question.correctIndex,
                          explanation: question.explanation,
                        ),
                        const SizedBox(height: 14),
                        _XpBox(
                          isCorrect:
                              state.selectedIndex == question.correctIndex,
                          xp: question.xpReward,
                        ),
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
                      onPressed: state.isAnswered
                          ? () {
                              context.read<QuizCubit>().nextQuestion();
                            }
                          : null,
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
                        state.currentIndex == state.questions.length - 1
                            ? "Finish quiz →"
                            : "Next question →",
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
  final Color backgroundColor;
  final Color borderColor;
  final Color letterColor;
  final VoidCallback onTap;

  const _OptionCard({
    required this.letter,
    required this.text,
    required this.backgroundColor,
    required this.borderColor,
    required this.letterColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final letterBg = letterColor.withOpacity(0.13);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.4),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: letterBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    color: letterColor,
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
            explanation,
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
          Text(
            isCorrect ? "🏆 Question answered correctly" : "💡 Keep learning",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
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

  @override
  Widget build(BuildContext context) {
    final percentage = ((state.score / state.questions.length) * 100).round();

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
                      "+${state.totalXp} XP earned",
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
                  onPressed: () {
                    context.read<HomeCubit>().gainXP(state.totalXp);
                    context.read<QuizCubit>().restartQuiz();
                  },
                  child: const Text("Restart Quiz"),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    context.read<HomeCubit>().gainXP(state.totalXp);
                    Navigator.pop(context);
                  },
                  child: const Text("Back to Home"),
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
