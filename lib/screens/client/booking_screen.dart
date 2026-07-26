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
  final _jobDescController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  String _selectedDuration = '1 hour';
  String _selectedUrgency = 'Normal';
  String _selectedSiteType = 'Residential';
  bool _providerSupplyParts = false;

  static const _primary = Color(0xFF2563EB);
  static const _bg = Color(0xFFF7F8FA);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);

  final List<String> _durations = [
    '1 hour', '2 hours', '3 hours', 'Half day', 'Full day', 'Multiple days'
  ];
  final List<String> _urgencyLevels = ['Normal', 'Urgent', 'Emergency'];
  final List<String> _siteTypes = ['Residential', 'Commercial', 'Industrial'];

  Color _urgencyColor(String u) {
    switch (u) {
      case 'Urgent': return const Color(0xFFF59E0B);
      case 'Emergency': return Colors.red;
      default: return const Color(0xFF10B981);
    }
  }

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
    if (_jobDescController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the job')),
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

      final budgetMin = double.tryParse(_budgetMinController.text) ?? 0;
      final budgetMax = double.tryParse(_budgetMaxController.text) ?? 0;

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
        'jobDescription': _jobDescController.text.trim(),
        'estimatedDuration': _selectedDuration,
        'budgetMin': budgetMin,
        'budgetMax': budgetMax,
        'urgency': _selectedUrgency,
        'siteType': _selectedSiteType,
        'providerSupplyParts': _providerSupplyParts,
        'status': 'pending',
        'reviewed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await NotificationService.sendNotification(
        toUserId: widget.providerId,
        title: 'New Booking Request',
        body:
            '$clientName has requested your ${widget.category} service on $dateStr at $timeStr — $_selectedUrgency priority',
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

            // ── Section: Date & Time ─────────────────────────────────────
            _sectionLabel('Date & Time'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _dateTile()),
                const SizedBox(width: 12),
                Expanded(child: _timeTile()),
              ],
            ),

            const SizedBox(height: 24),

            // ── Section: Job Description ─────────────────────────────────
            _sectionLabel('Job Description'),
            const SizedBox(height: 4),
            _sectionHint('Describe the issue or work you need done'),
            const SizedBox(height: 12),
            _textField(
              controller: _jobDescController,
              hint: 'e.g. Kitchen sink leaking under the cabinet, needs pipe replacement...',
              maxLines: 4,
            ),

            const SizedBox(height: 24),

            // ── Section: Estimated Duration ──────────────────────────────
            _sectionLabel('Estimated Duration'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _durations.map((d) => GestureDetector(
                onTap: () => setState(() => _selectedDuration = d),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedDuration == d
                        ? _primary
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedDuration == d
                          ? _primary
                          : _border,
                    ),
                  ),
                  child: Text(d,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _selectedDuration == d
                              ? Colors.white
                              : _textSecondary)),
                ),
              )).toList(),
            ),

            const SizedBox(height: 24),

            // ── Section: Budget Range ────────────────────────────────────
            _sectionLabel('Budget Range (RM)'),
            const SizedBox(height: 4),
            _sectionHint('Set your expected cost range for this job'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _textField(
                    controller: _budgetMinController,
                    hint: 'Min (e.g. 50)',
                    keyboardType: TextInputType.number,
                    prefix: const Text('RM ',
                        style: TextStyle(
                            color: _textSecondary,
                            fontWeight: FontWeight.w500)),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('—',
                      style: TextStyle(
                          color: _textSecondary, fontSize: 16)),
                ),
                Expanded(
                  child: _textField(
                    controller: _budgetMaxController,
                    hint: 'Max (e.g. 200)',
                    keyboardType: TextInputType.number,
                    prefix: const Text('RM ',
                        style: TextStyle(
                            color: _textSecondary,
                            fontWeight: FontWeight.w500)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Section: Urgency Level ───────────────────────────────────
            _sectionLabel('Urgency Level'),
            const SizedBox(height: 12),
            Row(
              children: _urgencyLevels.map((u) {
                final isSelected = _selectedUrgency == u;
                final color = _urgencyColor(u);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedUrgency = u),
                    child: Container(
                      margin: EdgeInsets.only(
                          right: u != _urgencyLevels.last ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? color : _border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            u == 'Normal'
                                ? Icons.schedule_rounded
                                : u == 'Urgent'
                                    ? Icons.priority_high_rounded
                                    : Icons.warning_rounded,
                            color: isSelected ? color : _textSecondary,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(u,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? color
                                      : _textSecondary)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ── Section: Site Type ───────────────────────────────────────
            _sectionLabel('Site Type'),
            const SizedBox(height: 12),
            Row(
              children: _siteTypes.map((s) {
                final isSelected = _selectedSiteType == s;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedSiteType = s),
                    child: Container(
                      margin: EdgeInsets.only(
                          right: s != _siteTypes.last ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _primary.withOpacity(0.08)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _primary : _border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            s == 'Residential'
                                ? Icons.home_rounded
                                : s == 'Commercial'
                                    ? Icons.business_rounded
                                    : Icons.factory_rounded,
                            color: isSelected ? _primary : _textSecondary,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(s,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? _primary
                                      : _textSecondary)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ── Section: Parts ───────────────────────────────────────────
            _sectionLabel('Parts & Materials'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _providerSupplyParts
                              ? 'Provider supplies parts'
                              : 'I will supply my own parts',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _providerSupplyParts
                              ? 'Parts cost will be added to the final bill'
                              : 'You are responsible for sourcing materials',
                          style: const TextStyle(
                              color: _textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _providerSupplyParts,
                    activeColor: _primary,
                    onChanged: (val) =>
                        setState(() => _providerSupplyParts = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Cost Estimate Banner ─────────────────────────────────────
            if (_budgetMinController.text.isNotEmpty ||
                _budgetMaxController.text.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _primary.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: _primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your budget: RM ${_budgetMinController.text.isEmpty ? '0' : _budgetMinController.text} — RM ${_budgetMaxController.text.isEmpty ? '?' : _budgetMaxController.text}. '
                        'Provider rate is RM ${widget.price}/hr.',
                        style: const TextStyle(
                            color: _primary,
                            fontSize: 13,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Submit Button ────────────────────────────────────────────
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
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: _textPrimary,
          letterSpacing: -0.3));

  Widget _sectionHint(String text) => Text(text,
      style: const TextStyle(
          fontSize: 12, color: _textSecondary, height: 1.4));

  Widget _dateTile() => GestureDetector(
        onTap: _pickDate,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: _selectedDate != null ? _primary : _border,
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
                  color: _selectedDate != null ? _primary : _textSecondary,
                  size: 18),
              const SizedBox(height: 8),
              Text(
                _selectedDate == null
                    ? 'Select date'
                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
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
      );

  Widget _timeTile() => GestureDetector(
        onTap: _pickTime,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: _selectedTime != null ? _primary : _border,
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
                  color: _selectedTime != null ? _primary : _textSecondary,
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
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    Widget? prefix,
  }) =>
      TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: _textPrimary),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _textSecondary, fontSize: 13),
          prefix: prefix,
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
            borderSide: const BorderSide(color: _primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      );
}