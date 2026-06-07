import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/services/local_data_service.dart';
import 'quiz_state.dart';

class QuizCubit extends Cubit<QuizState> {
  QuizCubit() : super(const QuizState());

  final LocalDataService _dataService = LocalDataService();

  Future<void> loadQuiz(String moduleId) async {
    emit(state.copyWith(isLoading: true));

    try {
      final data = await _dataService.loadQuizQuestions();
      final moduleIdString = moduleId.toString().trim().toUpperCase();

      final filtered = data
          .where((q) {
            final qModuleId = q['module_id'] ?? q['moduleId'] ?? q['moduleID'];

            final activeValue = q['is_active'] ?? q['active'] ?? true;
            final isActive =
                activeValue == true ||
                activeValue.toString().toLowerCase() == 'true';

            return qModuleId.toString().trim().toUpperCase() ==
                    moduleIdString &&
                isActive;
          })
          .map((q) {
            return _formatQuestion(q);
          })
          .where((q) {
            return (q['question'] ?? '').toString().trim().isNotEmpty &&
                (q['options'] as List).isNotEmpty;
          })
          .toList();

      final shuffledQuestions = List<Map<String, dynamic>>.from(filtered)
        ..shuffle();

      final selectedQuestions = shuffledQuestions.take(5).toList();

      emit(
        state.copyWith(
          questions: selectedQuestions,
          currentIndex: 0,
          clearSelectedIndex: true,
          score: 0,
          earnedXp: 0,
          answerResults: const [],
          isLoading: false,
          isFinished: false,
          isAnswered: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          questions: const [],
          isLoading: false,
          isFinished: false,
          isAnswered: false,
          clearSelectedIndex: true,
          score: 0,
          earnedXp: 0,
          answerResults: const [],
        ),
      );
    }
  }

  Map<String, dynamic> _formatQuestion(dynamic raw) {
    List<String> options = [];

    if (raw['options'] is List) {
      options = List<String>.from(
        (raw['options'] as List).map((option) => option.toString()),
      );
    } else {
      options = [
        raw['option_a']?.toString() ?? '',
        raw['option_b']?.toString() ?? '',
        raw['option_c']?.toString() ?? '',
        raw['option_d']?.toString() ?? '',
      ].where((option) => option.trim().isNotEmpty).toList();
    }

    int correctIndex = 0;

    if (raw['correctIndex'] != null) {
      correctIndex = int.tryParse(raw['correctIndex'].toString()) ?? 0;
    } else if (raw['correct_index'] != null) {
      correctIndex = int.tryParse(raw['correct_index'].toString()) ?? 0;
    } else {
      final correctLetter =
          raw['correct_option']?.toString().trim().toUpperCase() ?? 'A';

      correctIndex = switch (correctLetter) {
        'A' => 0,
        'B' => 1,
        'C' => 2,
        'D' => 3,
        _ => 0,
      };
    }

    if (correctIndex < 0 || correctIndex >= options.length) {
      correctIndex = 0;
    }

    final xpValue = raw['xpReward'] ?? raw['xp_reward'] ?? 10;

    return {
      'id': raw['question_id']?.toString() ?? raw['id']?.toString() ?? '',
      'moduleId':
          raw['module_id']?.toString() ?? raw['moduleId']?.toString() ?? '',
      'topic': raw['topic']?.toString() ?? '',
      'difficulty': raw['difficulty']?.toString() ?? '',
      'questionType': raw['question_type']?.toString() ?? 'MCQ',
      'scenario': raw['scenario']?.toString() ?? '',
      'question': raw['question']?.toString() ?? '',
      'options': options,
      'correctIndex': correctIndex,
      'explanation': raw['explanation']?.toString() ?? '',
      'xpReward': int.tryParse(xpValue.toString()) ?? 10,
    };
  }

  void selectAnswer(int index) {
    if (state.isAnswered) return;
    emit(state.copyWith(selectedIndex: index));
  }

  void submitAnswer() {
    if (state.selectedIndex == null || state.isAnswered) return;
    if (state.questions.isEmpty) return;

    final currentQuestion = state.questions[state.currentIndex];
    final correctIndex = currentQuestion['correctIndex'] ?? 0;
    final isCorrect = state.selectedIndex == correctIndex;

    final xpValue = currentQuestion['xpReward'];
    final xpReward = xpValue is int
        ? xpValue
        : int.tryParse(xpValue.toString()) ?? 0;

    final updatedResults = List<bool>.from(state.answerResults)..add(isCorrect);

    emit(
      state.copyWith(
        score: isCorrect ? state.score + 1 : state.score,
        earnedXp: isCorrect ? state.earnedXp + xpReward : state.earnedXp,
        answerResults: updatedResults,
        isAnswered: true,
      ),
    );
  }

  void nextQuestion() {
    if (state.questions.isEmpty) return;

    if (state.currentIndex >= state.questions.length - 1) {
      emit(state.copyWith(isFinished: true));
      return;
    }

    emit(
      state.copyWith(
        currentIndex: state.currentIndex + 1,
        clearSelectedIndex: true,
        isAnswered: false,
      ),
    );
  }

  void resetQuiz() {
    emit(const QuizState());
  }
}
