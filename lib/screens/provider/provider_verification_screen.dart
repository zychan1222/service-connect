import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProviderVerificationScreen extends StatefulWidget {
  const ProviderVerificationScreen({super.key});

  @override
  State<ProviderVerificationScreen> createState() =>
      _ProviderVerificationScreenState();
}

class _ProviderVerificationScreenState
    extends State<ProviderVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _icController = TextEditingController();
  final _experienceController = TextEditingController();
  final _certificationsController = TextEditingController();
  final _serviceAreaController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  // Verification documents (e.g. IC photo, certifications) picked by the
  // provider before submission. Stored as bytes so this works on both
  // mobile and web (XFile.readAsBytes avoids dart:io File, which isn't
  // available on web).
  final List<_PickedDoc> _pickedDocs = [];
  static const int _maxDocs = 3;
  bool _isUploadingDocs = false;

  static const _primary = Color(0xFF2563EB);
  static const _bg = Color(0xFFF7F8FA);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);

  @override
  void dispose() {
    _phoneController.dispose();
    _icController.dispose();
    _experienceController.dispose();
    _certificationsController.dispose();
    _serviceAreaController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    if (_pickedDocs.length >= _maxDocs) return;
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _pickedDocs.add(_PickedDoc(name: file.name, bytes: bytes));
    });
  }

  void _removeDocument(int index) {
    setState(() => _pickedDocs.removeAt(index));
  }

  /// Uploads every picked document to Firebase Storage under
  /// verification_documents/{uid}/ and returns their download URLs plus
  /// display names, ready to save on the verification request.
  Future<List<Map<String, String>>> _uploadDocuments(String uid) async {
    final results = <Map<String, String>>[];
    for (var i = 0; i < _pickedDocs.length; i++) {
      final doc = _pickedDocs[i];
      final ref = FirebaseStorage.instance
          .ref()
          .child('verification_documents')
          .child(uid)
          .child('${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
      await ref.putData(
        doc.bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await ref.getDownloadURL();
      results.add({'name': doc.name, 'url': url});
    }
    return results;
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedDocs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please attach at least one verification document (e.g. IC or certification photo)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final name = userDoc.data()?['name'] ?? 'Provider';
      final email = userDoc.data()?['email'] ?? '';

      // Upload verification documents first so we can attach their URLs
      // to the request below.
      setState(() => _isUploadingDocs = true);
      final documents = await _uploadDocuments(user.uid);
      setState(() => _isUploadingDocs = false);

      // Save verification request
      await FirebaseFirestore.instance
          .collection('verificationRequests')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'phone': _phoneController.text.trim(),
        'icNumber': _icController.text.trim(),
        'yearsOfExperience': _experienceController.text.trim(),
        'certifications': _certificationsController.text.trim(),
        'serviceArea': _serviceAreaController.text.trim(),
        'address': _addressController.text.trim(),
        'documents': documents,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      // Create provider document with isVerified: false
      await FirebaseFirestore.instance
          .collection('providers')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'serviceArea': _serviceAreaController.text.trim(),
        'rating': 0.0,
        'bookingCount': 0,
        'isVerified': false,
        'verificationStatus': 'pending',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Verification submitted for review'),
            backgroundColor: Color(0xFF10B981)),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to submit. Please try again.'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploadingDocs = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    // Check if already submitted
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('verificationRequests')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final hasRequest = snapshot.hasData && snapshot.data!.exists;
        final requestData = hasRequest
            ? snapshot.data!.data() as Map<String, dynamic>
            : null;
        final status = requestData?['status'] ?? '';
        final rejectionReason = requestData?['rejectionReason'] ?? '';

        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            title: const Text('Provider Verification',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16)),
            backgroundColor: _primary,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            automaticallyImplyLeading: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: hasRequest
                ? _buildStatusView(status, rejectionReason)
                : _buildForm(),
          ),
        );
      },
    );
  }

  Widget _buildStatusView(String status, String rejectionReason) {
    if (status == 'pending') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.schedule_rounded,
                  color: Color(0xFFF59E0B), size: 40),
            ),
            const SizedBox(height: 24),
            const Text('Verification Pending',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            const Text(
              'Your verification request has been submitted and is awaiting admin review. You will be notified once a decision has been made.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color(0xFF64748B), fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFFF59E0B).withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: Color(0xFFF59E0B), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You can browse the app but cannot offer services until your account is verified.',
                      style: TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 13,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Back to Home',
                    style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'rejected') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.cancel_rounded,
                  color: Colors.red, size: 40),
            ),
            const SizedBox(height: 24),
            const Text('Verification Rejected',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            const Text(
              'Your verification request was not approved. Please review the reason below and resubmit.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color(0xFF64748B), fontSize: 14, height: 1.5),
            ),
            if (rejectionReason.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reason:',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                            fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(rejectionReason,
                        style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                            height: 1.4)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  // Delete old request and allow resubmission
                  await FirebaseFirestore.instance
                      .collection('verificationRequests')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .delete();
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Resubmit Verification',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: _primary.withOpacity(0.15)),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_user_rounded,
                    color: _primary, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Become a Verified Provider',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: _primary)),
                      SizedBox(height: 4),
                      Text(
                        'Submit your details for admin review. Once approved, you can start offering services to clients.',
                        style: TextStyle(
                            color: _primary,
                            fontSize: 12,
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Personal Details
          _sectionLabel('Personal Details'),
          const SizedBox(height: 12),

          _formField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: 'e.g. 012-3456789',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) =>
                v!.isEmpty ? 'Phone number is required' : null,
          ),
          const SizedBox(height: 14),
          _formField(
            controller: _icController,
            label: 'IC Number',
            hint: 'e.g. 900101-14-5678',
            icon: Icons.badge_outlined,
            validator: (v) =>
                v!.isEmpty ? 'IC number is required' : null,
          ),
          const SizedBox(height: 14),
          _formField(
            controller: _addressController,
            label: 'Full Address',
            hint: 'e.g. No. 12, Jalan Harmoni, 47500 Subang Jaya, Selangor',
            icon: Icons.home_outlined,
            maxLines: 2,
            validator: (v) =>
                v!.isEmpty ? 'Address is required' : null,
          ),

          const SizedBox(height: 24),

          // Professional Details
          _sectionLabel('Professional Details'),
          const SizedBox(height: 12),

          _formField(
            controller: _experienceController,
            label: 'Years of Experience',
            hint: 'e.g. 5',
            icon: Icons.work_outline_rounded,
            keyboardType: TextInputType.number,
            validator: (v) =>
                v!.isEmpty ? 'Years of experience is required' : null,
          ),
          const SizedBox(height: 14),
          _formField(
            controller: _certificationsController,
            label: 'Certifications / Qualifications',
            hint: 'e.g. SKM Level 3 Plumbing, Certified Electrician',
            icon: Icons.workspace_premium_outlined,
            maxLines: 3,
            validator: (v) => null, // Optional
          ),
          const SizedBox(height: 14),
          _formField(
            controller: _serviceAreaController,
            label: 'Service Area',
            hint: 'e.g. Subang Jaya, Shah Alam, Petaling Jaya',
            icon: Icons.location_on_outlined,
            validator: (v) =>
                v!.isEmpty ? 'Service area is required' : null,
          ),

          const SizedBox(height: 24),

          // Verification Documents
          _sectionLabel('Verification Documents'),
          const SizedBox(height: 4),
          const Text(
            'Upload a photo of your IC and any certifications (max 3). '
            'These are reviewed by an admin before your account is verified.',
            style: TextStyle(
                color: _textSecondary, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          _buildDocumentPicker(),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        ),
                        if (_isUploadingDocs) ...[
                          const SizedBox(width: 12),
                          const Text('Uploading documents...',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ],
                    )
                  : const Text('Submit for Verification',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDocumentPicker() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ..._pickedDocs.asMap().entries.map((entry) {
          final index = entry.key;
          final doc = entry.value;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                  image: DecorationImage(
                    image: MemoryImage(doc.bytes),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: -8,
                right: -8,
                child: GestureDetector(
                  onTap: () => _removeDocument(index),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          );
        }),
        if (_pickedDocs.length < _maxDocs)
          GestureDetector(
            onTap: _pickDocument,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _primary.withOpacity(0.4),
                    style: BorderStyle.solid),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined,
                      color: _primary, size: 22),
                  SizedBox(height: 6),
                  Text('Add',
                      style: TextStyle(
                          color: _primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: _textPrimary,
          letterSpacing: -0.3));

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textPrimary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style:
              const TextStyle(fontSize: 14, color: _textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                color: _textSecondary, fontSize: 13),
            prefixIcon:
                Icon(icon, color: _textSecondary, size: 20),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 48, minHeight: 48),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: _primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Colors.red, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

/// A verification document the provider has picked but not yet uploaded.
class _PickedDoc {
  final String name;
  final Uint8List bytes;

  _PickedDoc({required this.name, required this.bytes});
}