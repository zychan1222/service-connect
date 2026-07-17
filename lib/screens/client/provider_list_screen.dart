import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_screen.dart';

class ProviderListScreen extends StatelessWidget {
  final String category;
  const ProviderListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchServicesByCategory(category),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final services = snapshot.data!;
          if (services.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('No $category providers yet',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final data = services[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF2563EB),
                    radius: 28,
                    child: Text(
                      (data['providerName'] ?? 'P')[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20),
                    ),
                  ),
                  title: Text(data['providerName'] ?? 'Provider',
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['description'] ?? ''),
                      Text('RM ${data['price']}/hr',
                          style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
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
                        price: (data['price'] as num).toDouble(),
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
    );
  }

  Future<List<Map<String, dynamic>>> _fetchServicesByCategory(
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
}