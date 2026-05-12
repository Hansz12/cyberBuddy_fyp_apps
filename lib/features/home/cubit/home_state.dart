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
  final Map<String, int> topicAnswered;
  final Map<String, int> topicCorrect;

  final int totalQuestionsAnswered;
  final int totalCorrectAnswers;
  final int quizzesCompleted;
  final int perfectQuizzes;
  final int threatChecks;

  final int dailyModulesCompleted;
  final int dailyQuizAttempts;
  final int dailyTopicsTried;
  final int dailyThreatChecks;
  final int dailyBestQuizScore;
  final DateTime? dailyQuestDate;

  final List<String> claimedDailyQuests;

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
      "phishing": 0.0,
      "password": 0.0,
      "social": 0.0,
      "malware": 0.0,
      "privacy": 0.0,
      "scam": 0.0,
      "mobile": 0.0,
      "network": 0.0,
      "ethics": 0.0,
      "banking": 0.0,
    },
    this.topicAnswered = const {
      "phishing": 0,
      "password": 0,
      "social": 0,
      "malware": 0,
      "privacy": 0,
      "scam": 0,
      "mobile": 0,
      "network": 0,
      "ethics": 0,
      "banking": 0,
    },
    this.topicCorrect = const {
      "phishing": 0,
      "password": 0,
      "social": 0,
      "malware": 0,
      "privacy": 0,
      "scam": 0,
      "mobile": 0,
      "network": 0,
      "ethics": 0,
      "banking": 0,
    },
    this.totalQuestionsAnswered = 0,
    this.totalCorrectAnswers = 0,
    this.quizzesCompleted = 0,
    this.perfectQuizzes = 0,
    this.threatChecks = 0,
    this.dailyModulesCompleted = 0,
    this.dailyQuizAttempts = 0,
    this.dailyTopicsTried = 0,
    this.dailyThreatChecks = 0,
    this.dailyBestQuizScore = 0,
    this.dailyQuestDate,
    this.claimedDailyQuests = const [],
    this.moduleScores = const {},
    this.moduleReasons = const {},
    this.lastActiveDate,
  });

  int get avgScore {
    if (totalQuestionsAnswered == 0) return 0;
    return ((totalCorrectAnswers / totalQuestionsAnswered) * 100).round();
  }

  double topicProgress(String topic) {
    final key = topic.toLowerCase();
    final answered = topicAnswered[key] ?? 0;
    final correct = topicCorrect[key] ?? 0;

    if (answered == 0) return 0.0;

    return (correct / answered).clamp(0.0, 1.0);
  }

  String get weakestTopic {
    if (topicAnswered.values.every((count) => count == 0)) {
      return "Not enough quiz data";
    }

    final attemptedTopics = topicAnswered.entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .toList();

    attemptedTopics.sort(
      (a, b) => topicProgress(a).compareTo(topicProgress(b)),
    );

    return attemptedTopics.isEmpty
        ? "Not enough quiz data"
        : attemptedTopics.first;
  }

  String get strongestTopic {
    if (topicAnswered.values.every((count) => count == 0)) {
      return "Not enough quiz data";
    }

    final attemptedTopics = topicAnswered.entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .toList();

    attemptedTopics.sort(
      (a, b) => topicProgress(b).compareTo(topicProgress(a)),
    );

    return attemptedTopics.isEmpty
        ? "Not enough quiz data"
        : attemptedTopics.first;
  }

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
    Map<String, int>? topicAnswered,
    Map<String, int>? topicCorrect,
    int? totalQuestionsAnswered,
    int? totalCorrectAnswers,
    int? quizzesCompleted,
    int? perfectQuizzes,
    int? threatChecks,
    int? dailyModulesCompleted,
    int? dailyQuizAttempts,
    int? dailyTopicsTried,
    int? dailyThreatChecks,
    int? dailyBestQuizScore,
    DateTime? dailyQuestDate,
    bool clearDailyQuestDate = false,
    List<String>? claimedDailyQuests,
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
      topicAnswered: topicAnswered ?? this.topicAnswered,
      topicCorrect: topicCorrect ?? this.topicCorrect,
      totalQuestionsAnswered:
          totalQuestionsAnswered ?? this.totalQuestionsAnswered,
      totalCorrectAnswers: totalCorrectAnswers ?? this.totalCorrectAnswers,
      quizzesCompleted: quizzesCompleted ?? this.quizzesCompleted,
      perfectQuizzes: perfectQuizzes ?? this.perfectQuizzes,
      threatChecks: threatChecks ?? this.threatChecks,
      dailyModulesCompleted:
          dailyModulesCompleted ?? this.dailyModulesCompleted,
      dailyQuizAttempts: dailyQuizAttempts ?? this.dailyQuizAttempts,
      dailyTopicsTried: dailyTopicsTried ?? this.dailyTopicsTried,
      dailyThreatChecks: dailyThreatChecks ?? this.dailyThreatChecks,
      dailyBestQuizScore: dailyBestQuizScore ?? this.dailyBestQuizScore,
      dailyQuestDate: clearDailyQuestDate
          ? null
          : dailyQuestDate ?? this.dailyQuestDate,
      claimedDailyQuests: claimedDailyQuests ?? this.claimedDailyQuests,
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
    topicAnswered,
    topicCorrect,
    totalQuestionsAnswered,
    totalCorrectAnswers,
    quizzesCompleted,
    perfectQuizzes,
    threatChecks,
    dailyModulesCompleted,
    dailyQuizAttempts,
    dailyTopicsTried,
    dailyThreatChecks,
    dailyBestQuizScore,
    dailyQuestDate,
    claimedDailyQuests,
    moduleScores,
    moduleReasons,
    lastActiveDate,
  ];
}
