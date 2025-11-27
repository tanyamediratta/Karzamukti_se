// schemes_screen.dart
import 'package:flutter/material.dart';
import 'scheme_data.dart';
import 'schemedetailscreen.dart';

class SchemesScreen extends StatefulWidget {
  const SchemesScreen({super.key});

  @override
  State<SchemesScreen> createState() => _SchemesScreenState();
}

class _SchemesScreenState extends State<SchemesScreen> {
  List<Scheme> schemes = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadSchemes();
  }

  Future<void> loadSchemes() async {
    try {
      schemes = await fetchSchemes();
    } catch (e) {
      schemes = [];
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Government Schemes',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFA8D5BA),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : schemes.isEmpty
          ? const Center(child: Text("No schemes available"))
          : Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                itemCount: schemes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (context, index) {
                  final scheme = schemes[index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SchemeDetailScreen(scheme: scheme),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF7F0),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.account_balance,
                            size: 40,
                            color: Colors.green,
                          ),

                          const SizedBox(height: 10),

                          Text(
                            scheme.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),

                          const Spacer(),

                          Row(
                            children: [
                              const Icon(
                                Icons.date_range,
                                size: 16,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  scheme.createdAt.split('T')[0],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ],
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
