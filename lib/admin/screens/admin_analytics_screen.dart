import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:karzamukti/admin/data/admin_analytics_service.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final AdminAnalyticsService _analytics = AdminAnalyticsService();

  bool loading = true;
  int totalUsers = 0;
  int totalFarmers = 0;
  int totalInstitutions = 0;
  int totalAdmins = 0;

  List roles = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      totalUsers = await _analytics.getTotalUsers();
      totalFarmers = await _analytics.getFarmersCount();
      totalInstitutions = await _analytics.getInstitutionsCount();
      totalAdmins = await _analytics.getAdminsCount();
      roles = await _analytics.getRoleDistribution();
    } catch (e) {
      debugPrint('Analytics load error: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFA8E6CF);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text("Analytics Overview"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCards(),
                const SizedBox(height: 20),
                _buildRolePieChart(),
              ],
            ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _summaryCard("Total Users", totalUsers),
        _summaryCard("Farmers", totalFarmers),
        _summaryCard("Institutions", totalInstitutions),
        _summaryCard("Admins", totalAdmins),
      ],
    );
  }

  Widget _summaryCard(String title, int value) {
    return Container(
      width: 90,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            color: Colors.grey.withOpacity(0.18),
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildRolePieChart() {
    if (roles.isEmpty) {
      return Container(
        height: 260,
        padding: const EdgeInsets.all(16),
        decoration: _box(),
        child: const Center(child: Text('No role distribution data')),
      );
    }

    Color colorForRole(String r) {
      switch (r) {
        case 'farmer':
          return Colors.green;
        case 'institution':
          return Colors.deepOrange;
        case 'admin':
          return Colors.blueGrey;
        default:
          return Colors.orange;
      }
    }

    return Container(
      height: 320,
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Users by Role",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: roles.map((r) {
                  return PieChartSectionData(
                    value: double.parse(r['total'].toString()),
                    title: r['role'].toString(),
                    color: colorForRole(r['role'].toString()),
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _box() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          blurRadius: 6,
          color: Colors.grey.withOpacity(0.18),
          offset: const Offset(2, 3),
        ),
      ],
    );
  }
}
