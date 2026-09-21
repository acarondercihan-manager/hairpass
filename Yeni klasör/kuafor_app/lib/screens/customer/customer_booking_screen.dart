import 'package:flutter/material.dart';
import '../../models/salon_model.dart';
import '../../models/staff_model.dart';
import '../../models/service_model.dart';
import '../../models/appointment_model.dart';
import '../../services/slot_calculator_service.dart';
import '../../services/appointment_repository.dart';

class CustomerBookingScreen extends StatefulWidget {
  final SalonModel salon;
  final List<StaffModel> staffList;
  final List<ServiceModel> services;

  const CustomerBookingScreen({
    super.key,
    required this.salon,
    required this.staffList,
    required this.services,
  });

  @override
  State<CustomerBookingScreen> createState() => _CustomerBookingScreenState();
}

class _CustomerBookingScreenState extends State<CustomerBookingScreen> {
  late StaffModel _selectedStaff;
  final List<ServiceModel> _selectedServices = [];
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController(text: "Caner Yılmaz");
  final TextEditingController _phoneController = TextEditingController(text: "0542 987 65 43");
  final AppointmentRepository _repo = AppointmentRepository.instance;

  @override
  void initState() {
    super.initState();
    _selectedStaff = widget.staffList.first;
    if (widget.services.isNotEmpty) {
      _selectedServices.add(widget.services.first);
    }
  }

  int get _totalDuration =>
      _selectedServices.fold(0, (sum, s) => sum + s.durationMinutes);

  double get _totalPrice =>
      _selectedServices.fold(0.0, (sum, s) => sum + s.price);

  @override
  Widget build(BuildContext context) {
    // Seçilen kuaförün yapmaya yetkili olduğu hizmetleri filtrele
    final allowedServices = widget.services
        .where((s) => _selectedStaff.allowedServices.contains(s.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.salon.name),
        backgroundColor: Colors.amber[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Kuaför Personeli Seçimi
            _buildSectionTitle("1. Kuaförünüzü Seçin"),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.staffList.length,
                itemBuilder: (context, index) {
                  final staff = widget.staffList[index];
                  final isSelected = staff.id == _selectedStaff.id;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedStaff = staff;
                        _selectedSlot = null;
                        // Seçili hizmetlerden bu personelin yapamadığı varsa temizle
                        _selectedServices.removeWhere(
                            (s) => !staff.allowedServices.contains(s.id));
                        if (_selectedServices.isEmpty && allowedServices.isNotEmpty) {
                          _selectedServices.add(allowedServices.first);
                        }
                      });
                    },
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.amber[50] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.amber[800]! : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage(staff.avatarUrl),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            staff.name,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // 2. Hizmet Seçimi
            _buildSectionTitle("2. Hizmet(ler) Seçin (Süreye Göre Slot Değişir)"),
            ...allowedServices.map((service) {
              final isSelected = _selectedServices.any((s) => s.id == service.id);
              return CheckboxListTile(
                title: Text(service.name),
                subtitle: Text("⏳ ${service.durationMinutes} dk  •  ${service.category}"),
                secondary: Text(
                  "${service.price.toStringAsFixed(0)} ₺",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[900],
                    fontSize: 15,
                  ),
                ),
                value: isSelected,
                activeColor: Colors.amber[800],
                onChanged: (bool? val) {
                  setState(() {
                    if (val == true) {
                      _selectedServices.add(service);
                    } else {
                      if (_selectedServices.length > 1) {
                        _selectedServices.removeWhere((s) => s.id == service.id);
                      }
                    }
                    _selectedSlot = null;
                  });
                },
              );
            }),

            // Süre & Fiyat Özeti
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Toplam Süre: $_totalDuration dk",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("Toplam Tutar: ${_totalPrice.toStringAsFixed(0)} ₺",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.amber[900])),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Tarih & Dinamik Boş Saat Slotları
            _buildSectionTitle("3. Uygun Randevu Saatleri"),
            _buildSlotSection(),
            const SizedBox(height: 24),

            // 4. Onay Butonu
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _selectedSlot == null || _isLoading ? null : _handleBooking,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _selectedSlot == null
                            ? "Lütfen Saat Seçiniz"
                            : "Randevuyu Onayla ($_selectedSlot)",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotSection() {
    // SlotCalculatorService ile gerçek boş saatleri hesapla
    final availableSlots = SlotCalculatorService.calculateAvailableSlots(
      salon: widget.salon,
      date: _selectedDate,
      totalDurationMinutes: _totalDuration,
      existingAppointments: [], // Firestore'dan gelen mevcut randevular buraya geçer
    );

    if (availableSlots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text("Bu tarihte seçilen süreye uygun boşluk kalmamıştır.",
            style: TextStyle(color: Colors.red)),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableSlots.map((slot) {
        final isSelected = _selectedSlot == slot;
        return ChoiceChip(
          label: Text(slot),
          selected: isSelected,
          selectedColor: Colors.amber[800],
          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
          onSelected: (selected) {
            setState(() {
              _selectedSlot = selected ? slot : null;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _handleBooking() async {
    setState(() => _isLoading = true);

    try {
      final parts = _selectedSlot!.split(':');
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      final endDateTime = startDateTime.add(Duration(minutes: _totalDuration));

      final newAppt = AppointmentModel(
        id: "APT-${DateTime.now().millisecondsSinceEpoch}",
        salonId: widget.salon.id,
        staffId: _selectedStaff.id,
        customerId: "USER-101",
        customerName: _nameController.text,
        customerPhone: _phoneController.text,
        services: _selectedServices,
        totalDuration: _totalDuration,
        totalPrice: _totalPrice,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        createdAt: DateTime.now(),
      );

      await _repo.addAppointment(newAppt);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🎉 Randevunuz oluşturuldu: ${_selectedStaff.name} ($_selectedSlot)"),
          backgroundColor: const Color(0xFF8B5A2B),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
