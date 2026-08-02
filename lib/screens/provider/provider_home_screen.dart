import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'provider_services_screen.dart';
import 'provider_reviews_screen.dart';
import 'provider_verification_screen.dart';
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

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('providers')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, providerSnap) {
        final providerData = providerSnap.hasData &&
                providerSnap.data!.exists
            ? providerSnap.data!.data() as Map<String, dynamic>
            : null;
        final isVerified = providerData?['isVerified'] ?? false;
        final verificationStatus =
            providerData?['verificationStatus'] ?? 'none';

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
                    Navigator.pushReplacement(
                        context,
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
              _BookingsTab(user: user, isVerified: isVerified),
              isVerified
                  ? const ProviderServicesScreen()
                  : _LockedServicesTab(
                      verificationStatus: verificationStatus),
              const ProviderReviewsScreen(),
              const NotificationsScreen(),
              _ProviderProfileTab(user: user),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(user),
        );
      },
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
              _navItem(
                  index: 4,
                  icon: Icons.person_rounded,
                  label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
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

// ── Locked Services Tab ───────────────────────────────────────────────────────
class _LockedServicesTab extends StatelessWidget {
  final String verificationStatus;
  const _LockedServicesTab({required this.verificationStatus});

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final isPending = verificationStatus == 'pending';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isPending
                    ? const Color(0xFFFFFBEB)
                    : _primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                isPending
                    ? Icons.schedule_rounded
                    : Icons.lock_rounded,
                color: isPending
                    ? const Color(0xFFF59E0B)
                    : _primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isPending
                  ? 'Verification Pending'
                  : 'Verification Required',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              isPending
                  ? 'Your verification request is under review. You will be notified once the admin has made a decision.'
                  : 'You need to complete verification before you can offer services. Tap the button below to get started.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 28),
            if (!isPending)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const ProviderVerificationScreen()),
                  ),
                  icon: const Icon(Icons.verified_user_rounded,
                      color: Colors.white, size: 18),
                  label: const Text('Submit Verification',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Bookings Tab ──────────────────────────────────────────────────────────────
class _BookingsTab extends StatefulWidget {
  final user;
  final bool isVerified;
  const _BookingsTab({required this.user, required this.isVerified});

  @override
  State<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<_BookingsTab> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  static const _primary = Color(0xFF2563EB);
  static const _bg = Color(0xFFF7F8FA);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);

  final List<String> _filters = [
    'All', 'Pending', 'Accepted', 'Completed', 'Declined', 'Cancelled'
  ];

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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  // ---- Time proposal helpers (shared schema with ClientBookingsScreen:
  // proposedDate / proposedTime / proposedBy / proposalStatus) ----

  Future<void> _showProposeTimeDialog(BuildContext context, String bookingId,
      Map<String, dynamic> data) async {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Propose New Time',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today_rounded,
                      color: _primary, size: 18),
                  title: Text(
                      DateFormat('EEE, MMM d, yyyy').format(selectedDate),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 180)),
                    );
                    if (picked != null) setState(() => selectedDate = picked);
                  },
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.access_time_rounded,
                      color: _primary, size: 18),
                  title: Text(selectedTime.format(context),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  onTap: () async {
                    final picked = await showTimePicker(
                        context: context, initialTime: selectedTime);
                    if (picked != null) setState(() => selectedTime = picked);
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child:
                  const Text('Send Proposal', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    final formattedTime = selectedTime.format(context);

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'proposedDate': formattedDate,
        'proposedTime': formattedTime,
        'proposedBy': 'provider',
        'proposalStatus': 'pending',
      });

      await NotificationService.sendNotification(
        toUserId: data['clientId'],
        title: 'New Time Proposed',
        body:
            '${data['providerName'] ?? 'Your provider'} proposed $formattedDate at $formattedTime for your booking',
        type: 'time_proposed',
        bookingId: bookingId,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send time proposal')),
        );
      }
    }
  }

  Future<void> _acceptProposedTime(
      BuildContext context, String bookingId, Map<String, dynamic> data) async {
    try {
      final newDate = data['proposedDate'];
      final newTime = data['proposedTime'];
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'date': newDate,
        'time': newTime,
        'proposedDate': FieldValue.delete(),
        'proposedTime': FieldValue.delete(),
        'proposedBy': FieldValue.delete(),
        'proposalStatus': 'none',
      });
      await NotificationService.sendNotification(
        toUserId: data['clientId'],
        title: 'Time Proposal Accepted',
        body:
            '${data['providerName'] ?? 'Your provider'} accepted the new time: $newDate at $newTime',
        type: 'time_accepted',
        bookingId: bookingId,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to accept the proposed time')),
        );
      }
    }
  }

  Future<void> _declineProposedTime(
      BuildContext context, String bookingId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'proposedDate': FieldValue.delete(),
        'proposedTime': FieldValue.delete(),
        'proposedBy': FieldValue.delete(),
        'proposalStatus': 'none',
      });
      await NotificationService.sendNotification(
        toUserId: data['clientId'],
        title: 'Time Proposal Declined',
        body:
            '${data['providerName'] ?? 'Your provider'} kept the original booking time',
        type: 'time_declined',
        bookingId: bookingId,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to decline the proposed time')),
        );
      }
    }
  }

  List<QueryDocumentSnapshot> _filterBookings(
      List<QueryDocumentSnapshot> bookings) {
    return bookings.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] ?? 'pending';
      final clientName = (data['clientName'] ?? '').toLowerCase();
      final category = (data['category'] ?? '').toLowerCase();
      final q = _searchQuery.toLowerCase();
      final matchesFilter = _selectedFilter == 'All' ||
          status.toLowerCase() == _selectedFilter.toLowerCase();
      final matchesSearch = q.isEmpty ||
          clientName.contains(q) ||
          category.contains(q);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero header
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.user?.uid)
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
                                color: Colors.white70,
                                fontSize: 14)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) =>
                        setState(() => _searchQuery = val),
                    style: const TextStyle(
                        fontSize: 14, color: _textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search by client or category...',
                      hintStyle: const TextStyle(
                          color: _textSecondary, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: _textSecondary, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  color: _textSecondary, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Unverified banner
          if (!widget.isVerified) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFF59E0B).withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFF59E0B), size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Your account is not yet verified. Complete verification to start offering services.',
                        style: TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 12,
                            height: 1.4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const ProviderVerificationScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Verify',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Filter chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedFilter = filter),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? _primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? _primary
                            : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: _primary.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : [],
                    ),
                    child: Text(filter,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : _textSecondary)),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('providerId', isEqualTo: widget.user?.uid)
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

              final filtered =
                  _filterBookings(snapshot.data!.docs);

              if (filtered.isEmpty) {
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
                        Text(
                          _searchQuery.isNotEmpty ||
                                  _selectedFilter != 'All'
                              ? 'No bookings match your filter'
                              : 'No bookings yet',
                          style: const TextStyle(
                              color: _textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _searchQuery.isNotEmpty ||
                                  _selectedFilter != 'All'
                              ? 'Try a different filter or search term'
                              : 'Bookings will appear here when clients request your services',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: _textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${filtered.length} booking${filtered.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                          fontSize: 13,
                          color: _textSecondary,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final data = filtered[index].data()
                            as Map<String, dynamic>;
                        final bookingId = filtered[index].id;
                        final status =
                            data['status'] ?? 'pending';
                        final urgency =
                            data['urgency'] ?? 'Normal';
                        final budgetMin =
                            data['budgetMin'] ?? 0;
                        final budgetMax =
                            data['budgetMax'] ?? 0;
                        final hasBudget =
                            budgetMin > 0 || budgetMax > 0;
                        final proposalStatus =
                            data['proposalStatus'] ?? 'none';
                        final proposedBy = data['proposedBy'];
                        final canProposeTime = status == 'pending' ||
                            status == 'accepted';

                        return Container(
                          margin:
                              const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(16),
                            border: urgency == 'Emergency'
                                ? Border.all(
                                    color: Colors.red
                                        .withOpacity(0.3),
                                    width: 1.5)
                                : urgency == 'Urgent'
                                    ? Border.all(
                                        color: const Color(
                                                0xFFF59E0B)
                                            .withOpacity(0.3),
                                        width: 1.5)
                                    : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                // Client info + status
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration:
                                              BoxDecoration(
                                            color: _primary
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius
                                                    .circular(12),
                                          ),
                                          child: Center(
                                            child: Text(
                                              (data['clientName'] ??
                                                      'C')[0]
                                                  .toUpperCase(),
                                              style:
                                                  const TextStyle(
                                                color: _primary,
                                                fontWeight:
                                                    FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                          children: [
                                            Text(
                                                data['clientName'] ??
                                                    'Client',
                                                style:
                                                    const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  fontSize: 14,
                                                  color: _textPrimary,
                                                )),
                                            Text(
                                                data['category'] ??
                                                    '',
                                                style:
                                                    const TextStyle(
                                                  color:
                                                      _textSecondary,
                                                  fontSize: 12,
                                                )),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5),
                                      decoration: BoxDecoration(
                                        color: _statusBg(status),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight:
                                                FontWeight.w700,
                                            color:
                                                _statusColor(status),
                                            letterSpacing: 0.5,
                                          )),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Date & time
                                Container(
                                  padding:
                                      const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _bg,
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                          Icons
                                              .calendar_today_rounded,
                                          size: 14,
                                          color: _textSecondary),
                                      const SizedBox(width: 6),
                                      Text(data['date'] ?? '',
                                          style: const TextStyle(
                                              color: _textSecondary,
                                              fontSize: 13)),
                                      const SizedBox(width: 16),
                                      const Icon(
                                          Icons.access_time_rounded,
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

                                // ---- Time proposal section (shared
                                // schema with ClientBookingsScreen) ----
                                if (proposalStatus == 'pending' &&
                                    proposedBy == 'client') ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding:
                                        const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      border: Border.all(
                                          color: const Color(
                                                  0xFF2563EB)
                                              .withOpacity(0.2)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(
                                                Icons
                                                    .schedule_rounded,
                                                color:
                                                    Color(0xFF2563EB),
                                                size: 14),
                                            SizedBox(width: 6),
                                            Text(
                                                'Client proposed a new time',
                                                style: TextStyle(
                                                    color: Color(
                                                        0xFF2563EB),
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight
                                                            .w600)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                            '${data['proposedDate']} at ${data['proposedTime']}',
                                            style: const TextStyle(
                                                color:
                                                    Color(0xFF2563EB),
                                                fontSize: 13,
                                                fontWeight:
                                                    FontWeight.w700)),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () =>
                                                    _showProposeTimeDialog(
                                                        context,
                                                        bookingId,
                                                        data),
                                                style: OutlinedButton
                                                    .styleFrom(
                                                  foregroundColor:
                                                      _primary,
                                                  side: const BorderSide(
                                                      color: _primary),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      vertical: 10),
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(
                                                                  8)),
                                                ),
                                                child: const Text(
                                                    'Counter',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight
                                                                .w600)),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () =>
                                                    _declineProposedTime(
                                                        context,
                                                        bookingId,
                                                        data),
                                                style: OutlinedButton
                                                    .styleFrom(
                                                  foregroundColor:
                                                      _textSecondary,
                                                  side: const BorderSide(
                                                      color: Color(
                                                          0xFFE2E8F0)),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      vertical: 10),
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(
                                                                  8)),
                                                ),
                                                child: const Text(
                                                    'Keep Original',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight
                                                                .w600)),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () =>
                                                    _acceptProposedTime(
                                                        context,
                                                        bookingId,
                                                        data),
                                                style: ElevatedButton
                                                    .styleFrom(
                                                  backgroundColor:
                                                      const Color(
                                                          0xFF10B981),
                                                  elevation: 0,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      vertical: 10),
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(
                                                                  8)),
                                                ),
                                                child: const Text(
                                                    'Accept',
                                                    style: TextStyle(
                                                        color: Colors
                                                            .white,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight
                                                                .w600)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else if (proposalStatus == 'pending' &&
                                    proposedBy == 'provider') ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _bg,
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      border: Border.all(
                                          color:
                                              const Color(0xFFE2E8F0)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                            Icons.hourglass_top_rounded,
                                            size: 13,
                                            color: _textSecondary),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                              'Waiting for client to respond to ${data['proposedDate']} at ${data['proposedTime']}',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      _textSecondary)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else if (canProposeTime) ...[
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                      onPressed: () =>
                                          _showProposeTimeDialog(
                                              context, bookingId, data),
                                      icon: const Icon(
                                          Icons.edit_calendar_rounded,
                                          size: 15,
                                          color: _primary),
                                      label: const Text(
                                          'Propose New Time',
                                          style: TextStyle(
                                              color: _primary,
                                              fontWeight:
                                                  FontWeight.w600,
                                              fontSize: 12)),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(0, 0),
                                        tapTargetSize:
                                            MaterialTapTargetSize
                                                .shrinkWrap,
                                      ),
                                    ),
                                  ),
                                ],

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
                                    if ((data['estimatedDuration'] ??
                                            '')
                                        .isNotEmpty)
                                      _tag(
                                        data['estimatedDuration'],
                                        _primary.withOpacity(0.08),
                                        _primary,
                                      ),
                                    if ((data['siteType'] ?? '')
                                        .isNotEmpty)
                                      _tag(
                                        data['siteType'],
                                        const Color(0xFFF1F5F9),
                                        _textSecondary,
                                      ),
                                    if (data['providerSupplyParts'] ==
                                        true)
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
                                    padding:
                                        const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _bg,
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      border: Border.all(
                                          color: const Color(
                                              0xFFE2E8F0)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                            'Job Description',
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight:
                                                    FontWeight.w600,
                                                color:
                                                    _textSecondary)),
                                        const SizedBox(height: 4),
                                        Text(
                                            data['jobDescription'],
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
                                            await FirebaseFirestore
                                                .instance
                                                .collection('bookings')
                                                .doc(bookingId)
                                                .update({
                                              'status': 'accepted'
                                            });
                                            await NotificationService
                                                .sendNotification(
                                              toUserId:
                                                  data['clientId'],
                                              title:
                                                  'Booking Accepted',
                                              body:
                                                  '${data['providerName'] ?? 'Your provider'} has accepted your booking on ${data['date']}',
                                              type: 'booking_accepted',
                                              bookingId: bookingId,
                                            );
                                          },
                                          style:
                                              ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF10B981),
                                            elevation: 0,
                                            shape:
                                                RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(
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
                                            await FirebaseFirestore
                                                .instance
                                                .collection('bookings')
                                                .doc(bookingId)
                                                .update({
                                              'status': 'declined'
                                            });
                                            await NotificationService
                                                .sendNotification(
                                              toUserId:
                                                  data['clientId'],
                                              title:
                                                  'Booking Declined',
                                              body:
                                                  '${data['providerName'] ?? 'Your provider'} is unavailable on ${data['date']}.',
                                              type: 'booking_declined',
                                              bookingId: bookingId,
                                            );
                                          },
                                          style:
                                              OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(
                                                color:
                                                    Color(0xFFE2E8F0)),
                                            shape:
                                                RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(
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
                                if (status == 'accepted' &&
                                    proposalStatus != 'pending') ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      20)),
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
                                                  Navigator.pop(
                                                      context),
                                              child: const Text(
                                                  'Not yet'),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                Navigator.pop(context);
                                                await FirebaseFirestore
                                                    .instance
                                                    .collection(
                                                        'bookings')
                                                    .doc(bookingId)
                                                    .update({
                                                  'status': 'completed'
                                                });
                                                await NotificationService
                                                    .sendNotification(
                                                  toUserId:
                                                      data['clientId'],
                                                  title:
                                                      'Job Completed',
                                                  body:
                                                      '${data['providerName'] ?? 'Your provider'} has marked the job on ${data['date']} as completed. Leave a review!',
                                                  type:
                                                      'booking_completed',
                                                  bookingId: bookingId,
                                                );
                                              },
                                              child: const Text(
                                                  'Mark complete',
                                                  style: TextStyle(
                                                      color: Color(
                                                          0xFF2563EB),
                                                      fontWeight:
                                                          FontWeight
                                                              .w600)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      icon: const Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.white,
                                          size: 16),
                                      label: const Text(
                                          'Mark as Completed',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight:
                                                  FontWeight.w600)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF2563EB),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(
                                                    10)),
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
                                                  BorderRadius.circular(
                                                      20)),
                                          title: const Text(
                                              'Cancel booking?',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.w700)),
                                          content: const Text(
                                              'This will notify the client and cannot be undone.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(
                                                      context),
                                              child: const Text(
                                                  'Keep it'),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                Navigator.pop(context);
                                                await FirebaseFirestore
                                                    .instance
                                                    .collection(
                                                        'bookings')
                                                    .doc(bookingId)
                                                    .update({
                                                  'status': 'cancelled'
                                                });
                                                await NotificationService
                                                    .sendNotification(
                                                  toUserId:
                                                      data['clientId'],
                                                  title:
                                                      'Booking Cancelled by Provider',
                                                  body:
                                                      '${data['providerName'] ?? 'Your provider'} has cancelled the booking on ${data['date']}.',
                                                  type:
                                                      'booking_cancelled',
                                                  bookingId: bookingId,
                                                );
                                              },
                                              child: const Text(
                                                  'Cancel booking',
                                                  style: TextStyle(
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight
                                                              .w600)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      icon: const Icon(
                                          Icons.cancel_outlined,
                                          color: Colors.red,
                                          size: 16),
                                      label: const Text(
                                          'Cancel Booking',
                                          style: TextStyle(
                                              color: Colors.red,
                                              fontWeight:
                                                  FontWeight.w600)),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                            color: Color(0xFFE2E8F0)),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(
                                                    10)),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Provider Profile Tab ──────────────────────────────────────────────────────
