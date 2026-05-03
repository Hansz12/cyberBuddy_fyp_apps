import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/home/home_screen.dart';
import 'features/learning/learning_screen.dart';
import 'features/leaderboard/leaderboard_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/threat_checker/threat_checker_screen.dart';

import 'features/quiz/cubit/quiz_cubit.dart';
import 'features/quiz/quiz_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    LearningScreen(),
    ThreatCheckerScreen(),
    LeaderboardScreen(),
    ProfileScreen(),
  ];

  void _onTap(int index) {
    setState(() => _currentIndex = index);
  }

  void _startQuiz(BuildContext context) {
    context.read<QuizCubit>().loadQuiz();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuizScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],

      // 🚀 QUICK QUIZ BUTTON
      floatingActionButton: FloatingActionButton(
        onPressed: () => _startQuiz(context),
        child: const Icon(Icons.play_arrow),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "Learn"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Check"),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: "Rank"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
