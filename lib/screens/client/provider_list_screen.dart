import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'provider_profile_screen.dart';

class ProviderListScreen extends StatelessWidget {
  final String category;
  const ProviderListScreen({super.key, required this.category});

  static const _primary = Color(0xFF2563EB);
  static const _bg = Color(0xFFF7F8FA);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(category,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16)),
        backgroundColor: _primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchProvidersByCategory(category),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: _primary));
          }
          final providers = snapshot.data!;
          if (providers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.search_off_rounded,
                        color: _primary, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text('No $category providers yet',
                      style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('Check back soon',
                      style: TextStyle(
                          color: _textSecondary, fontSize: 13)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final data = providers[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProviderProfileScreen(
                      providerId: data['providerId'],
                      providerName: data['providerName'],
                      providerRating:
                          (data['providerRating'] as num).toDouble(),
                    ),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
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
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: _primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            (data['providerName'] ?? 'P')[0]
                                .toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['providerName'] ?? 'Provider',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: _textPrimary)),
                            const SizedBox(height: 3),
                            Text(
                              '${data['serviceCount']} service${data['serviceCount'] == 1 ? '' : 's'} available',
                              style: const TextStyle(
                                  color: _textSecondary,
                                  fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: Colors.amber, size: 14),
                                const SizedBox(width: 3),
                                Text(
                                  (data['providerRating'] ?? 0.0)
                                      .toStringAsFixed(1),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _textPrimary),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${data['bookingCount']} bookings',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: _textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'From RM ${data['minPrice']}',
                            style: const TextStyle(
                                color: _primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13),
                          ),
                          const Text('/hr',
                              style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 11)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('View Profile',
                                style: TextStyle(
                                    color: _primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
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
    );
  }

  Future<List<Map<String, dynamic>>> _fetchProvidersByCategory(
      String category) async {
    final providersSnap = await FirebaseFirestore.instance
        .collection('providers')
        .where('isVerified', isEqualTo: true)
        .get();

    final List<Map<String, dynamic>> results = [];

    for (final providerDoc in providersSnap.docs) {
      final providerData = providerDoc.data();
      final servicesSnap = await FirebaseFirestore.instance
          .collection('providers')
          .doc(providerDoc.id)
          .collection('services')
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .get();

      if (servicesSnap.docs.isEmpty) continue;

      final prices = servicesSnap.docs
          .map((d) => (d.data()['price'] as num).toDouble())
          .toList();
      final minPrice = prices.reduce((a, b) => a < b ? a : b);

      results.add({
        'providerId': providerDoc.id,
        'providerName': providerData['name'] ?? '',
        'providerRating': providerData['rating'] ?? 0.0,
        'bookingCount': providerData['bookingCount'] ?? 0,
        'serviceCount': servicesSnap.docs.length,
        'minPrice': minPrice,
      });
    }
    return results;
  }
}