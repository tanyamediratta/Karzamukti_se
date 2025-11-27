import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SchemeInsightsScreen extends StatelessWidget {
  const SchemeInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFA8E6CF);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheme Insights'),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active Schemes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(value: 35, title: 'PM-KISAN', color: primaryColor),
                    PieChartSectionData(value: 25, title: 'AIF', color: Colors.teal[200]),
                    PieChartSectionData(value: 20, title: 'PMFBY', color: Colors.teal[400]),
                    PieChartSectionData(value: 20, title: 'KCC', color: Colors.green[300]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
