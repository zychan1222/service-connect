import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_screen.dart';

class ProviderProfileScreen extends StatelessWidget {
  final String providerId;
  final String providerName;
  final double providerRating;

  const ProviderProfileScreen({
    super.key,
    required this.providerId,
    required this.providerName,
    required this.providerRating,
  });

  static const _primary = Color(0xFF2563EB);
  static const _bg = Color(0xFFF7F8FA);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          FirebaseFirestore.instance
              .collection('providers')
              .doc(providerId)
              .get(),
          FirebaseFirestore.instance
              .collection('providers')
              .doc(providerId)
              .collection('services')
              .where('isActive', isEqualTo: true)
              .get(),
          FirebaseFirestore.instance
              .collection('reviews')
              .where('providerId', isEqualTo: providerId)
              .orderBy('createdAt', descending: true)
              .get(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: _primary));
          }

          final providerDoc =
              snapshot.data![0] as DocumentSnapshot;
          final servicesSnap =
              snapshot.data![1] as QuerySnapshot;
          final reviewsSnap =
              snapshot.data![2] as QuerySnapshot;

          final providerData =
              providerDoc.data() as Map<String, dynamic>? ?? {};
          final services = servicesSnap.docs;
          final reviews = reviewsSnap.docs;
          final bookingCount =
              providerData['bookingCount'] ?? 0;
          final isVerified = providerData['isVerified'] == true;
          final phone = providerData['phone'] ?? '';
          final email = providerData['email'] ?? '';
          final hasContact =
              isVerified && (phone.isNotEmpty || email.isNotEmpty);

          return CustomScrollView(
            slivers: [
              // Hero app bar
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: _primary,
                iconTheme:
                    const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      color: _primary,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 48),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: Text(
                              providerName[0].toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(providerName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700)),
                            if (isVerified) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified_rounded,
                                  color: Colors.white, size: 18),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              providerRating.toStringAsFixed(1),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${reviews.length} reviews)',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats row
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          _statCard(
                              '${services.length}',
                              'Services',
                              Icons.handyman_rounded),
                          const SizedBox(width: 12),
                          _statCard(
                              '$bookingCount',
                              'Bookings',
                              Icons.calendar_month_rounded),
                          const SizedBox(width: 12),
                          _statCard(
                              providerRating.toStringAsFixed(1),
                              'Rating',
                              Icons.star_rounded),
                        ],
                      ),
                    ),

                    // Verified contact card — visible to any client
                    // browsing the profile once the provider is approved.
                    if (hasContact)
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFF10B981)
                                    .withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.verified_rounded,
                                      size: 15,
                                      color: Color(0xFF10B981)),
                                  const SizedBox(width: 8),
                                  const Text('Verified Contact',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF10B981))),
                                ],
                              ),
                              if (phone.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.phone_rounded,
                                        size: 14,
                                        color: _textSecondary),
                                    const SizedBox(width: 8),
                                    Text(phone,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: _textPrimary,
                                            fontWeight:
                                                FontWeight.w500)),
                                  ],
                                ),
                              ],
                              if (email.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.email_rounded,
                                        size: 14,
                                        color: _textSecondary),
                                    const SizedBox(width: 8),
                                    Text(email,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: _textPrimary,
                                            fontWeight:
                                                FontWeight.w500)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                    // Services section
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: Text('Services Offered',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                              letterSpacing: -0.3)),
                    ),

                    if (services.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        child: Text('No active services',
                            style: TextStyle(
                                color: _textSecondary,
                                fontSize: 13)),
                      ),

                    ...services.map((serviceDoc) {
                      final s = serviceDoc.data()
                          as Map<String, dynamic>;
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingScreen(
                              providerId: providerId,
                              providerName: providerName,
                              category: s['category'] ?? '',
                              price: (s['price'] as num)
                                  .toDouble(),
                              serviceId: serviceDoc.id,
                              serviceDescription:
                                  s['description'] ?? '',
                            ),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(
                              20, 0, 20, 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.black.withOpacity(0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color:
                                      _primary.withOpacity(0.08),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                    Icons.handyman_rounded,
                                    color: _primary,
                                    size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(s['category'] ?? '',
                                        style: const TextStyle(
                                            fontWeight:
                                                FontWeight.w700,
                                            fontSize: 14,
                                            color: _textPrimary)),
                                    const SizedBox(height: 2),
                                    Text(s['description'] ?? '',
                                        style: const TextStyle(
                                            color: _textSecondary,
                                            fontSize: 12),
                                        maxLines: 2,
                                        overflow:
                                            TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                      'RM ${s['price']}',
                                      style: const TextStyle(
                                          color: _primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15)),
                                  const Text('/hr',
                                      style: TextStyle(
                                          color: _textSecondary,
                                          fontSize: 11)),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _primary,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: const Text('Book',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight:
                                                FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    // Reviews section
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
                      child: Text('Reviews',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                              letterSpacing: -0.3)),
                    ),

                    if (reviews.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            20, 0, 20, 20),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text('No reviews yet',
                                style: TextStyle(
                                    color: _textSecondary,
                                    fontSize: 13)),
                          ),
                        ),
                      ),

                    ...reviews.take(5).map((reviewDoc) {
                      final r = reviewDoc.data()
                          as Map<String, dynamic>;
                      final rating = r['rating'] as int? ?? 0;
                      return Container(
                        margin: const EdgeInsets.fromLTRB(
                            20, 0, 20, 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color:
                                            _primary.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(9),
                                      ),
                                      child: Center(
                                        child: Text(
                                          (r['clientName'] ??
                                                  'C')[0]
                                              .toUpperCase(),
                                          style: const TextStyle(
                                              color: _primary,
                                              fontWeight:
                                                  FontWeight.w700,
                                              fontSize: 13),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                        r['clientName'] ?? 'Client',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: _textPrimary)),
                                  ],
                                ),
                                Row(
                                  children: List.generate(
                                    5,
                                    (i) => Icon(
                                      i < rating
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if ((r['review'] ?? '').isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(r['review'],
                                  style: const TextStyle(
                                      color: _textSecondary,
                                      fontSize: 13,
                                      height: 1.4)),
                            ],
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: _primary, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}