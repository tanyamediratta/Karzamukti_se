import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminPersonalInfoScreen extends StatefulWidget {
  const AdminPersonalInfoScreen({super.key});

  @override
  State<AdminPersonalInfoScreen> createState() => _AdminPersonalInfoScreenState();
}

class _AdminPersonalInfoScreenState extends State<AdminPersonalInfoScreen> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;
  final nameController = TextEditingController();
  final designationController = TextEditingController();
  final contactController = TextEditingController();
  final officeController = TextEditingController();
  String email = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    email = user.email ?? '';

    try {
      final data = await supabase
          .from('admin_personal_info')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        nameController.text = data['full_name'] ?? '';
        designationController.text = data['designation'] ?? '';
        contactController.text = data['contact_number'] ?? '';
        officeController.text = data['office_address'] ?? '';
      } else {
        // create an empty row for this admin (policy must allow this)
        await supabase.from('admin_personal_info').insert({
          'id': user.id,
          'full_name': '',
          'designation': '',
          'contact_number': '',
          'office_address': '',
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading admin info: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error loading profile — check RLS policies'),
        backgroundColor: Colors.red,
      ));
    }

    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _save() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('admin_personal_info').update({
        'full_name': nameController.text,
        'designation': designationController.text,
        'contact_number': contactController.text,
        'office_address': officeController.text,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Saved successfully'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      debugPrint('❌ Error saving admin info: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Save failed — check permissions'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFA8E6CF);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Info'),
        backgroundColor: primaryColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  _buildEditableField('Full Name', nameController),
                  _buildNonEditableField('Email', email),
                  _buildEditableField('Designation', designationController),
                  _buildEditableField('Contact Number', contactController),
                  _buildEditableField('Office Address', officeController),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                    child: const Text('Save Changes', style: TextStyle(color: Colors.black)),
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 6, offset: const Offset(2,4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(controller: c, decoration: const InputDecoration(border: InputBorder.none)),
      ]),
    );
  }

  Widget _buildNonEditableField(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 6, offset: const Offset(2,4))]),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold))
      ]),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    designationController.dispose();
    contactController.dispose();
    officeController.dispose();
    super.dispose();
  }
}