class _ProviderProfileTab extends StatefulWidget {
  final user;
  const _ProviderProfileTab({required this.user});

  @override
  State<_ProviderProfileTab> createState() =>
      _ProviderProfileTabState();
}

class _ProviderProfileTabState extends State<_ProviderProfileTab> {
  final _nameController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  static const _primary = Color(0xFF2563EB);
  static const _bg = Color(0xFFF7F8FA);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);

  Future<void> _saveName() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final uid = widget.user?.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'name': _nameController.text.trim()});
      final providerDoc = await FirebaseFirestore.instance
          .collection('providers')
          .doc(uid)
          .get();
      if (providerDoc.exists) {
        await FirebaseFirestore.instance
            .collection('providers')
            .doc(uid)
            .update({'name': _nameController.text.trim()});
      }
      if (!mounted) return;
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Name updated'),
            backgroundColor: Color(0xFF10B981)),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.user?.uid ?? '';

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        FirebaseFirestore.instance.collection('users').doc(uid).get(),
        FirebaseFirestore.instance
            .collection('providers')
            .doc(uid)
            .get(),
        FirebaseFirestore.instance
            .collection('bookings')
            .where('providerId', isEqualTo: uid)
            .get(),
        FirebaseFirestore.instance
            .collection('reviews')
            .where('providerId', isEqualTo: uid)
            .get(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: _primary));
        }

        final userData =
            (snapshot.data![0] as DocumentSnapshot).data()
                    as Map<String, dynamic>? ??
                {};
        final providerData =
            (snapshot.data![1] as DocumentSnapshot).data()
                    as Map<String, dynamic>? ??
                {};
        final bookings = (snapshot.data![2] as QuerySnapshot).docs;
        final reviews = (snapshot.data![3] as QuerySnapshot).docs;

        final name = userData['name'] ?? 'Provider';
        final email = userData['email'] ?? widget.user?.email ?? '';
        final rating = (providerData['rating'] ?? 0.0).toDouble();
        final isVerified = providerData['isVerified'] ?? false;
        final phone = providerData['phone'] ?? '-';
        final address = providerData['address'] ?? '-';
        final serviceArea = providerData['serviceArea'] ?? '-';

        final completed = bookings
            .where((b) =>
                (b.data() as Map)['status'] == 'completed')
            .length;
        final pending = bookings
            .where(
                (b) => (b.data() as Map)['status'] == 'pending')
            .length;
        final accepted = bookings
            .where(
                (b) => (b.data() as Map)['status'] == 'accepted')
            .length;

        if (!_isEditing && _nameController.text.isEmpty) {
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
                          decoration: const InputDecoration(
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.white54),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.white),
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
                            color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isVerified
                                ? const Color(0xFF10B981)
                                    .withOpacity(0.2)
                                : Colors.orange.withOpacity(0.2),
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isVerified
                                    ? Icons.verified_rounded
                                    : Icons.schedule_rounded,
                                color: isVerified
                                    ? const Color(0xFF10B981)
                                    : Colors.orange,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isVerified
                                    ? 'Verified Provider'
                                    : 'Pending Verification',
                                style: TextStyle(
                                    color: isVerified
                                        ? const Color(0xFF10B981)
                                        : Colors.orange,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isEditing) ...[
                          TextButton(
                            onPressed:
                                _isSaving ? null : _saveName,
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withOpacity(0.2),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10)),
                            ),
                            child: const Text('Save',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => setState(
                                () => _isEditing = false),
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10)),
                            ),
                            child: const Text('Cancel',
                                style: TextStyle(
                                    color: Colors.white70)),
                          ),
                        ] else
                          TextButton.icon(
                            onPressed: () => setState(
                                () => _isEditing = true),
                            icon: const Icon(Icons.edit_rounded,
                                color: Colors.white, size: 14),
                            label: const Text('Edit Profile',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withOpacity(0.15),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Stats
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _statCard('${bookings.length}', 'Total\nJobs',
                        Icons.work_rounded),
                    const SizedBox(width: 12),
                    _statCard('$completed', 'Completed',
                        Icons.check_circle_rounded),
                    const SizedBox(width: 12),
                    _statCard(rating.toStringAsFixed(1), 'Rating',
                        Icons.star_rounded),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _statCard('$pending', 'Pending',
                        Icons.schedule_rounded),
                    const SizedBox(width: 12),
                    _statCard('$accepted', 'Accepted',
                        Icons.thumb_up_rounded),
                    const SizedBox(width: 12),
                    _statCard('${reviews.length}', 'Reviews',
                        Icons.reviews_rounded),
                  ],
                ),
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
                          value: name),
                      _divider(),
                      _infoRow(
                          icon: Icons.mail_outline_rounded,
                          label: 'Email',
                          value: email),
                      _divider(),
                      _infoRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: phone),
                      _divider(),
                      _infoRow(
                          icon: Icons.home_outlined,
                          label: 'Address',
                          value: address),
                      _divider(),
                      _infoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Service Area',
                          value: serviceArea),
                      _divider(),
                      _infoRow(
                          icon: Icons.shield_outlined,
                          label: 'Account Type',
                          value: 'Service Provider'),
                      _divider(),
                      _infoRow(
                          icon: Icons.star_outline_rounded,
                          label: 'Average Rating',
                          value: rating > 0
                              ? '${rating.toStringAsFixed(1)} / 5.0'
                              : 'No ratings yet'),
                    ],
                  ),
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
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!context.mounted) return;
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const LoginScreen()));
                    },
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
          Expanded(
            child: Column(
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
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
      height: 1, thickness: 0.5, indent: 66, endIndent: 16);
}