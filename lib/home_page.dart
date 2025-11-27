import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/login_page.dart'; // redirect target after logout

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseClient client = Supabase.instance.client;
  Map<String, dynamic>? profile;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (mounted) setState(() => profile = response);
    } catch (e) {
      debugPrint('⚠️ Error loading profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
      }
    }
  }

  /// ✅ Fully safe logout flow
  Future<void> _performSignOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);

    try {
      debugPrint('🔒 Attempting Supabase sign-out...');

      // 1️⃣ Sign out globally (clears all sessions and tokens)
      await client.auth.signOut(scope: SignOutScope.global);

      // 2️⃣ Check user status
      final currentUser = client.auth.currentUser;
      debugPrint('👤 After sign-out, currentUser = $currentUser');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Signed out successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // 3️⃣ Navigate to LoginPage and clear previous routes
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('❌ Error signing out: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  Future<void> _confirmSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Confirm logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      await _performSignOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome!'),
        actions: [
          IconButton(
            icon: _isSigningOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: _isSigningOut ? null : _confirmSignOut,
          ),
        ],
      ),
      body: Center(
        child: profile == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '👤 Name: ${profile!['name'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '🎭 Role: ${profile!['role'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '📧 Email: ${user?.email ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _isSigningOut ? null : _confirmSignOut,
                    icon: _isSigningOut
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.logout),
                    label: Text(_isSigningOut ? 'Signing out...' : 'Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
