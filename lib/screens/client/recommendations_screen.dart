import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_screen.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _recommended = [];
  List<Map<String, dynamic>> _others = [];
  String _insight = '';

  static const _primary = Color(0xFF2563EB);
  static const _bg = Color(0xFFF7F8FA);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _runMatchingAlgorithm();
  }

  Future<void> _runMatchingAlgorithm() async {
    final user = FirebaseAuth.instance.currentUser!;

    final bookingsSnap = await FirebaseFirestore.instance
        .collection('bookings')
        .where('clientId', isEqualTo: user.uid)
        .get();

    final Map<String, int> categoryCount = {};
    for (final doc in bookingsSnap.docs) {
      final category = doc.data()['category'] as String? ?? '';
      if (category.isNotEmpty) {
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }
    }

    final providersSnap = await FirebaseFirestore.instance
        .collection('providers')
        .where('isVerified', isEqualTo: true)
        .get();

    final List<Map<String, dynamic>> scored = [];

    for (final providerDoc in providersSnap.docs) {
      final providerData = providerDoc.data();
      final servicesSnap = await FirebaseFirestore.instance
          .collection('providers')
          .doc(providerDoc.id)
          .collection('services')
          .where('isActive', isEqualTo: true)
          .get();

      for (final serviceDoc in servicesSnap.docs) {
        final serviceData = serviceDoc.data();
        final category = serviceData['category'] as String? ?? '';
        final rating = (providerData['rating'] ?? 0.0).toDouble();
        final bookingCount = (providerData['bookingCount'] ?? 0).toInt();
        final categoryWeight = categoryCount.containsKey(category)
            ? (categoryCount[category]! * 10).toDouble()
            : 0.0;
        final score = (categoryWeight * 0.5) +
            (rating * 10 * 0.3) +
            (bookingCount * 0.2);

        scored.add({
          'id': providerDoc.id,
          'serviceId': serviceDoc.id,
          'name': providerData['name'] ?? 'Provider',
          'category': category,
          'price': (serviceData['price'] ?? 0).toDouble(),
          'rating': rating,
          'description': serviceData['description'] ?? '',
          'score': score,
          'isRecommended': categoryWeight > 0,
        });
      }
    }

    scored.sort((a, b) => (b['score'] as double).compareTo(a['score']));

    final recommended =
        scored.where((p) => p['isRecommended'] == true).toList();
    final others =
        scored.where((p) => p['isRecommended'] == false).toList();

    String insight = '';
    if (categoryCount.isEmpty) {
      insight =
          'Book a service to start getting personalised recommendations.';
    } else {
      final topCategory = categoryCount.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      insight =
          'Based on your history, you frequently book $topCategory services. Here are your best matches.';
    }

    if (mounted) {
      setState(() {
        _recommended = recommended;
        _others = others;
        _insight = insight;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('For You',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16)),
        backgroundColor: _primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: _primary, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text('Analysing your preferences',
                      style: TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  const SizedBox(height: 6),
                  const Text('Finding your best matches...',
                      style: TextStyle(
                          color: _textSecondary, fontSize: 13)),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(color: _primary),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Insight banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: _primary.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.auto_awesome_rounded,
                              color: _primary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(_insight,
                              style: const TextStyle(
                                  color: _primary,
                                  fontSize: 13,
                                  height: 1.4)),
                        ),
                      ],
                    ),
                  ),

                  if (_recommended.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 18),
                        const SizedBox(width: 6),
                        const Text('Recommended For You',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                                letterSpacing: -0.3)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._recommended.map((p) => _serviceCard(p, true)),
                  ],

                  if (_others.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('Other Services',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                            letterSpacing: -0.3)),
                    const SizedBox(height: 12),
                    ..._others.map((p) => _serviceCard(p, false)),
                  ],

                  if (_recommended.isEmpty && _others.isEmpty)
                    Center(
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
                              child: const Icon(Icons.search_off_rounded,
                                  color: _primary, size: 32),
                            ),
                            const SizedBox(height: 16),
                            const Text('No services available yet',
                                style: TextStyle(
                                    color: _textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15)),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _serviceCard(Map<String, dynamic> provider, bool isRecommended) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingScreen(
            providerId: provider['id'],
            providerName: provider['name'],
            category: provider['category'],
            price: provider['price'],
            serviceId: provider['serviceId'],
            serviceDescription: provider['description'],
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: isRecommended
              ? Border.all(color: Colors.amber.withOpacity(0.3))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      provider['name'][0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                if (isRecommended)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star_rounded,
                          size: 11, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(provider['name'],
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: _textPrimary)),
                      if (isRecommended) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Best match',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.amber,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(provider['category'],
                      style: const TextStyle(
                          color: _textSecondary, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(provider['description'],
                      style: const TextStyle(
                          color: _textSecondary, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 13),
                    const SizedBox(width: 2),
                    Text(provider['rating'].toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('RM ${provider['price']}/hr',
                    style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}