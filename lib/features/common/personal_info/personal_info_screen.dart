import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _aadharController = TextEditingController();
  final _panController = TextEditingController();
  final _addressController = TextEditingController();

  // Picked files (Drive-safe)
  PlatformFile? aadharFile;
  PlatformFile? panFile;
  PlatformFile? landFile;

  // Uploaded URLs
  String? aadharUrl;
  String? panUrl;
  String? landUrl;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // 📥 Load user profile
  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        setState(() {
          _nameController.text = data['full_name'] ?? '';
          _ageController.text = data['age']?.toString() ?? '';
          _phoneController.text = data['phone'] ?? '';
          _emailController.text = data['email'] ?? '';
          _dobController.text = data['dob'] != null
              ? DateTime.parse(data['dob']).toIso8601String().split('T').first
              : '';
          _aadharController.text = data['aadhar'] ?? '';
          _panController.text = data['pan'] ?? '';
          _addressController.text = data['address'] ?? '';
          aadharUrl = data['aadhar_file_url'];
          panUrl = data['pan_file_url'];
          landUrl = data['land_proof_url'];
        });
      }
    } catch (e) {
      print("⚠️ Error loading profile: $e");
    }
  }

  // 📂 Drive-safe file picker
  Future<void> _pickFile(Function(PlatformFile) onPicked) async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        print('📁 Picked file: ${file.name} (path: ${file.path})');
        onPicked(file);
      } else {
        print('⚠️ No file selected.');
      }
    } catch (e) {
      print('❌ File pick failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ File selection failed. Try again.')),
      );
    }
  }

  // 📅 DOB picker
  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(1995),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      _dobController.text =
          "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";
    }
  }

  // 📤 Upload file (supports both Drive + local)
  Future<String?> _uploadFile(
    PlatformFile pickedFile,
    String bucket,
    String userId,
  ) async {
    final fileName = pickedFile.name;
    final storagePath = '$userId/$fileName';
    print('🧠 Uploading to $storagePath');

    try {
      if (pickedFile.bytes != null) {
        // Drive file (in-memory)
        await supabase.storage
            .from(bucket)
            .uploadBinary(
              storagePath,
              pickedFile.bytes!,
              fileOptions: const FileOptions(upsert: true),
            );
      } else if (pickedFile.path != null) {
        // Local file
        await supabase.storage
            .from(bucket)
            .upload(
              storagePath,
              File(pickedFile.path!),
              fileOptions: const FileOptions(upsert: true),
            );
      } else {
        print('❌ No file data found.');
        return null;
      }

      final publicUrl = supabase.storage.from(bucket).getPublicUrl(storagePath);
      print('✅ Uploaded: $publicUrl');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ ${pickedFile.name} uploaded successfully!')),
      );
      return publicUrl;
    } catch (e) {
      print('❌ Upload error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Upload failed: $e')));
      return null;
    }
  }

  // 💾 Save profile
  Future<void> _saveDetails() async {
    if (!_formKey.currentState!.validate()) return;

    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('❌ User not logged in')));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('⏳ Saving your details...')));

    try {
      String? aadharUrlUpdated = aadharUrl;
      String? panUrlUpdated = panUrl;
      String? landUrlUpdated = landUrl;

      if (aadharFile != null) {
        aadharUrlUpdated = await _uploadFile(aadharFile!, 'documents', user.id);
      }
      if (panFile != null) {
        panUrlUpdated = await _uploadFile(panFile!, 'documents', user.id);
      }
      if (landFile != null) {
        landUrlUpdated = await _uploadFile(landFile!, 'documents', user.id);
      }

      final response = await supabase
          .from('profiles')
          .update({
            'full_name': _nameController.text.trim(),
            'age': int.tryParse(_ageController.text.trim()),
            'phone': _phoneController.text.trim(),
            'email': _emailController.text.trim(),
            'dob': _dobController.text.trim(),
            'aadhar': _aadharController.text.trim(),
            'pan': _panController.text.trim(),
            'address': _addressController.text.trim(),
            'aadhar_file_url': aadharUrlUpdated,
            'pan_file_url': panUrlUpdated,
            'land_proof_url': landUrlUpdated,
          })
          .eq('id', user.id)
          .select()
          .maybeSingle();

      print('✅ Supabase updated: $response');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Profile updated successfully!')),
      );
    } catch (e) {
      print('❌ Error saving profile: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error saving: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Information'),
        backgroundColor: const Color(0xFFA8E6CF),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Farmer Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField('Full Name', _nameController),
                _buildTextField(
                  'Age',
                  _ageController,
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  'Phone Number',
                  _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                _buildTextField(
                  'Email',
                  _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: _buildTextField('Date of Birth', _dobController),
                  ),
                ),
                _buildTextField('Aadhar Number', _aadharController),
                _buildTextField('PAN Number', _panController),
                _buildTextField('Address', _addressController, maxLines: 3),
                const SizedBox(height: 20),
                const Text(
                  'Upload Required Documents',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                _buildUploadButton(
                  'Upload Aadhar Card',
                  aadharFile,
                  aadharUrl,
                  (file) => setState(() => aadharFile = file),
                ),
                _buildUploadButton(
                  'Upload PAN Card',
                  panFile,
                  panUrl,
                  (file) => setState(() => panFile = file),
                ),
                _buildUploadButton(
                  'Upload Land Proof',
                  landFile,
                  landUrl,
                  (file) => setState(() => landFile = file),
                ),

                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: _saveDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA8E6CF),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 40,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
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
      ),
    );
  }

  // 🧱 Text Field Builder
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
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: (value) =>
            value == null || value.isEmpty ? 'Please enter $label' : null,
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

  // 📎 File Upload Button
  Widget _buildUploadButton(
    String label,
    PlatformFile? pickedFile,
    String? existingUrl,
    Function(PlatformFile) onPicked,
  ) {
    final hasUploaded = existingUrl != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              side: const BorderSide(color: Color(0xFFA8E6CF)),
            ),
            onPressed: () => _pickFile(onPicked),
            icon: Icon(
              hasUploaded ? Icons.check_circle : Icons.upload_file,
              color: hasUploaded ? Colors.green : Colors.black87,
            ),
            label: Text(
              pickedFile != null
                  ? "$label ✅ (${pickedFile.name})"
                  : hasUploaded
                  ? "$label ✅ (Already uploaded)"
                  : label,
              style: const TextStyle(color: Colors.black87),
            ),
          ),

          // 🔗 “View File” link
          if (existingUrl != null) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                await launchUrl(Uri.parse(existingUrl));
              },
              child: const Text(
                "📄 View Uploaded File",
                style: TextStyle(
                  color: Colors.blueAccent,
                  decoration: TextDecoration.underline,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
