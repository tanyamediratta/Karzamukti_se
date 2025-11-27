import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/farmer/farmer_dashboard.dart';
import '../features/institution/govt_dashboard.dart';
import '../admin/admin_dashboard.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // 1️⃣ LOGIN WITH SUPABASE
      final response =
          await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session == null || response.user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid email or password.')),
        );
        return;
      }

      final userId = response.user!.id;

      // 2️⃣ FETCH PROFILE WITH ROLE + ACTIVE STATUS
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role, active')
          .eq('id', userId)
          .maybeSingle();

      if (profile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User profile not found.')),
        );
        await Supabase.instance.client.auth.signOut();
        return;
      }

      final bool isActive = profile['active'] == true;

      // 3️⃣ IF ACCOUNT IS DEACTIVATED → BLOCK LOGIN
  if (!isActive) {
  if (!mounted) return;

  // 1️⃣ Show popup first (MUST AWAIT)
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Account Deactivated"),
      content: const Text(
        "Your account has been deactivated by an administrator.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK"),
        ),
      ],
    ),
  );

  // 2️⃣ After closing popup → log user out
  await Supabase.instance.client.auth.signOut();

  return; // Stop login flow
}


      // 4️⃣ ROLE-BASED NAVIGATION
      final role = profile['role'] ?? 'farmer';

      if (!mounted) return;

      Widget page;
      if (role == "institution") {
        page = const GovtDashboard();
      } else if (role == "admin") {
        page = const AdminDashboard();
      } else {
        page = const FarmerDashboard();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF9F1),
      body: Center(
        child: SingleChildScrollView(
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
                    'Login to Karzamukti',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // EMAIL FIELD
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PASSWORD FIELD
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // LOGIN BUTTON
                  _loading
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                          onPressed: _login,
                          icon: const Icon(Icons.login),
                          label: const Text('Login'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                  const SizedBox(height: 16),

                  // SIGNUP LINK
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupPage()),
                    ),
                    child: const Text("Don't have an account? Sign Up"),
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
