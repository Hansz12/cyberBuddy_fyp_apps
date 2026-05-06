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

  final Map<String, List<double>> moduleVectors = {
    "Phishing Awareness": [1, 0, 0],
    "Password Security": [0, 1, 0],
    "Social Engineering": [0, 0, 1],
    "Malware & Safe Downloads": [0.4, 0.2, 0.8],
    "Privacy Protection": [0.2, 0.7, 0.4],
    "Online Scam Awareness": [0.8, 0.1, 0.9],
    "Mobile Device Security": [0.3, 0.4, 0.6],
    "Public Wi-Fi Safety": [0.6, 0.2, 0.5],
    "Two-Factor Authentication": [0.2, 1, 0.2],
    "Data Breach Response": [0.4, 0.7, 0.5],
    "Cyberbullying & Digital Ethics": [0.1, 0.2, 0.9],
    "Safe Online Banking": [0.9, 0.4, 0.7],
  };

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
            notifications: List<String>.from(cloudData['notifications'] ?? []),
            hasUnreadNotifications:
                cloudData['hasUnreadNotifications'] ?? false,
            lastActiveDate: cloudData['lastActiveDate'] == null
                ? null
                : DateTime.tryParse(cloudData['lastActiveDate']),
          ),
        );

        updateStreak();
        _checkBadges();
        _generateRecommendation();

        await _saveLocalProgress();
        await _saveLeaderboard();
        return;
      }

      // IMPORTANT:
      // New account with no Firestore progress must NOT read old local data.
      emit(const HomeState());
      await _saveAllProgress();
      return;
    } catch (_) {
      // Only use local cache if cloud fails for same logged-in user.
      if (_activeUid == uid) {
        await _loadLocalProgress();
      }
    }
  }

  Map<String, double> _mapDouble(dynamic raw, Map<String, double> fallback) {
    if (raw == null) return fallback;

    final data = Map<String, dynamic>.from(raw);
    final defaults = Map<String, double>.from(fallback);

    data.forEach((key, value) {
      defaults[key] = (value as num).toDouble();
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
        lastActiveDate: prefs.getString(_key('lastActiveDate')) == null
            ? null
            : DateTime.tryParse(prefs.getString(_key('lastActiveDate'))!),
      ),
    );

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
      defaults[key] = (value as num).toDouble();
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

  Future<void> recordQuizAnswer(String topic, bool correct) async {
    final key = topic.toLowerCase();

    final topicAnswered = Map<String, int>.from(state.topicAnswered);
    final topicCorrect = Map<String, int>.from(state.topicCorrect);
    final topicScores = Map<String, double>.from(state.topicScores);

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
    final isPerfect = totalQuestions > 0 && totalQuestions == correctAnswers;

    emit(
      state.copyWith(
        quizzesCompleted: state.quizzesCompleted + 1,
        perfectQuizzes: state.perfectQuizzes + (isPerfect ? 1 : 0),
      ),
    );

    _checkBadges();
    await _saveAllProgress();
  }

  Future<void> recordThreatCheck() async {
    emit(state.copyWith(threatChecks: state.threatChecks + 1));

    _checkBadges();
    await gainXP(10);
  }

  Future<void> updateTopicScore(String topic, bool correct) async {
    await recordQuizAnswer(topic, correct);
  }

  Future<void> gainXP(int value) async {
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

    if (state.threatChecks >= 5) unlockBadge("Threat Spotter");

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

    final phishingWeakness = 1 - state.topicProgress("phishing");
    final passwordWeakness = 1 - state.topicProgress("password");
    final socialWeakness = 1 - state.topicProgress("social");

    final userVector = [phishingWeakness, passwordWeakness, socialWeakness];

    final weakestTopic = state.weakestTopic;

    final scores = <String, double>{};
    final reasons = <String, String>{};

    moduleVectors.forEach((module, vector) {
      final similarityScore = _cosineSimilarity(userVector, vector);
      scores[module] = similarityScore;

      reasons[module] =
          "Recommended because your $weakestTopic performance is lower, so this module can help strengthen that topic.";
    });

    final sortedModules = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    emit(
      state.copyWith(
        recommendedModules: sortedModules.map((e) => e.key).take(3).toList(),
        moduleScores: scores,
        moduleReasons: reasons,
      ),
    );
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    double dotProduct = 0;
    double magnitudeA = 0;
    double magnitudeB = 0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      magnitudeA += pow(a[i], 2);
      magnitudeB += pow(b[i], 2);
    }

    final denominator = sqrt(magnitudeA) * sqrt(magnitudeB);

    if (denominator == 0) return 0;

    return dotProduct / denominator;
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

    if (state.lastActiveDate != null) {
      await prefs.setString(
        _key('lastActiveDate'),
        state.lastActiveDate!.toIso8601String(),
      );
    }
  }
}
