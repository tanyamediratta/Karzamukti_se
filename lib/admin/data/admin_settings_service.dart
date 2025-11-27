import 'package:supabase_flutter/supabase_flutter.dart';

class AdminSettingsService {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getSettings() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final result = await supabase
        .from('admin_settings')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (result == null) {
      // Create default settings if not exists
      await supabase.from('admin_settings').insert({
        'id': user.id,
        'dark_mode': false,
        'notifications_enabled': true,
      });

      return {
        'dark_mode': false,
        'notifications_enabled': true,
      };
    }

    return result;
  }

  Future<void> updateDarkMode(bool value) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('admin_settings').update({
      'dark_mode': value,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', user.id);
  }

  Future<void> updateNotifications(bool value) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('admin_settings').update({
      'notifications_enabled': value,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', user.id);
  }
}
