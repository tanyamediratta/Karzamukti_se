import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/farmer/farmer_dashboard.dart';
import '../features/institution/govt_dashboard.dart';
import '../admin/admin_dashboard.dart';

class SetPasswordPage extends StatefulWidget {
  const SetPasswordPage({super.key});

  @override
  State<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
  final _passwordController = TextEditingController();

  String _role = 'farmer';
  bool _isLoading = false;
  bool _checkingProfile = true; // To block UI until verification is done
  bool _isNewUser = false; // Whether to show the role dropdown

  @override
  void initState() {
    super.initState();
    _checkExistingProfile();
  }

  /// 🔍 Check if user already has a profile stored in Supabase
  Future<void> _checkExistingProfile() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null && profile['role'] != null) {
        // ✔ Existing user — auto-redirect to their role dashboard
        final savedRole = profile['role'] as String;

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) {
                if (savedRole == 'admin') return const AdminDashboard();
                if (savedRole == 'institution') return const GovtDashboard();
                return const FarmerDashboard();
              },
            ),
          );
        }
      } else {
        // ✔ NEW USER — show role dropdown + password form
        setState(() {
          _isNewUser = true;
          _checkingProfile = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Error checking profile: $e');
      setState(() => _checkingProfile = false);
    }
  }

  /// 🟩 Complete the signup (password + role)
  Future<void> _completeSignup() async {
    final user = Supabase.instance.client.auth.currentUser;
    final password = _passwordController.text.trim();

    if (password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a password')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Update user password
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );

      // Save profile
      await Supabase.instance.client.from('profiles').upsert({
        'id': user!.id,
        'name': user.email?.split('@')[0],
        'role': _role,
      });

      // Redirect user to dashboard
      if (mounted) {
        if (_role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
        } else if (_role == 'institution') {
          await Supabase.instance.client.from('govt_officials').upsert({
            'user_id': user.id,
            'email': user.email,
            'full_name': user.email?.split('@')[0],
          });
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const GovtDashboard()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const FarmerDashboard()),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unexpected error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loader while checking user
    if (_checkingProfile) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEEF9F1),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Set Your Password',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // PASSWORD FIELD
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // SHOW ROLE DROPDOWN ONLY FOR NEW USERS
                  if (_isNewUser)
                    DropdownButtonFormField<String>(
                      value: _role,
                      items: const [
                        DropdownMenuItem(
                          value: 'farmer',
                          child: Text('Farmer'),
                        ),
                        DropdownMenuItem(
                          value: 'institution',
                          child: Text('Financial Institution'),
                        ),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      ],
                      onChanged: (val) => setState(() => _role = val!),
                      decoration: const InputDecoration(
                        labelText: 'Select Role',
                      ),
                    ),

                  const SizedBox(height: 20),

                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _completeSignup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: const Text('Continue to Dashboard'),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}