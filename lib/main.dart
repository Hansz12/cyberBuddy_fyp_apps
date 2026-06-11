import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'main_navigation.dart';

import 'features/auth/splash_screen.dart';
import 'features/auth/cubit/auth_cubit.dart';

import 'features/home/cubit/home_cubit.dart';
import 'features/quiz/cubit/quiz_cubit.dart';
import 'features/leaderboard/cubit/leaderboard_cubit.dart';
import 'features/learning/cubit/learning_cubit.dart';

import 'data/services/notification_service.dart';
import 'data/services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await NotificationService.init();
  await PushNotificationService.init();
  await NotificationService.scheduleDailyReminder();

  runApp(const CyberBuddyApp());
}

class CyberBuddyApp extends StatelessWidget {
  const CyberBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => AuthCubit()),

        // IMPORTANT:
        // Jangan auto load kat sini.
        // Load user data hanya selepas login berjaya.
        BlocProvider<HomeCubit>(create: (_) => HomeCubit()),

        BlocProvider<QuizCubit>(create: (_) => QuizCubit()),

        BlocProvider<LeaderboardCubit>(create: (_) => LeaderboardCubit()),

        BlocProvider<LearningCubit>(
          create: (_) => LearningCubit()..loadModules(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CyberBuddy',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF1F5F9),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        ),
        home: const SplashScreen(),
        routes: {'/home': (_) => const MainNavigation()},
      ),
    );
  }
}
