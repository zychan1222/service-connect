import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderReviewsScreen extends StatelessWidget {
  const ProviderReviewsScreen({super.key});

  static const _primary = Color(0xFF2563EB);
  static const _bg = Color(0xFFF7F8FA);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('My Reviews',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16)),
        backgroundColor: _primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('providerId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: _primary));
          }
          final reviews = snapshot.data!.docs;
          if (reviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text('No reviews yet',
                      style: TextStyle(
                          color: _textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text(
                      'Reviews from clients will appear here',
                      style: TextStyle(
                          color: _textSecondary, fontSize: 13)),
                ],
              ),
            );
          }

          final ratings = reviews
              .map((d) => (d.data() as Map)['rating'] as int)
              .toList();
          final avg = ratings.reduce((a, b) => a + b) / ratings.length;

          return Column(
            children: [
              // Rating summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                decoration: const BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    Text(avg.toStringAsFixed(1),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -2)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < avg.round()
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${reviews.length} ${reviews.length == 1 ? 'review' : 'reviews'}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final data =
                        reviews[index].data() as Map<String, dynamic>;
                    final rating = data['rating'] as int;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _primary.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        (data['clientName'] ?? 'C')[0]
                                            .toUpperCase(),
                                        style: const TextStyle(
                                            color: _primary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(data['clientName'] ?? 'Client',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: _textPrimary,
                                          fontSize: 14)),
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
                                    size: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if ((data['review'] ?? '').isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(data['review'],
                                style: const TextStyle(
                                    color: _textSecondary,
                                    fontSize: 13,
                                    height: 1.5)),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}