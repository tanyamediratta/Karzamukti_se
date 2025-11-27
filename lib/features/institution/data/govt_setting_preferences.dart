import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository (data connector) to manage government user preferences in Supabase
class GovtSettingPreferences {
  final supabase = Supabase.instance.client;

  /// Fetch preferences for the currently logged-in government user
  Future<Map<String, dynamic>?> fetchSettings() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      print("⚠️ No user logged in!");
      return null;
    }

    try {
      final response = await supabase
          .from('user_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      print("📥 Settings fetched: $response");
      return response;
    } catch (e) {
      print("❌ Error fetching settings: $e");
      return null;
    }
  }

  /// Save or update preferences in the 'user_settings' table
  Future<void> saveSettings({
    required String themeMode,
    required bool notificationsEnabled,
    required String language,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      print("⚠️ Cannot save — no user logged in!");
      return;
    }

    try {
      final existing = await supabase
          .from('user_settings')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (existing != null && existing.isNotEmpty) {
        print("✏️ Updating existing settings...");
        await supabase.from('user_settings').update({
          'theme_mode': themeMode,
          'notifications_enabled': notificationsEnabled,
          'language_preference': language,
        }).eq('user_id', user.id);
      } else {
        print("➕ Inserting new settings...");
        await supabase.from('user_settings').insert({
          'user_id': user.id,
          'theme_mode': themeMode,
          'notifications_enabled': notificationsEnabled,
          'language_preference': language,
        });
      }

      print("✅ Settings saved successfully");
    } catch (e) {
      print("❌ Error saving settings: $e");
    }
  }
}
