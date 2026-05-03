import 'package:equatable/equatable.dart';

class QuizQuestion extends Equatable {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  @override
  List<Object> get props => [question, options, correctIndex, explanation];
}

class QuizState extends Equatable {
  final List<QuizQuestion> questions;
  final int currentIndex;
  final int score;
  final int? selectedIndex;
  final bool isAnswered;
  final bool isFinished;

  const QuizState({
    this.questions = const [],
    this.currentIndex = 0,
    this.score = 0,
    this.selectedIndex,
    this.isAnswered = false,
    this.isFinished = false,
  });

  QuizQuestion get currentQuestion => questions[currentIndex];

  QuizState copyWith({
    List<QuizQuestion>? questions,
    int? currentIndex,
    int? score,
    int? selectedIndex,
    bool clearSelectedIndex = false,
    bool? isAnswered,
    bool? isFinished,
  }) {
    return QuizState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      selectedIndex: clearSelectedIndex
          ? null
          : selectedIndex ?? this.selectedIndex,
      isAnswered: isAnswered ?? this.isAnswered,
      isFinished: isFinished ?? this.isFinished,
    );
  }

  @override
  List<Object?> get props => [
    questions,
    currentIndex,
    score,
    selectedIndex,
    isAnswered,
    isFinished,
  ];
}
