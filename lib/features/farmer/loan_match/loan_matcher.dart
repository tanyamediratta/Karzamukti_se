import '../view_schemes/scheme_data.dart';

class SchemeMatch {
  final Scheme scheme;
  final double score;

  SchemeMatch({required this.scheme, required this.score});
}

List<SchemeMatch> matchSchemes({
  required double userAmount,
  required double userInterestRate,
  required int userTimeMonths,
  required List<Scheme> schemes,
}) {
  List<SchemeMatch> results = [];

  for (var s in schemes) {
    // Skip if any required field is missing
    if (s.minimumAmount == null ||
        s.interestRate == null ||
        s.timePeriodMonths == null) {
      continue;
    }

    // Partial scoring
    double amountScore = (userAmount / s.minimumAmount!).clamp(0, 1);
    double interestScore = (userInterestRate / s.interestRate!).clamp(0, 1);
    double timeScore = (s.timePeriodMonths! / userTimeMonths).clamp(0, 1);

    double finalScore =
        (amountScore * 0.4) + (interestScore * 0.4) + (timeScore * 0.2);

    results.add(SchemeMatch(scheme: s, score: finalScore));
  }

  // Sort desc
  results.sort((a, b) => b.score.compareTo(a.score));

  // Return TOP 2
  return results.take(2).toList();
}
