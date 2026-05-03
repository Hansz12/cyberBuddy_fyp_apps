import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateUser({
    required String userId,
    required String name,
    required int xp,
    required int level,
  }) async {
    await _firestore.collection('leaderboard').doc(userId).set({
      'name': name,
      'xp': xp,
      'level': level,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
