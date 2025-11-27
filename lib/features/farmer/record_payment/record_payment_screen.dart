import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class RecordPaymentScreen extends StatefulWidget {
  const RecordPaymentScreen({super.key});

  @override
  State<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSuccess = false;

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedLoan;
  String? _selectedMethod;
  DateTime? _selectedDate;

  late Razorpay _razorpay;

  List<Map<String, dynamic>> _loansList = [];
  final List<String> _methods = ["UPI", "Bank Transfer", "Cash"];

  double? _minPayment; // minimum allowed (EMI or scheme minimum)
  double? _emiAmount; // emi fetched from DB (if available)
  double? _remainingAmount; // remaining_amount from DB
  DateTime? _nextDueDate; // next_due_date from DB
  int? _tenureMonths;

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _loadApprovedLoans();
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Load only APPROVED loans and include EMI / remaining / next_due_date fields
  Future<void> _loadApprovedLoans() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Select loan fields + nested scheme title + minimum_amount
    final response = await Supabase.instance.client
        .from('loan_applications')
        .select(
          'id, amount, emi_amount, remaining_amount, next_due_date, tenure_months, interest_rate, purpose, created_at, schemes(title, minimum_amount)',
        )
        .eq('farmer_id', user.id)
        .eq('status', 'approved')
        .order('created_at', ascending: false);

    // response is a List<dynamic>. Keep it as-is for simplicity.
    setState(() {
      _loansList = (response as List).cast<Map<String, dynamic>>();
    });
  }

  /// Save payment to payments table
  Future<void> _savePayment(double amount) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await Supabase.instance.client.from('payments').insert({
      "farmer_id": user.id,
      "loan_id": _selectedLoan!,
      "amount": amount,
      "method": _selectedMethod,
      "payment_date": _selectedDate?.toIso8601String(),
      "notes": _noteController.text,
    });
    // After insert, DB trigger (if created) will update loan_applications.
    // We re-load loan info so UI reflects updated remaining/next due.
    await Future.delayed(const Duration(milliseconds: 400));
    await _refreshSelectedLoanInfo();
  }

  /// Refresh only selected loan info (in case DB trigger updated values)
  Future<void> _refreshSelectedLoanInfo() async {
    if (_selectedLoan == null) return;

    final response = await Supabase.instance.client
        .from('loan_applications')
        .select(
          'id, amount, emi_amount, remaining_amount, next_due_date, tenure_months, interest_rate, purpose, created_at, schemes(title, minimum_amount)',
        )
        .eq('id', _selectedLoan!)
        .maybeSingle();

    if (response == null) return;

    final loan = Map<String, dynamic>.from(response);

    setState(() {
      // overwrite the entry in _loansList for easy reuse
      final idx = _loansList.indexWhere((l) => l['id'] == _selectedLoan);
      if (idx != -1) _loansList[idx] = loan;

      _emiAmount = (loan['emi_amount'] as num?)?.toDouble();
      _remainingAmount = (loan['remaining_amount'] as num?)?.toDouble();
      _tenureMonths = (loan['tenure_months'] as num?)?.toInt();
      _nextDueDate = loan['next_due_date'] == null
          ? null
          : DateTime.tryParse(loan['next_due_date'].toString());
      final double? minScheme = (loan['schemes']?['minimum_amount'] as num?)
          ?.toDouble();

      // minimum is the max of EMI (if exists) and scheme minimum; fallback to amount/tenure
      double fallbackEmi = 0;
      final amount = (loan['amount'] as num?)?.toDouble() ?? 0;
      if (_tenureMonths != null && _tenureMonths! > 0) {
        fallbackEmi = amount / _tenureMonths!;
      }
      _minPayment = _emiAmount != null
          ? ((_emiAmount! > (minScheme ?? 0))
                ? _emiAmount!
                : (minScheme ?? _emiAmount!))
          : (minScheme != null ? _max(minScheme, fallbackEmi) : fallbackEmi);

      // pre-fill amount input with EMI if empty
      if ((_amountController.text).trim().isEmpty && _minPayment != null) {
        _amountController.text = _minPayment!.toStringAsFixed(0);
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  /// Main submit
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select payment date")),
      );
      return;
    }

    // Save for cash quickly; for online, razorpay triggers save on success via success handler
    if (_selectedMethod == "Cash") {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(seconds: 1));
      await _savePayment(amount);
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _isSuccess = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Cash payment recorded successfully")),
      );
      return;
    }

    // Online payment: open Razorpay. On success, _handlePaymentSuccess will save payment.
    var options = {
      'key': 'rzp_test_RdDc5XWuNsP88g',
      'amount': (amount * 100).toInt(),
      'name': 'KarzaMukti',
      'description': 'Loan Repayment',
      'theme': {'color': '#A8E6CF'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Error opening Razorpay: $e");
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    await _savePayment(amount);

    setState(() {
      _isLoading = false;
      _isSuccess = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Payment Successful: ${response.paymentId}")),
    );

    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _isSuccess = false);
    });
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ Payment Failed: ${response.message}")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("💳 External Wallet: ${response.walletName}")),
    );
  }

  String _formatCurrency(double? v) {
    if (v == null) return '—';
    final f = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2, // ⭐ EXACT FORMAT YOU WANT
    );
    return f.format(v);
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat.yMMMd().format(dt);
  }

  Widget _infoCard(
    String title,
    String value, {
    Color bg = const Color(0xFFEAF7F0),
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.12), blurRadius: 6),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFA8E6CF);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FFF8),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'Record Payment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Loan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),

              // Dropdown with REAL approved loans
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: _loansList.map((loan) {
                  // **Show scheme title if available**, otherwise fallback to amount + purpose
                  final scheme = loan['schemes'];
                  final schemeTitle = scheme != null && scheme['title'] != null
                      ? scheme['title'].toString()
                      : null;

                  final amountVal = (loan['amount'] as num?)?.toDouble() ?? 0.0;
                  final purposeVal = loan['purpose'] ?? '';

                  final displayTitle =
                      schemeTitle != null && schemeTitle.isNotEmpty
                      ? "$schemeTitle — ₹${amountVal.toStringAsFixed(0)}"
                      : "₹${amountVal.toStringAsFixed(0)} • ${purposeVal} (Approved)";

                  return DropdownMenuItem<String>(
                    value: loan['id'] as String,
                    child: Text(displayTitle),
                  );
                }).toList(),
                onChanged: (val) async {
                  setState(() {
                    _selectedLoan = val;
                    _emiAmount = null;
                    _remainingAmount = null;
                    _nextDueDate = null;
                    _minPayment = null;
                  });

                  if (val != null) {
                    // Populate details for selected loan
                    final selected = _loansList.firstWhere(
                      (l) => l['id'] == val,
                    );
                    // If selected already contains emi/remaining etc, use them; otherwise refresh from server
                    _emiAmount = (selected['emi_amount'] as num?)?.toDouble();
                    _remainingAmount = (selected['remaining_amount'] as num?)
                        ?.toDouble();
                    _tenureMonths = (selected['tenure_months'] as num?)
                        ?.toInt();
                    _nextDueDate = selected['next_due_date'] == null
                        ? null
                        : DateTime.tryParse(
                            selected['next_due_date'].toString(),
                          );

                    // If server didn't include emi (null), try refresh single row (ensures latest)
                    if (_emiAmount == null || _remainingAmount == null) {
                      await _refreshSelectedLoanInfo();
                    } else {
                      // compute min payment from available data
                      final double amount =
                          (selected['amount'] as num?)?.toDouble() ?? 0;
                      final double fallbackEmi =
                          (_tenureMonths != null && _tenureMonths! > 0)
                          ? amount / _tenureMonths!
                          : 0;
                      final double? minScheme =
                          (selected['schemes']?['minimum_amount'] as num?)
                              ?.toDouble();

                      _minPayment = _emiAmount != null
                          ? ((_emiAmount! > (minScheme ?? 0))
                                ? _emiAmount!
                                : (minScheme ?? _emiAmount!))
                          : (minScheme != null
                                ? (_max(minScheme, fallbackEmi))
                                : fallbackEmi);

                      // prefill amount if empty
                      if (_amountController.text.trim().isEmpty &&
                          _minPayment != null) {
                        _amountController.text = _minPayment!.toStringAsFixed(
                          0,
                        );
                      }

                      setState(() {});
                    }
                  }
                },
                validator: (val) => val == null ? 'Please select a loan' : null,
              ),

              const SizedBox(height: 16),

              // Info cards (EMI / Remaining / Next Due) — visible when a loan is selected
              if (_selectedLoan != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      _infoCard(
                        'Monthly EMI',
                        _formatCurrency(_emiAmount ?? (_minPayment ?? 0)),
                      ),
                      _infoCard(
                        'Remaining',
                        _formatCurrency(_remainingAmount),
                        bg: const Color(0xFFFFF0E6),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5FF),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.12),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Next Due',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatDate(_nextDueDate),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const Text(
                'Payment Amount',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),

              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  hintText: 'Enter amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter amount';
                  final amt = double.tryParse(val);
                  if (amt == null) return 'Invalid amount';
                  if (_minPayment != null && amt < _minPayment!) {
                    return "Amount must be ≥ ₹${_minPayment!.toStringAsFixed(2)}";
                  }
                  return null;
                },
              ),

              if (_minPayment != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    "Minimum payable: ₹${_minPayment!.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),

              const SizedBox(height: 16),
              const Text(
                'Payment Date',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),

              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedDate == null
                        ? 'Select payment date'
                        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'Payment Method',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: _methods
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedMethod = val),
                validator: (val) =>
                    val == null ? 'Please select payment method' : null,
              ),

              const SizedBox(height: 16),
              const Text(
                'Notes (optional)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),

              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  hintText: 'Add remarks or reference ID',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 24),

              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: _isLoading || _isSuccess ? 60 : double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading || _isSuccess
                        ? null
                        : () => _submit(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : _isSuccess
                        ? const Icon(Icons.check, color: Colors.white)
                        : const Text(
                            'Pay Now',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
}

/// small helper - dart:math max is not imported above, so use this local:
double _max(double a, double b) => a > b ? a : b;
