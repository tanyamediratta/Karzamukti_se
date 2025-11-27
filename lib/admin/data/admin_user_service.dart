import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUserService {
  final supabase = Supabase.instance.client;

  /// Fetch all users with basic fields
  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    final res = await supabase
        .from('profiles')
        .select('id, name, full_name, email, role, created_at, phone, active')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  /// Update user role
  Future<void> updateUserRole(String userId, String newRole) async {
    await supabase.from('profiles').update({'role': newRole}).eq('id', userId);
    await _logAction("update_role", "profiles", userId, "Changed role to $newRole");
  }

  /// Set active flag (activate/deactivate)
  Future<void> setUserActive(String userId, bool active) async {
    await supabase.from('profiles').update({'active': active}).eq('id', userId);
    final action = active ? "activate_user" : "deactivate_user";
    await _logAction(action, "profiles", userId, active ? "Activated user" : "Deactivated user");
  }

  /// Delete user completely: auth + profile + related rows (best-effort)
  Future<void> deleteUser(String userId) async {
    // try delete related app rows (best-effort). adjust table names as necessary.
    try {
      await supabase.from('user_documents').delete().eq('profile_id', userId);
      await supabase.from('farmers').delete().eq('profile_id', userId);
      await supabase.from('institutions').delete().eq('profile_id', userId);
    } catch (_) {}

    // delete profile row
    try {
      await supabase.from('profiles').delete().eq('id', userId);
    } catch (_) {}

    // delete auth user via Admin API (requires service_role or admin permission in server environment).
    // This call will fail in client-side if the SDK/environment doesn't permit admin deletion.
    // If it errors, the profile row deletion above still removes the user record.
    try {
      await supabase.auth.admin.deleteUser(userId);
    } catch (e) {
      // it's okay if this fails from client environment; log it server-side if needed.
      // Re-throw if you want to force failure:
      // throw e;
    }

    await _logAction("delete_user", "profiles", userId, "Deleted user (and related rows)");
  }

  /// Fetch details for a single user (optional)
  Future<Map<String, dynamic>?> fetchUserDetails(String userId) async {
    final res = await supabase.from('profiles').select().eq('id', userId).maybeSingle();
    if (res == null) return null;
    return Map<String, dynamic>.from(res);
  }

  /// Insert a system log row for admin actions
  Future<void> _logAction(String action, String table, String recordId, String details) async {
    final user = supabase.auth.currentUser;
    try {
      if (user == null) return;
      await supabase.from('system_logs').insert({
        'actor_id': user.id,
        'action': action,
        'table_name': table,
        'record_id': recordId,
        'details': details,
      });
    } catch (_) {
      // If policy blocks logging, ignore to not break admin flow.
    }
  }
}
