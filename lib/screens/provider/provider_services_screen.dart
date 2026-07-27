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
  final _priceMinController = TextEditingController();
  final _priceMaxController = TextEditingController();
  final _detailsController = TextEditingController();
  String _selectedCategory = 'Plumbing';
  bool _isLoading = false;
  bool _showForm = false;

  static const _primary = Color(0xFF2563EB);
  static const _bg = Color(0xFFF7F8FA);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);

  final List<String> _categories = [
    'Plumbing', 'Electrical', 'Cleaning',
    'Carpentry', 'Painting', 'Landscaping'
  ];

  Future<void> _addService() async {
    if (_descriptionController.text.isEmpty ||
        _priceMinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill in all required fields')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();
      final providerName = userDoc.data()?['name'] ?? 'Provider';

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

      final priceMin =
          double.tryParse(_priceMinController.text) ?? 0;
      final priceMax =
          double.tryParse(_priceMaxController.text) ?? priceMin;

      await FirebaseFirestore.instance
          .collection('providers')
          .doc(user.uid)
          .collection('services')
          .add({
        'providerId': user.uid,
        'providerName': providerName,
        'category': _selectedCategory,
        'description': _descriptionController.text.trim(),
        'details': _detailsController.text.trim(),
        'price': priceMin,
        'priceMin': priceMin,
        'priceMax': priceMax > priceMin ? priceMax : priceMin,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _descriptionController.clear();
      _priceMinController.clear();
      _priceMaxController.clear();
      _detailsController.clear();
      setState(() => _showForm = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Service added — pending admin approval'),
            backgroundColor: Color(0xFF10B981)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleService(
      String serviceId, bool currentStatus) async {
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
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('My Services',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16)),
        backgroundColor: _primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() => _showForm = !_showForm),
        backgroundColor: _primary,
        icon: Icon(_showForm ? Icons.close : Icons.add,
            color: Colors.white),
        label: Text(_showForm ? 'Close' : 'Add Service',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add form
            if (_showForm) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('New Service',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary)),
                    const SizedBox(height: 20),

                    _label('Category'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: _inputDecoration('Select category'),
                      items: _categories
                          .map((cat) => DropdownMenuItem(
                              value: cat, child: Text(cat)))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCategory = val!),
                    ),

                    const SizedBox(height: 16),
                    _label('Short Description'),
                    const SizedBox(height: 4),
                    _hint('A brief summary shown on listings'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      decoration: _inputDecoration(
                          'e.g. Professional pipe repair and installation'),
                      maxLines: 2,
                      style: const TextStyle(fontSize: 14),
                    ),

                    const SizedBox(height: 16),
                    _label('Full Details'),
                    const SizedBox(height: 4),
                    _hint('What exactly do you offer? Tools, experience, what\'s included'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _detailsController,
                      decoration: _inputDecoration(
                          'e.g. 5 years experience, includes free inspection, all tools provided, fix leaks, replace pipes, install fixtures...'),
                      maxLines: 4,
                      style: const TextStyle(fontSize: 14),
                    ),

                    const SizedBox(height: 16),
                    _label('Price Range (RM/hr)'),
                    const SizedBox(height: 4),
                    _hint('Set a min and max to show clients your range'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _priceMinController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('Min (e.g. 60)'),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('—',
                              style: TextStyle(
                                  color: _textSecondary, fontSize: 16)),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _priceMaxController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('Max (e.g. 120)'),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _addService,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2),
                              )
                            : const Text('Add Service',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            const Text('My Services',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    letterSpacing: -0.3)),
            const SizedBox(height: 14),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('providers')
                  .doc(user.uid)
                  .collection('services')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: _primary));
                }
                final services = snapshot.data!.docs;
                if (services.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.handyman_rounded,
                                color: _primary, size: 32),
                          ),
                          const SizedBox(height: 16),
                          const Text('No services yet',
                              style: TextStyle(
                                  color: _textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15)),
                          const SizedBox(height: 4),
                          const Text('Tap the button below to add one',
                              style: TextStyle(
                                  color: _textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final data = services[index].data()
                        as Map<String, dynamic>;
                    final isActive = data['isActive'] ?? true;
                    final priceMin = data['priceMin'] ?? data['price'] ?? 0;
                    final priceMax = data['priceMax'] ?? priceMin;
                    final hasPriceRange = priceMax > priceMin;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: isActive
                                ? const Color(0xFFE2E8F0)
                                : const Color(0xFFF1F5F9)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _primary.withOpacity(0.08),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Text(data['category'] ?? '',
                                      style: const TextStyle(
                                          color: _primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12)),
                                ),
                                const Spacer(),
                                Switch(
                                  value: isActive,
                                  activeColor:
                                      const Color(0xFF10B981),
                                  onChanged: (_) => _toggleService(
                                      services[index].id, isActive),
                                ),
                                GestureDetector(
                                  onTap: () => showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(
                                                  20)),
                                      title: const Text(
                                          'Delete service?',
                                          style: TextStyle(
                                              fontWeight:
                                                  FontWeight.w700)),
                                      content: const Text(
                                          'This cannot be undone.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Keep it'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _deleteService(
                                                services[index].id);
                                          },
                                          child: const Text('Delete',
                                              style: TextStyle(
                                                  color: Colors.red,
                                                  fontWeight:
                                                      FontWeight.w600)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.red.withOpacity(0.08),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.red,
                                        size: 16),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Description
                            Text(data['description'] ?? '',
                                style: const TextStyle(
                                    color: _textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),

                            // Details
                            if ((data['details'] ?? '').isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(data['details'],
                                  style: const TextStyle(
                                      color: _textSecondary,
                                      fontSize: 13,
                                      height: 1.4),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis),
                            ],

                            const SizedBox(height: 12),

                            // Price + status row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _primary.withOpacity(0.06),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                          Icons.attach_money_rounded,
                                          color: _primary,
                                          size: 14),
                                      Text(
                                        hasPriceRange
                                            ? 'RM $priceMin — RM $priceMax/hr'
                                            : 'RM $priceMin/hr',
                                        style: const TextStyle(
                                            color: _primary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? const Color(0xFFECFDF5)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isActive
                                            ? const Color(0xFF10B981)
                                            : _textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _textPrimary));

  Widget _hint(String text) => Text(text,
      style: const TextStyle(fontSize: 12, color: _textSecondary));

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: _textSecondary, fontSize: 13),
        filled: true,
        fillColor: _bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
      );
}