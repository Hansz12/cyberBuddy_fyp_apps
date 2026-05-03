import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../home/cubit/home_cubit.dart';
import 'cubit/threat_checker_cubit.dart';
import 'cubit/threat_checker_state.dart';

class ThreatCheckerScreen extends StatelessWidget {
  const ThreatCheckerScreen({super.key});

  Color _riskColor(int score) {
    if (score >= 70) return Colors.red;
    if (score >= 40) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Threat Checker"),
        backgroundColor: const Color(0xFF0D1B3E),
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<ThreatCheckerCubit, ThreatCheckerState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF7F1D1D),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Suspicious Link / Message Checker 🔍",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Paste a suspicious URL or message to analyse basic phishing risk.",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              TextField(
                minLines: 4,
                maxLines: 7,
                onChanged: context.read<ThreatCheckerCubit>().updateInput,
                decoration: InputDecoration(
                  hintText:
                      "Example: Urgent! Your bank account is locked. Click http://bank-secure-verify.net/login",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: () {
                  context.read<ThreatCheckerCubit>().analyseThreat();

                  if (state.input.trim().isNotEmpty) {
                    context.read<HomeCubit>().gainXP(10);
                  }
                },
                icon: const Icon(Icons.search),
                label: const Text("Analyse Threat"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),

              const SizedBox(height: 18),

              if (state.analysed)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.verdict,
                        style: TextStyle(
                          color: _riskColor(state.riskScore),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        "Risk Score: ${state.riskScore}/100",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 8),

                      LinearProgressIndicator(
                        value: state.riskScore / 100,
                        minHeight: 10,
                        color: _riskColor(state.riskScore),
                        backgroundColor: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(20),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        "Detected Flags",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 8),

                      if (state.flags.isEmpty)
                        const Text("No major red flags detected.")
                      else
                        ...state.flags.map(
                          (flag) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.warning,
                              color: Colors.orange,
                            ),
                            title: Text(flag),
                          ),
                        ),

                      const SizedBox(height: 10),

                      const Text(
                        "Safety Tip: Never enter passwords, OTP, or banking details through links received in messages. Always verify using the official website or app.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}