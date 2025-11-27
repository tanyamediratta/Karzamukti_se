import 'package:flutter/material.dart';

class LoanStatusDetailScreen extends StatelessWidget {
  final Map loan;

  const LoanStatusDetailScreen({super.key, required this.loan});

  Widget _label(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = loan['schemes'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FFF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFA8D5BA),
        title: const Text("Loan Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label("Scheme", scheme?['title'] ?? "N/A"),
            _label("Amount", "₹${loan['amount']}"),
            _label("Purpose", loan['purpose'] ?? "N/A"),
            _label("Status", loan['status']),
            _label(
              "Applied On",
              loan['created_at'].toString().substring(0, 10),
            ),
            if (scheme != null) ...[
              _label("Interest Rate", "${scheme['interest_rate']}%"),
              _label("Tenure", "${scheme['tenure_months']} months"),
            ],

            const Spacer(),

            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA8E6CF),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 40,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "Back",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
