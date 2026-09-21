import 'package:flutter/material.dart';
import '../../models/staff_model.dart';
import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';
import '../customer/customer_chat_screen.dart';

class StaffAgendaScreen extends StatefulWidget {
  final StaffModel staff;

  const StaffAgendaScreen({super.key, required this.staff});

  @override
  State<StaffAgendaScreen> createState() => _StaffAgendaScreenState();
}

class _StaffAgendaScreenState extends State<StaffAgendaScreen> {
  DateTime _selectedDate = DateTime.now();
  final AppointmentService _service = AppointmentService();

  @override
  Widget build(BuildContext context) {
    final permissions = widget.staff.permissions;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.staff.name, style: const TextStyle(fontSize: 16)),
            Text(widget.staff.title, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Tarih Başlığı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.blueGrey[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Günlük Randevu Ajandası", style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text("${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}"),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                ),
              ],
            ),
          ),

          // Randevu Listesi
          Expanded(
            child: StreamBuilder<List<AppointmentModel>>(
              stream: _service.streamStaffAppointments(widget.staff.id, _selectedDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final appointments = snapshot.data ?? [];
                if (appointments.isEmpty) {
                  return const Center(
                    child: Text("Bugün için onaylanmış randevunuz bulunmamaktadır."),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appt = appointments[index];

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
                                  "⏰ ${appt.startDateTime.hour.toString().padLeft(2, '0')}:${appt.startDateTime.minute.toString().padLeft(2, '0')} - ${appt.endDateTime.hour.toString().padLeft(2, '0')}:${appt.endDateTime.minute.toString().padLeft(2, '0')}",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Chip(
                                  label: Text(
                                    appt.status,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor: appt.status == 'ONAYLANDI'
                                      ? Colors.green[100]
                                      : Colors.red[100],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Müşteri Bilgisi (Yetki kontrolü ile telefon gizleme)
                            Text("👤 Müşteri: ${appt.customerName}",
                                style: const TextStyle(fontWeight: FontWeight.bold)),

                            if (permissions.canViewCustomerPhone)
                              Text("📞 Telefon: ${appt.customerPhone}",
                                  style: const TextStyle(color: Colors.blueGrey))
                            else
                              const Text("🔒 Telefon: Yönetici Tarafından Gizlendi",
                                  style: TextStyle(color: Colors.grey, fontSize: 11)),

                            const SizedBox(height: 4),
                            Text("✂️ Hizmetler: ${appt.services.map((s) => s.name).join(' + ')}"),
                            const Divider(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.chat, size: 14),
                                  label: const Text("Müşteriye Mesaj"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber[800],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CustomerChatScreen(appointment: appt),
                                      ),
                                    );
                                  },
                                ),

                                if (permissions.canCancelAppointments && appt.status == 'ONAYLANDI')
                                  TextButton(
                                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                                    onPressed: () => _cancelByStaff(appt.id),
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
          ),
        ],
      ),
    );
  }

  void _cancelByStaff(String apptId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Randevu İptali"),
        content: const Text("Bu randevuyu iptal etmek istediğinizden emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hayır")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Evet")),
        ],
      ),
    );

    if (confirm == true) {
      await _service.cancelAppointmentByStaff(apptId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Randevu iptal edildi.")),
        );
      }
    }
  }
}
