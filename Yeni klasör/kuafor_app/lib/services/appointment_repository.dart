import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../models/service_model.dart';

/// Offline ve hazır demo modunu destekleyen merkezi veri deposu
class AppointmentRepository {
  static final AppointmentRepository instance = AppointmentRepository._internal();
  AppointmentRepository._internal() {
    _initInitialData();
  }

  final List<AppointmentModel> _appointments = [];

  void _initInitialData() {
    final now = DateTime.now();
    _appointments.add(
      AppointmentModel(
        id: "APT-101",
        salonId: 1,
        staffId: 1,
        customerId: "USER-101",
        customerName: "Caner Yılmaz",
        customerPhone: "0542 987 65 43",
        services: [
          ServiceModel(id: 1, name: "Saç Kesimi & Yıkama", durationMinutes: 30, price: 400, category: "Saç"),
        ],
        totalDuration: 30,
        totalPrice: 400,
        startDateTime: DateTime(now.year, now.month, now.day, 16, 0),
        endDateTime: DateTime(now.year, now.month, now.day, 16, 30),
        status: "ONAYLANDI",
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
    );
  }

  List<AppointmentModel> getCustomerAppointments(String customerId) {
    return _appointments.where((a) => a.customerId == customerId).toList()
      ..sort((a, b) => b.startDateTime.compareTo(a.startDateTime));
  }

  List<AppointmentModel> getStaffAppointments(int staffId, DateTime date) {
    return _appointments.where((a) {
      return a.staffId == staffId &&
          a.startDateTime.year == date.year &&
          a.startDateTime.month == date.month &&
          a.startDateTime.day == date.day;
    }).toList()
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
  }

  Future<void> addAppointment(AppointmentModel appt) async {
    // Çakışma kontrolü
    for (var existing in _appointments) {
      if (existing.staffId == appt.staffId && existing.status == 'ONAYLANDI') {
        if (appt.startDateTime.isBefore(existing.endDateTime) &&
            appt.endDateTime.isAfter(existing.startDateTime)) {
          throw Exception("Bu saat aralığı doludur. Lütfen başka bir saat seçin.");
        }
      }
    }
    _appointments.add(appt);
  }

  Future<void> cancelAppointment(String id, {bool isCustomer = true}) async {
    final index = _appointments.indexWhere((a) => a.id == id);
    if (index == -1) throw Exception("Randevu bulunamadı.");

    final appt = _appointments[index];
    if (isCustomer && !appt.canCustomerCancel(cancellationWindowHours: 3)) {
      throw Exception("Randevunuza 3 saatten az kaldığı için uygulama üzerinden iptal edilemez.");
    }

    _appointments[index] = AppointmentModel(
      id: appt.id,
      salonId: appt.salonId,
      staffId: appt.staffId,
      customerId: appt.customerId,
      customerName: appt.customerName,
      customerPhone: appt.customerPhone,
      services: appt.services,
      totalDuration: appt.totalDuration,
      totalPrice: appt.totalPrice,
      startDateTime: appt.startDateTime,
      endDateTime: appt.endDateTime,
      status: "IPTAL",
      createdAt: appt.createdAt,
    );
  }
}
