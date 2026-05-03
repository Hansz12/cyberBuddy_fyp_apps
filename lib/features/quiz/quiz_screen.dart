import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../home/cubit/home_cubit.dart';
import 'cubit/quiz_cubit.dart';
import 'cubit/quiz_state.dart';

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  String _getTopic(int index) {
    if (index == 0) return "phishing";
    if (index == 1) return "password";
    return "social";
  }

  Color _optionColor(QuizState state, int index) {
    if (!state.isAnswered) return Colors.white;

    if (index == state.currentQuestion.correctIndex) {
      return Colors.green.shade100;
    }

    if (index == state.selectedIndex) {
      return Colors.red.shade100;
    }

    return Colors.white;
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
          final xpEarned = state.score * 20;

          return Scaffold(
            appBar: AppBar(title: const Text('Quiz Result')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Quiz Completed 🎉',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Score: ${state.score}/${state.questions.length}',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'XP Earned: +$xpEarned',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.read<HomeCubit>().gainXP(xpEarned);
                        context.read<QuizCubit>().restartQuiz();
                      },
                      child: const Text('Restart Quiz'),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<HomeCubit>().gainXP(xpEarned);
                        Navigator.pop(context);
                      },
                      child: const Text('Back to Home'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final question = state.currentQuestion;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Question ${state.currentIndex + 1}/${state.questions.length}',
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: (state.currentIndex + 1) / state.questions.length,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(20),
                ),
                const SizedBox(height: 24),

                Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                ...List.generate(question.options.length, (index) {
                  return Card(
                    color: _optionColor(state, index),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: ListTile(
                      title: Text(question.options[index]),
                      onTap: () {
                        final isCorrect =
                            index == state.currentQuestion.correctIndex;

                        final topic = _getTopic(state.currentIndex);

                        context.read<HomeCubit>().updateTopicScore(
                          topic,
                          isCorrect,
                        );

                        context.read<QuizCubit>().answerQuestion(index);
                      },
                    ),
                  );
                }),

                const SizedBox(height: 16),

                if (state.isAnswered)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      question.explanation,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.isAnswered
                        ? () {
                            context.read<QuizCubit>().nextQuestion();
                          }
                        : null,
                    child: const Text('Next'),
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
