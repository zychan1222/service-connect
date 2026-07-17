import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderServicesScreen extends StatefulWidget {
  const ProviderServicesScreen({super.key});

  @override
  State<ProviderServicesScreen> createState() =>
      _ProviderServicesScreenState();
}

class _ProviderServicesScreenState extends State<ProviderServicesScreen> {
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedCategory = 'Plumbing';
  bool _isLoading = false;

  final List<String> _categories = [
    'Plumbing', 'Electrical', 'Cleaning',
    'Carpentry', 'Painting', 'Landscaping'
  ];

  Future<void> _addService() async {
    if (_descriptionController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();
      final providerName = userDoc.data()?['name'] ?? 'Provider';

      // Ensure provider document exists
      await FirebaseFirestore.instance
          .collection('providers')
          .doc(user.uid)
          .set({
            'uid': user.uid,
            'name': providerName,
            'email': userDoc.data()?['email'] ?? '',
            'rating': 0.0,
            'bookingCount': 0,
            'isVerified': false,
          }, SetOptions(merge: true));

      // Add service as subcollection
      await FirebaseFirestore.instance
          .collection('providers')
          .doc(user.uid)
          .collection('services')
          .add({
            'providerId': user.uid,
            'providerName': providerName,
            'category': _selectedCategory,
            'description': _descriptionController.text.trim(),
            'price': double.tryParse(_priceController.text) ?? 0,
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      _descriptionController.clear();
      _priceController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Service added successfully!'),
            backgroundColor: Colors.green),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleService(String serviceId, bool currentStatus) async {
    final user = FirebaseAuth.instance.currentUser!;
    await FirebaseFirestore.instance
        .collection('providers')
        .doc(user.uid)
        .collection('services')
        .doc(serviceId)
        .update({'isActive': !currentStatus});
  }

  Future<void> _deleteService(String serviceId) async {
    final user = FirebaseAuth.instance.currentUser!;
    await FirebaseFirestore.instance
        .collection('providers')
        .doc(user.uid)
        .collection('services')
        .doc(serviceId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

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
            const Text('Add a New Service',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: _inputDecoration('Category'),
              items: _categories
                  .map((cat) =>
                      DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedCategory = val!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
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
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _addService,
                icon: const Icon(Icons.add, color: Colors.white),
                label: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Add Service',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text('My Services',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('providers')
                  .doc(user.uid)
                  .collection('services')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final services = snapshot.data!.docs;
                if (services.isEmpty) {
                  return const Center(
                    child: Text('No services added yet.',
                        style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final data =
                        services[index].data() as Map<String, dynamic>;
                    final isActive = data['isActive'] ?? true;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(data['category'] ?? '',
                                      style: const TextStyle(
                                          color: Color(0xFF2563EB),
                                          fontWeight: FontWeight.bold)),
                                ),
                                Row(
                                  children: [
                                    Switch(
                                      value: isActive,
                                      activeColor: Colors.green,
                                      onChanged: (_) => _toggleService(
                                          services[index].id, isActive),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title:
                                              const Text('Delete Service?'),
                                          content: const Text(
                                              'This cannot be undone.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                _deleteService(
                                                    services[index].id);
                                              },
                                              child: const Text('Delete',
                                                  style: TextStyle(
                                                      color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(data['description'] ?? '',
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('RM ${data['price']}/hr',
                                style: const TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                  color: isActive
                                      ? Colors.green
                                      : Colors.grey,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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