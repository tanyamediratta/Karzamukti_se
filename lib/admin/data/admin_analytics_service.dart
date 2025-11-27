import 'package:supabase_flutter/supabase_flutter.dart';

class AdminAnalyticsService {
  final supabase = Supabase.instance.client;

  /// Total users (returns int)
  Future<int> getTotalUsers() async {
    final res = await supabase.from('profiles').select('*').count();
    return res.count ?? 0;
  }

  /// Total farmers
  Future<int> getFarmersCount() async {
    final res = await supabase
        .from('profiles')
        .select('*')
        .eq('role', 'farmer')
        .count();
    return res.count ?? 0;
  }

  /// Total institutions
  Future<int> getInstitutionsCount() async {
    final res = await supabase
        .from('profiles')
        .select('*')
        .eq('role', 'institution')
        .count();
    return res.count ?? 0;
  }

  /// Total admins
  Future<int> getAdminsCount() async {
    final res = await supabase
        .from('profiles')
        .select('*')
        .eq('role', 'admin')
        .count();
    return res.count ?? 0;
  }

  /// Role distribution (view)
  Future<List<Map<String, dynamic>>> getRoleDistribution() async {
    final data = await supabase.from('user_role_distribution').select();
    return List<Map<String, dynamic>>.from(data);
  }

  /// Monthly signups (view)
  Future<List<Map<String, dynamic>>> getMonthlySignups() async {
    final data = await supabase.from('monthly_signups').select();
    return List<Map<String, dynamic>>.from(data);
  }
}
