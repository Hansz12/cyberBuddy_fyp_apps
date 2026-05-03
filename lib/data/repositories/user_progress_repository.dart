import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProgressRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("No logged in user found.");
    }
    return user.uid;
  }

  Future<Map<String, dynamic>?> loadProgress() async {
    final doc = await _firestore.collection('user_progress').doc(_uid).get();

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
  }) async {
    await _firestore.collection('user_progress').doc(_uid).set({
      'xp': xp,
      'level': level,
      'streak': streak,
      'badges': badges,
      'topicScores': topicScores,
      'lastActiveDate': lastActiveDate?.toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> resetProgress() async {
    await _firestore.collection('user_progress').doc(_uid).delete();
  }
}
