import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:karzamukti/core/theme/theme_controller.dart';
import 'package:karzamukti/admin/data/admin_settings_service.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final AdminSettingsService _settingsService = AdminSettingsService();

  bool isLoading = true;
  bool notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

 Future<void> _loadSettings() async {
  final settings = await _settingsService.getSettings();
  if (settings != null) {
    notificationsEnabled = settings['notifications_enabled'] ?? true;

    // Safe Provider access
    Future.microtask(() {
      final themeController = context.read<ThemeController>();
      if (settings['dark_mode'] != themeController.isDarkMode) {
        themeController.setTheme(settings['dark_mode']);
      }
    });
  }

  setState(() => isLoading = false);
}


  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFFA8E6CF);
    final themeController = Provider.of<ThemeController>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Settings'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // DARK MODE TOGGLE
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Switch app theme'),
                  value: themeController.isDarkMode,
                  onChanged: (val) async {
                    themeController.toggleTheme();
                    await _settingsService.updateDarkMode(val);
                  },
                ),

                const Divider(),

                // NOTIFICATIONS TOGGLE
                SwitchListTile(
                  title: const Text('Notifications'),
                  subtitle: const Text('Enable alerts for updates'),
                  value: notificationsEnabled,
                  onChanged: (val) async {
                    setState(() => notificationsEnabled = val);
                    await _settingsService.updateNotifications(val);
                  },
                ),
              ],
            ),
    );
  }
}
