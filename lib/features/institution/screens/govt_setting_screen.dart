import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:karzamukti/core/theme/theme_controller.dart';
import '../../../auth/login_page.dart';
import '../data/govt_setting_preferences.dart';

class GovtSettingsScreen extends StatefulWidget {
  const GovtSettingsScreen({super.key});

  @override
  State<GovtSettingsScreen> createState() => _GovtSettingsScreenState();
}

class _GovtSettingsScreenState extends State<GovtSettingsScreen> {
  final GovtSettingPreferences _prefs = GovtSettingPreferences();

  bool _loading = true;
  bool notificationsEnabled = true;
  String themeMode = 'light';
  String language = 'en';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

Future<void> _loadSettings() async {
  try {
    final data = await _prefs.fetchSettings();
    if (data != null) {
      setState(() {
        notificationsEnabled = data['notifications_enabled'] ?? true;
        themeMode = data['theme_mode'] ?? 'light';
        language = data['language_preference'] ?? 'en';
      });

      // ✅ Safe Provider call (AFTER widget is built)
      Future.microtask(() {
        final themeController = context.read<ThemeController>();
        themeController.setTheme(themeMode == 'dark');
      });
    }
  } catch (e) {
    print('❌ Error loading settings: $e');
  } finally {
    setState(() => _loading = false);
  }
}


  Future<void> _saveSettings() async {
    try {
      await _prefs.saveSettings(
        themeMode: themeMode,
        notificationsEnabled: notificationsEnabled,
        language: language,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Settings updated successfully!')),
      );
    } catch (e) {
      print('❌ Error saving settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Failed to save settings')),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Logged out successfully!")),
      );

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      print('❌ Error logging out: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("⚠️ Logout failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFA8E6CF);
    final themeController = Provider.of<ThemeController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: primaryColor,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 🔔 Notifications
                SwitchListTile(
                  title: const Text("Notifications"),
                  subtitle: const Text("Enable or disable alerts"),
                  value: notificationsEnabled,
                  onChanged: (val) =>
                      setState(() => notificationsEnabled = val),
                  activeColor: Colors.green,
                ),
                const Divider(),

                // 🎨 Theme Mode
                ListTile(
                  title: const Text("Theme Mode"),
                  subtitle: Text(
                    themeMode == 'light'
                        ? 'Currently Light Mode'
                        : 'Currently Dark Mode',
                  ),
                  trailing: DropdownButton<String>(
                    value: themeMode,
                    onChanged: (val) async {
                      final newMode = val ?? 'light';
                      setState(() => themeMode = newMode);

                      // ✅ Update theme instantly
                      themeController.setTheme(newMode == 'dark');

                      // ✅ Save preference in Supabase
                      await _prefs.saveSettings(
                        themeMode: newMode,
                        notificationsEnabled: notificationsEnabled,
                        language: language,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Theme changed to ${newMode.toUpperCase()} mode',
                          ),
                        ),
                      );
                    },
                    items: const [
                      DropdownMenuItem(value: 'light', child: Text('Light')),
                      DropdownMenuItem(value: 'dark', child: Text('Dark')),
                    ],
                  ),
                ),
                const Divider(),

                // 🌐 Language
                ListTile(
                  title: const Text("Language"),
                  subtitle: Text(language == 'en' ? 'English' : 'Hindi'),
                  trailing: DropdownButton<String>(
                    value: language,
                    onChanged: (val) => setState(() => language = val ?? 'en'),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                    ],
                  ),
                ),
                const Divider(),

                const SizedBox(height: 20),

                // 💾 Save Settings
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save, color: Colors.black87),
                  label: const Text(
                    "Save Settings",
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 🚪 Logout
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.85),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    "Logout",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
