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

  final Map<String, List<double>> moduleVectors = {
    "Phishing Awareness": [1, 0, 0],
    "Password Security": [0, 1, 0],
    "Social Engineering": [0, 0, 1],
    "Malware & Safe Downloads": [0.4, 0.2, 0.8],
    "Privacy Protection": [0.2, 0.7, 0.4],
    "Online Scam Awareness": [0.8, 0.1, 0.9],
  };

  Future<void> loadUserData() async {
    try {
      final cloudData = await _progressRepository.loadProgress();

      if (cloudData != null) {
        final topicRaw = cloudData['topicScores'] as Map<String, dynamic>?;

        final topicScores = topicRaw != null
            ? topicRaw.map(
                (key, value) => MapEntry(key, (value as num).toDouble()),
              )
            : const {"phishing": 0.5, "password": 0.5, "social": 0.5};

        final lastActiveString = cloudData['lastActiveDate'] as String?;

        emit(
          state.copyWith(
            xp: cloudData['xp'] ?? 0,
            level: cloudData['level'] ?? 1,
            streak: cloudData['streak'] ?? 0,
            badges: List<String>.from(cloudData['badges'] ?? []),
            topicScores: topicScores,
            lastActiveDate: lastActiveString == null
                ? null
                : DateTime.tryParse(lastActiveString),
          ),
        );

        updateStreak();
        checkBadges();
        _generateRecommendation();

        await _saveLocalProgress();
        await _saveLeaderboard();
        return;
      }
    } catch (_) {
      await _loadLocalProgress();
      return;
    }

    await _loadLocalProgress();
  }

  Future<void> _loadLocalProgress() async {
    final prefs = await SharedPreferences.getInstance();

    final xp = prefs.getInt('xp') ?? 0;
    final level = prefs.getInt('level') ?? 1;
    final streak = prefs.getInt('streak') ?? 0;
    final badges = prefs.getStringList('badges') ?? [];

    final topicJson = prefs.getString('topicScores');
    final lastActiveString = prefs.getString('lastActiveDate');

    Map<String, double> topicScores = const {
      "phishing": 0.5,
      "password": 0.5,
      "social": 0.5,
    };

    if (topicJson != null) {
      final decoded = jsonDecode(topicJson) as Map<String, dynamic>;
      topicScores = decoded.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
    }

    emit(
      state.copyWith(
        xp: xp,
        level: level,
        streak: streak,
        badges: badges,
        topicScores: topicScores,
        lastActiveDate: lastActiveString == null
            ? null
            : DateTime.tryParse(lastActiveString),
      ),
    );

    updateStreak();
    checkBadges();
    _generateRecommendation();

    await _saveAllProgress();
  }

  Future<void> updateTopicScore(String topic, bool correct) async {
    final currentScores = Map<String, double>.from(state.topicScores);

    if (!currentScores.containsKey(topic)) return;

    final updatedScore = currentScores[topic]! + (correct ? 0.1 : -0.1);
    currentScores[topic] = updatedScore.clamp(0.0, 1.0);

    emit(state.copyWith(topicScores: currentScores));

    _generateRecommendation();
    await _saveAllProgress();
  }

  Future<void> gainXP(int value) async {
    final newXP = state.xp + value;
    final newLevel = (newXP ~/ 100) + 1;

    emit(state.copyWith(xp: newXP, level: newLevel));

    updateStreak();
    checkBadges();
    _generateRecommendation();

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

  void checkBadges() {
    final updatedBadges = List<String>.from(state.badges);

    if (!updatedBadges.contains("Rookie Badge")) {
      updatedBadges.add("Rookie Badge");
    }

    if (state.xp >= 100 && !updatedBadges.contains("Beginner Defender")) {
      updatedBadges.add("Beginner Defender");
    }

    if (state.xp >= 300 && !updatedBadges.contains("Intermediate Defender")) {
      updatedBadges.add("Intermediate Defender");
    }

    if (state.xp >= 500 && !updatedBadges.contains("Cyber Hero")) {
      updatedBadges.add("Cyber Hero");
    }

    if (state.streak >= 3 && !updatedBadges.contains("Consistent Learner")) {
      updatedBadges.add("Consistent Learner");
    }

    emit(state.copyWith(badges: updatedBadges));
  }

  Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    try {
      await _progressRepository.resetProgress();
    } catch (_) {}

    emit(const HomeState());

    _generateRecommendation();
    checkBadges();

    await _saveAllProgress();
  }

  void _generateRecommendation() {
    final userVector = [
      1 - state.topicScores["phishing"]!,
      1 - state.topicScores["password"]!,
      1 - state.topicScores["social"]!,
    ];

    String weakestTopic = "phishing";
    double weakestScore = state.topicScores["phishing"] ?? 0.5;

    state.topicScores.forEach((topic, score) {
      if (score < weakestScore) {
        weakestScore = score;
        weakestTopic = topic;
      }
    });

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

    final recommendations = sortedModules
        .map((entry) => entry.key)
        .take(3)
        .toList();

    emit(
      state.copyWith(
        recommendedModules: recommendations,
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
        lastActiveDate: state.lastActiveDate,
      );
    } catch (_) {
      // Firestore progress fail, local storage masih backup.
    }

    await _saveLeaderboard();
  }

  Future<void> _saveLeaderboard() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      await _leaderboardRepository.updateUser(
        userId: user.uid,
        name: user.email ?? "User",
        xp: state.xp,
        level: state.level,
        streak: state.streak,
        badges: state.badges.length,
      );
    } catch (_) {
      // Leaderboard fail, app masih boleh jalan.
    }
  }

  Future<void> _saveLocalProgress() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('xp', state.xp);
    await prefs.setInt('level', state.level);
    await prefs.setInt('streak', state.streak);
    await prefs.setStringList('badges', state.badges);
    await prefs.setString('topicScores', jsonEncode(state.topicScores));

    if (state.lastActiveDate != null) {
      await prefs.setString(
        'lastActiveDate',
        state.lastActiveDate!.toIso8601String(),
      );
    }
  }
}
