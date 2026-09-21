import 'package:flutter/material.dart';
import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';
import 'customer_chat_screen.dart';

class CustomerAppointmentsScreen extends StatelessWidget {
  final String customerId;
  final AppointmentService _service = AppointmentService();

  CustomerAppointmentsScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Randevularım"),
        backgroundColor: Colors.amber[800],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<AppointmentModel>>(
        stream: _service.streamCustomerAppointments(customerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final appointments = snapshot.data ?? [];
          if (appointments.isEmpty) {
            return const Center(
              child: Text("Henüz aktif bir randevunuz bulunmamaktadır."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appt = appointments[index];
              final canCancel = appt.canCustomerCancel(cancellationWindowHours: 3);
              final isCancelled = appt.status == 'IPTAL';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "⏰ ${appt.startDateTime.hour.toString().padLeft(2, '0')}:${appt.startDateTime.minute.toString().padLeft(2, '0')}",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Chip(
                            label: Text(
                              appt.status,
                              style: TextStyle(
                                color: isCancelled ? Colors.red : Colors.green[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            backgroundColor: isCancelled ? Colors.red[50] : Colors.green[50],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text("Hizmetler: ${appt.services.map((s) => s.name).join(' + ')}"),
                      Text("Tutar: ${appt.totalPrice.toStringAsFixed(0)} ₺  •  Süre: ${appt.totalDuration} dk"),
                      const Divider(height: 20),

                      // 3 Saat Kuralı Bilgilendirme Kutusu
                      if (!canCancel && !isCancelled)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber[300]!),
                          ),
                          child: const Text(
                            "⚠️ 3 Saat İptal Kısıtlaması: Randevunuza 3 saatten az kaldığı için uygulama üzerinden iptal yapılamamaktadır. Lütfen salonu doğrudan arayınız.",
                            style: TextStyle(fontSize: 11, color: Colors.brown),
                          ),
                        ),

                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Mesajlaşma Butonu
                          OutlinedButton.icon(
                            icon: const Icon(Icons.chat_bubble_outline, size: 16),
                            label: const Text("Kuaförle Yazış"),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CustomerChatScreen(
                                    appointment: appt,
                                  ),
                                ),
                              );
                            },
                          ),

                          // İptal Butonu
                          if (!isCancelled)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canCancel ? Colors.red : Colors.grey[300],
                                foregroundColor: canCancel ? Colors.white : Colors.grey[600],
                              ),
                              onPressed: canCancel
                                  ? () => _confirmCancel(context, appt.id)
                                  : null,
                              child: const Text("İptal Et"),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmCancel(BuildContext context, String appointmentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Randevu İptali"),
        content: const Text("Bu randevuyu iptal etmek istediğinizden emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Vazgeç")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _service.cancelAppointmentByCustomer(appointmentId: appointmentId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Randevunuz iptal edildi.")),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("İptal Et", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
