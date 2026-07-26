import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'provider_services_screen.dart';
import 'provider_reviews_screen.dart';
import '../auth/login_screen.dart';
import '../../services/notification_service.dart';
import '../../screens/notifications_screen.dart';

class ProviderHomeScreen extends StatefulWidget {
  const ProviderHomeScreen({super.key});

  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  int _currentIndex = 0;

  static const _primary = Color(0xFF2563EB);
  static const _bg = Color(0xFFF7F8FA);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
              child: const Icon(Icons.handyman_rounded,
                  color: Colors.white, size: 17),
            ),
            const SizedBox(width: 10),
            const Text('ServiceConnect',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3)),
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
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _BookingsTab(user: user),
          const ProviderServicesScreen(),
          const ProviderReviewsScreen(),
          const NotificationsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(user),
    );
  }

  Widget _buildBottomNav(user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              _navItem(
                  index: 0,
                  icon: Icons.home_rounded,
                  label: 'Home'),
              _navItem(
                  index: 1,
                  icon: Icons.handyman_rounded,
                  label: 'Services'),
              _navItem(
                  index: 2,
                  icon: Icons.star_rounded,
                  label: 'Reviews'),
              _navItemWithBadge(
                index: 3,
                icon: Icons.notifications_rounded,
                label: 'Notifications',
                userId: user?.uid ?? '',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
      {required int index,
      required IconData icon,
      required String label}) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF2563EB).withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF94A3B8),
                  size: 22),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF94A3B8))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItemWithBadge({
    required int index,
    required IconData icon,
    required String label,
    required String userId,
  }) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF2563EB).withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('toUserId', isEqualTo: userId)
                    .where('isRead', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(icon,
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF94A3B8),
                          size: 22),
                      if (count > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                count > 9 ? '9+' : '$count',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF94A3B8))),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingsTab extends StatelessWidget {
  final user;
  const _BookingsTab({required this.user});

  static const _primary = Color(0xFF2563EB);
  static const _bg = Color(0xFFF7F8FA);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted': return const Color(0xFF10B981);
      case 'completed': return const Color(0xFF2563EB);
      case 'declined': return Colors.red;
      case 'cancelled': return Colors.grey;
      default: return const Color(0xFFF59E0B);
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'accepted': return const Color(0xFFECFDF5);
      case 'completed': return const Color(0xFFEFF6FF);
      case 'declined': return const Color(0xFFFEF2F2);
      case 'cancelled': return const Color(0xFFF1F5F9);
      default: return const Color(0xFFFFFBEB);
    }
  }

  Color _urgencyColor(String u) {
    switch (u) {
      case 'Urgent': return const Color(0xFFF59E0B);
      case 'Emergency': return Colors.red;
      default: return const Color(0xFF10B981);
    }
  }

  Widget _tag(String label, Color bg, Color color) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color)),
      );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .get(),
              builder: (context, snapshot) {
                final name =
                    snapshot.data?.get('name') ?? 'Provider';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome, $name',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          height: 1.2,
                        )),
                    const SizedBox(height: 4),
                    const Text('Manage your bookings below.',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 14)),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 28),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text('Booking Requests',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    letterSpacing: -0.3)),
          ),
          const SizedBox(height: 14),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('providerId', isEqualTo: user?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                      child: CircularProgressIndicator(
                          color: _primary)),
                );
              }
              final bookings = snapshot.data!.docs;
              if (bookings.isEmpty) {
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
                          child: const Icon(Icons.inbox_rounded,
                              color: _primary, size: 32),
                        ),
                        const SizedBox(height: 16),
                        const Text('No bookings yet',
                            style: TextStyle(
                                color: _textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                        const SizedBox(height: 4),
                        const Text(
                            'Bookings will appear here when clients request your services',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: _textSecondary,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final data = bookings[index].data()
                      as Map<String, dynamic>;
                  final status = data['status'] ?? 'pending';
                  final urgency = data['urgency'] ?? 'Normal';
                  final budgetMin = data['budgetMin'] ?? 0;
                  final budgetMax = data['budgetMax'] ?? 0;
                  final hasBudget =
                      budgetMin > 0 || budgetMax > 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: urgency == 'Emergency'
                          ? Border.all(
                              color: Colors.red.withOpacity(0.3),
                              width: 1.5)
                          : urgency == 'Urgent'
                              ? Border.all(
                                  color: const Color(0xFFF59E0B)
                                      .withOpacity(0.3),
                                  width: 1.5)
                              : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Client info + status
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color:
                                          _primary.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        (data['clientName'] ??
                                                'C')[0]
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
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          data['clientName'] ??
                                              'Client',
                                          style: const TextStyle(
                                              fontWeight:
                                                  FontWeight.w700,
                                              fontSize: 14,
                                              color: _textPrimary)),
                                      Text(data['category'] ?? '',
                                          style: const TextStyle(
                                              color: _textSecondary,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _statusBg(status),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Text(status.toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: _statusColor(status),
                                        letterSpacing: 0.5)),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Date & time
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _bg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 14,
                                    color: _textSecondary),
                                const SizedBox(width: 6),
                                Text(data['date'] ?? '',
                                    style: const TextStyle(
                                        color: _textSecondary,
                                        fontSize: 13)),
                                const SizedBox(width: 16),
                                const Icon(Icons.access_time_rounded,
                                    size: 14,
                                    color: _textSecondary),
                                const SizedBox(width: 6),
                                Text(data['time'] ?? '',
                                    style: const TextStyle(
                                        color: _textSecondary,
                                        fontSize: 13)),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Tags
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _tag(
                                urgency,
                                _urgencyColor(urgency)
                                    .withOpacity(0.12),
                                _urgencyColor(urgency),
                              ),
                              if ((data['estimatedDuration'] ?? '')
                                  .isNotEmpty)
                                _tag(
                                  data['estimatedDuration'],
                                  _primary.withOpacity(0.08),
                                  _primary,
                                ),
                              if ((data['siteType'] ?? '').isNotEmpty)
                                _tag(
                                  data['siteType'],
                                  const Color(0xFFF1F5F9),
                                  _textSecondary,
                                ),
                              if (data['providerSupplyParts'] == true)
                                _tag(
                                  'Parts required',
                                  const Color(0xFFFFFBEB),
                                  const Color(0xFFF59E0B),
                                ),
                            ],
                          ),

                          // Budget
                          if (hasBudget) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(
                                    Icons
                                        .account_balance_wallet_rounded,
                                    size: 13,
                                    color: _textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  'Client budget: RM $budgetMin — RM $budgetMax',
                                  style: const TextStyle(
                                      color: _textSecondary,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ],

                          // Job description
                          if ((data['jobDescription'] ?? '')
                              .isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _bg,
                                borderRadius:
                                    BorderRadius.circular(10),
                                border: Border.all(
                                    color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text('Job Description',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: _textSecondary)),
                                  const SizedBox(height: 4),
                                  Text(data['jobDescription'],
                                      style: const TextStyle(
                                          color: _textPrimary,
                                          fontSize: 13,
                                          height: 1.4)),
                                ],
                              ),
                            ),
                          ],

                          // Pending — accept/decline
                          if (status == 'pending') ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('bookings')
                                          .doc(bookings[index].id)
                                          .update(
                                              {'status': 'accepted'});
                                      await NotificationService
                                          .sendNotification(
                                        toUserId: data['clientId'],
                                        title: 'Booking Accepted',
                                        body:
                                            '${data['providerName'] ?? 'Your provider'} has accepted your booking on ${data['date']}',
                                        type: 'booking_accepted',
                                        bookingId: bookings[index].id,
                                      );
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
                                    child: const Text('Accept',
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
                                      await FirebaseFirestore.instance
                                          .collection('bookings')
                                          .doc(bookings[index].id)
                                          .update(
                                              {'status': 'declined'});
                                      await NotificationService
                                          .sendNotification(
                                        toUserId: data['clientId'],
                                        title: 'Booking Declined',
                                        body:
                                            '${data['providerName'] ?? 'Your provider'} is unavailable on ${data['date']}.',
                                        type: 'booking_declined',
                                        bookingId: bookings[index].id,
                                      );
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
                                    child: const Text('Decline',
                                        style: TextStyle(
                                            fontWeight:
                                                FontWeight.w600)),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Accepted — mark complete + cancel
                          if (status == 'accepted') ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    title: const Text(
                                        'Mark as completed?',
                                        style: TextStyle(
                                            fontWeight:
                                                FontWeight.w700)),
                                    content: const Text(
                                        'This confirms the job is done. The client will be notified and can leave a review.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context),
                                        child: const Text('Not yet'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          await FirebaseFirestore
                                              .instance
                                              .collection('bookings')
                                              .doc(bookings[index].id)
                                              .update({
                                            'status': 'completed'
                                          });
                                          await NotificationService
                                              .sendNotification(
                                            toUserId: data['clientId'],
                                            title: 'Job Completed',
                                            body:
                                                '${data['providerName'] ?? 'Your provider'} has marked the job on ${data['date']} as completed. Leave a review!',
                                            type: 'booking_completed',
                                            bookingId:
                                                bookings[index].id,
                                          );
                                        },
                                        child: const Text(
                                            'Mark complete',
                                            style: TextStyle(
                                                color: Color(
                                                    0xFF2563EB),
                                                fontWeight:
                                                    FontWeight.w600)),
                                      ),
                                    ],
                                  ),
                                ),
                                icon: const Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: 16),
                                label: const Text('Mark as Completed',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF2563EB),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    title: const Text('Cancel booking?',
                                        style: TextStyle(
                                            fontWeight:
                                                FontWeight.w700)),
                                    content: const Text(
                                        'This will notify the client and cannot be undone.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context),
                                        child: const Text('Keep it'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          await FirebaseFirestore
                                              .instance
                                              .collection('bookings')
                                              .doc(bookings[index].id)
                                              .update({
                                            'status': 'cancelled'
                                          });
                                          await NotificationService
                                              .sendNotification(
                                            toUserId: data['clientId'],
                                            title:
                                                'Booking Cancelled by Provider',
                                            body:
                                                '${data['providerName'] ?? 'Your provider'} has cancelled the booking on ${data['date']}.',
                                            type: 'booking_cancelled',
                                            bookingId:
                                                bookings[index].id,
                                          );
                                        },
                                        child: const Text(
                                            'Cancel booking',
                                            style: TextStyle(
                                                color: Colors.red,
                                                fontWeight:
                                                    FontWeight.w600)),
                                      ),
                                    ],
                                  ),
                                ),
                                icon: const Icon(Icons.cancel_outlined,
                                    color: Colors.red, size: 16),
                                label: const Text('Cancel Booking',
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: Color(0xFFE2E8F0)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}