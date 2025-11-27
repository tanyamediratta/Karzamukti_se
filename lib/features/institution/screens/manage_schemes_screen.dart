import 'package:flutter/material.dart';
import '../govt_scheme_service.dart';

class ManageSchemesScreen extends StatefulWidget {
  const ManageSchemesScreen({super.key});

  @override
  State<ManageSchemesScreen> createState() => _ManageSchemesScreenState();
}

class _ManageSchemesScreenState extends State<ManageSchemesScreen> {
  final Color primaryColor = const Color(0xFFA8E6CF);
  final GovtSchemeService _service = GovtSchemeService();

  List<Map<String, dynamic>> _schemes = [];

  // controllers
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _minAmountController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _timePeriodController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSchemes();
  }

  Future<void> _loadSchemes() async {
    final data = await _service.getSchemes();
    setState(() => _schemes = data);
  }

  void _showAddSchemeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add New Scheme',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),

                _buildField("Scheme Title", _titleController),
                const SizedBox(height: 12),

                _buildField("Description", _descController, maxLines: 2),
                const SizedBox(height: 12),

                _buildField("Minimum Loan Amount", _minAmountController,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),

                _buildField("Interest Rate (%)", _interestRateController,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),

                _buildField("Time Period (months)", _timePeriodController,
                    keyboardType: TextInputType.number),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _saveScheme,
                    child: const Text('Save Scheme'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
border: OutlineInputBorder(
  borderRadius: BorderRadius.circular(10),
),
      ),
    );
  }

  Future<void> _saveScheme() async {
    if (_titleController.text.isEmpty ||
        _descController.text.isEmpty ||
        _minAmountController.text.isEmpty ||
        _interestRateController.text.isEmpty ||
        _timePeriodController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠ Please fill all fields")),
      );
      return;
    }

    await _service.addScheme(
      title: _titleController.text,
      description: _descController.text,
      minimumAmount: double.parse(_minAmountController.text),
      interestRate: double.parse(_interestRateController.text),
      timePeriodMonths: int.parse(_timePeriodController.text),
    );

    // clear inputs
    _titleController.clear();
    _descController.clear();
    _minAmountController.clear();
    _interestRateController.clear();
    _timePeriodController.clear();

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Scheme added successfully")),
    );

    _loadSchemes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'Manage Schemes',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        label: const Text('Add Scheme', style: TextStyle(color: Colors.black)),
        icon: const Icon(Icons.add, color: Colors.black),
        onPressed: _showAddSchemeSheet,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _schemes.isEmpty
            ? const Center(
                child: Text(
                  'No schemes available.\nTap “Add Scheme” to create one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : ListView.builder(
                itemCount: _schemes.length,
                itemBuilder: (context, index) {
                  final scheme = _schemes[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        scheme['title'],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        "${scheme['description']}\n"
                        "Min Amount: ₹${scheme['minimum_amount']}\n"
                        "Interest: ${scheme['interest_rate']}%\n"
                        "Period: ${scheme['time_period_months']} months",
                      ),
                      isThreeLine: true,
                      // ❌ Delete removed
                    ),
                  );
                },
              ),
      ),
    );
  }
}
