import 'package:supabase_flutter/supabase_flutter.dart';

class GovtLoansService {
  final supabase = Supabase.instance.client;

  // Fetch all loans
  Future<List<Map<String, dynamic>>> getAllLoans() async {
    final response = await supabase
        .from('loan_applications')
        .select('''
          id,
          farmer_id,
          amount,
          status,
          created_at,
          updated_at,
          purpose,
          remarks,
          latitude,
          longitude,
          land_proof_url,
          id_proof_url,
          passbook_url,
          
          farmer:profiles!loan_applications_farmer_id_fkey (
            id,
            full_name
          ),
          
          scheme:schemes!loan_applications_scheme_id_fkey (
            id,
            title,
            minimum_amount,
            interest_rate,
            time_period_months
          )
        ''')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response as List);
  }

  // Add a new loan correctly
  Future<void> addLoan({
    required String farmerId,
    required double amount,
    required int tenureMonths,
    required double interestRate,
    required String schemeId,
  }) async {
    await supabase.from('loan_applications').insert({
      'farmer_id': farmerId,
      'scheme_id': schemeId,
      'amount': amount,
      'interest_rate': interestRate,
      'tenure_months': tenureMonths,
      'status': 'pending',
    });
  }

  // Update status
Future<void> updateLoanStatus(String id, String newStatus) async {
  print("🔥 Updating $id → $newStatus");

  await supabase
      .from('loan_applications')
      .update({
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      })
      .eq('id', id);
}




  // Delete
  Future<void> deleteLoan(String id) async {
    await supabase.from('loan_applications').delete().eq('id', id);
  }
}
