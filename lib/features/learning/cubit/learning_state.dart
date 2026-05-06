import 'package:equatable/equatable.dart';

class LearningModule extends Equatable {
  final String id;
  final String title;
  final String topic;
  final String difficulty;
  final int xpReward;
  final String content;
  final bool completed;

  const LearningModule({
    required this.id,
    required this.title,
    required this.topic,
    required this.difficulty,
    required this.xpReward,
    required this.content,
    this.completed = false,
  });

  LearningModule copyWith({
    String? id,
    String? title,
    String? topic,
    String? difficulty,
    int? xpReward,
    String? content,
    bool? completed,
  }) {
    return LearningModule(
      id: id ?? this.id,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      difficulty: difficulty ?? this.difficulty,
      xpReward: xpReward ?? this.xpReward,
      content: content ?? this.content,
      completed: completed ?? this.completed,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    topic,
    difficulty,
    xpReward,
    content,
    completed,
  ];
}

class LearningState extends Equatable {
  final List<LearningModule> modules;
  final bool isLoading;

  const LearningState({this.modules = const [], this.isLoading = false});

  LearningState copyWith({List<LearningModule>? modules, bool? isLoading}) {
    return LearningState(
      modules: modules ?? this.modules,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [modules, isLoading];
}
