class ServiceModel {
  final int id;
  final String name;
  final int durationMinutes;
  final double price;
  final String category;

  ServiceModel({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.price,
    required this.category,
  });

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      durationMinutes: map['durationMinutes'] ?? 30,
      price: (map['price'] ?? 0).toDouble(),
      category: map['category'] ?? 'Genel',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'durationMinutes': durationMinutes,
      'price': price,
      'category': category,
    };
  }
}
