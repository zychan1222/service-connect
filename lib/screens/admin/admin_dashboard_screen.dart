import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        title: const Text('Admin Dashboard',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome, Admin 👋',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Manage your platform below',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stats row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _statCard('Total Users', 'users', Colors.blue),
                  const SizedBox(width: 12),
                  _statCard('Providers', 'providers', Colors.green),
                  const SizedBox(width: 12),
                  _statCard('Bookings', 'bookings', Colors.orange),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text('Pending Provider Approvals',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('providers')
                  .where('isVerified', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final pending = snapshot.data!.docs;
                if (pending.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.check_circle,
                              size: 48, color: Colors.green),
                          SizedBox(height: 8),
                          Text('No pending approvals',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: pending.length,
                  itemBuilder: (context, index) {
                    final data =
                        pending[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFF2563EB),
                                  child: Text(
                                    (data['name'] ?? 'P')[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(data['name'] ?? 'Provider',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15)),
                                      Text(data['category'] ?? '',
                                          style: const TextStyle(
                                              color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text('PENDING',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(data['description'] ?? '',
                                style: const TextStyle(color: Colors.grey)),
                            Text('RM ${data['price']}/hr',
                                style: const TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('providers')
                                          .doc(pending[index].id)
                                          .update({'isVerified': true});
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content: Text('Provider approved!'),
                                          backgroundColor: Colors.green,
                                        ));
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green),
                                    child: const Text('Approve',
                                        style:
                                            TextStyle(color: Colors.white)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('providers')
                                          .doc(pending[index].id)
                                          .delete();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content: Text('Provider rejected'),
                                          backgroundColor: Colors.red,
                                        ));
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red),
                                    child: const Text('Reject'),
                                  ),
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

            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text('All Users',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final users = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final data = users[index].data() as Map<String, dynamic>;
                    final role = data['role'] ?? 'client';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: role == 'admin'
                              ? Colors.purple
                              : role == 'provider'
                                  ? Colors.green
                                  : const Color(0xFF2563EB),
                          child: Text(
                            (data['name'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(data['name'] ?? 'User',
                            style: const TextStyle(
                                fontWeight: FontWeight.w500)),
                        subtitle: Text(data['email'] ?? ''),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: role == 'admin'
                                ? Colors.purple.withOpacity(0.1)
                                : role == 'provider'
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(role.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: role == 'admin'
                                      ? Colors.purple
                                      : role == 'provider'
                                          ? Colors.green
                                          : Colors.blue)),
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

  Widget _statCard(String label, String collection, Color color) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(collection).snapshots(),
        builder: (context, snapshot) {
          final count = snapshot.data?.docs.length ?? 0;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Text('$count',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: color)),
                const SizedBox(height: 4),
                Text(label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          );
        },
      ),
    );
  }
}