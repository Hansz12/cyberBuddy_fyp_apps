import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> leaderboardStream() {
    return _firestore
        .collection('user_progress')
        .orderBy('leaderboardScore', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();

            return {
              'userId': data['userId'] ?? doc.id,
              'name': data['name'] ?? 'User',
              'email': data['email'] ?? '',
              'faculty': data['faculty'] ?? 'FSKM',
              'xp': data['xp'] ?? 0,
              'level': data['level'] ?? 1,
              'streak': data['streak'] ?? 0,
              'badgesCount': data['badgesCount'] ?? 0,
              'leaderboardScore': data['leaderboardScore'] ?? 0,
            };
          }).toList();
        });
  }

  Future<void> updateUser({
    required String userId,
    required String name,
    required int xp,
    required int level,
    required int streak,
    required int badges,
    String faculty = 'FSKM Mobile Computing',
  }) async {
    final leaderboardScore = xp + (streak * 10) + (badges * 25);

    await _firestore.collection('user_progress').doc(userId).set({
      'userId': userId,
      'name': name,
      'faculty': faculty,
      'xp': xp,
      'level': level,
      'streak': streak,
      'badgesCount': badges,
      'leaderboardScore': leaderboardScore,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
