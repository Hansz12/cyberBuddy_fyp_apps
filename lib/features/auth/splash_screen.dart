import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../main_navigation.dart';
import '../home/cubit/home_cubit.dart';
import '../learning/cubit/learning_cubit.dart';
import 'cubit/auth_cubit.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  String _loadingText = "Preparing your cyber mission...";

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.88,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward();
    _goNext();
  }

  Future<void> _goNext() async {
    await Future.delayed(const Duration(milliseconds: 700));

    if (mounted) {
      setState(() {
        _loadingText = "Loading learning modules...";
      });
    }

    await Future.delayed(const Duration(milliseconds: 700));

    if (mounted) {
      setState(() {
        _loadingText = "Checking your progress...";
      });
    }

    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user != null && !AuthCubit.isUniversityStudentEmail(user.email ?? '')) {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    if (user != null) {
      try {
        await context.read<HomeCubit>().loadUserData().timeout(
          const Duration(seconds: 4),
        );
      } catch (_) {}

      try {
        await context.read<LearningCubit>().loadModules().timeout(
          const Duration(seconds: 4),
        );
      } catch (_) {}

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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _glowCircle({
    required double size,
    required Color color,
    required double opacity,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071123),
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -80,
            child: _glowCircle(
              size: 220,
              color: const Color(0xFF2563EB),
              opacity: 0.16,
            ),
          ),
          Positioned(
            bottom: -120,
            left: -90,
            child: _glowCircle(
              size: 260,
              color: const Color(0xFF38BDF8),
              opacity: 0.10,
            ),
          ),

          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 122,
                          height: 122,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(34),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF0F172A),
                                Color(0xFF1D4ED8),
                                Color(0xFF2563EB),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF2563EB,
                                ).withOpacity(0.45),
                                blurRadius: 45,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text("🛡️", style: TextStyle(fontSize: 50)),
                          ),
                        ),

                        const SizedBox(height: 30),

                        const Text(
                          "CyberBuddy",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: const Text(
                            "CYBERSECURITY · LEARN · DEFEND",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        const SizedBox(height: 50),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: const SizedBox(
                            width: 170,
                            child: LinearProgressIndicator(
                              minHeight: 5,
                              valueColor: AlwaysStoppedAnimation(
                                Color(0xFF38BDF8),
                              ),
                              backgroundColor: Color(0xFF111C33),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _loadingText,
                            key: ValueKey(_loadingText),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
