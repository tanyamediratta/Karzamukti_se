import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:karzamukti/features/common/drawer/govt_drawer.dart';
import 'package:karzamukti/features/institution/screens/loan_review_screen.dart';
import 'package:karzamukti/features/institution/screens/disbursement_tracking_screen.dart';
import 'package:karzamukti/features/institution/screens/manage_schemes_screen.dart';
import 'package:karzamukti/features/institution/screens/loan_heatmap_screen.dart'; // ⭐ NEW IMPORT

class GovtDashboard extends StatefulWidget {
  const GovtDashboard({super.key});

  @override
  State<GovtDashboard> createState() => _GovtDashboardState();
}

class _GovtDashboardState extends State<GovtDashboard> {
  final client = Supabase.instance.client;

  String fullName = "Loading...";
  String role = "";
  int pending = 0;
  int approved = 0;
  int rejected = 0;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _fetchCounts();
    _startPollingCounts();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = client.auth.currentUser;
    if (user == null) return;

    final data = await client
        .from('govt_officials')
        .select('full_name, designation')
        .eq('user_id', user.id)
        .maybeSingle();

    setState(() {
      fullName = data?['full_name'] ?? user.email!.split('@')[0];
      role = data?['designation'] ?? "institution";
    });
  }

  Future<void> _fetchCounts() async {
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      // Count statuses from loan_applications
      final loans = await client.from('loan_applications').select('status');

      int p = 0, a = 0, r = 0;

      for (var loan in loans as List) {
        switch (loan['status']) {
          case 'pending':
            p++;
            break;
          case 'approved':
            a++;
            break;
          case 'rejected':
            r++;
            break;
        }
      }

      setState(() {
        pending = p;
        approved = a;
        rejected = r;
      });
    } catch (e) {
      debugPrint("Error fetching counts: $e");
    }
  }

  void _startPollingCounts() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _fetchCounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFA8E6CF);

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: GovtDrawer(name: fullName, role: role),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          "Welcome, $fullName",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _welcomeCard(),
            const SizedBox(height: 20),
            _sectionTitle("Quick Actions"),
            const SizedBox(height: 12),
            _actionsGrid(context),
            const SizedBox(height: 24),
            _sectionTitle("Loan Summary"),
            const SizedBox(height: 12),
            _summaryRow(),
          ],
        ),
      ),
    );
  }

  Widget _welcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFA8E6CF), Color(0xFFDFF3DE)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance, size: 50, color: Colors.black54),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "Welcome back, $fullName",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 18,
        color: Colors.black87,
      ),
    );
  }

  // ⭐ UPDATED ACTION GRID – Settings REMOVED, Heatmap ADDED
  Widget _actionsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.1,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _actionCard(
          "Loan Applications",
          "Review & approve",
          Icons.assignment_outlined,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoanReviewScreen()),
          ),
        ),
        _actionCard(
          "Disbursements",
          "Track released funds",
          Icons.account_balance_wallet_outlined,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const DisbursementTrackingScreen(),
            ),
          ),
        ),
        _actionCard(
          "Manage Schemes",
          "Add or edit schemes",
          Icons.library_add_outlined,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManageSchemesScreen()),
          ),
        ),

        // ⭐ NEW HEATMAP CARD
        _actionCard(
          "View Heatmap",
          "See loan density",
          Icons.map_outlined,
          () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoanHeatmapScreen()),
            );
            setState(() {}); // refresh dashboard on return
          },
        ),
      ],
    );
  }

  Widget _actionCard(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.green.shade100,
              child: Icon(icon, size: 30, color: Colors.green.shade700),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _summaryCard("Pending", pending, Colors.orange),
        _summaryCard("Approved", approved, Colors.green),
        _summaryCard("Rejected", rejected, Colors.red),
      ],
    );
  }

  Widget _summaryCard(String label, int value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(
              color == Colors.orange
                  ? Icons.access_time
                  : color == Colors.green
                  ? Icons.check_circle
                  : Icons.cancel,
              color: color,
            ),
            const SizedBox(height: 6),
            Text(
              "$value",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
