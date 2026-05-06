import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProgressRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

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
    final userId = _userId;

    if (userId == null) return null;

    final doc = await _firestore.collection('user_progress').doc(userId).get();

    if (!doc.exists) return null;

    return doc.data();
  }

  Future<void> saveProgress({
    required int xp,
    required int level,
    required int streak,
    required List<String> badges,
    required Map<String, double> topicScores,
    required DateTime? lastActiveDate,
    required List<String> notifications,
    required bool hasUnreadNotifications,
  }) async {
    final userId = _userId;

    if (userId == null) return;

    final leaderboardScore = xp + (streak * 10) + (badges.length * 25);

    await _firestore.collection('user_progress').doc(userId).set({
      'userId': userId,
      'name': _getDisplayName(),
      'email': _getEmail(),
      'faculty': 'FSKM Mobile Computing',
      'xp': xp,
      'level': level,
      'streak': streak,
      'badges': badges,
      'badgesCount': badges.length,
      'topicScores': topicScores,
      'leaderboardScore': leaderboardScore,
      'lastActiveDate': lastActiveDate?.toIso8601String(),
      'notifications': notifications,
      'hasUnreadNotifications': hasUnreadNotifications,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> resetProgress() async {
    final userId = _userId;

    if (userId == null) return;

    await _firestore.collection('user_progress').doc(userId).delete();
  }
}
