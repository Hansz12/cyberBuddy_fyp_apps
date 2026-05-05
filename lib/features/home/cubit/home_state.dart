import 'package:equatable/equatable.dart';

class HomeState extends Equatable {
  final int xp;
  final int level;
  final int streak;

  final List<String> badges;
  final List<String> completedModules;
  final List<String> recommendedModules;
  final List<String> notifications;

  final bool hasUnreadNotifications;

  final Map<String, double> topicScores;
  final Map<String, double> moduleScores;
  final Map<String, String> moduleReasons;

  final DateTime? lastActiveDate;

  const HomeState({
    this.xp = 0,
    this.level = 1,
    this.streak = 0,
    this.badges = const [],
    this.completedModules = const [],
    this.recommendedModules = const [],
    this.notifications = const [],
    this.hasUnreadNotifications = false,
    this.topicScores = const {
      "phishing": 0.5,
      "password": 0.5,
      "social": 0.5,
      "malware": 0.5,
      "scam": 0.5,
      "mobile": 0.5,
    },
    this.moduleScores = const {},
    this.moduleReasons = const {},
    this.lastActiveDate,
  });

  HomeState copyWith({
    int? xp,
    int? level,
    int? streak,
    List<String>? badges,
    List<String>? completedModules,
    List<String>? recommendedModules,
    List<String>? notifications,
    bool? hasUnreadNotifications,
    Map<String, double>? topicScores,
    Map<String, double>? moduleScores,
    Map<String, String>? moduleReasons,
    DateTime? lastActiveDate,
    bool clearLastActiveDate = false,
  }) {
    return HomeState(
      xp: xp ?? this.xp,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      badges: badges ?? this.badges,
      completedModules: completedModules ?? this.completedModules,
      recommendedModules: recommendedModules ?? this.recommendedModules,
      notifications: notifications ?? this.notifications,
      hasUnreadNotifications:
          hasUnreadNotifications ?? this.hasUnreadNotifications,
      topicScores: topicScores ?? this.topicScores,
      moduleScores: moduleScores ?? this.moduleScores,
      moduleReasons: moduleReasons ?? this.moduleReasons,
      lastActiveDate: clearLastActiveDate
          ? null
          : lastActiveDate ?? this.lastActiveDate,
    );
  }

  @override
  List<Object?> get props => [
    xp,
    level,
    streak,
    badges,
    completedModules,
    recommendedModules,
    notifications,
    hasUnreadNotifications,
    topicScores,
    moduleScores,
    moduleReasons,
    lastActiveDate,
  ];
}
