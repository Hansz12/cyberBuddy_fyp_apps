import 'package:equatable/equatable.dart';

class ThreatCheckerState extends Equatable {
  final String input;
  final int riskScore;
  final String verdict;
  final List<String> flags;
  final bool analysed;

  const ThreatCheckerState({
    this.input = '',
    this.riskScore = 0,
    this.verdict = '',
    this.flags = const [],
    this.analysed = false,
  });

  ThreatCheckerState copyWith({
    String? input,
    int? riskScore,
    String? verdict,
    List<String>? flags,
    bool? analysed,
  }) {
    return ThreatCheckerState(
      input: input ?? this.input,
      riskScore: riskScore ?? this.riskScore,
      verdict: verdict ?? this.verdict,
      flags: flags ?? this.flags,
      analysed: analysed ?? this.analysed,
    );
  }

  @override
  List<Object> get props => [input, riskScore, verdict, flags, analysed];
}
