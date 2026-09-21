import '../models/salon_model.dart';
import '../models/appointment_model.dart';

class TimeInterval {
  final int startMinutes;
  final int endMinutes;

  TimeInterval({required this.startMinutes, required this.endMinutes});

  bool overlapsWith(int candidateStart, int candidateEnd) {
    return candidateStart < endMinutes && candidateEnd > startMinutes;
  }
}

class SlotCalculatorService {
  /// Kuaförün çalışma saatleri ve mevcut randevularına göre seçilen hizmet süresine uygun boş saatleri hesaplar
  static List<String> calculateAvailableSlots({
    required SalonModel salon,
    required DateTime date,
    required int totalDurationMinutes,
    required List<AppointmentModel> existingAppointments,
    int stepMinutes = 15,
  }) {
    if (totalDurationMinutes <= 0) return [];

    final openMinutes = _parseTimeToMinutes(salon.openTime);
    final closeMinutes = _parseTimeToMinutes(salon.closeTime);
    final lunchStart = _parseTimeToMinutes(salon.lunchStart);
    final lunchEnd = _parseTimeToMinutes(salon.lunchEnd);

    // Meşgul Zaman Dilimleri (Mevcut Onaylı Randevular + Öğle Molası)
    final List<TimeInterval> busyIntervals = [];

    // Öğle molasını ekle
    busyIntervals.add(TimeInterval(startMinutes: lunchStart, endMinutes: lunchEnd));

    // O günkü onaylı randevuları ekle
    for (final appt in existingAppointments) {
      if (appt.status == 'ONAYLANDI') {
        final startM = appt.startDateTime.hour * 60 + appt.startDateTime.minute;
        final endM = appt.endDateTime.hour * 60 + appt.endDateTime.minute;
        busyIntervals.add(TimeInterval(startMinutes: startM, endMinutes: endM));
      }
    }

    final List<String> availableSlots = [];

    // Açılış saatinden kapanış saatine kadar stepMinutes (15 dk) adımlarla tara
    for (int m = openMinutes; m + totalDurationMinutes <= closeMinutes; m += stepMinutes) {
      final slotStart = m;
      final slotEnd = m + totalDurationMinutes;

      // Çakışma var mı kontrolü
      bool hasConflict = false;
      for (final busy in busyIntervals) {
        if (busy.overlapsWith(slotStart, slotEnd)) {
          hasConflict = true;
          break;
        }
      }

      if (!hasConflict) {
        availableSlots.add(_formatMinutesToTime(slotStart));
      }
    }

    return availableSlots;
  }

  static int _parseTimeToMinutes(String timeStr) {
    final parts = timeStr.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    return h * 60 + m;
  }

  static String _formatMinutesToTime(int totalMinutes) {
    final h = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final m = (totalMinutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}
