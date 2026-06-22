import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProgressRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

  String _getDisplayName() {
    final user = _auth.currentUser;

    if (user?.displayName != null && user!.displayName!.trim().isNotEmpty) {
      return user.displayName!.trim();
    }

    final email = user?.email ?? "User";

    if (email.contains("@")) {
      final name = email.split("@").first;
      return name.isEmpty ? "User" : name;
    }

    return "User";
  }

  String _getEmail() {
    return _auth.currentUser?.email ?? "";
  }

  Future<Map<String, dynamic>?> loadProgress() async {
    final uid = userId;
    if (uid == null) return null;

    final doc = await _firestore.collection('user_progress').doc(uid).get();

    if (!doc.exists) return null;

    return doc.data();
  }

  Future<void> saveProgress({
    required int xp,
    required int level,
    required int streak,
    required List<String> badges,
    required List<String> completedModules,
    required Map<String, double> topicScores,
    required Map<String, int> topicAnswered,
    required Map<String, int> topicCorrect,
    required int totalQuestionsAnswered,
    required int totalCorrectAnswers,
    required int quizzesCompleted,
    required List<int> last3Scores,
    required int perfectQuizzes,
    required int threatChecks,
    required int dailyModulesCompleted,
    required int dailyQuizAttempts,
    required int dailyTopicsTried,
    required int dailyBestQuizScore,
    required DateTime? dailyQuestDate,
    required List<String> claimedDailyQuests,
    required List<String> rewardedNewsUrls,
    required Map<String, double> recommendationScores,
    required DateTime? lastActiveDate,
    required List<String> notifications,
    required bool hasUnreadNotifications,
  }) async {
    final uid = userId;
    if (uid == null) return;

    final leaderboardScore = xp + (streak * 10) + (badges.length * 25);

    await _firestore.collection('user_progress').doc(uid).set({
      'userId': uid,
      'name': _getDisplayName(),
      'email': _getEmail(),

      'xp': xp,
      'level': level,
      'streak': streak,
      'badges': badges,
      'badgesCount': badges.length,
      'completedModules': completedModules,

      'topicScores': topicScores,
      'topicAnswered': topicAnswered,
      'topicCorrect': topicCorrect,

      'totalQuestionsAnswered': totalQuestionsAnswered,
      'totalCorrectAnswers': totalCorrectAnswers,
      'quizzesCompleted': quizzesCompleted,
      'last3Scores': last3Scores,
      'perfectQuizzes': perfectQuizzes,
      'threatChecks': threatChecks,

      'dailyModulesCompleted': dailyModulesCompleted,
      'dailyQuizAttempts': dailyQuizAttempts,
      'dailyTopicsTried': dailyTopicsTried,
      'dailyBestQuizScore': dailyBestQuizScore,
      'dailyQuestDate': dailyQuestDate?.toIso8601String(),
      'claimedDailyQuests': claimedDailyQuests,

      'rewardedNewsUrls': rewardedNewsUrls,
      'recommendationScores': recommendationScores,

      'leaderboardScore': leaderboardScore,
      'lastActiveDate': lastActiveDate?.toIso8601String(),
      'notifications': notifications,
      'hasUnreadNotifications': hasUnreadNotifications,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> resetProgress() async {
    final uid = userId;
    if (uid == null) return;

    // Replace the document rather than deleting it. The leaderboard keeps a
    // user entry in this collection, so a delete followed by a leaderboard
    // update could recreate a partial document or leave old data behind when
    // the delete failed. A full overwrite makes the cloud source of truth
    // explicitly zeroed before the user can sign in again.
    await _firestore.collection('user_progress').doc(uid).set({
      'userId': uid,
      'name': _getDisplayName(),
      'email': _getEmail(),
      'xp': 0,
      'level': 1,
      'streak': 0,
      'badges': <String>[],
      'badgesCount': 0,
      'completedModules': <String>[],
      'topicScores': const <String, double>{
        'phishing': 0,
        'password': 0,
        'social': 0,
        'malware': 0,
        'privacy': 0,
        'scam': 0,
        'mobile': 0,
        'network': 0,
        'ethics': 0,
        'banking': 0,
      },
      'topicAnswered': const <String, int>{
        'phishing': 0,
        'password': 0,
        'social': 0,
        'malware': 0,
        'privacy': 0,
        'scam': 0,
        'mobile': 0,
        'network': 0,
        'ethics': 0,
        'banking': 0,
      },
      'topicCorrect': const <String, int>{
        'phishing': 0,
        'password': 0,
        'social': 0,
        'malware': 0,
        'privacy': 0,
        'scam': 0,
        'mobile': 0,
        'network': 0,
        'ethics': 0,
        'banking': 0,
      },
      'totalQuestionsAnswered': 0,
      'totalCorrectAnswers': 0,
      'quizzesCompleted': 0,
      'last3Scores': <int>[],
      'perfectQuizzes': 0,
      'threatChecks': 0,
      'dailyModulesCompleted': 0,
      'dailyQuizAttempts': 0,
      'dailyTopicsTried': 0,
      'dailyBestQuizScore': 0,
      'dailyQuestDate': null,
      'claimedDailyQuests': <String>[],
      'rewardedNewsUrls': <String>[],
      'recommendationScores': <String, double>{},
      'leaderboardScore': 0,
      'lastActiveDate': null,
      'notifications': <String>[],
      'hasUnreadNotifications': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
