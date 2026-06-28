import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewScreen extends StatefulWidget {
  final String providerId;
  final String providerName;
  final String bookingId;

  const ReviewScreen({
    super.key,
    required this.providerId,
    required this.providerName,
    required this.bookingId,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _reviewController = TextEditingController();
  int _rating = 0;
  bool _isLoading = false;

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();
      final clientName = userDoc.data()?['name'] ?? 'Client';

      // Save review
      await FirebaseFirestore.instance.collection('reviews').add({
        'providerId': widget.providerId,
        'clientId': user.uid,
        'clientName': clientName,
        'bookingId': widget.bookingId,
        'rating': _rating,
        'review': _reviewController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update provider average rating
      final reviewsSnap = await FirebaseFirestore.instance
          .collection('reviews')
          .where('providerId', isEqualTo: widget.providerId)
          .get();

      final ratings = reviewsSnap.docs
          .map((d) => (d.data()['rating'] as num).toDouble())
          .toList();
      final avgRating = ratings.reduce((a, b) => a + b) / ratings.length;

      await FirebaseFirestore.instance
          .collection('providers')
          .doc(widget.providerId)
          .update({
            'rating': double.parse(avgRating.toStringAsFixed(1)),
            'bookingCount': ratings.length,
          });

      // Mark booking as reviewed
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({'reviewed': true});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted!'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Leave a Review',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2563EB),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF2563EB),
                    radius: 36,
                    child: Text(
                      widget.providerName[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 28),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(widget.providerName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('How was your experience?',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Your Rating',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => setState(() => _rating = index + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 42,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _rating == 0 ? 'Tap to rate' :
                _rating == 1 ? 'Poor' :
                _rating == 2 ? 'Fair' :
                _rating == 3 ? 'Good' :
                _rating == 4 ? 'Very Good' : 'Excellent!',
                style: TextStyle(
                    color: _rating == 0 ? Colors.grey : Colors.amber,
                    fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 28),
            const Text('Your Review',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share your experience with this provider...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Review',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}