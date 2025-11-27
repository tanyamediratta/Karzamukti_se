import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:karzamukti/admin/admin_dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/login_page.dart';
import 'features/farmer/farmer_dashboard.dart';
import 'features/institution/govt_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const KarzamuktiApp());
}

class KarzamuktiApp extends StatefulWidget {
  const KarzamuktiApp({super.key});

  @override
  State<KarzamuktiApp> createState() => _KarzamuktiAppState();
}

class _KarzamuktiAppState extends State<KarzamuktiApp> {
  final supabase = Supabase.instance.client;
  Session? _session;
  bool _ready = false;

  @override
  void initState() {
    super.initState();

    supabase.auth.onAuthStateChange.listen((event) async {
      final session = event.session;

      setState(() {
        _session = session;
        _ready = true;
      });
    });
  }

  Future<Widget> _resolveHome() async {
    if (_session == null) return const LoginPage();

    final profile = await supabase
        .from('profiles')
        .select('role')
        .eq('id', _session!.user.id)
        .maybeSingle();

    final role = profile?['role'] ?? 'farmer';

    if (role == 'institution') {
      return const GovtDashboard();
    }
    if (role == 'admin') {
      return const AdminDashboard();
    } else {
      return const FarmerDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return FutureBuilder(
      future: _resolveHome(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        return MaterialApp(debugShowCheckedModeBanner: false, home: snap.data!);
      },
    );
  }
}