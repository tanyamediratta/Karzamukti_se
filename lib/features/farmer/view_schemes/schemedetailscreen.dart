// scheme_detail_screen.dart
import 'package:flutter/material.dart';
import 'scheme_data.dart';

class SchemeDetailScreen extends StatelessWidget {
  final Scheme scheme;

  const SchemeDetailScreen({super.key, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FCF9),
      appBar: AppBar(
        title: Text(scheme.title),
        backgroundColor: const Color(0xFFA8D5BA),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F4E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance,
                  size: 60,
                  color: Colors.green,
                ),
              ),
            ),

            const SizedBox(height: 25),

            Text(
              scheme.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                const Icon(Icons.percent, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  "Interest Rate: ${scheme.interestRate?.toStringAsFixed(2) ?? 'N/A'}%",
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  "Time Period: ${scheme.timePeriodMonths ?? 0} months",
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.currency_rupee, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  "Minimum Amount: ₹${scheme.minimumAmount?.toStringAsFixed(0) ?? 'N/A'}",
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                const Icon(Icons.date_range, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  "Created On: ${scheme.createdAt.split('T')[0]}",
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
