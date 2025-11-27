import 'package:flutter/material.dart';
import 'package:karzamukti/admin/data/admin_user_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AdminUserService _userService = AdminUserService();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filtered = [];
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;

  final List<String> _roles = ['admin', 'farmer', 'institution'];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(() => _onSearchChanged());
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final data = await _userService.fetchAllUsers();
      setState(() {
        _users = data;
        _filtered = data;
      });
    } catch (e) {
      _showSnack("Failed to load users: $e", isError: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = List.from(_users));
      return;
    }
    setState(() {
      _filtered = _users.where((u) {
        final name = (u['full_name'] ?? u['name'] ?? '')
            .toString()
            .toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        return name.contains(q) || email.contains(q);
      }).toList();
    });
  }

  Future<void> _changeRole(BuildContext ctx, Map<String, dynamic> user) async {
    final String userId = user['id'];
    String selected = (user['role'] ?? _roles.first).toString();

    await showModalBottomSheet(
      context: ctx,
      builder: (c) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Change Role",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  for (var r in _roles)
                    RadioListTile<String>(
                      title: Text(r),
                      value: r,
                      groupValue: selected,
                      onChanged: (v) =>
                          setStateSB(() => selected = v ?? selected),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(c),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(c);
                          try {
                            await _userService.updateUserRole(userId, selected);
                            _showSnack("Role updated");
                            await _loadUsers();
                          } catch (e) {
                            _showSnack(
                              "Failed to update role: $e",
                              isError: true,
                            );
                          }
                        },
                        child: const Text("Save"),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleActive(
    BuildContext ctx,
    Map<String, dynamic> user,
  ) async {
    final bool currentlyActive = (user['active'] == null)
        ? true
        : (user['active'] as bool);
    final bool newVal = !currentlyActive;
    final actionText = newVal ? "Activate" : "Deactivate";

    final confirmed = await _confirmDialog(
      ctx,
      "$actionText user",
      "Are you sure you want to $actionText this user?",
    );
    if (!confirmed) return;

    try {
      await _userService.setUserActive(user['id'], newVal);
      _showSnack("${actionText}d successfully");
      await _loadUsers();
    } catch (e) {
      _showSnack("Failed to $actionText user: $e", isError: true);
    }
  }

  Future<bool> _confirmDialog(
    BuildContext ctx,
    String title,
    String body,
  ) async {
    return (await showDialog<bool>(
          context: ctx,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Confirm"),
              ),
            ],
          ),
        )) ??
        false;
  }

  void _showSnack(String msg, {bool isError = false}) {
    final color = isError ? Colors.redAccent : Colors.green;
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Widget _roleBadge(String role) {
    Color bg;
    switch (role) {
      case 'farmer':
        bg = Colors.green.shade300;
        break;
      case 'institution':
        bg = Colors.deepOrange.shade300;
        break;
      case 'admin':
        bg = Colors.blueGrey.shade300;
        break;
      default:
        bg = Colors.grey.shade300;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFA8E6CF);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text("User Management"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by name or email...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadUsers,
                    child: _filtered.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 80),
                              Center(child: Text("No users found")),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) {
                              final u = _filtered[i];
                              final displayName =
                                  (u['full_name'] ??
                                          u['name'] ??
                                          "Unknown User")
                                      .toString();
                              final email = (u['email'] ?? '').toString();
                              final role = (u['role'] ?? 'unknown').toString();
                              final active = (u['active'] == null)
                                  ? true
                                  : (u['active'] as bool);

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFA8E6CF),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.black,
                                  ),
                                ),
                                title: Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(email),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _roleBadge(role),
                                    const SizedBox(width: 8),
                                    PopupMenuButton<String>(
                                      onSelected: (v) async {
                                        if (v == 'role') {
                                          await _changeRole(context, u);
                                        } else if (v == 'toggle_active') {
                                          await _toggleActive(context, u);
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(
                                          value: 'role',
                                          child: Text("Change Role"),
                                        ),
                                        PopupMenuItem(
                                          value: 'toggle_active',
                                          child: Text(
                                            active ? "Deactivate" : "Activate",
                                          ),
                                        ),
                                        // DELETE REMOVED
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
