import 'package:supabase_flutter/supabase_flutter.dart';

class GovtSchemeService {
  final supabase = Supabase.instance.client;

  // Fetch all schemes
  Future<List<Map<String, dynamic>>> getSchemes() async {
    final response = await supabase
        .from('schemes')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Add a new scheme
  Future<void> addScheme({
    required String title,
    required String description,
    required double minimumAmount,
    required double interestRate,
    required int timePeriodMonths,
  }) async {
    final userId = supabase.auth.currentUser!.id;

    // 🔍 Fetch govt_official primary key
    final govt = await supabase
        .from('govt_officials')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (govt == null) {
      throw Exception(
        "⚠ No govt_official entry found. Signup might be broken.",
      );
    }

    await supabase.from('schemes').insert({
      'title': title,
      'description': description,
      'minimum_amount': minimumAmount,
      'interest_rate': interestRate,
      'time_period_months': timePeriodMonths,
      'institution_id': govt['id'],
    });
  }

  Future<void> deleteScheme(String id) async {
    await supabase.from('schemes').delete().eq('id', id);
  }
}
