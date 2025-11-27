import 'package:flutter/material.dart';
import '../govt_loans_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoanReviewScreen extends StatefulWidget {
  const LoanReviewScreen({super.key});

  @override
  State<LoanReviewScreen> createState() => _LoanReviewScreenState();
}

class _LoanReviewScreenState extends State<LoanReviewScreen> {
  final GovtLoansService _loanService = GovtLoansService();
  List<Map<String, dynamic>> _loans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    print(
      "🔥 LOGGED IN USER ID: ${Supabase.instance.client.auth.currentUser?.id}",
    );

    _fetchLoans();
  }

  Future<void> _fetchLoans() async {
    setState(() => _loading = true);

    try {
      print("DEBUG: Fetching loans...");
      final data = await _loanService.getAllLoans();
      print("DEBUG: Loans fetched: $data");

      setState(() {
        _loans = data;
        _loading = false;
      });
    } catch (e, st) {
      print("ERROR in _fetchLoans: $e");
      print(st);

      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    await _loanService.updateLoanStatus(id, status);
    _fetchLoans();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Loan marked as $status ✅")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Loan Applications Review")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loans.isEmpty
          ? const Center(child: Text("No loan applications found"))
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

                      // 🔥 FIXED: Removed due_date (does NOT exist)
                      subtitle: Text(
                        "Status: ${loan['status']}\n"
                        "Created: ${loan['created_at']}",
                      ),

                      trailing: PopupMenuButton<String>(
                        onSelected: (val) => _updateStatus(loan['id'], val),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'approved',
                            child: Text('Approve'),
                          ),
                          const PopupMenuItem(
                            value: 'rejected',
                            child: Text('Reject'),
                          ),
                          const PopupMenuItem(
                            value: 'disbursed',
                            child: Text('Mark Disbursed'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
