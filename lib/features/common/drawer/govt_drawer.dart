import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../institution/screens/govt_personal_info_screen.dart';
import '../../institution/screens/reports_screen.dart';     // ✅ ADD THIS
import '../../../auth/login_page.dart';
// import '../../institution/screens/govt_setting_screen.dart';  
class GovtDrawer extends StatelessWidget {
  final String name;
  final String role;

  const GovtDrawer({super.key, required this.name, required this.role});

  Future<void> _logout(BuildContext context) async {
    Navigator.of(context).pop(); // close drawer

    await Supabase.instance.client.auth.signOut();

    if (!context.mounted) return;

    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: const Color(0xFFA8E6CF),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: const TextStyle(fontSize: 15, color: Colors.black54),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ---------------- PROFILE ----------------
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text("Profile"),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GovtPersonalInfoScreen(),
                ),
              );
            },
          ),

          // ---------------- REPORTS ----------------
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text("Reports"),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GovtReportsScreen(),   // ✅ THIS WORKS
                ),
              );
            },
          ),

          // ---------------- SETTINGS ----------------
          // ListTile(
          //   leading: const Icon(Icons.settings_outlined),
          //   title: const Text("Settings"),
          //   onTap: () {
          //     Navigator.of(context).pop();
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (_) => const GovtSettingsScreen(),
          //       ),
          //     );
          //   },
          // ),

          // const Spacer(),

          // ---------------- LOGOUT ----------------
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout"),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
