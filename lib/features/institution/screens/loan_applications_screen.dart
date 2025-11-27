import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../govt_loans_service.dart';

class LoanApplicationsScreen extends StatefulWidget {
  const LoanApplicationsScreen({super.key});

  @override
  State<LoanApplicationsScreen> createState() => _LoanApplicationsScreenState();
}

class _LoanApplicationsScreenState extends State<LoanApplicationsScreen> {
  final GovtLoansService _loanService = GovtLoansService();

  final _amountController = TextEditingController();
  final _interestController = TextEditingController();
  final _tenureController = TextEditingController();

  String? _selectedSchemeId;
  List<Map<String, dynamic>> _schemes = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSchemes();
  }

  Future<void> _loadSchemes() async {
    final client = Supabase.instance.client;

    final data = await client.from('schemes').select('id, name');

    setState(() {
      _schemes = List<Map<String, dynamic>>.from(data);
      _loading = false;
    });
  }

  Future<void> _submitLoan() async {
    if (_amountController.text.isEmpty ||
        _interestController.text.isEmpty ||
        _tenureController.text.isEmpty ||
        _selectedSchemeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please fill all fields & select a scheme")),
      );
      return;
    }

    final farmerId = Supabase.instance.client.auth.currentUser?.id;
    if (farmerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in")),
      );
      return;
    }

    await _loanService.addLoan(
      farmerId: farmerId,
      amount: double.parse(_amountController.text),
      schemeId: _selectedSchemeId!,
      interestRate: double.parse(_interestController.text),
      tenureMonths: int.parse(_tenureController.text),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Loan application submitted")),
    );

    _amountController.clear();
    _interestController.clear();
    _tenureController.clear();
    setState(() => _selectedSchemeId = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Apply for Loan")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: "Loan Amount (₹)",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: _interestController,
                    decoration: const InputDecoration(
                      labelText: "Interest Rate (%)",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: _tenureController,
                    decoration: const InputDecoration(
                      labelText: "Tenure (months)",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 15),

                  // SCHEME DROPDOWN
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Select Scheme",
                    ),
initialValue: _selectedSchemeId,
                   items: _schemes
    .map<DropdownMenuItem<String>>(
      (s) => DropdownMenuItem<String>(
        value: s['id'] as String,
        child: Text(s['name'] as String),
      ),
    )
    .toList(),

                    onChanged: (val) {
                      setState(() => _selectedSchemeId = val);
                    },
                  ),

                  const SizedBox(height: 25),

                  ElevatedButton(
                    onPressed: _submitLoan,
                    child: const Text("Submit Application"),
                  ),
                ],
              ),
            ),
    );
  }
}
