import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/repositories/leaderboard_repository.dart';
import '../../../data/repositories/user_progress_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeState());

  final UserProgressRepository _progressRepository = UserProgressRepository();
  final LeaderboardRepository _leaderboardRepository = LeaderboardRepository();

  String? _activeUid;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  String _key(String name) {
    final uid = _uid;
    if (uid == null) return name;
    return '${uid}_$name';
  }

  bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  void clearSession() {
    _activeUid = null;
    emit(const HomeState());
  }

  Future<void> loadUserData() async {
    final uid = _uid;

    emit(const HomeState());

    if (uid == null) {
      _activeUid = null;
      return;
    }

    _activeUid = uid;

    try {
      final cloudData = await _progressRepository.loadProgress();

      if (_activeUid != uid) return;

      if (cloudData != null) {
        emit(
          state.copyWith(
            xp: cloudData['xp'] ?? 0,
            level: cloudData['level'] ?? 1,
            streak: cloudData['streak'] ?? 0,
            badges: List<String>.from(cloudData['badges'] ?? []),
            completedModules: List<String>.from(
              cloudData['completedModules'] ?? [],
            ),
            topicScores: _mapDouble(
              cloudData['topicScores'],
              const HomeState().topicScores,
            ),
            topicAnswered: _mapInt(
              cloudData['topicAnswered'],
              const HomeState().topicAnswered,
            ),
            topicCorrect: _mapInt(
              cloudData['topicCorrect'],
              const HomeState().topicCorrect,
            ),
            totalQuestionsAnswered: cloudData['totalQuestionsAnswered'] ?? 0,
            totalCorrectAnswers: cloudData['totalCorrectAnswers'] ?? 0,
            quizzesCompleted: cloudData['quizzesCompleted'] ?? 0,
            perfectQuizzes: cloudData['perfectQuizzes'] ?? 0,
            threatChecks: cloudData['threatChecks'] ?? 0,
            dailyModulesCompleted: cloudData['dailyModulesCompleted'] ?? 0,
            dailyQuizAttempts: cloudData['dailyQuizAttempts'] ?? 0,
            dailyTopicsTried: cloudData['dailyTopicsTried'] ?? 0,
            dailyThreatChecks: cloudData['dailyThreatChecks'] ?? 0,
            dailyBestQuizScore: cloudData['dailyBestQuizScore'] ?? 0,
            dailyQuestDate: _parseDate(cloudData['dailyQuestDate']),
            claimedDailyQuests: List<String>.from(
              cloudData['claimedDailyQuests'] ?? [],
            ),
            rewardedNewsUrls: List<String>.from(
              cloudData['rewardedNewsUrls'] ?? [],
            ),
            notifications: List<String>.from(cloudData['notifications'] ?? []),
            hasUnreadNotifications:
                cloudData['hasUnreadNotifications'] ?? false,
            lastActiveDate: _parseDate(cloudData['lastActiveDate']),
          ),
        );

        _resetDailyQuestIfNeeded();
        updateStreak();
        _checkBadges();
        _generateRecommendation();

        await _saveLocalProgress();
        await _saveLeaderboard();
        return;
      }

      emit(const HomeState());
      _resetDailyQuestIfNeeded();
      await _saveAllProgress();
    } catch (_) {
      if (_activeUid == uid) {
        await _loadLocalProgress();
      }
    }
  }

  void _resetDailyQuestIfNeeded() {
    final today = DateTime.now();

    if (_isSameDay(state.dailyQuestDate, today)) return;

    emit(
      state.copyWith(
        dailyModulesCompleted: 0,
        dailyQuizAttempts: 0,
        dailyTopicsTried: 0,
        dailyThreatChecks: 0,
        dailyBestQuizScore: 0,
        claimedDailyQuests: const [],
        dailyQuestDate: today,
      ),
    );
  }

  Map<String, double> _mapDouble(dynamic raw, Map<String, double> fallback) {
    if (raw == null) return fallback;

    final data = Map<String, dynamic>.from(raw);
    final defaults = Map<String, double>.from(fallback);

    data.forEach((key, value) {
      defaults[key] = value is num ? value.toDouble() : 0.0;
    });

    return defaults;
  }

  Map<String, int> _mapInt(dynamic raw, Map<String, int> fallback) {
    if (raw == null) return fallback;

    final data = Map<String, dynamic>.from(raw);
    final defaults = Map<String, int>.from(fallback);

    data.forEach((key, value) {
      defaults[key] = int.tryParse(value.toString()) ?? 0;
    });

    return defaults;
  }

  Future<void> _loadLocalProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = _uid;

    if (uid == null || _activeUid != uid) {
      emit(const HomeState());
      return;
    }

    emit(
      state.copyWith(
        xp: prefs.getInt(_key('xp')) ?? 0,
        level: prefs.getInt(_key('level')) ?? 1,
        streak: prefs.getInt(_key('streak')) ?? 0,
        badges: prefs.getStringList(_key('badges')) ?? [],
        completedModules: prefs.getStringList(_key('completedModules')) ?? [],
        notifications: prefs.getStringList(_key('notifications')) ?? [],
        hasUnreadNotifications:
            prefs.getBool(_key('hasUnreadNotifications')) ?? false,
        topicScores: _decodeDoubleMap(
          prefs.getString(_key('topicScores')),
          const HomeState().topicScores,
        ),
        topicAnswered: _decodeIntMap(
          prefs.getString(_key('topicAnswered')),
          const HomeState().topicAnswered,
        ),
        topicCorrect: _decodeIntMap(
          prefs.getString(_key('topicCorrect')),
          const HomeState().topicCorrect,
        ),
        totalQuestionsAnswered:
            prefs.getInt(_key('totalQuestionsAnswered')) ?? 0,
        totalCorrectAnswers: prefs.getInt(_key('totalCorrectAnswers')) ?? 0,
        quizzesCompleted: prefs.getInt(_key('quizzesCompleted')) ?? 0,
        perfectQuizzes: prefs.getInt(_key('perfectQuizzes')) ?? 0,
        threatChecks: prefs.getInt(_key('threatChecks')) ?? 0,
        dailyModulesCompleted: prefs.getInt(_key('dailyModulesCompleted')) ?? 0,
        dailyQuizAttempts: prefs.getInt(_key('dailyQuizAttempts')) ?? 0,
        dailyTopicsTried: prefs.getInt(_key('dailyTopicsTried')) ?? 0,
        dailyThreatChecks: prefs.getInt(_key('dailyThreatChecks')) ?? 0,
        dailyBestQuizScore: prefs.getInt(_key('dailyBestQuizScore')) ?? 0,
        claimedDailyQuests:
            prefs.getStringList(_key('claimedDailyQuests')) ?? [],
        rewardedNewsUrls: prefs.getStringList(_key('rewardedNewsUrls')) ?? [],
        dailyQuestDate: prefs.getString(_key('dailyQuestDate')) == null
            ? null
            : DateTime.tryParse(prefs.getString(_key('dailyQuestDate'))!),
        lastActiveDate: prefs.getString(_key('lastActiveDate')) == null
            ? null
            : DateTime.tryParse(prefs.getString(_key('lastActiveDate'))!),
      ),
    );

    _resetDailyQuestIfNeeded();
    updateStreak();
    _checkBadges();
    _generateRecommendation();

    await _saveAllProgress();
  }

  Map<String, double> _decodeDoubleMap(
    String? json,
    Map<String, double> fallback,
  ) {
    if (json == null) return fallback;

    final decoded = jsonDecode(json) as Map<String, dynamic>;
    final defaults = Map<String, double>.from(fallback);

    decoded.forEach((key, value) {
      defaults[key] = value is num ? value.toDouble() : 0.0;
    });

    return defaults;
  }

  Map<String, int> _decodeIntMap(String? json, Map<String, int> fallback) {
    if (json == null) return fallback;

    final decoded = jsonDecode(json) as Map<String, dynamic>;
    final defaults = Map<String, int>.from(fallback);

    decoded.forEach((key, value) {
      defaults[key] = int.tryParse(value.toString()) ?? 0;
    });

    return defaults;
  }

  Future<void> recordModuleCompleted(String moduleId) async {
    if (moduleId.isEmpty) return;

    _resetDailyQuestIfNeeded();

    final completed = List<String>.from(state.completedModules);

    if (!completed.contains(moduleId)) {
      completed.add(moduleId);

      emit(
        state.copyWith(
          completedModules: completed,
          dailyModulesCompleted: state.dailyModulesCompleted + 1,
        ),
      );

      await _saveAllProgress();
    }
  }

  Future<void> recordQuizAnswer(String topic, bool correct) async {
    _resetDailyQuestIfNeeded();

    final key = topic.toLowerCase().trim().isEmpty
        ? 'general'
        : topic.toLowerCase().trim();

    final topicAnswered = Map<String, int>.from(state.topicAnswered);
    final topicCorrect = Map<String, int>.from(state.topicCorrect);
    final topicScores = Map<String, double>.from(state.topicScores);

    final wasNewTopicToday = (topicAnswered[key] ?? 0) == 0;

    topicAnswered[key] = (topicAnswered[key] ?? 0) + 1;
    topicCorrect[key] = (topicCorrect[key] ?? 0) + (correct ? 1 : 0);

    final answered = topicAnswered[key] ?? 0;
    final correctCount = topicCorrect[key] ?? 0;

    topicScores[key] = answered == 0 ? 0.0 : correctCount / answered;

    emit(
      state.copyWith(
        topicAnswered: topicAnswered,
        topicCorrect: topicCorrect,
        topicScores: topicScores,
        totalQuestionsAnswered: state.totalQuestionsAnswered + 1,
        totalCorrectAnswers: state.totalCorrectAnswers + (correct ? 1 : 0),
        dailyTopicsTried: state.dailyTopicsTried + (wasNewTopicToday ? 1 : 0),
      ),
    );

    _generateRecommendation();
    _checkBadges();

    await _saveAllProgress();
  }

  Future<void> recordQuizCompleted({
    required int totalQuestions,
    required int correctAnswers,
  }) async {
    _resetDailyQuestIfNeeded();

    final isPerfect = totalQuestions > 0 && totalQuestions == correctAnswers;

    final quizScore = totalQuestions == 0
        ? 0
        : ((correctAnswers / totalQuestions) * 100).round();

    emit(
      state.copyWith(
        quizzesCompleted: state.quizzesCompleted + 1,
        perfectQuizzes: state.perfectQuizzes + (isPerfect ? 1 : 0),
        dailyQuizAttempts: state.dailyQuizAttempts + 1,
        dailyBestQuizScore: max(state.dailyBestQuizScore, quizScore),
      ),
    );

    _checkBadges();

    await _saveAllProgress();
  }

  Future<void> recordThreatCheck() async {
    _resetDailyQuestIfNeeded();

    emit(
      state.copyWith(
        threatChecks: state.threatChecks + 1,
        dailyThreatChecks: state.dailyThreatChecks + 1,
      ),
    );

    _checkBadges();

    await gainXP(10);
  }

  Future<void> updateTopicScore(String topic, bool correct) async {
    await recordQuizAnswer(topic, correct);
  }

  Future<void> gainXP(int value) async {
    _resetDailyQuestIfNeeded();

    final newXP = state.xp + value;
    final newLevel = (newXP ~/ 100) + 1;

    final updatedNotifications = List<String>.from(state.notifications)
      ..insert(0, "You gained +$value XP.");

    emit(
      state.copyWith(
        xp: newXP,
        level: newLevel,
        notifications: updatedNotifications,
        hasUnreadNotifications: true,
      ),
    );

    updateStreak();
    _checkBadges();
    _generateRecommendation();

    await _saveAllProgress();
  }

  Future<void> claimDailyQuest({
    required String questId,
    required int xpReward,
  }) async {
    _resetDailyQuestIfNeeded();

    if (state.claimedDailyQuests.contains(questId)) return;

    final updatedClaimed = List<String>.from(state.claimedDailyQuests)
      ..add(questId);

    final newXP = state.xp + xpReward;
    final newLevel = (newXP ~/ 100) + 1;

    final updatedNotifications = List<String>.from(state.notifications)
      ..insert(0, "Daily quest claimed: +$xpReward XP.");

    emit(
      state.copyWith(
        xp: newXP,
        level: newLevel,
        claimedDailyQuests: updatedClaimed,
        notifications: updatedNotifications,
        hasUnreadNotifications: true,
      ),
    );

    updateStreak();
    _checkBadges();
    _generateRecommendation();

    await _saveAllProgress();
  }

  Future<bool> rewardNewsRead(String url) async {
    final cleanUrl = url.trim();

    if (cleanUrl.isEmpty) return false;

    if (state.rewardedNewsUrls.contains(cleanUrl)) {
      return false;
    }

    final updatedRewardedUrls = List<String>.from(state.rewardedNewsUrls)
      ..add(cleanUrl);

    final newXP = state.xp + 5;
    final newLevel = (newXP ~/ 100) + 1;

    final updatedNotifications = List<String>.from(state.notifications)
      ..insert(0, "You earned +5 XP for reading cybersecurity news.");

    emit(
      state.copyWith(
        xp: newXP,
        level: newLevel,
        rewardedNewsUrls: updatedRewardedUrls,
        notifications: updatedNotifications,
        hasUnreadNotifications: true,
      ),
    );

    updateStreak();
    _checkBadges();
    _generateRecommendation();

    await _saveAllProgress();

    return true;
  }

  Future<void> addNotification(String message) async {
    final updatedNotifications = List<String>.from(state.notifications)
      ..insert(0, message);

    emit(
      state.copyWith(
        notifications: updatedNotifications,
        hasUnreadNotifications: true,
      ),
    );

    await _saveAllProgress();
  }

  Future<void> markNotificationsAsRead() async {
    emit(state.copyWith(hasUnreadNotifications: false));
    await _saveAllProgress();
  }

  void updateStreak() {
    final today = DateTime.now();

    if (state.lastActiveDate == null) {
      emit(state.copyWith(streak: 1, lastActiveDate: today));
      return;
    }

    final lastDate = state.lastActiveDate!;

    final lastOnlyDate = DateTime(lastDate.year, lastDate.month, lastDate.day);
    final todayOnlyDate = DateTime(today.year, today.month, today.day);

    final difference = todayOnlyDate.difference(lastOnlyDate).inDays;

    if (difference == 0) return;

    if (difference == 1) {
      emit(state.copyWith(streak: state.streak + 1, lastActiveDate: today));
    } else {
      emit(state.copyWith(streak: 1, lastActiveDate: today));
    }
  }

  void _checkBadges() {
    final updatedBadges = List<String>.from(state.badges);
    final updatedNotifications = List<String>.from(state.notifications);

    bool hasNewNotification = false;

    void unlockBadge(String badgeName) {
      if (!updatedBadges.contains(badgeName)) {
        updatedBadges.add(badgeName);
        updatedNotifications.insert(0, "Badge unlocked: $badgeName.");
        hasNewNotification = true;
      }
    }

    if (state.totalQuestionsAnswered > 0 || state.xp > 0) {
      unlockBadge("Rookie Badge");
    }

    if (state.xp >= 100) unlockBadge("Beginner Defender");
    if (state.xp >= 300) unlockBadge("Intermediate Defender");
    if (state.xp >= 500) unlockBadge("Cyber Hero");
    if (state.xp >= 1000) unlockBadge("Cyber Champion");

    if (state.streak >= 3) unlockBadge("Consistent Learner");
    if (state.streak >= 7) unlockBadge("7-Day Streak");

    if (state.quizzesCompleted >= 1) unlockBadge("Quiz Starter");
    if (state.quizzesCompleted >= 5) unlockBadge("Quiz Master");
    if (state.perfectQuizzes >= 1) unlockBadge("Perfect Score");

    if (state.topicProgress("phishing") >= 0.7) {
      unlockBadge("Phishing Shield");
    }

    if (state.topicProgress("password") >= 0.8) {
      unlockBadge("Password Pro");
    }

    if (state.topicProgress("malware") >= 0.7) {
      unlockBadge("Malware Hunter");
    }

    if (state.topicProgress("privacy") >= 0.7) {
      unlockBadge("Privacy Guardian");
    }

    if (state.threatChecks >= 5) {
      unlockBadge("Threat Spotter");
    }

    emit(
      state.copyWith(
        badges: updatedBadges,
        notifications: updatedNotifications,
        hasUnreadNotifications: hasNewNotification
            ? true
            : state.hasUnreadNotifications,
      ),
    );
  }

  Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();

    final keys = [
      'xp',
      'level',
      'streak',
      'badges',
      'completedModules',
      'notifications',
      'hasUnreadNotifications',
      'topicScores',
      'topicAnswered',
      'topicCorrect',
      'totalQuestionsAnswered',
      'totalCorrectAnswers',
      'quizzesCompleted',
      'perfectQuizzes',
      'threatChecks',
      'dailyModulesCompleted',
      'dailyQuizAttempts',
      'dailyTopicsTried',
      'dailyThreatChecks',
      'dailyBestQuizScore',
      'dailyQuestDate',
      'claimedDailyQuests',
      'rewardedNewsUrls',
      'lastActiveDate',
    ];

    for (final key in keys) {
      await prefs.remove(_key(key));
    }

    try {
      await _progressRepository.resetProgress();
    } catch (_) {}

    emit(const HomeState());

    await _saveLocalProgress();
    await _saveLeaderboard();
  }

  void _generateRecommendation() {
    if (state.totalQuestionsAnswered == 0) {
      emit(
        state.copyWith(
          recommendedModules: const [],
          moduleScores: const {},
          moduleReasons: const {},
        ),
      );
      return;
    }

    final weakestTopic = state.weakestTopic.toLowerCase().trim();

    final allModules = [
      {"title": "Phishing Awareness", "topic": "phishing"},
      {"title": "Password Security", "topic": "password"},
      {"title": "Social Engineering", "topic": "social"},
      {"title": "Malware & Safe Downloads", "topic": "malware"},
      {"title": "Privacy Protection", "topic": "privacy"},
      {"title": "Online Scam Awareness", "topic": "scam"},
      {"title": "Mobile Device Security", "topic": "mobile"},
      {"title": "Public Wi-Fi Safety", "topic": "network"},
      {"title": "Two-Factor Authentication", "topic": "password"},
      {"title": "Data Breach Response", "topic": "privacy"},
      {"title": "Cyberbullying & Digital Ethics", "topic": "ethics"},
      {"title": "Safe Online Banking", "topic": "banking"},
    ];

    final matchedModules = allModules.where((module) {
      final topic = module["topic"]!.toLowerCase().trim();

      return topic.contains(weakestTopic) || weakestTopic.contains(topic);
    }).toList();

    final fallbackModules = allModules.where((module) {
      final title = module["title"]!;
      return !matchedModules.any((matched) => matched["title"] == title);
    }).toList();

    final recommended = [
      ...matchedModules,
      ...fallbackModules,
    ].take(3).toList();

    final moduleReasons = <String, String>{};
    final moduleScores = <String, double>{};

    for (final module in recommended) {
      final title = module["title"]!;
      final topic = module["topic"]!;

      if (topic.contains(weakestTopic) || weakestTopic.contains(topic)) {
        moduleReasons[title] =
            "Recommended because your $weakestTopic quiz performance is lower.";
      } else {
        moduleReasons[title] =
            "Recommended to strengthen your overall cybersecurity awareness.";
      }

      moduleScores[title] = state.topicProgress(weakestTopic);
    }

    emit(
      state.copyWith(
        recommendedModules: recommended.map((e) => e["title"]!).toList(),
        moduleScores: moduleScores,
        moduleReasons: moduleReasons,
      ),
    );
  }

  Future<void> recordFullQuizResult({
    required int earnedXp,
    required List<Map<String, dynamic>> questions,
    required List<bool> answerResults,
    required int totalQuestions,
    required int correctAnswers,
  }) async {
    _resetDailyQuestIfNeeded();

    final topicAnswered = Map<String, int>.from(state.topicAnswered);
    final topicCorrect = Map<String, int>.from(state.topicCorrect);
    final topicScores = Map<String, double>.from(state.topicScores);

    int totalAnsweredAdd = 0;
    int totalCorrectAdd = 0;
    final newTopicsTodaySet = <String>{};

    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];

      final rawTopic = (question['topic'] ?? question['moduleId'] ?? 'general')
          .toString()
          .toLowerCase()
          .trim();

      final topic = rawTopic.isEmpty ? 'general' : rawTopic;
      final isCorrect = i < answerResults.length ? answerResults[i] : false;

      if ((topicAnswered[topic] ?? 0) == 0) {
        newTopicsTodaySet.add(topic);
      }

      topicAnswered[topic] = (topicAnswered[topic] ?? 0) + 1;
      topicCorrect[topic] = (topicCorrect[topic] ?? 0) + (isCorrect ? 1 : 0);

      final answered = topicAnswered[topic] ?? 0;
      final correct = topicCorrect[topic] ?? 0;

      topicScores[topic] = answered == 0 ? 0.0 : correct / answered;

      totalAnsweredAdd++;
      if (isCorrect) totalCorrectAdd++;
    }

    final quizScore = totalQuestions == 0
        ? 0
        : ((correctAnswers / totalQuestions) * 100).round();

    final isPerfect = totalQuestions > 0 && totalQuestions == correctAnswers;

    final newXP = state.xp + earnedXp;
    final newLevel = (newXP ~/ 100) + 1;

    final updatedNotifications = List<String>.from(state.notifications);

    if (earnedXp > 0) {
      updatedNotifications.insert(0, "You gained +$earnedXp XP.");
    }

    emit(
      state.copyWith(
        xp: newXP,
        level: newLevel,
        topicAnswered: topicAnswered,
        topicCorrect: topicCorrect,
        topicScores: topicScores,
        totalQuestionsAnswered: state.totalQuestionsAnswered + totalAnsweredAdd,
        totalCorrectAnswers: state.totalCorrectAnswers + totalCorrectAdd,
        quizzesCompleted: state.quizzesCompleted + 1,
        perfectQuizzes: state.perfectQuizzes + (isPerfect ? 1 : 0),
        dailyQuizAttempts: state.dailyQuizAttempts + 1,
        dailyBestQuizScore: max(state.dailyBestQuizScore, quizScore),
        dailyTopicsTried: state.dailyTopicsTried + newTopicsTodaySet.length,
        notifications: updatedNotifications,
        hasUnreadNotifications: earnedXp > 0
            ? true
            : state.hasUnreadNotifications,
      ),
    );

    updateStreak();
    _checkBadges();
    _generateRecommendation();

    await _saveAllProgress();
  }

  Future<void> _saveAllProgress() async {
    await _saveLocalProgress();

    try {
      await _progressRepository.saveProgress(
        xp: state.xp,
        level: state.level,
        streak: state.streak,
        badges: state.badges,
        topicScores: state.topicScores,
        topicAnswered: state.topicAnswered,
        topicCorrect: state.topicCorrect,
        totalQuestionsAnswered: state.totalQuestionsAnswered,
        totalCorrectAnswers: state.totalCorrectAnswers,
        quizzesCompleted: state.quizzesCompleted,
        perfectQuizzes: state.perfectQuizzes,
        threatChecks: state.threatChecks,
        dailyModulesCompleted: state.dailyModulesCompleted,
        dailyQuizAttempts: state.dailyQuizAttempts,
        dailyTopicsTried: state.dailyTopicsTried,
        dailyThreatChecks: state.dailyThreatChecks,
        dailyBestQuizScore: state.dailyBestQuizScore,
        dailyQuestDate: state.dailyQuestDate,
        claimedDailyQuests: state.claimedDailyQuests,
        rewardedNewsUrls: state.rewardedNewsUrls,
        lastActiveDate: state.lastActiveDate,
        notifications: state.notifications,
        hasUnreadNotifications: state.hasUnreadNotifications,
      );
    } catch (_) {}

    await _saveLeaderboard();
  }

  Future<void> _saveLeaderboard() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      await _leaderboardRepository.updateUser(
        userId: user.uid,
        name: user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : user.email ?? "User",
        xp: state.xp,
        level: state.level,
        streak: state.streak,
        badges: state.badges.length,
      );
    } catch (_) {}
  }

  Future<void> _saveLocalProgress() async {
    final prefs = await SharedPreferences.getInstance();

    if (_uid == null) return;

    await prefs.setInt(_key('xp'), state.xp);
    await prefs.setInt(_key('level'), state.level);
    await prefs.setInt(_key('streak'), state.streak);

    await prefs.setStringList(_key('badges'), state.badges);
    await prefs.setStringList(_key('completedModules'), state.completedModules);
    await prefs.setStringList(_key('notifications'), state.notifications);

    await prefs.setStringList(
      _key('claimedDailyQuests'),
      state.claimedDailyQuests,
    );

    await prefs.setStringList(_key('rewardedNewsUrls'), state.rewardedNewsUrls);

    await prefs.setBool(
      _key('hasUnreadNotifications'),
      state.hasUnreadNotifications,
    );

    await prefs.setString(_key('topicScores'), jsonEncode(state.topicScores));

    await prefs.setString(
      _key('topicAnswered'),
      jsonEncode(state.topicAnswered),
    );

    await prefs.setString(_key('topicCorrect'), jsonEncode(state.topicCorrect));

    await prefs.setInt(
      _key('totalQuestionsAnswered'),
      state.totalQuestionsAnswered,
    );

    await prefs.setInt(_key('totalCorrectAnswers'), state.totalCorrectAnswers);
    await prefs.setInt(_key('quizzesCompleted'), state.quizzesCompleted);
    await prefs.setInt(_key('perfectQuizzes'), state.perfectQuizzes);
    await prefs.setInt(_key('threatChecks'), state.threatChecks);

    await prefs.setInt(
      _key('dailyModulesCompleted'),
      state.dailyModulesCompleted,
    );

    await prefs.setInt(_key('dailyQuizAttempts'), state.dailyQuizAttempts);
    await prefs.setInt(_key('dailyTopicsTried'), state.dailyTopicsTried);
    await prefs.setInt(_key('dailyThreatChecks'), state.dailyThreatChecks);
    await prefs.setInt(_key('dailyBestQuizScore'), state.dailyBestQuizScore);

    if (state.dailyQuestDate != null) {
      await prefs.setString(
        _key('dailyQuestDate'),
        state.dailyQuestDate!.toIso8601String(),
      );
    }

    if (state.lastActiveDate != null) {
      await prefs.setString(
        _key('lastActiveDate'),
        state.lastActiveDate!.toIso8601String(),
      );
    }
  }
}
