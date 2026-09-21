import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Yeni randevu oluşturma (Çakışma önleyici Transaction ile)
  Future<bool> createAppointment(AppointmentModel appt) async {
    final appointmentsRef = _firestore.collection('appointments');

    return await _firestore.runTransaction((transaction) async {
      // Çakışma kontrolü: Aynı personelin aynı zaman aralığında randevusu var mı?
      final querySnapshot = await appointmentsRef
          .where('staffId', isEqualTo: appt.staffId)
          .where('status', isEqualTo: 'ONAYLANDI')
          .get();

      for (var doc in querySnapshot.docs) {
        final existingStart = DateTime.parse(doc['startDateTime']);
        final existingEnd = DateTime.parse(doc['endDateTime']);

        // Zaman aralıklarının kesişmesi kontrolü
        if (appt.startDateTime.isBefore(existingEnd) && appt.endDateTime.isAfter(existingStart)) {
          throw Exception("Bu saat dilimi az önce başka bir müşteri tarafından rezerve edildi.");
        }
      }

      // Çakışma yoksa randevuyu kaydet
      final newDocRef = appointmentsRef.doc(appt.id);
      transaction.set(newDocRef, appt.toMap());
      return true;
    });
  }

  /// Müşteri Tarafından Randevu İptali (3 Saat Kuralı Kontrolü ile)
  Future<void> cancelAppointmentByCustomer({
    required String appointmentId,
    int cancellationWindowHours = 3,
  }) async {
    final docRef = _firestore.collection('appointments').doc(appointmentId);
    final doc = await docRef.get();

    if (!doc.exists) {
      throw Exception("Randevu bulunamadı.");
    }

    final appt = AppointmentModel.fromMap(doc.data()!, doc.id);

    // 3 Saat Kuralı Kontrolü
    if (!appt.canCustomerCancel(cancellationWindowHours: cancellationWindowHours)) {
      throw Exception(
        "Randevunuza 3 saatten az kaldığı için uygulama üzerinden iptal edilemez. Lütfen doğrudan salonu arayınız."
      );
    }

    await docRef.update({'status': 'IPTAL'});
  }

  /// Kuaför Çalışanı Tarafından Randevu İptali
  Future<void> cancelAppointmentByStaff(String appointmentId) async {
    final docRef = _firestore.collection('appointments').doc(appointmentId);
    await docRef.update({'status': 'IPTAL'});
  }

  /// Müşterinin Randevuları Akışı (Canlı Firestore Dinleyicisi)
  Stream<List<AppointmentModel>> streamCustomerAppointments(String customerId) {
    return _firestore
        .collection('appointments')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
          .toList()
        ..sort((a, b) => b.startDateTime.compareTo(a.startDateTime));
    });
  }

  /// Kuaför Çalışanının Günlük Randevu Ajandası Akışı
  Stream<List<AppointmentModel>> streamStaffAppointments(int staffId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _firestore
        .collection('appointments')
        .where('staffId', isEqualTo: staffId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
          .where((a) =>
              a.startDateTime.isAfter(startOfDay) &&
              a.startDateTime.isBefore(endOfDay))
          .toList()
        ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    });
  }
}
