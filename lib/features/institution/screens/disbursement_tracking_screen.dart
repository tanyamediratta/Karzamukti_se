import 'package:flutter/material.dart';
import '../govt_loans_service.dart';

class DisbursementTrackingScreen extends StatefulWidget {
  const DisbursementTrackingScreen({super.key});

  @override
  State<DisbursementTrackingScreen> createState() =>
      _DisbursementTrackingScreenState();
}

class _DisbursementTrackingScreenState
    extends State<DisbursementTrackingScreen> {
  final GovtLoansService _loanService = GovtLoansService();
  List<Map<String, dynamic>> _loans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchLoans();
  }

  Future<void> _fetchLoans() async {
    setState(() => _loading = true);
    final data = await _loanService.getAllLoans();
    setState(() {
      _loans = data.where((l) => l['status'] == 'disbursed').toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Disbursement Tracking")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loans.isEmpty
          ? const Center(child: Text("No disbursed loans found"))
          : RefreshIndicator(
              onRefresh: _fetchLoans,
              child: ListView.builder(
                itemCount: _loans.length,
                itemBuilder: (context, index) {
                  final loan = _loans[index];
                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      title: Text("₹${loan['amount']}"),
                      subtitle: Text("Farmer ID: ${loan['farmer_id'] ?? '-'}"),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
