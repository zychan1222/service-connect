class ProviderModel {
  final String uid;
  final String name;
  final String email;
  final double rating;
  final int bookingCount;
  final bool isVerified;

  ProviderModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.rating,
    required this.bookingCount,
    required this.isVerified,
  });

  factory ProviderModel.fromMap(String uid, Map<String, dynamic> map) {
    return ProviderModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      bookingCount: (map['bookingCount'] ?? 0).toInt(),
      isVerified: map['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'rating': rating,
      'bookingCount': bookingCount,
      'isVerified': isVerified,
    };
  }
}