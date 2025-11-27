import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final List<Map<String, String>> _uploadedDocs = [];

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _uploadedDocs.add({
          'name': result.files.single.name,
          'path': result.files.single.path!,
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.files.single.name} uploaded successfully!')),
      );
    }
  }

  void _deleteDocument(int index) {
    String docName = _uploadedDocs[index]['name']!;
    setState(() {
      _uploadedDocs.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$docName deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        backgroundColor: const Color(0xFFA8E6CF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Uploaded Documents',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _uploadedDocs.isEmpty
                  ? const Center(
                      child: Text(
                        'No documents uploaded yet.\nTap below to add new ones.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54, fontSize: 15),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _uploadedDocs.length,
                      itemBuilder: (context, index) {
                        final doc = _uploadedDocs[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          color: const Color(0xFFF8FDFB),
                          child: ListTile(
                            leading: const Icon(Icons.insert_drive_file_outlined,
                                color: Color(0xFF6B705C), size: 32),
                            title: Text(doc['name']!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 15)),
                            subtitle: const Text('Uploaded Document'),
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility_outlined,
                                      color: Colors.blueGrey),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Opening ${doc['name']} (view not yet implemented)')),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent),
                                  onPressed: () => _deleteDocument(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA8E6CF),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.upload_file, color: Colors.black87),
                label: const Text(
                  'Upload New Document',
                  style: TextStyle(color: Colors.black87, fontSize: 16),
                ),
                onPressed: _pickDocument,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
