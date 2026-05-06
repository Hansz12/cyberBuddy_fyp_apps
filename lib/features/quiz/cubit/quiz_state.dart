import 'package:equatable/equatable.dart';

class QuizState extends Equatable {
  final List<Map<String, dynamic>> questions;
  final int currentIndex;
  final int? selectedIndex;
  final int score;
  final bool isLoading;
  final bool isFinished;
  final bool isAnswered;

  const QuizState({
    this.questions = const [],
    this.currentIndex = 0,
    this.selectedIndex,
    this.score = 0,
    this.isLoading = false,
    this.isFinished = false,
    this.isAnswered = false,
  });

  Map<String, dynamic> get currentQuestion {
    if (questions.isEmpty) return {};
    return questions[currentIndex];
  }

  int get totalQuestions => questions.length;

  QuizState copyWith({
    List<Map<String, dynamic>>? questions,
    int? currentIndex,
    int? selectedIndex,
    bool clearSelectedIndex = false,
    int? score,
    bool? isLoading,
    bool? isFinished,
    bool? isAnswered,
  }) {
    return QuizState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedIndex: clearSelectedIndex
          ? null
          : selectedIndex ?? this.selectedIndex,
      score: score ?? this.score,
      isLoading: isLoading ?? this.isLoading,
      isFinished: isFinished ?? this.isFinished,
      isAnswered: isAnswered ?? this.isAnswered,
    );
  }

  @override
  List<Object?> get props => [
    questions,
    currentIndex,
    selectedIndex,
    score,
    isLoading,
    isFinished,
    isAnswered,
  ];
}
