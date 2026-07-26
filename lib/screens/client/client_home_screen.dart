import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_screen.dart';
import 'client_bookings_screen.dart';
import 'recommendations_screen.dart';
import 'provider_list_screen.dart';
import 'provider_profile_screen.dart';
import '../../screens/notifications_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _currentIndex = 0;

  static const _primary = Color(0xFF2563EB);
  static const _bg = Color(0xFFF7F8FA);

  static const List<Map<String, dynamic>> _categories = [
    {'label': 'Plumbing', 'icon': Icons.plumbing},
    {'label': 'Electrical', 'icon': Icons.electrical_services},
    {'label': 'Cleaning', 'icon': Icons.cleaning_services},
    {'label': 'Carpentry', 'icon': Icons.handyman},
    {'label': 'Painting', 'icon': Icons.format_paint},
    {'label': 'Landscaping', 'icon': Icons.grass},
  ];

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
          _HomeTab(user: user),
          const RecommendationsScreen(),
          const ClientBookingsScreen(),
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
                  icon: Icons.auto_awesome_rounded,
                  label: 'For You'),
              _navItem(
                  index: 2,
                  icon: Icons.calendar_month_rounded,
                  label: 'Bookings'),
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
                  final count =
                      snapshot.data?.docs.length ?? 0;
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
                                    fontWeight:
                                        FontWeight.w700),
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

class _HomeTab extends StatefulWidget {
  final user;
  const _HomeTab({required this.user});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _allServices = [];
  bool _servicesLoaded = false;

  static const _primary = Color(0xFF2563EB);
  static const _bg = Color(0xFFF7F8FA);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);

  static const List<Map<String, dynamic>> _categories = [
    {'label': 'Plumbing', 'icon': Icons.plumbing},
    {'label': 'Electrical', 'icon': Icons.electrical_services},
    {'label': 'Cleaning', 'icon': Icons.cleaning_services},
    {'label': 'Carpentry', 'icon': Icons.handyman},
    {'label': 'Painting', 'icon': Icons.format_paint},
    {'label': 'Landscaping', 'icon': Icons.grass},
  ];

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    final results = await _fetchAllServices();
    if (mounted) {
      setState(() {
        _allServices = results;
        _servicesLoaded = true;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredServices {
    if (_searchQuery.isEmpty) return _allServices;
    final q = _searchQuery.toLowerCase();
    return _allServices.where((s) {
      return (s['providerName'] ?? '').toLowerCase().contains(q) ||
          (s['category'] ?? '').toLowerCase().contains(q) ||
          (s['description'] ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _searchQuery.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero header with search
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
                        snapshot.data?.get('name') ?? 'there';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello, $name',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                              height: 1.2,
                            )),
                        const SizedBox(height: 4),
                        const Text(
                            'What do you need help with today?',
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
                      hintText:
                          'Search providers, services, categories...',
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

          // Search results
          if (isSearching) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      size: 16, color: _textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '${_filteredServices.length} result${_filteredServices.length == 1 ? '' : 's'} for "$_searchQuery"',
                    style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_filteredServices.isEmpty)
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
                      const Text('No results found',
                          style: TextStyle(
                              color: _textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                      const SizedBox(height: 4),
                      const Text('Try a different search term',
                          style: TextStyle(
                              color: _textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _filteredServices.length,
                itemBuilder: (context, index) {
                  final data = _filteredServices[index];
                  return _serviceCard(context, data);
                },
              ),
          ],

          // Normal home content (hidden during search)
          if (!isSearching) ...[
            const SizedBox(height: 28),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text('Browse Categories',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                      letterSpacing: -0.3)),
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.05,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ProviderListScreen(
                              category: cat['label']))),
                  child: Container(
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(cat['icon'],
                              color: _primary, size: 22),
                        ),
                        const SizedBox(height: 8),
                        Text(cat['label'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _textPrimary)),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text('All Services',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                      letterSpacing: -0.3)),
            ),
            const SizedBox(height: 14),

            if (!_servicesLoaded)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                    child:
                        CircularProgressIndicator(color: _primary)),
              )
            else if (_allServices.isEmpty)
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
                      const Text('No services yet',
                          style: TextStyle(
                              color: _textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                      const SizedBox(height: 4),
                      const Text('Check back soon',
                          style: TextStyle(
                              color: _textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _allServices.length,
                itemBuilder: (context, index) {
                  final data = _allServices[index];
                  return _serviceCard(context, data);
                },
              ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _serviceCard(
      BuildContext context, Map<String, dynamic> data) {
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
        child: Row(
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
                  (data['providerName'] ?? 'P')[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
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
                          fontSize: 14,
                          color: _textPrimary)),
                  const SizedBox(height: 2),
                  Text(data['category'] ?? '',
                      style: const TextStyle(
                          color: _textSecondary, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(data['description'] ?? '',
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
                        color: Colors.amber, size: 14),
                    const SizedBox(width: 2),
                    Text(
                        (data['providerRating'] ?? 0.0)
                            .toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('RM ${data['price']}/hr',
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

Future<List<Map<String, dynamic>>> _fetchAllServices() async {
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
        .where('isActive', isEqualTo: true)
        .get();

    for (final serviceDoc in servicesSnap.docs) {
      final serviceData = serviceDoc.data();
      results.add({
        ...serviceData,
        'serviceId': serviceDoc.id,
        'providerId': providerDoc.id,
        'providerName': providerData['name'] ?? '',
        'providerRating': providerData['rating'] ?? 0.0,
      });
    }
  }
  return results;
}