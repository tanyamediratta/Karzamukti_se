import 'package:flutter/material.dart';
import 'package:karzamukti/admin/user_management/user_management_screen.dart';
import 'package:karzamukti/admin/screens/admin_analytics_screen.dart';
// import 'package:karzamukti/features/admin/screens/admin_logs_screen.dart';
import 'package:karzamukti/features/common/drawer/admin_drawer.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFA8E6CF);

    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: primaryColor,
        elevation: 2,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Welcome, Admin 👋',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // 🌟 FLASHCARDS GRID
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9,
                    children: [
                      // USER MANAGEMENT
                      _buildFlashCard(
                        context,
                        title: 'Official User Management',
                        subtitle: 'Modify or deactivate accounts',
                        icon: Icons.manage_accounts,
                        color: primaryColor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UserManagementScreen(),
                            ),
                          );
                        },
                      ),

                      // ANALYTICS
                      _buildFlashCard(
                        context,
                        title: 'Analytics Overview',
                        subtitle: 'Visualize platform performance',
                        icon: Icons.bar_chart_rounded,
                        color: primaryColor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminAnalyticsScreen(),
                            ),
                          );
                        },
                      ),

                      // SYSTEM LOGS (ADDED HERE)
                      // _buildFlashCard(
                      //   context,
                      //   title: 'System Logs',
                      //   subtitle: 'View admin activity logs',
                      //   icon: Icons.history_rounded,
                      //   color: primaryColor,
                      //   onTap: () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (_) => const AdminLogsScreen(),
                      //       ),
                      //     );
                      //   },
                      // ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 Flashcard widget
  Widget _buildFlashCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.25),
              radius: 28,
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
