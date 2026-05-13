import 'package:equatable/equatable.dart';

class ThreatCheckerState extends Equatable {
  final String input;
  final int riskScore;
  final String riskLevel;
  final String verdict;
  final String explanation;
  final String safetyTip;
  final List<String> flags;
  final bool analysed;

  const ThreatCheckerState({
    this.input = '',
    this.riskScore = 0,
    this.riskLevel = '',
    this.verdict = '',
    this.explanation = '',
    this.safetyTip = '',
    this.flags = const [],
    this.analysed = false,
  });

  ThreatCheckerState copyWith({
    String? input,
    int? riskScore,
    String? riskLevel,
    String? verdict,
    String? explanation,
    String? safetyTip,
    List<String>? flags,
    bool? analysed,
  }) {
    return ThreatCheckerState(
      input: input ?? this.input,
      riskScore: riskScore ?? this.riskScore,
      riskLevel: riskLevel ?? this.riskLevel,
      verdict: verdict ?? this.verdict,
      explanation: explanation ?? this.explanation,
      safetyTip: safetyTip ?? this.safetyTip,
      flags: flags ?? this.flags,
      analysed: analysed ?? this.analysed,
    );
  }

  @override
  List<Object> get props => [
    input,
    riskScore,
    riskLevel,
    verdict,
    explanation,
    safetyTip,
    flags,
    analysed,
  ];
}
