import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../common/drawer/app_drawer.dart';
import 'view_schemes/schemes_screen.dart';
import 'log_loan/log_loan_screen.dart';
import 'loan_match/loan_comparison_screen.dart';
import 'record_payment/record_payment_screen.dart';

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({super.key});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  final supabase = Supabase.instance.client;
  String? _name;
  String? _role;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  /// ✅ Fetch user profile from Supabase
  Future<void> _fetchProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // request both full_name and name from profiles
      final response = await supabase
          .from('profiles')
          .select('full_name, name, role')
          .eq('id', user.id)
          .maybeSingle();

      // response can be null, or a Map<String, dynamic>
      final String? dbFullName = response?['full_name'] as String?;
      final String? dbName = response?['name'] as String?;
      final String emailPrefix = user.email?.split('@').first ?? '';

      // choose preferred display name: full_name > name > email prefix > 'Farmer'
      String displayName;
      if (dbFullName != null && dbFullName.trim().isNotEmpty) {
        displayName = dbFullName.trim();
      } else if (dbName != null && dbName.trim().isNotEmpty) {
        displayName = dbName.trim();
      } else if (emailPrefix.isNotEmpty) {
        displayName = emailPrefix;
      } else {
        displayName = 'Farmer';
      }

      setState(() {
        _name = displayName;
        _role = (response?['role'] as String?) ?? 'Farmer';
      });
    } catch (e) {
      print('❌ Error fetching profile: $e');
      // keep existing fallback if fetch fails
      final user = supabase.auth.currentUser;
      setState(() {
        _name = user?.email?.split('@').first ?? 'Farmer';
        _role = 'Farmer';
      });
    }
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFFEEF9F1), Color(0xFFDFF3DE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white,
                child: Icon(icon, color: AppColors.muted),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.black45,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _name ?? 'Loading...';
    final role = _role ?? 'Farmer';

    return Scaffold(
      drawer: AppDrawer(name: name, role: role),
      appBar: AppBar(
        title: const Text('Farmer Dashboard'),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              name,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            const Text(
              'Quick actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            /// 🔹 View Government Schemes
            _buildCard(
              icon: Icons.receipt_long,
              title: 'View Existing Schemes',
              subtitle: 'See your active loans & schedules',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SchemesScreen(),
                  ),
                );
              },
            ),

            /// 🔹 Log a new loan
            _buildCard(
              icon: Icons.add_box,
              title: 'Log a Loan',
              subtitle: 'Add new loan details',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LogLoanScreen(),
                  ),
                );
              },
            ),

            /// 🔹 Record repayment
            _buildCard(
              icon: Icons.payment,
              title: 'Record Payment',
              subtitle: 'Add loan repayments',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RecordPaymentScreen(),
                  ),
                );
              },
            ),

            const Spacer(),

            /// 🔹 Loan Comparison Tool
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pastelMint,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.calculate_outlined),
                label: const Text(
                  'Open Loan Comparison Tool',
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoanComparisonScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
