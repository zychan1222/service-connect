import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/notification_service.dart';

class BookingScreen extends StatefulWidget {
  final String providerId;
  final String providerName;
  final String category;
  final double price;
  final String serviceId;
  final String serviceDescription;

  const BookingScreen({
    super.key,
    required this.providerId,
    required this.providerName,
    required this.category,
    required this.price,
    required this.serviceId,
    required this.serviceDescription,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _notesController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  static const _primary = Color(0xFF2563EB);
  static const _bg = Color(0xFFF7F8FA);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _primary),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _primary),
        ),
        child: child!,
      ),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _submitBooking() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();
      final clientName = userDoc.data()?['name'] ?? 'Client';

      final dateStr =
          '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';
      final timeStr = _selectedTime!.format(context);

      final bookingRef = await FirebaseFirestore.instance
          .collection('bookings')
          .add({
        'clientId': user.uid,
        'clientName': clientName,
        'providerId': widget.providerId,
        'providerName': widget.providerName,
        'serviceId': widget.serviceId,
        'serviceDescription': widget.serviceDescription,
        'category': widget.category,
        'price': widget.price,
        'date': dateStr,
        'time': timeStr,
        'notes': _notesController.text.trim(),
        'status': 'pending',
        'reviewed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await NotificationService.sendNotification(
        toUserId: widget.providerId,
        title: 'New Booking Request',
        body:
            '$clientName has requested your ${widget.category} service on $dateStr at $timeStr',
        type: 'booking_received',
        bookingId: bookingRef.id,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Booking submitted successfully'),
            backgroundColor: Color(0xFF10B981)),
      );
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Book Service',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16)),
        backgroundColor: _primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        widget.providerName[0].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.providerName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: _textPrimary)),
                        const SizedBox(height: 2),
                        Text(widget.category,
                            style: const TextStyle(
                                color: _textSecondary, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(widget.serviceDescription,
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
                      Text('RM ${widget.price}',
                          style: const TextStyle(
                              color: _primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 18)),
                      const Text('/hr',
                          style: TextStyle(
                              color: _textSecondary, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text('Select Date & Time',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    letterSpacing: -0.3)),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: _selectedDate != null
                                ? _primary
                                : _border,
                            width: _selectedDate != null ? 1.5 : 1),
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
                          Icon(Icons.calendar_today_rounded,
                              color: _selectedDate != null
                                  ? _primary
                                  : _textSecondary,
                              size: 18),
                          const SizedBox(height: 8),
                          Text(
                            _selectedDate == null ? 'Select date' : 
                            '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                            style: TextStyle(
                                color: _selectedDate == null
                                    ? _textSecondary
                                    : _textPrimary,
                                fontWeight: _selectedDate != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: _selectedTime != null
                                ? _primary
                                : _border,
                            width: _selectedTime != null ? 1.5 : 1),
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
                          Icon(Icons.access_time_rounded,
                              color: _selectedTime != null
                                  ? _primary
                                  : _textSecondary,
                              size: 18),
                          const SizedBox(height: 8),
                          Text(
                            _selectedTime == null
                                ? 'Select time'
                                : _selectedTime!.format(context),
                            style: TextStyle(
                                color: _selectedTime == null
                                    ? _textSecondary
                                    : _textPrimary,
                                fontWeight: _selectedTime != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text('Additional Notes',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    letterSpacing: -0.3)),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 4,
              style: const TextStyle(fontSize: 14, color: _textPrimary),
              decoration: InputDecoration(
                hintText:
                    'Describe your issue or any special requirements...',
                hintStyle: const TextStyle(
                    color: _textSecondary, fontSize: 14),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: _primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Confirm Booking',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}