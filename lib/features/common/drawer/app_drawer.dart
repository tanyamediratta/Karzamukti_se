import 'package:flutter/material.dart';
import 'package:karzamukti/features/farmer/loan_status/loan_status_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/login_page.dart';
import '../personal_info/personal_info_screen.dart';
import '../settings/settings_screen.dart';
import '../documents/documents_screen.dart';
import '../../farmer/log_loan/log_loan_screen.dart';

class AppDrawer extends StatelessWidget {
  final String? name;
  final String? role;

  const AppDrawer({super.key, required this.name, required this.role});

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFA8E6CF), Color(0xFFDCEDC1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 32, color: Color(0xFF6B705C)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? 'User',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (role ?? 'Farmer').toUpperCase(),
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6B705C)),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      onTap: () {
        Navigator.of(context).pop(); // close drawer
        onTap();
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      final client = Supabase.instance.client;

      // ✅ Sign out from Supabase
      await client.auth.signOut();

      // ✅ Navigate back to LoginPage and clear navigation stack
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFarmer = role?.toLowerCase() == 'farmer';
    return Drawer(
      child: Column(
        children: [
          _buildHeader(context),
          const SizedBox(height: 8),
          _tile(context, Icons.person_outline, 'Personal Info', () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (c) => const PersonalInfoScreen()),
            );
          }),
          _tile(context, Icons.description_outlined, 'View Loan Status', () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (c) => const LoanStatusScreen()));
          }),

          // _tile(context, Icons.settings_outlined, 'Settings', () {
          //   Navigator.of(
          //     context,
          //   ).push(MaterialPageRoute(builder: (c) => const SettingsScreen()));
          // }),
          const Divider(),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Color(0xFF6B705C)),
            title: const Text('Logout', style: TextStyle(fontSize: 15)),
            onTap: () => _logout(context),
          ),

          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
