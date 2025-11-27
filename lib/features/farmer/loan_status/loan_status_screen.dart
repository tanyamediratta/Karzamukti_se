import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'loan_status_detail_screen.dart';

class LoanStatusScreen extends StatefulWidget {
  const LoanStatusScreen({super.key});

  @override
  State<LoanStatusScreen> createState() => _LoanStatusScreenState();
}

class _LoanStatusScreenState extends State<LoanStatusScreen> {
  List<Map<String, dynamic>> _loans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  Future<void> _loadLoans() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final data = await Supabase.instance.client
        .from('loan_applications')
        .select(
          'id, amount, purpose, status, created_at, scheme_id, schemes(title, interest_rate, time_period_months)',
        )
        .eq('farmer_id', user.id)
        .order('created_at', ascending: false);

    setState(() {
      _loans = data;
      _loading = false;
    });
  }

  Widget _statusBadge(String status) {
    late Color color;
    late String text;

    switch (status) {
      case 'approved':
        color = Colors.green;
        text = "Approved";
        break;
      case 'rejected':
        color = Colors.red;
        text = "Rejected";
        break;
      default:
        color = Colors.orange;
        text = "Pending";
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFF8),
      appBar: AppBar(
        title: const Text("Loan Status"),
        backgroundColor: const Color(0xFFA8D5BA),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loans.isEmpty
          ? const Center(
              child: Text(
                "No loan applications found.",
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _loans.length,
              itemBuilder: (context, index) {
                final loan = _loans[index];
                final scheme = loan['schemes'];

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      scheme?['title'] ?? loan['purpose'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text("Amount: ₹${loan['amount']}"),
                        Text(
                          "Applied on: ${loan['created_at'].toString().substring(0, 10)}",
                        ),
                      ],
                    ),
                    trailing: _statusBadge(loan['status']),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LoanStatusDetailScreen(loan: loan),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
