import 'service_model.dart';

class AppointmentModel {
  final String id;
  final int salonId;
  final int staffId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final List<ServiceModel> services;
  final int totalDuration;
  final double totalPrice;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String status; // 'ONAYLANDI', 'IPTAL', 'TAMAMLANDI'
  final DateTime createdAt;

  AppointmentModel({
    required this.id,
    required this.salonId,
    required this.staffId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.services,
    required this.totalDuration,
    required this.totalPrice,
    required this.startDateTime,
    required this.endDateTime,
    this.status = 'ONAYLANDI',
    required this.createdAt,
  });

  /// 3 Saat İptal Kuralı Kontrolü
  /// Randevu başlangıcına kalan süre parametre olarak verilen pencereden (varsayılan 3 saat) büyükse true döner.
  bool canCustomerCancel({int cancellationWindowHours = 3}) {
    if (status == 'IPTAL') return false;
    final now = DateTime.now();
    final difference = startDateTime.difference(now);
    return difference.inMinutes >= (cancellationWindowHours * 60);
  }

  factory AppointmentModel.fromMap(Map<String, dynamic> map, String docId) {
    return AppointmentModel(
      id: docId,
      salonId: map['salonId'] ?? 1,
      staffId: map['staffId'] ?? 1,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      services: (map['services'] as List<dynamic>? ?? [])
          .map((s) => ServiceModel.fromMap(Map<String, dynamic>.from(s)))
          .toList(),
      totalDuration: map['totalDuration'] ?? 30,
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      startDateTime: DateTime.parse(map['startDateTime']),
      endDateTime: DateTime.parse(map['endDateTime']),
      status: map['status'] ?? 'ONAYLANDI',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'salonId': salonId,
      'staffId': staffId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'services': services.map((s) => s.toMap()).toList(),
      'totalDuration': totalDuration,
      'totalPrice': totalPrice,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
