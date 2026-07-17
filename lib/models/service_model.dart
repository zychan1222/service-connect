class ServiceModel {
  final String id;
  final String providerId;
  final String providerName;
  final String category;
  final String description;
  final double price;
  final bool isActive;

  ServiceModel({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.category,
    required this.description,
    required this.price,
    required this.isActive,
  });

  factory ServiceModel.fromMap(String id, Map<String, dynamic> map) {
    return ServiceModel(
      id: id,
      providerId: map['providerId'] ?? '',
      providerName: map['providerName'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'providerId': providerId,
      'providerName': providerName,
      'category': category,
      'description': description,
      'price': price,
      'isActive': isActive,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}