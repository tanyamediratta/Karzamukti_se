import 'package:supabase_flutter/supabase_flutter.dart';

class GovtService {
  final _supabase = Supabase.instance.client;

  /// Fetch all loans
  Future<List<Map<String, dynamic>>> fetchLoans() async {
    final response = await _supabase
        .from('loan_applications')
        .select('id, amount, status, profiles(name, role)');
    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Update loan status (e.g., mark as paid)
  Future<void> updateLoanStatus(String loanId, String newStatus) async {
    await _supabase
        .from('loan_applications')
        .update({'status': newStatus})
        .eq('id', loanId);
  }

  /// Fetch all users (farmers, officials, etc.)
  Future<List<Map<String, dynamic>>> fetchProfiles() async {
    final response = await _supabase
        .from('profiles')
        .select('id, name, role, created_at');
    return (response as List).cast<Map<String, dynamic>>();
  }
}
