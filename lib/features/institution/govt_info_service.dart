import 'package:supabase_flutter/supabase_flutter.dart';

class GovtInfoService {
  final supabase = Supabase.instance.client;

  /// Fetch government official info for the logged-in user
  Future<Map<String, dynamic>?> fetchGovtInfo() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      print("❌ No logged-in user found.");
      return null;
    }

    try {
      final response = await supabase
          .from('govt_officials')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      print("📥 Govt info fetched: $response");
      return response;
    } catch (e) {
      print("❌ Error fetching govt info: $e");
      return null;
    }
  }

  /// Save or update government official info
  Future<void> saveGovtInfo(Map<String, dynamic> data) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      print("❌ Cannot save info — no user logged in.");
      return;
    }

    try {
      // Check if record exists for this user
      final existing = await supabase
          .from('govt_officials')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      print("🔍 Existing record: $existing");

      if (existing != null && existing.isNotEmpty) {
        // Update existing record
        final updateResponse = await supabase
            .from('govt_officials')
            .update(data)
            .eq('user_id', user.id)
            .select();
        print("✏️ Update response: $updateResponse");
      } else {
        // Insert new record
        final insertResponse = await supabase.from('govt_officials').insert({
          'user_id': user.id,
          ...data,
        }).select();
        print("➕ Insert response: $insertResponse");
      }
    } catch (e) {
      print("❌ Error saving govt info: $e");
    }
  }
}
