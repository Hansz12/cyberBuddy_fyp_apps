import 'package:equatable/equatable.dart';

class HomeState extends Equatable {
  final int xp;
  final int level;
  final List<String> recommendedModules;
  final Map<String, double> topicScores;
  final int streak;
  final List<String> badges;
  final DateTime? lastActiveDate;

  const HomeState({
    this.xp = 0,
    this.level = 1,
    this.recommendedModules = const [],
    this.topicScores = const {"phishing": 0.5, "password": 0.5, "social": 0.5},
    this.streak = 0,
    this.badges = const [],
    this.lastActiveDate,
  });

  HomeState copyWith({
    int? xp,
    int? level,
    List<String>? recommendedModules,
    Map<String, double>? topicScores,
    int? streak,
    List<String>? badges,
    DateTime? lastActiveDate,
  }) {
    return HomeState(
      xp: xp ?? this.xp,
      level: level ?? this.level,
      recommendedModules: recommendedModules ?? this.recommendedModules,
      topicScores: topicScores ?? this.topicScores,
      streak: streak ?? this.streak,
      badges: badges ?? this.badges,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    );
  }

  @override
  List<Object?> get props => [
    xp,
    level,
    recommendedModules,
    topicScores,
    streak,
    badges,
    lastActiveDate,
  ];
}
