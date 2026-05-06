import 'package:equatable/equatable.dart';

class LeaderboardUser extends Equatable {
  final String name;
  final String faculty;
  final int xp;
  final bool isCurrentUser;

  const LeaderboardUser({
    required this.name,
    required this.faculty,
    required this.xp,
    this.isCurrentUser = false,
  });

  @override
  List<Object> get props => [name, faculty, xp, isCurrentUser];
}

class LeaderboardState extends Equatable {
  final List<LeaderboardUser> users;
  final bool isLoading;
  final String errorMessage;
  final bool loaded;

  const LeaderboardState({
    this.users = const [],
    this.isLoading = false,
    this.errorMessage = '',
    this.loaded = false,
  });

  LeaderboardState copyWith({
    List<LeaderboardUser>? users,
    bool? isLoading,
    String? errorMessage,
    bool? loaded,
  }) {
    return LeaderboardState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      loaded: loaded ?? this.loaded,
    );
  }

  @override
  List<Object> get props => [users, isLoading, errorMessage, loaded];
}
