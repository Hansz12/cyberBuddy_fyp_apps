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

  const LeaderboardState({this.users = const []});

  LeaderboardState copyWith({List<LeaderboardUser>? users}) {
    return LeaderboardState(users: users ?? this.users);
  }

  @override
  List<Object> get props => [users];
}
