import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateUser({
    required String userId,
    required String name,
    required int xp,
    required int level,
    required int streak,
    required int badges,
  }) async {
    final leaderboardScore = xp + (streak * 10) + (badges * 25);

    await _firestore.collection('leaderboard').doc(userId).set({
      'name': name,
      'xp': xp,
      'level': level,
      'streak': streak,
      'badges': badges,
      'leaderboardScore': leaderboardScore,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
