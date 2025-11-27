import 'package:flutter/material.dart';
import '../govt_loans_service.dart';

class DisbursementScreen extends StatefulWidget {
  const DisbursementScreen({super.key});

  @override
  State<DisbursementScreen> createState() => _DisbursementScreenState();
}

class _DisbursementScreenState extends State<DisbursementScreen> {
  final GovtLoansService _loanService = GovtLoansService();
  List<Map<String, dynamic>> _loans = [];

  @override
  void initState() {
    super.initState();
    _fetchLoans();
  }

  Future<void> _fetchLoans() async {
    final data = await _loanService.getAllLoans();
    setState(() => _loans = data);
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    await _loanService.updateLoanStatus(id, newStatus);
    _fetchLoans();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Disbursement Tracking")),
      body: _loans.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _loans.length,
              itemBuilder: (context, index) {
                final loan = _loans[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text("₹${loan['amount']}"),
                    subtitle: Text(
                      "Scheme: ${loan['scheme']?['name'] ?? 'N/A'}\nStatus: ${loan['status']}",
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (val) => _updateStatus(loan['id'], val),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                            value: 'approved', child: Text('Approve')),
                        const PopupMenuItem(
                            value: 'disbursed', child: Text('Mark Disbursed')),
                        const PopupMenuItem(
                            value: 'rejected', child: Text('Reject')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
