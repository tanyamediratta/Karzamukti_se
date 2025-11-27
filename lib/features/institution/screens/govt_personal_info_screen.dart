import 'package:flutter/material.dart';
import '../govt_info_service.dart';

class GovtPersonalInfoScreen extends StatefulWidget {
  const GovtPersonalInfoScreen({super.key});

  @override
  State<GovtPersonalInfoScreen> createState() => _GovtPersonalInfoScreenState();
}

class _GovtPersonalInfoScreenState extends State<GovtPersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final GovtInfoService _service = GovtInfoService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  final _designationController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _officeAddressController = TextEditingController();

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _service.fetchGovtInfo();
    if (data != null) {
      _nameController.text = data['full_name'] ?? '';
      _emailController.text = data['email'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _departmentController.text = data['department'] ?? '';
      _designationController.text = data['designation'] ?? '';
      _employeeIdController.text = data['employee_id'] ?? '';
      _officeAddressController.text = data['office_address'] ?? '';
    }
    setState(() => _loading = false);
  }

  Future<void> _saveData() async {
    if (_formKey.currentState!.validate()) {
      await _service.saveGovtInfo({
        'full_name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'department': _departmentController.text,
        'designation': _designationController.text,
        'employee_id': _employeeIdController.text,
        'office_address': _officeAddressController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Information saved successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFA8E6CF);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Government Official Info'),
        backgroundColor: primaryColor,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Official Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildTextField('Full Name', _nameController),
                    _buildTextField(
                      'Email',
                      _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _buildTextField(
                      'Phone Number',
                      _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildTextField('Department', _departmentController),
                    _buildTextField('Designation', _designationController),
                    _buildTextField('Employee ID', _employeeIdController),
                    _buildTextField(
                      'Office Address',
                      _officeAddressController,
                      maxLines: 2,
                    ),

                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 40,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _saveData,
                        child: const Text(
                          'Save Details',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF8FDFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
