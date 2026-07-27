import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_screen.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() =>
      _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final _nameController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;
  late Future<DocumentSnapshot> _userFuture;

  static const _primary = Color(0xFF2563EB);
  static const _bg = Color(0xFFF7F8FA);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _userFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'name': _nameController.text.trim()});

      final providerDoc = await FirebaseFirestore.instance
          .collection('providers')
          .doc(user.uid)
          .get();
      if (providerDoc.exists) {
        await FirebaseFirestore.instance
            .collection('providers')
            .doc(user.uid)
            .update({'name': _nameController.text.trim()});
      }

      // Refresh the future
      setState(() {
        _isEditing = false;
        _userFuture = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Name updated'),
            backgroundColor: Color(0xFF10B981)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to update name'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('My Profile',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16)),
        backgroundColor: _primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _isEditing
                ? (_isSaving ? null : _saveName)
                : () => setState(() => _isEditing = true),
            child: Text(
              _isEditing ? 'Save' : 'Edit',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14),
            ),
          ),
          if (_isEditing)
            TextButton(
              onPressed: () => setState(() => _isEditing = false),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 14)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: _primary));
          }
          final data = snapshot.data!.data()
                  as Map<String, dynamic>? ??
              {};
          final name = data['name'] ?? 'User';
          final email = data['email'] ?? user.email ?? '';

          if (_nameController.text.isEmpty) {
            _nameController.text = name;
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Hero
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.fromLTRB(24, 28, 24, 32),
                  decoration: const BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Text(
                            name[0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_isEditing)
                        Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 32),
                          child: TextField(
                            controller: _nameController,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700),
                            decoration:
                                const InputDecoration(
                              hintText: 'Your name',
                              hintStyle: TextStyle(
                                  color: Colors.white54),
                              enabledBorder:
                                  UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.white54),
                              ),
                              focusedBorder:
                                  UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.white),
                              ),
                              filled: false,
                            ),
                          ),
                        )
                      else
                        Text(name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(email,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13)),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Stats — use StreamBuilder so counts update live
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .where('clientId', isEqualTo: user.uid)
                      .snapshots(),
                  builder: (context, bookingSnap) {
                    final bookings =
                        bookingSnap.data?.docs ?? [];
                    final total = bookings.length;
                    final completed = bookings
                        .where((b) =>
                            (b.data() as Map)['status'] ==
                            'completed')
                        .length;
                    final pending = bookings
                        .where((b) =>
                            (b.data() as Map)['status'] ==
                            'pending')
                        .length;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20),
                      child: Row(
                        children: [
                          _statCard(
                              '$total',
                              'Total\nBookings',
                              Icons.calendar_month_rounded),
                          const SizedBox(width: 12),
                          _statCard(
                              '$completed',
                              'Completed',
                              Icons.check_circle_rounded),
                          const SizedBox(width: 12),
                          _statCard('$pending', 'Pending',
                              Icons.schedule_rounded),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Account info
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
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
                    child: Column(
                      children: [
                        _infoRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Full Name',
                          value: name,
                        ),
                        _divider(),
                        _infoRow(
                          icon: Icons.mail_outline_rounded,
                          label: 'Email',
                          value: email,
                        ),
                        _divider(),
                        _infoRow(
                          icon: Icons.shield_outlined,
                          label: 'Account Type',
                          value: 'Client',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Recent bookings
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Recent Activity',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                              letterSpacing: -0.3)),
                      const SizedBox(height: 12),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('bookings')
                            .where('clientId',
                                isEqualTo: user.uid)
                            .orderBy('createdAt',
                                descending: true)
                            .limit(3)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Text('No recent activity',
                                    style: TextStyle(
                                        color: _textSecondary,
                                        fontSize: 13)),
                              ),
                            );
                          }
                          return Column(
                            children:
                                snapshot.data!.docs.map((doc) {
                              final d = doc.data()
                                  as Map<String, dynamic>;
                              final status =
                                  d['status'] ?? 'pending';
                              final statusColor =
                                  status == 'completed'
                                      ? _primary
                                      : status == 'accepted'
                                          ? const Color(
                                              0xFF10B981)
                                          : status ==
                                                      'declined' ||
                                                  status ==
                                                      'cancelled'
                                              ? Colors.red
                                              : const Color(
                                                  0xFFF59E0B);
                              return Container(
                                margin: const EdgeInsets.only(
                                    bottom: 10),
                                padding:
                                    const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: _primary
                                            .withOpacity(0.08),
                                        borderRadius:
                                            BorderRadius.circular(
                                                10),
                                      ),
                                      child: const Icon(
                                          Icons.handyman_rounded,
                                          color: _primary,
                                          size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                              d['providerName'] ??
                                                  'Provider',
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight
                                                          .w600,
                                                  fontSize: 13,
                                                  color:
                                                      _textPrimary)),
                                          Text(
                                              '${d['category']} • ${d['date']}',
                                              style: const TextStyle(
                                                  color:
                                                      _textSecondary,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor
                                            .withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(
                                                8),
                                      ),
                                      child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight:
                                                  FontWeight.w700,
                                              color: statusColor)),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Sign out
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout_rounded,
                          color: Colors.red, size: 18),
                      label: const Text('Sign Out',
                          style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(
      String value, String label, IconData icon) {
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
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _primary, size: 18),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: _textSecondary,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      color: _textPrimary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
      height: 1,
      thickness: 0.5,
      indent: 66,
      endIndent: 16);
}