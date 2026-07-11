import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderServicesScreen extends StatefulWidget {
  const ProviderServicesScreen({super.key});

  @override
  State<ProviderServicesScreen> createState() => _ProviderServicesScreenState();
}

class _ProviderServicesScreenState extends State<ProviderServicesScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedCategory = 'Plumbing';
  bool _isLoading = false;

  final List<String> _categories = [
    'Plumbing', 'Electrical', 'Cleaning',
    'Carpentry', 'Painting', 'Landscaping'
  ];

  Future<void> _saveService() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();
      await FirebaseFirestore.instance
          .collection('providers')
          .doc(user.uid)
          .set({
            'uid': user.uid,
            'name': userDoc.data()?['name'] ?? 'Provider',
            'category': _selectedCategory,
            'description': _nameController.text.trim(),
            'price': double.tryParse(_priceController.text) ?? 0,
            'rating': 0.0,
            'isVerified': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service saved successfully!'),
            backgroundColor: Colors.green),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Services',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2563EB),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Set Up Your Service',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            const Text('Service Category'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: _inputDecoration('Category'),
              items: _categories.map((cat) =>
                  DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: _inputDecoration('Service Description'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Price per hour (RM)'),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveService,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Service',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 32),
            const Text('My Current Service',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('providers')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Text('No service set up yet.',
                      style: TextStyle(color: Colors.grey));
                }
                final data = snapshot.data!.data() as Map<String, dynamic>;
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(data['category'] ?? '',
                                  style: const TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.bold)),
                            ),
                            const Spacer(),
                            const Icon(Icons.verified,
                                color: Colors.green, size: 20),
                            const SizedBox(width: 4),
                            const Text('Verified',
                                style: TextStyle(color: Colors.green)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(data['description'] ?? '',
                            style: const TextStyle(fontSize: 15)),
                        const SizedBox(height: 8),
                        Text('RM ${data['price']}/hr',
                            style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }
}