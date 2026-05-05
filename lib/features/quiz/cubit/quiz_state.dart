import 'package:equatable/equatable.dart';

class QuizQuestion extends Equatable {
  final String topic;
  final String difficulty;
  final String scenario;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final int xpReward;

  const QuizQuestion({
    required this.topic,
    required this.difficulty,
    required this.scenario,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.xpReward = 15,
  });

  @override
  List<Object> get props => [
    topic,
    difficulty,
    scenario,
    question,
    options,
    correctIndex,
    explanation,
    xpReward,
  ];
}

class QuizState extends Equatable {
  final List<QuizQuestion> questions;
  final int currentIndex;
  final int score;
  final int totalXp;
  final int? selectedIndex;
  final bool isAnswered;
  final bool isFinished;

  const QuizState({
    this.questions = const [],
    this.currentIndex = 0,
    this.score = 0,
    this.totalXp = 0,
    this.selectedIndex,
    this.isAnswered = false,
    this.isFinished = false,
  });

  QuizQuestion get currentQuestion => questions[currentIndex];

  QuizState copyWith({
    List<QuizQuestion>? questions,
    int? currentIndex,
    int? score,
    int? totalXp,
    int? selectedIndex,
    bool clearSelectedIndex = false,
    bool? isAnswered,
    bool? isFinished,
  }) {
    return QuizState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      totalXp: totalXp ?? this.totalXp,
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
    totalXp,
    selectedIndex,
    isAnswered,
    isFinished,
  ];
}
