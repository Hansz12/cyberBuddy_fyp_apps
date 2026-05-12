import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'leaderboard_state.dart';

class LeaderboardCubit extends Cubit<LeaderboardState> {
  LeaderboardCubit() : super(const LeaderboardState());

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  void listenLeaderboard() {
    emit(state.copyWith(isLoading: true, errorMessage: ''));

    _subscription?.cancel();

    _subscription = _firestore
        .collection('user_progress')
        .orderBy('leaderboardScore', descending: true)
        .limit(20)
        .snapshots()
        .listen(
          (snapshot) {
            final currentUserId = _auth.currentUser?.uid;

            final users = snapshot.docs.map((doc) {
              final data = doc.data();

              return LeaderboardUser(
                userId: (data['userId'] ?? doc.id).toString(),
                name: (data['name'] ?? 'User').toString(),
                faculty: (data['faculty'] ?? 'FSKM').toString(),
                xp: _toInt(data['xp']),
                level: _toInt(data['level']),
                streak: _toInt(data['streak']),
                badgesCount: _toInt(data['badgesCount']),
                leaderboardScore: _toInt(data['leaderboardScore']),
                isCurrentUser:
                    doc.id == currentUserId ||
                    (data['userId'] ?? '').toString() == currentUserId,
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
          },
          onError: (error) {
            emit(
              state.copyWith(
                isLoading: false,
                loaded: false,
                errorMessage: 'Failed to load leaderboard.',
              ),
            );
          },
        );
  }

  Future<void> loadLeaderboard({bool forceRefresh = false}) async {
    if (!forceRefresh && state.isLoading) return;

    emit(state.copyWith(isLoading: true, errorMessage: ''));

    try {
      final currentUserId = _auth.currentUser?.uid;

      final snapshot = await _firestore
          .collection('user_progress')
          .orderBy('leaderboardScore', descending: true)
          .limit(20)
          .get();

      final users = snapshot.docs.map((doc) {
        final data = doc.data();

        return LeaderboardUser(
          userId: (data['userId'] ?? doc.id).toString(),
          name: (data['name'] ?? 'User').toString(),
          faculty: (data['faculty'] ?? 'FSKM').toString(),
          xp: _toInt(data['xp']),
          level: _toInt(data['level']),
          streak: _toInt(data['streak']),
          badgesCount: _toInt(data['badgesCount']),
          leaderboardScore: _toInt(data['leaderboardScore']),
          isCurrentUser:
              doc.id == currentUserId ||
              (data['userId'] ?? '').toString() == currentUserId,
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
      emit(
        state.copyWith(
          isLoading: false,
          loaded: false,
          errorMessage: 'Failed to load leaderboard.',
        ),
      );
    }
  }

  Future<void> refreshLeaderboard() async {
    await loadLeaderboard(forceRefresh: true);
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
