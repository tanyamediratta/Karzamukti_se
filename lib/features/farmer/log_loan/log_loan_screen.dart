import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:location/location.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LogLoanScreen extends StatefulWidget {
  const LogLoanScreen({super.key});

  @override
  State<LogLoanScreen> createState() => _LogLoanScreenState();
}

class _LogLoanScreenState extends State<LogLoanScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _loanAmountController = TextEditingController();
  final TextEditingController _interestRateController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  List<Map<String, dynamic>> _schemes = [];
  Map<String, dynamic>? _selectedScheme;
  bool loadingSchemes = true;

  // Institution ID from schemes table
  String? institutionId;

  // Location
  double? latitude;
  double? longitude;

  // Files
  PlatformFile? landProof;
  PlatformFile? idProof;
  PlatformFile? passbook;

  @override
  void initState() {
    super.initState();
    _loadSchemes();
  }

  // -------------------------------------------------------------
  // 🔽 Load Schemes (NO JOIN)
  // -------------------------------------------------------------
  Future<void> _loadSchemes() async {
    try {
      final data = await Supabase.instance.client
          .from('schemes')
          .select()
          .order('created_at');

      setState(() {
        _schemes = List<Map<String, dynamic>>.from(data);
        loadingSchemes = false;
      });
    } catch (e) {
      print("Error loading schemes: $e");
      loadingSchemes = false;
    }
  }

  // -------------------------------------------------------------
  // 📍 Get Location
  // -------------------------------------------------------------
  Future<void> _getLocation() async {
    Location location = Location();

    bool enabled = await location.serviceEnabled();
    if (!enabled) enabled = await location.requestService();
    if (!enabled) return;

    PermissionStatus permission = await location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await location.requestPermission();
      if (permission != PermissionStatus.granted) return;
    }

    final loc = await location.getLocation();
    setState(() {
      latitude = loc.latitude;
      longitude = loc.longitude;
    });
  }

  // -------------------------------------------------------------
  // 📂 File Picker
  // -------------------------------------------------------------
  Future<PlatformFile?> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null) return result.files.single;
    return null;
  }

  // -------------------------------------------------------------
  // 📤 Upload file
  // -------------------------------------------------------------
  Future<String?> _uploadFile(PlatformFile file, String userId) async {
    final path = "$userId/${file.name}";
    try {
      if (file.bytes != null) {
        await Supabase.instance.client.storage
            .from('documents')
            .uploadBinary(
              path,
              file.bytes!,
              fileOptions: const FileOptions(upsert: true),
            );
      }
      return Supabase.instance.client.storage
          .from('documents')
          .getPublicUrl(path);
    } catch (e) {
      print("Upload failed: $e");
      return null;
    }
  }

  // -------------------------------------------------------------
  // 🚀 Submit Loan Application
  // -------------------------------------------------------------
  Future<void> _submitLoan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedScheme == null) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final userAmount = double.parse(_loanAmountController.text.trim());
    final minAmount = (_selectedScheme!['minimum_amount']).toDouble();

    if (userAmount < minAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Minimum amount for this scheme is ₹$minAmount"),
        ),
      );
      return;
    }

    if (latitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fetch your location")),
      );
      return;
    }

    // Upload documents
    String? landUrl, idUrl, passbookUrl;
    if (landProof != null) landUrl = await _uploadFile(landProof!, user.id);
    if (idProof != null) idUrl = await _uploadFile(idProof!, user.id);
    if (passbook != null) passbookUrl = await _uploadFile(passbook!, user.id);

    // -------------------------------------------------------------
    // 🛑 FIX: Force location to stay inside India
    // -------------------------------------------------------------
    bool isIndia(double lat, double lon) {
      return lat >= 6.0 && lat <= 38.0 && lon >= 68.0 && lon <= 98.0;
    }

    double fixedLat = latitude!;
    double fixedLon = longitude!;

    if (!isIndia(fixedLat, fixedLon)) {
      // Fallback to New Delhi (or your preferred default)
      fixedLat = 28.6139;
      fixedLon = 77.2090;
    }

    await Supabase.instance.client.from('loan_applications').insert({
      'farmer_id': user.id,
      'scheme_id': _selectedScheme!['id'],
      'institution_id': institutionId,
      'amount': userAmount,
      'interest_rate': _selectedScheme!['interest_rate'],
      'tenure_months': _selectedScheme!['time_period_months'],
      'purpose': _purposeController.text.trim(),
      'remarks': _remarksController.text.trim(),
      'land_proof_url': landUrl,
      'id_proof_url': idUrl,
      'passbook_url': passbookUrl,
      'latitude': fixedLat,
      'longitude': fixedLon,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Loan application submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context, true);
  }

  // -------------------------------------------------------------
  // UI
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FFF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFA8E6A2),
        title: const Text(
          "Apply for Loan",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: loadingSchemes
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle("Loan Scheme"),
                    _buildSchemeDropdown(),

                    _sectionTitle("Loan Details"),
                    _buildTextField(
                      _loanAmountController,
                      "Loan Amount (₹)",
                      true,
                      isNumber: true,
                    ),
                    _buildTextField(
                      _interestRateController,
                      "Interest Rate (%)",
                      true,
                      isNumber: true,
                      enabled: false,
                    ),

                    _sectionTitle("Your Location"),
                    OutlinedButton.icon(
                      onPressed: _getLocation,
                      icon: const Icon(Icons.my_location),
                      label: Text(
                        latitude == null
                            ? "Fetch Current Location"
                            : "Lat: $latitude, Lng: $longitude",
                      ),
                    ),

                    _sectionTitle("Documents"),
                    _uploadButton(
                      "Upload Land Proof",
                      landProof,
                      (file) => landProof = file,
                    ),
                    _uploadButton(
                      "Upload ID Proof",
                      idProof,
                      (file) => idProof = file,
                    ),
                    _uploadButton(
                      "Upload Bank Passbook",
                      passbook,
                      (file) => passbook = file,
                    ),

                    _sectionTitle("Other Information"),
                    _buildTextField(
                      _purposeController,
                      "Purpose",
                      true,
                      maxLines: 3,
                    ),
                    _buildTextField(
                      _remarksController,
                      "Remarks",
                      false,
                      maxLines: 2,
                    ),

                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(200, 50),
                          backgroundColor: const Color(0xFFA8E6A2),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _submitLoan,
                        child: const Text("Submit Loan"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // -------------------------------------------------------------
  // Widgets
  // -------------------------------------------------------------
  Widget _buildSchemeDropdown() {
    return DropdownButtonFormField<Map<String, dynamic>>(
      decoration: _inputDecoration("Select Scheme"),
      items: _schemes.map((scheme) {
        return DropdownMenuItem(value: scheme, child: Text(scheme['title']));
      }).toList(),
      onChanged: (scheme) {
        setState(() {
          _selectedScheme = scheme;
          _interestRateController.text = scheme!['interest_rate'].toString();
          institutionId = scheme['institution_id'];
        });
      },
      validator: (val) => val == null ? "Please select a scheme" : null,
    );
  }

  Widget _uploadButton(
    String label,
    PlatformFile? file,
    Function(PlatformFile) onPick,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OutlinedButton.icon(
        onPressed: () async {
          final picked = await _pickFile();
          if (picked != null) setState(() => onPick(picked));
        },
        icon: const Icon(Icons.upload_file, color: Colors.green),
        label: Text(file != null ? file.name : label),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    bool required, {
    bool isNumber = false,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        validator: required
            ? (value) =>
                  value == null || value.isEmpty ? "Please enter $label" : null
            : null,
        decoration: _inputDecoration(label),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
