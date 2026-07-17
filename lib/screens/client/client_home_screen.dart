import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_screen.dart';
import 'client_bookings_screen.dart';
import 'recommendations_screen.dart';
import 'provider_list_screen.dart';
import 'booking_screen.dart';
import '../../widgets/notification_bell.dart';

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key});

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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        title: const Text('ServiceConnect',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const RecommendationsScreen())),
          ),
          const NotificationBell(),
          IconButton(
            icon: const Icon(Icons.bookmark, color: Colors.white),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const ClientBookingsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(
                        builder: (_) => const LoginScreen()));
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user?.uid)
                    .get(),
                builder: (context, snapshot) {
                  final name =
                      snapshot.data?.get('name') ?? 'there';
                  return Text('Hello, $name 👋',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold));
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text('What do you need help with?',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
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
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(cat['icon'],
                            color: const Color(0xFF2563EB), size: 32),
                        const SizedBox(height: 8),
                        Text(cat['label'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text('All Services',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchAllServices(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                final services = snapshot.data!;
                if (services.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No services yet',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final data = services[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF2563EB),
                          child: Text(
                            (data['providerName'] ?? 'P')[0]
                                .toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white),
                          ),
                        ),
                        title: Text(data['providerName'] ?? 'Provider',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            '${data['category']} • RM ${data['price']}/hr'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 16),
                            Text((data['providerRating'] ?? 0.0)
                                .toStringAsFixed(1)),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingScreen(
                              providerId: data['providerId'],
                              providerName: data['providerName'],
                              category: data['category'],
                              price:
                                  (data['price'] as num).toDouble(),
                              serviceId: data['serviceId'],
                              serviceDescription: data['description'],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
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