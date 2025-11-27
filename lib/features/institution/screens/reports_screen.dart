import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../govt_loans_service.dart';

class GovtReportsScreen extends StatefulWidget {
  const GovtReportsScreen({super.key});

  @override
  State<GovtReportsScreen> createState() => _GovtReportsScreenState();
}

class _GovtReportsScreenState extends State<GovtReportsScreen> {
  final GovtLoansService _loanService = GovtLoansService();
  bool _loading = true;

  int totalLoans = 0;
  int approvedLoans = 0;
  int disbursedLoans = 0;
  int rejectedLoans = 0;
  int totalSchemes = 0;
  int activeSchemes = 0;
  double totalDisbursed = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      // Fetch loans
      final loans = await _loanService.getAllLoans();

      // Fetch schemes
      final schemesResponse = await Supabase.instance.client
          .from('schemes')
          .select();

      // Calculate total disbursed amount
      double disbursedAmount = 0;
      for (final loan in loans) {
        if (loan['status'] == 'disbursed' && loan['amount'] != null) {
          disbursedAmount += double.tryParse(loan['amount'].toString()) ?? 0;
        }
      }

      setState(() {
        totalLoans = loans.length;
        approvedLoans = loans.where((l) => l['status'] == 'approved').length;
        disbursedLoans = loans.where((l) => l['status'] == 'disbursed').length;
        rejectedLoans = loans.where((l) => l['status'] == 'rejected').length;

        totalSchemes = schemesResponse.length;
        activeSchemes = schemesResponse
            .where((s) => s['status'] == 'active')
            .length;

        totalDisbursed = disbursedAmount;
        _loading = false;
      });
    } catch (e) {
      print("❌ Error fetching stats: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFA8E6CF);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: primaryColor,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(
                      title: 'Total Loans',
                      value: totalLoans.toString(),
                      color: Colors.blueAccent,
                    ),
                    _buildSummaryCard(
                      title: 'Approved Loans',
                      value: approvedLoans.toString(),
                      color: Colors.green,
                    ),
                    _buildSummaryCard(
                      title: 'Disbursed Loans',
                      value: disbursedLoans.toString(),
                      color: Colors.orange,
                    ),
                    _buildSummaryCard(
                      title: 'Rejected Loans',
                      value: rejectedLoans.toString(),
                      color: Colors.redAccent,
                    ),
                    _buildSummaryCard(
                      title: 'Total Disbursed Amount',
                      value: '₹${totalDisbursed.toStringAsFixed(2)}',
                      color: Colors.teal,
                    ),
                    const Divider(height: 30),
                    _buildSummaryCard(
                      title: 'Total Schemes',
                      value: totalSchemes.toString(),
                      color: Colors.deepPurple,
                    ),
                    _buildSummaryCard(
                      title: 'Active Schemes',
                      value: activeSchemes.toString(),
                      color: Colors.purpleAccent,
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Loan Status Distribution',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AspectRatio(
                      aspectRatio: 1.3,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 0,
                          centerSpaceRadius: 45,
                          sections: [
                            PieChartSectionData(
                              title: 'Approved',
                              value: approvedLoans.toDouble(),
                              color: Colors.green,
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            PieChartSectionData(
                              title: 'Disbursed',
                              value: disbursedLoans.toDouble(),
                              color: Colors.orange,
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            PieChartSectionData(
                              title: 'Rejected',
                              value: rejectedLoans.toDouble(),
                              color: Colors.redAccent,
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Loans by Status (Bar Chart)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: BarChart(
                        BarChartData(
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(show: false),
                          barGroups: [
                            _buildBarGroup(
                              'Approved',
                              approvedLoans,
                              Colors.green,
                            ),
                            _buildBarGroup(
                              'Disbursed',
                              disbursedLoans,
                              Colors.orange,
                            ),
                            _buildBarGroup(
                              'Rejected',
                              rejectedLoans,
                              Colors.redAccent,
                            ),
                          ],
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget:
                                    (double value, TitleMeta meta) {
                                      switch (value.toInt()) {
                                        case 0:
                                          return const Text('Approved');
                                        case 1:
                                          return const Text('Disbursed');
                                        case 2:
                                          return const Text('Rejected');
                                      }
                                      return const Text('');
                                    },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: color.withOpacity(0.15),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(String label, int value, Color color) {
    int index;
    switch (label) {
      case 'Approved':
        index = 0;
        break;
      case 'Disbursed':
        index = 1;
        break;
      default:
        index = 2;
    }

    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: value.toDouble(),
          color: color,
          width: 24,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
