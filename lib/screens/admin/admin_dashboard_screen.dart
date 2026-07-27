import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static const _primary = Color(0xFF2563EB);
  static const _bg = Color(0xFFF7F8FA);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white, size: 17),
            ),
            const SizedBox(width: 10),
            const Text('Admin',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded,
                  color: Colors.white, size: 17),
            ),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(
                        builder: (_) => const LoginScreen()));
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              decoration: const BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Platform Overview',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8)),
                  SizedBox(height: 4),
                  Text('Manage users, providers and approvals.',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _statCard('Users', 'users',
                      const Color(0xFF2563EB)),
                  const SizedBox(width: 12),
                  _statCard('Providers', 'providers',
                      const Color(0xFF10B981)),
                  const SizedBox(width: 12),
                  _statCard('Bookings', 'bookings',
                      const Color(0xFFF59E0B)),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Pending approvals
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Pending Approvals',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                      letterSpacing: -0.3)),
            ),
            const SizedBox(height: 14),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('providers')
                  .where('isVerified', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: _primary));
                }
                final pending = snapshot.data!.docs;
                if (pending.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFF10B981)
                                .withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: Color(0xFF10B981), size: 20),
                          SizedBox(width: 10),
                          Text('All providers are verified',
                              style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20),
                  itemCount: pending.length,
                  itemBuilder: (context, index) {
                    final data = pending[index].data()
                        as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
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
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color:
                                      _primary.withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    (data['name'] ??
                                            'P')[0]
                                        .toUpperCase(),
                                    style: const TextStyle(
                                        color: _primary,
                                        fontWeight:
                                            FontWeight.w700,
                                        fontSize: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        data['name'] ??
                                            'Provider',
                                        style: const TextStyle(
                                            fontWeight:
                                                FontWeight.w700,
                                            fontSize: 14,
                                            color: _textPrimary)),
                                    Text(data['email'] ?? '',
                                        style: const TextStyle(
                                            color: _textSecondary,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFBEB),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: const Text('PENDING',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFFF59E0B),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5)),
                              ),
                            ],
                          ),

                          // Services summary
                          FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('providers')
                                .doc(pending[index].id)
                                .collection('services')
                                .get(),
                            builder: (context, svcSnap) {
                              if (!svcSnap.hasData) {
                                return const SizedBox.shrink();
                              }
                              final services =
                                  svcSnap.data!.docs;
                              if (services.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(
                                    top: 12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${services.length} service${services.length == 1 ? '' : 's'} submitted:',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: _textSecondary,
                                          fontWeight:
                                              FontWeight.w500),
                                    ),
                                    const SizedBox(height: 6),
                                    ...services.map((s) {
                                      final sd = s.data()
                                          as Map<String, dynamic>;
                                      final priceMin =
                                          sd['priceMin'] ??
                                              sd['price'] ??
                                              0;
                                      final priceMax =
                                          sd['priceMax'] ??
                                              priceMin;
                                      final hasPriceRange =
                                          priceMax > priceMin;
                                      return Container(
                                        margin:
                                            const EdgeInsets.only(
                                                bottom: 6),
                                        padding:
                                            const EdgeInsets.all(
                                                10),
                                        decoration: BoxDecoration(
                                          color: _bg,
                                          borderRadius:
                                              BorderRadius.circular(
                                                  10),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 8,
                                                  vertical: 3),
                                              decoration:
                                                  BoxDecoration(
                                                color: _primary
                                                    .withOpacity(
                                                        0.08),
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(6),
                                              ),
                                              child: Text(
                                                  sd['category'] ??
                                                      '',
                                                  style: const TextStyle(
                                                      color: _primary,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight
                                                              .w600)),
                                            ),
                                            const SizedBox(
                                                width: 8),
                                            Expanded(
                                              child: Text(
                                                  sd['description'] ??
                                                      '',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          _textSecondary),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow
                                                          .ellipsis),
                                            ),
                                            Text(
                                              hasPriceRange
                                                  ? 'RM $priceMin–$priceMax/hr'
                                                  : 'RM $priceMin/hr',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: _primary,
                                                  fontWeight:
                                                      FontWeight.w700),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      await FirebaseFirestore
                                          .instance
                                          .collection('providers')
                                          .doc(pending[index].id)
                                          .update(
                                              {'isVerified': true});
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                                context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Provider approved'),
                                            backgroundColor:
                                                Color(0xFF10B981),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                                context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Failed to approve provider')),
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF10B981),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                                10)),
                                  ),
                                  child: const Text('Approve',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight:
                                              FontWeight.w600)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    try {
                                      // Delete services subcollection first
                                      final services =
                                          await FirebaseFirestore
                                              .instance
                                              .collection(
                                                  'providers')
                                              .doc(pending[index].id)
                                              .collection('services')
                                              .get();
                                      final batch =
                                          FirebaseFirestore.instance
                                              .batch();
                                      for (final s
                                          in services.docs) {
                                        batch.delete(s.reference);
                                      }
                                      batch.delete(FirebaseFirestore
                                          .instance
                                          .collection('providers')
                                          .doc(pending[index].id));
                                      await batch.commit();

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                                context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Provider rejected and removed'),
                                            backgroundColor:
                                                Colors.red,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                                context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Failed to reject provider')),
                                        );
                                      }
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(
                                        color: Color(0xFFE2E8F0)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                                10)),
                                  ),
                                  child: const Text('Reject',
                                      style: TextStyle(
                                          fontWeight:
                                              FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 28),

            // All users
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('All Users',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                      letterSpacing: -0.3)),
            ),
            const SizedBox(height: 14),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: _primary));
                }
                final users = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final data = users[index].data()
                        as Map<String, dynamic>;
                    final role = data['role'] ?? 'client';
                    final roleColor = role == 'admin'
                        ? Colors.purple
                        : role == 'provider'
                            ? const Color(0xFF10B981)
                            : _primary;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                (data['name'] ?? 'U')[0]
                                    .toUpperCase(),
                                style: TextStyle(
                                    color: roleColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(data['name'] ?? 'User',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _textPrimary,
                                        fontSize: 14)),
                                Text(data['email'] ?? '',
                                    style: const TextStyle(
                                        color: _textSecondary,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.08),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Text(role.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: roleColor,
                                    letterSpacing: 0.5)),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
      String label, String collection, Color color) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(collection)
            .snapshots(),
        builder: (context, snapshot) {
          final count = snapshot.data?.docs.length ?? 0;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: color.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                Text('$count',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: color)),
                const SizedBox(height: 4),
                Text(label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          );
        },
      ),
    );
  }
}