import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../main_navigation.dart';
import '../home/cubit/home_cubit.dart';
import '../learning/cubit/learning_cubit.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goNext();
  }

  Future<void> _goNext() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await context.read<HomeCubit>().loadUserData();
      await context.read<LearningCubit>().loadModules();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071123),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.35),
                        blurRadius: 35,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text("🛡️", style: TextStyle(fontSize: 44)),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  "CyberBuddy",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 31,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "// CYBERSECURITY · LEARN ·\nDEFEND",
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      letterSpacing: 2.2,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 54),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: const SizedBox(
                    width: 140,
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      valueColor: AlwaysStoppedAnimation(Color(0xFF38BDF8)),
                      backgroundColor: Color(0xFF0F1B33),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
