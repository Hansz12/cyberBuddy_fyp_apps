import 'package:equatable/equatable.dart';

class LearningModule extends Equatable {
  final String title;
  final String topic;
  final String difficulty;
  final String content;
  final int xpReward;
  final bool completed;

  const LearningModule({
    required this.title,
    required this.topic,
    required this.difficulty,
    required this.content,
    required this.xpReward,
    this.completed = false,
  });

  LearningModule copyWith({bool? completed}) {
    return LearningModule(
      title: title,
      topic: topic,
      difficulty: difficulty,
      content: content,
      xpReward: xpReward,
      completed: completed ?? this.completed,
    );
  }

  @override
  List<Object> get props => [
    title,
    topic,
    difficulty,
    content,
    xpReward,
    completed,
  ];
}

class LearningState extends Equatable {
  final List<LearningModule> modules;

  const LearningState({this.modules = const []});

  LearningState copyWith({List<LearningModule>? modules}) {
    return LearningState(modules: modules ?? this.modules);
  }

  @override
  List<Object> get props => [modules];
}
