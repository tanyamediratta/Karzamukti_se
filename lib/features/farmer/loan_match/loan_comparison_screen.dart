import 'package:flutter/material.dart';
import '../view_schemes/scheme_data.dart';

import 'loan_matcher.dart';
import 'loan_comparison_result.dart';

class LoanComparisonScreen extends StatefulWidget {
  const LoanComparisonScreen({super.key});

  @override
  State<LoanComparisonScreen> createState() => _LoanComparisonScreenState();
}

class _LoanComparisonScreenState extends State<LoanComparisonScreen> {
  final amountController = TextEditingController();
  final interestController = TextEditingController();
  final timeController = TextEditingController();

  bool loading = false;

  void compareLoans() async {
    if (amountController.text.isEmpty ||
        interestController.text.isEmpty ||
        timeController.text.isEmpty)
      return;

    setState(() => loading = true);

    final amount = double.tryParse(amountController.text) ?? 0;
    final interest = double.tryParse(interestController.text) ?? 0;
    final months = int.tryParse(timeController.text) ?? 0;

    final schemes = await fetchSchemes();

    final matched = matchSchemes(
      userAmount: amount,
      userInterestRate: interest,
      userTimeMonths: months,
      schemes: schemes,
    );

    setState(() => loading = false);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LoanComparisonResult(results: matched)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Compare Loan Schemes"),
        backgroundColor: const Color(0xFFA8D5BA),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Required Loan Amount (₹)",
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: interestController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Maximum Interest Rate (%)",
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: timeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Loan Duration (months)",
              ),
            ),

            const SizedBox(height: 25),

            ElevatedButton(
              onPressed: loading ? null : compareLoans,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 20,
                ),
              ),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Find Best Scheme",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
