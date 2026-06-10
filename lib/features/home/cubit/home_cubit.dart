import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/repositories/leaderboard_repository.dart';
import '../../../data/repositories/user_progress_repository.dart';
import '../../../data/services/local_data_service.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeState());

  final UserProgressRepository _progressRepository = UserProgressRepository();
  final LeaderboardRepository _leaderboardRepository = LeaderboardRepository();
  final LocalDataService _dataService = LocalDataService();

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
            last3Scores: _mapIntList(cloudData['last3Scores']),
            perfectQuizzes: cloudData['perfectQuizzes'] ?? 0,
            threatChecks: cloudData['threatChecks'] ?? 0,
            dailyModulesCompleted: cloudData['dailyModulesCompleted'] ?? 0,
            dailyQuizAttempts: cloudData['dailyQuizAttempts'] ?? 0,
            dailyTopicsTried: cloudData['dailyTopicsTried'] ?? 0,
            dailyBestQuizScore: cloudData['dailyBestQuizScore'] ?? 0,
            dailyQuestDate: _parseDate(cloudData['dailyQuestDate']),
            claimedDailyQuests: List<String>.from(
              cloudData['claimedDailyQuests'] ?? [],
            ),
            rewardedNewsUrls: List<String>.from(
              cloudData['rewardedNewsUrls'] ?? [],
            ),
            recommendationScores: _mapDouble(
              cloudData['recommendationScores'],
              const {},
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

  List<int> _mapIntList(dynamic raw) {
    if (raw == null) return const [];

    return List<dynamic>.from(raw)
        .map((value) => int.tryParse(value.toString()) ?? 0)
        .toList();
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
        last3Scores: _decodeIntList(prefs.getString(_key('last3Scores'))),
        perfectQuizzes: prefs.getInt(_key('perfectQuizzes')) ?? 0,
        threatChecks: prefs.getInt(_key('threatChecks')) ?? 0,
        dailyModulesCompleted: prefs.getInt(_key('dailyModulesCompleted')) ?? 0,
        dailyQuizAttempts: prefs.getInt(_key('dailyQuizAttempts')) ?? 0,
        dailyTopicsTried: prefs.getInt(_key('dailyTopicsTried')) ?? 0,
        dailyBestQuizScore: prefs.getInt(_key('dailyBestQuizScore')) ?? 0,
        claimedDailyQuests:
            prefs.getStringList(_key('claimedDailyQuests')) ?? [],
        rewardedNewsUrls: prefs.getStringList(_key('rewardedNewsUrls')) ?? [],
        recommendationScores: _decodeDoubleMap(
          prefs.getString(_key('recommendationScores')),
          const {},
        ),
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

  List<int> _decodeIntList(String? json) {
    if (json == null) return const [];

    final decoded = jsonDecode(json) as List<dynamic>;

    return decoded
        .map((value) => int.tryParse(value.toString()) ?? 0)
        .toList();
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

  List<int> _last3ScoresWith(int quizScore) {
    final scores = List<int>.from(state.last3Scores)..add(quizScore);

    if (scores.length <= 3) return scores;

    return scores.sublist(scores.length - 3);
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

    final last3Scores = _last3ScoresWith(quizScore);

    emit(
      state.copyWith(
        quizzesCompleted: state.quizzesCompleted + 1,
        last3Scores: last3Scores,
        perfectQuizzes: state.perfectQuizzes + (isPerfect ? 1 : 0),
        dailyQuizAttempts: state.dailyQuizAttempts + 1,
        dailyBestQuizScore: max(state.dailyBestQuizScore, quizScore),
      ),
    );

    _checkBadges();

    await _saveAllProgress();
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
      'last3Scores',
      'perfectQuizzes',
      'threatChecks',
      'dailyModulesCompleted',
      'dailyQuizAttempts',
      'dailyTopicsTried',
      'dailyBestQuizScore',
      'dailyQuestDate',
      'claimedDailyQuests',
      'rewardedNewsUrls',
      'recommendationScores',
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

  void _generateRecommendation() async {
    if (state.totalQuestionsAnswered == 0) {
      emit(
        state.copyWith(
          recommendedModules: const [],
          recommendedModuleIds: const [],
          moduleScores: const {},
          moduleReasons: const {},
          recommendationScores: const {},
        ),
      );
      return;
    }

    try {
      final modules = await _dataService.loadModules();

      final completedIds = state.completedModules
          .map((id) => id.toUpperCase())
          .toSet();

      final scoredModules = <Map<String, dynamic>>[];

      for (final module in modules) {
        final moduleId =
            module['module_id']?.toString() ?? module['id']?.toString() ?? '';

        if (moduleId.isEmpty || completedIds.contains(moduleId.toUpperCase())) {
          continue;
        }

        final title = module['title']?.toString() ?? 'Untitled Module';
        final topic = _normaliseTopic(module['topic']?.toString() ?? '');
        final difficulty = module['difficulty']?.toString() ?? 'Beginner';
        final xpReward = int.tryParse(module['xp_reward'].toString()) ?? 20;

        final answered = state.topicAnswered[topic] ?? 0;
        final correct = state.topicCorrect[topic] ?? 0;

        final accuracy = answered == 0 ? 0.0 : correct / answered;
        final weaknessScore = answered == 0 ? 0.35 : 1.0 - accuracy;

        final difficultyBoost = _difficultyProgressionBoost(
          difficulty: difficulty,
          topicAccuracy: accuracy,
          answered: answered,
        );
        final xpBoost = xpReward / 1000;

        final finalScore = weaknessScore + difficultyBoost + xpBoost;

        scoredModules.add({
          'id': moduleId,
          'title': title,
          'topic': topic,
          'difficulty': difficulty,
          'answered': answered,
          'accuracy': accuracy,
          'score': finalScore,
        });
      }

      scoredModules.sort(
        (a, b) => (b['score'] as double).compareTo(a['score'] as double),
      );

      final topModules = scoredModules.take(3).toList();

      final recommendedModules = <String>[];
      final recommendedModuleIds = <String>[];
      final moduleReasons = <String, String>{};
      final moduleScores = <String, double>{};
      final recommendationScores = <String, double>{};

      for (final module in topModules) {
        final title = module['title'].toString();
        final id = module['id'].toString();
        final topic = module['topic'].toString();
        final answered = module['answered'] as int;
        final accuracy = module['accuracy'] as double;
        final percent = (accuracy * 100).round();
        final recommendationScore = (100 - (accuracy * 100))
            .clamp(0, 100)
            .toDouble();

        recommendedModules.add(title);
        recommendedModuleIds.add(id);
        moduleScores[title] = module['score'] as double;
        recommendationScores[id] = recommendationScore;

        if (answered > 0) {
          moduleReasons[title] =
              'Recommended because your $topic quiz score is $percent%. This module targets your weaker area.';
        } else {
          moduleReasons[title] =
              'Recommended to expand your cybersecurity coverage in $topic.';
        }
      }

      emit(
        state.copyWith(
          recommendedModules: recommendedModules,
          recommendedModuleIds: recommendedModuleIds,
          moduleReasons: moduleReasons,
          moduleScores: moduleScores,
          recommendationScores: recommendationScores,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          recommendedModules: const [],
          recommendedModuleIds: const [],
          moduleReasons: const {},
          moduleScores: const {},
          recommendationScores: const {},
        ),
      );
    }
  }

  String _normaliseTopic(String topic) {
    final t = topic.toLowerCase().trim();

    if (t.contains('phishing')) return 'phishing';
    if (t.contains('password') || t.contains('2fa') || t.contains('mfa')) {
      return 'password';
    }
    if (t.contains('malware') || t.contains('usb')) return 'malware';
    if (t.contains('privacy') || t.contains('breach') || t.contains('cloud')) {
      return 'privacy';
    }
    if (t.contains('scam') || t.contains('banking')) return 'scam';
    if (t.contains('mobile')) return 'mobile';
    if (t.contains('network') || t.contains('wifi') || t.contains('wi-fi')) {
      return 'network';
    }
    if (t.contains('social')) return 'social';
    if (t.contains('ethics') || t.contains('law')) return 'ethics';

    return t;
  }

  int _difficultyWeight(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return 1;
      case 'intermediate':
        return 2;
      case 'advanced':
        return 3;
      default:
        return 1;
    }
  }

  double _difficultyProgressionBoost({
    required String difficulty,
    required double topicAccuracy,
    required int answered,
  }) {
    final level = _difficultyWeight(difficulty);

    if (answered == 0) {
      if (level == 1) return 0.12;
      if (level == 2) return 0.07;
      return 0.03;
    }

    if (topicAccuracy < 0.6) {
      if (level == 1) return 0.15;
      if (level == 2) return 0.08;
      return 0.02;
    }

    if (topicAccuracy >= 0.8) {
      if (level == 2) return 0.15;
      if (level == 3) return 0.10;
      return 0.04;
    }

    if (level == 2) return 0.10;
    return 0.05;
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

      final topic = rawTopic.isEmpty ? 'general' : _normaliseTopic(rawTopic);
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
    final last3Scores = _last3ScoresWith(quizScore);

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
        last3Scores: last3Scores,
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
        last3Scores: state.last3Scores,
        perfectQuizzes: state.perfectQuizzes,
        threatChecks: state.threatChecks,
        dailyModulesCompleted: state.dailyModulesCompleted,
        dailyQuizAttempts: state.dailyQuizAttempts,
        dailyTopicsTried: state.dailyTopicsTried,
        dailyBestQuizScore: state.dailyBestQuizScore,
        dailyQuestDate: state.dailyQuestDate,
        claimedDailyQuests: state.claimedDailyQuests,
        rewardedNewsUrls: state.rewardedNewsUrls,
        recommendationScores: state.recommendationScores,
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

    await prefs.setString(
      _key('recommendationScores'),
      jsonEncode(state.recommendationScores),
    );

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
    await prefs.setString(_key('last3Scores'), jsonEncode(state.last3Scores));
    await prefs.setInt(_key('perfectQuizzes'), state.perfectQuizzes);
    await prefs.setInt(_key('threatChecks'), state.threatChecks);

    await prefs.setInt(
      _key('dailyModulesCompleted'),
      state.dailyModulesCompleted,
    );

    await prefs.setInt(_key('dailyQuizAttempts'), state.dailyQuizAttempts);
    await prefs.setInt(_key('dailyTopicsTried'), state.dailyTopicsTried);
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
