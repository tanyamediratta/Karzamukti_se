import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'English';

  final List<String> _languages = ['English', 'Hindi', 'Marathi', 'Tamil', 'Telugu'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFFA8E6CF),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'App Preferences',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // 🔔 Notifications toggle
              SwitchListTile(
                activeColor: const Color(0xFF81C784),
                title: const Text('Payment Reminders'),
                subtitle: const Text('Receive payment due and approval notifications'),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                },
              ),

              const Divider(height: 32),

              // 🌓 Dark mode toggle
              SwitchListTile(
              activeColor: const Color(0xFF81C784),
              title: const Text('Dark Mode'),
              subtitle: const Text('Use dark background with pastel accents'),
              value: context.watch<ThemeController>().isDarkMode,
              onChanged: (value) {
                context.read<ThemeController>().toggleTheme();
              },
            ),


              const Divider(height: 32),

              // 🌐 Language dropdown
              const Text(
                'Language',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FDFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA8E6CF)),
                ),
                child: DropdownButton<String>(
                  value: _selectedLanguage,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: _languages
                      .map((lang) => DropdownMenuItem(
                            value: lang,
                            child: Text(lang),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() => _selectedLanguage = val!);
                  },
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Theme Preview',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              // 🎨 Theme preview card
              Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFA8E6CF), Color(0xFFDCEDC1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 3))
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Pastel Theme Active 🌿',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA8E6CF),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.save_outlined, color: Colors.black87),
                  label: const Text(
                    'Save Settings',
                    style: TextStyle(color: Colors.black87, fontSize: 16),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings saved successfully!')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
