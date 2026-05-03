import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'main_navigation.dart';

import 'features/auth/splash_screen.dart';
import 'features/auth/cubit/auth_cubit.dart';

import 'features/home/cubit/home_cubit.dart';
import 'features/quiz/cubit/quiz_cubit.dart';
import 'features/leaderboard/cubit/leaderboard_cubit.dart';
import 'features/learning/cubit/learning_cubit.dart';
import 'features/threat_checker/cubit/threat_checker_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const CyberBuddyApp());
}

class CyberBuddyApp extends StatelessWidget {
  const CyberBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => AuthCubit()),
        BlocProvider<HomeCubit>(create: (_) => HomeCubit()..loadUserData()),
        BlocProvider<QuizCubit>(create: (_) => QuizCubit()..loadQuiz()),
        BlocProvider<LeaderboardCubit>(create: (_) => LeaderboardCubit()),
        BlocProvider<LearningCubit>(
          create: (_) => LearningCubit()..loadModules(),
        ),
        BlocProvider<ThreatCheckerCubit>(create: (_) => ThreatCheckerCubit()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CyberBuddy',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF1F5F9),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0D1B3E),
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF2563EB),
                width: 1.5,
              ),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF2563EB),
            foregroundColor: Colors.white,
          ),
        ),
        home: const SplashScreen(),
        routes: {'/home': (_) => const MainNavigation()},
      ),
    );
  }
}
