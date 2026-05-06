import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'leaderboard_state.dart';

class LeaderboardCubit extends Cubit<LeaderboardState> {
  LeaderboardCubit() : super(const LeaderboardState());

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> loadLeaderboard() async {
    // IMPORTANT FIX
    if (state.loaded || state.isLoading) return;

    emit(state.copyWith(isLoading: true, errorMessage: ''));

    try {
      final snapshot = await _firestore
          .collection('leaderboard')
          .orderBy('xp', descending: true)
          .get();

      final currentUserId = _auth.currentUser?.uid;

      final users = snapshot.docs.map((doc) {
        final data = doc.data();

        return LeaderboardUser(
          name: data['name'] ?? 'User',
          faculty: data['faculty'] ?? 'FSKM',
          xp: data['xp'] ?? 0,
          isCurrentUser: doc.id == currentUserId,
        );
      }).toList();

      emit(
        state.copyWith(
          users: users,
          isLoading: false,
          loaded: true,
          errorMessage: '',
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: '', loaded: false));
    }
  }
}
