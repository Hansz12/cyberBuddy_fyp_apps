import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../main_navigation.dart';
import '../home/cubit/home_cubit.dart';
import '../learning/cubit/learning_cubit.dart';
import 'cubit/auth_cubit.dart';
import 'cubit/auth_state.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _handleLogin(BuildContext context) async {
    final success = await context.read<AuthCubit>().signIn();

    if (success && context.mounted) {
      await context.read<HomeCubit>().loadUserData();
      await context.read<LearningCubit>().loadModules();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    }
  }

  Future<void> _handleGoogleLogin(BuildContext context) async {
    final success = await context.read<AuthCubit>().signInWithGoogle();

    if (success && context.mounted) {
      await context.read<HomeCubit>().loadUserData();
      await context.read<LearningCubit>().loadModules();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    }
  }

  void _goToForgotPassword(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  void _goToRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  String _friendlyError(String? error) {
    if (error == null || error.trim().isEmpty) return "";

    final lower = error.toLowerCase();

    if (lower.contains("credential") ||
        lower.contains("password") ||
        lower.contains("malformed") ||
        lower.contains("expired") ||
        lower.contains("invalid") ||
        lower.contains("user-not-found") ||
        lower.contains("wrong-password")) {
      return "Email or password is incorrect. If you registered with Google, use Continue with Google or reset your password first.";
    }

    if (lower.contains("network")) {
      return "Network error. Please check your internet connection.";
    }

    if (lower.contains("too-many-requests")) {
      return "Too many attempts. Please wait a while before trying again.";
    }

    return error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071123),
      body: SafeArea(
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final canSignIn =
                state.email.trim().isNotEmpty &&
                state.password.trim().isNotEmpty;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(34),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 34, 24, 46),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF0D1B3E), Color(0xFF1E3A8A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "🛡️",
                                      style: TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF38BDF8,
                                    ).withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(7),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF38BDF8,
                                      ).withOpacity(0.4),
                                    ),
                                  ),
                                  child: const Text(
                                    "SECURED · PDPA",
                                    style: TextStyle(
                                      color: Color(0xFF38BDF8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            const Text(
                              "Welcome back",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 9),
                            const Text(
                              "Sign in to continue your cybersecurity learning journey with CyberBuddy.",
                              style: TextStyle(
                                color: Colors.white70,
                                height: 1.45,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Transform.translate(
                        offset: const Offset(0, -22),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(32),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel("EMAIL ADDRESS"),
                              const SizedBox(height: 6),
                              TextField(
                                keyboardType: TextInputType.emailAddress,
                                onChanged: context
                                    .read<AuthCubit>()
                                    .updateEmail,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.email),
                                  hintText: "farhana@uitm.edu.my",
                                ),
                              ),

                              const SizedBox(height: 16),

                              const _FieldLabel("PASSWORD"),
                              const SizedBox(height: 6),
                              TextField(
                                obscureText: true,
                                onChanged: context
                                    .read<AuthCubit>()
                                    .updatePassword,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.lock),
                                  hintText: "Password",
                                ),
                              ),

                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: state.isLoading
                                      ? null
                                      : () => _goToForgotPassword(context),
                                  child: const Text(
                                    "Forgot password?",
                                    style: TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),

                              if (state.errorMessage != null)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFFECACA),
                                    ),
                                  ),
                                  child: Text(
                                    _friendlyError(state.errorMessage),
                                    style: const TextStyle(
                                      color: Color(0xFFDC2626),
                                      fontSize: 12,
                                      height: 1.35,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: state.isLoading || !canSignIn
                                      ? null
                                      : () => _handleLogin(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: const Color(
                                      0xFFE2E8F0,
                                    ),
                                    disabledForegroundColor: const Color(
                                      0xFF94A3B8,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: state.isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          "Sign in →",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              Row(
                                children: const [
                                  Expanded(child: Divider()),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Text(
                                      "or",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                  Expanded(child: Divider()),
                                ],
                              ),

                              const SizedBox(height: 18),

                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: state.isLoading
                                      ? null
                                      : () => _handleGoogleLogin(context),
                                  icon: const Text(
                                    "G",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  label: const Text(
                                    "Continue with Google",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0F172A),
                                    side: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                      width: 1.2,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              Center(
                                child: GestureDetector(
                                  onTap: state.isLoading
                                      ? null
                                      : () => _goToRegister(context),
                                  child: RichText(
                                    text: const TextSpan(
                                      style: TextStyle(color: Colors.grey),
                                      children: [
                                        TextSpan(
                                          text: "Don’t have an account? ",
                                        ),
                                        TextSpan(
                                          text: "Create one",
                                          style: TextStyle(
                                            color: Color(0xFF2563EB),
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 22),

                              const Divider(),

                              const SizedBox(height: 10),

                              const Row(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: Colors.green,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "256-bit encrypted · PDPA compliant",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
      ),
    );
  }
}
