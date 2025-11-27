import 'package:flutter/material.dart';
import 'loan_matcher.dart';

class LoanComparisonResult extends StatelessWidget {
  final List<SchemeMatch> results;

  const LoanComparisonResult({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Best Matching Schemes"),
        backgroundColor: const Color(0xFFA8D5BA),
      ),
      body: results.isEmpty
          ? const Center(child: Text("No matching schemes found"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: results.length,
              itemBuilder: (ctx, index) {
                final match = results[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      match.scheme.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Match Score: ${(match.score * 100).toStringAsFixed(0)}%",
                    ),
                    onTap: () {},
                  ),
                );
              },
            ),
    );
  }
}
