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

      final filtered = data
          .where((q) {
            final active =
                q['active'] == true || q['active'].toString() == 'true';

            final qModuleId =
                q['module_id']?.toString() ?? q['moduleId']?.toString() ?? '';

            return qModuleId == moduleId && active;
          })
          .map((q) => _formatQuestion(q))
          .where((q) => (q['question'] ?? '').toString().trim().isNotEmpty)
          .toList();

      final shuffledQuestions = List<Map<String, dynamic>>.from(filtered)
        ..shuffle();

      emit(
        state.copyWith(
          questions: shuffledQuestions,
          currentIndex: 0,
          clearSelectedIndex: true,
          score: 0,
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
        ),
      );
    }
  }

  Map<String, dynamic> _formatQuestion(dynamic raw) {
    final correctLetter =
        raw['correct_option']?.toString().trim().toUpperCase() ?? 'A';

    final originalOptions =
        [
          {'text': raw['option_a']?.toString() ?? '', 'letter': 'A'},
          {'text': raw['option_b']?.toString() ?? '', 'letter': 'B'},
          {'text': raw['option_c']?.toString() ?? '', 'letter': 'C'},
          {'text': raw['option_d']?.toString() ?? '', 'letter': 'D'},
        ].where((option) {
          return (option['text'] ?? '').toString().trim().isNotEmpty;
        }).toList();

    final shouldShuffle =
        raw['shuffle_options'] == true ||
        raw['shuffle_options'].toString().toLowerCase() == 'true';

    final shuffledOptions = List<Map<String, String>>.from(originalOptions);

    if (shouldShuffle) {
      shuffledOptions.shuffle();
    }

    final correctIndex = shuffledOptions.indexWhere(
      (option) => option['letter'] == correctLetter,
    );

    return {
      'id': raw['question_id']?.toString() ?? raw['id']?.toString() ?? '',
      'moduleId':
          raw['module_id']?.toString() ?? raw['moduleId']?.toString() ?? '',
      'topic': raw['topic']?.toString() ?? '',
      'difficulty': raw['difficulty']?.toString() ?? '',
      'questionType': raw['question_type']?.toString() ?? 'MCQ',
      'scenario': raw['scenario']?.toString() ?? '',
      'question': raw['question']?.toString() ?? '',
      'options': shuffledOptions.map((option) => option['text'] ?? '').toList(),
      'correctIndex': correctIndex < 0 ? 0 : correctIndex,
      'explanation': raw['explanation']?.toString() ?? '',
      'xpReward': int.tryParse(raw['xp_reward'].toString()) ?? 10,
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

    emit(
      state.copyWith(
        score: isCorrect ? state.score + 1 : state.score,
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
