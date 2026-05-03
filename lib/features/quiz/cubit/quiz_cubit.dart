import 'package:flutter_bloc/flutter_bloc.dart';
import 'quiz_state.dart';

class QuizCubit extends Cubit<QuizState> {
  QuizCubit() : super(const QuizState());

  void loadQuiz() {
    const questions = [
      QuizQuestion(
        question: 'What is phishing?',
        options: [
          'A type of secure login',
          'A cyberattack that tricks users into giving sensitive information',
          'A password manager',
          'A firewall setting',
        ],
        correctIndex: 1,
        explanation:
            'Phishing is a social engineering attack where attackers trick users into revealing private information.',
      ),
      QuizQuestion(
        question: 'Which password is the strongest?',
        options: [
          '12345678',
          'password123',
          'Farhana2002',
          'M@laysia!Cyber#2026',
        ],
        correctIndex: 3,
        explanation:
            'A strong password uses a mix of uppercase, lowercase, symbols, and numbers.',
      ),
      QuizQuestion(
        question: 'What should you do when you receive a suspicious link?',
        options: [
          'Click immediately',
          'Forward to friends',
          'Verify through official website first',
          'Reply to the sender',
        ],
        correctIndex: 2,
        explanation:
            'Always verify suspicious links through official sources before clicking.',
      ),
    ];

    emit(
      state.copyWith(
        questions: questions,
        currentIndex: 0,
        score: 0,
        clearSelectedIndex: true,
        isAnswered: false,
        isFinished: false,
      ),
    );
  }

  void answerQuestion(int selectedIndex) {
    if (state.isAnswered) return;

    final isCorrect = selectedIndex == state.currentQuestion.correctIndex;

    emit(
      state.copyWith(
        selectedIndex: selectedIndex,
        isAnswered: true,
        score: isCorrect ? state.score + 1 : state.score,
      ),
    );
  }

  void nextQuestion() {
    if (state.currentIndex == state.questions.length - 1) {
      emit(state.copyWith(isFinished: true));
    } else {
      emit(
        state.copyWith(
          currentIndex: state.currentIndex + 1,
          clearSelectedIndex: true,
          isAnswered: false,
        ),
      );
    }
  }

  void restartQuiz() {
    loadQuiz();
  }
}
