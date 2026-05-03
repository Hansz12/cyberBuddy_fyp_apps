import 'package:flutter_bloc/flutter_bloc.dart';
import 'leaderboard_state.dart';

class LeaderboardCubit extends Cubit<LeaderboardState> {
  LeaderboardCubit() : super(const LeaderboardState());

  void loadLeaderboard({required int currentUserXp}) {
    final users = [
      const LeaderboardUser(name: "Nadhira", faculty: "FSKM", xp: 950),
      const LeaderboardUser(name: "Haziq", faculty: "FSKM", xp: 760),
      const LeaderboardUser(name: "Aiman", faculty: "FBMSK", xp: 640),
      LeaderboardUser(
        name: "Farhana",
        faculty: "FSKM Mobile Computing",
        xp: currentUserXp,
        isCurrentUser: true,
      ),
      const LeaderboardUser(name: "Danish", faculty: "FBMSK", xp: 310),
      const LeaderboardUser(name: "Damia", faculty: "FSSR", xp: 230),
    ];

    users.sort((a, b) => b.xp.compareTo(a.xp));

    emit(state.copyWith(users: users));
  }
}
