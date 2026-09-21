class SalonModel {
  final int id;
  final String name;
  final String logoUrl;
  final String phone;
  final String address;
  final String openTime;    // Örn: "09:00"
  final String closeTime;   // Örn: "19:00"
  final String lunchStart;  // Örn: "12:30"
  final String lunchEnd;    // Örn: "13:30"
  final int cancellationWindowHours; // Varsayılan 3 saat

  SalonModel({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.phone,
    required this.address,
    required this.openTime,
    required this.closeTime,
    required this.lunchStart,
    required this.lunchEnd,
    this.cancellationWindowHours = 3,
  });

  factory SalonModel.fromMap(Map<String, dynamic> map) {
    return SalonModel(
      id: map['id'] ?? 1,
      name: map['name'] ?? '',
      logoUrl: map['logoUrl'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      openTime: map['openTime'] ?? '09:00',
      closeTime: map['closeTime'] ?? '19:00',
      lunchStart: map['lunchStart'] ?? '12:30',
      lunchEnd: map['lunchEnd'] ?? '13:30',
      cancellationWindowHours: map['cancellationWindowHours'] ?? 3,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
      'phone': phone,
      'address': address,
      'openTime': openTime,
      'closeTime': closeTime,
      'lunchStart': lunchStart,
      'lunchEnd': lunchEnd,
      'cancellationWindowHours': cancellationWindowHours,
    };
  }
}
