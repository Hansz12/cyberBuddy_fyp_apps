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

  int _xp(QuizState state) => _q(state)['xpReward'] ?? 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuizCubit, QuizState>(
      builder: (context, state) {
        if (state.isLoading || state.questions.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.isFinished) {
          return _Result(state: state);
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          body: SafeArea(
            child: Column(
              children: [
                _Header(state: state),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _ScenarioBox(text: _scenario(state)),

                      const SizedBox(height: 16),

                      Text(
                        _question(state),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      ...List.generate(_options(state).length, (index) {
                        return _OptionCard(
                          text: _options(state)[index],
                          index: index,
                          state: state,
                          correctIndex: _correctIndex(state),
                          onTap: () {
                            context.read<QuizCubit>().selectAnswer(index);
                          },
                        );
                      }),

                      if (state.isAnswered) ...[
                        const SizedBox(height: 16),
                        _ExplanationBox(
                          isCorrect:
                              state.selectedIndex == _correctIndex(state),
                          text: _explanation(state),
                        ),
                        const SizedBox(height: 12),
                        _XpBox(
                          isCorrect:
                              state.selectedIndex == _correctIndex(state),
                          xp: _xp(state),
                        ),
                      ],
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () {
                      if (!state.isAnswered) {
                        context.read<QuizCubit>().submitAnswer();
                      } else {
                        context.read<QuizCubit>().nextQuestion();
                      }
                    },
                    child: Text(state.isAnswered ? "Next" : "Submit"),
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

class _Header extends StatelessWidget {
  final QuizState state;
  const _Header({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1E3A8A),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(
            "${state.currentIndex + 1}/${state.questions.length}",
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ScenarioBox extends StatelessWidget {
  final String text;
  const _ScenarioBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String text;
  final int index;
  final QuizState state;
  final int correctIndex;
  final VoidCallback onTap;

  const _OptionCard({
    required this.text,
    required this.index,
    required this.state,
    required this.correctIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color color = Colors.white;

    if (state.isAnswered) {
      if (index == correctIndex) {
        color = Colors.green.shade100;
      } else if (index == state.selectedIndex) {
        color = Colors.red.shade100;
      }
    }

    return GestureDetector(
      onTap: state.isAnswered ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(text),
      ),
    );
  }
}

class _ExplanationBox extends StatelessWidget {
  final bool isCorrect;
  final String text;

  const _ExplanationBox({required this.isCorrect, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: isCorrect ? Colors.green : Colors.red),
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
    return Text(
      isCorrect ? "+$xp XP" : "+0 XP",
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
  }
}

class _Result extends StatelessWidget {
  final QuizState state;
  const _Result({required this.state});

  @override
  Widget build(BuildContext context) {
    final totalXp = state.questions.fold(
      0,
      (sum, q) => sum + ((q['xpReward'] ?? 0) as int),
    );

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Score: ${state.score}/${state.questions.length}"),
            Text("+$totalXp XP"),
            ElevatedButton(
              onPressed: () {
                context.read<HomeCubit>().gainXP(totalXp);
                context.read<QuizCubit>().resetQuiz();
                Navigator.pop(context);
              },
              child: const Text("Back"),
            ),
          ],
        ),
      ),
    );
  }
}
