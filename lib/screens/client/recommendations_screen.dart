import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_screen.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _recommended = [];
  List<Map<String, dynamic>> _others = [];
  String _insight = '';

  @override
  void initState() {
    super.initState();
    _runMatchingAlgorithm();
  }

  Future<void> _runMatchingAlgorithm() async {
    final user = FirebaseAuth.instance.currentUser!;

    // Step 1: Get client's booking history
    final bookingsSnap = await FirebaseFirestore.instance
        .collection('bookings')
        .where('clientId', isEqualTo: user.uid)
        .get();

    // Step 2: Count category frequency (behaviour analysis)
    final Map<String, int> categoryCount = {};
    for (final doc in bookingsSnap.docs) {
      final category = doc.data()['category'] as String? ?? '';
      if (category.isNotEmpty) {
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }
    }

    // Step 3: Get all verified providers
    final providersSnap = await FirebaseFirestore.instance
        .collection('providers')
        .where('isVerified', isEqualTo: true)
        .get();

    // Step 4: Score each provider using hybrid algorithm
    // Score = (category_match_weight * 0.5) + (rating * 0.3) + (booking_count * 0.2)
    final List<Map<String, dynamic>> scored = [];
    for (final doc in providersSnap.docs) {
      final data = doc.data();
      final category = data['category'] as String? ?? '';
      final rating = (data['rating'] ?? 0.0).toDouble();
      final bookingCount = (data['bookingCount'] ?? 0).toInt();

      // Category match weight — higher if user has booked this before
      final categoryWeight = categoryCount.containsKey(category)
          ? (categoryCount[category]! * 10).toDouble()
          : 0.0;

      // Composite score
      final score =
          (categoryWeight * 0.5) + (rating * 10 * 0.3) + (bookingCount * 0.2);

      scored.add({
        'id': doc.id,
        'name': data['name'] ?? 'Provider',
        'category': category,
        'price': (data['price'] ?? 0).toDouble(),
        'rating': rating,
        'description': data['description'] ?? '',
        'score': score,
        'isRecommended': categoryWeight > 0,
      });
    }

    // Step 5: Sort by score descending
    scored.sort((a, b) => (b['score'] as double).compareTo(a['score']));

    // Step 6: Split into recommended vs others
    final recommended =
        scored.where((p) => p['isRecommended'] == true).toList();
    final others =
        scored.where((p) => p['isRecommended'] == false).toList();

    // Step 7: Generate insight text
    String insight = '';
    if (categoryCount.isEmpty) {
      insight = 'Book a service to get personalised recommendations!';
    } else {
      final topCategory = categoryCount.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      insight =
          'Based on your history, you frequently book $topCategory services. '
          'We\'ve ranked the best providers for you!';
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Recommended For You',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2563EB),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF2563EB)),
                  SizedBox(height: 16),
                  Text('Analysing your preferences...',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Insight banner
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFF2563EB).withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: Color(0xFF2563EB)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(_insight,
                              style: const TextStyle(
                                  color: Color(0xFF2563EB), fontSize: 13)),
                        ),
                      ],
                    ),
                  ),

                  // Recommended section
                  if (_recommended.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 18),
                          SizedBox(width: 6),
                          Text('Recommended For You',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    ..._recommended.map((p) => _providerCard(p, true)),
                  ],

                  // Other providers
                  if (_others.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text('Other Providers',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    ..._others.map((p) => _providerCard(p, false)),
                  ],

                  if (_recommended.isEmpty && _others.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.search_off,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('No providers available yet',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _providerCard(Map<String, dynamic> provider, bool isRecommended) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingScreen(
              providerId: provider['id'],
              providerName: provider['name'],
              category: provider['category'],
              price: provider['price'],
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF2563EB),
                    radius: 28,
                    child: Text(
                      provider['name'][0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20),
                    ),
                  ),
                  if (isRecommended)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.star,
                            size: 12, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(provider['name'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        if (isRecommended) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Best Match',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(provider['category'],
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(provider['description'],
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: Colors.amber, size: 14),
                      Text(provider['rating'].toStringAsFixed(1),
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('RM ${provider['price']}/hr',
                      style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}