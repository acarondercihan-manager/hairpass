import 'package:flutter/material.dart';
import '../../models/salon_model.dart';
import '../../models/staff_model.dart';
import '../../models/service_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  final SalonModel initialSalon;
  final List<StaffModel> initialStaff;
  final List<ServiceModel> initialServices;

  const AdminDashboardScreen({
    super.key,
    required this.initialSalon,
    required this.initialStaff,
    required this.initialServices,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SalonModel _salon;
  late List<StaffModel> _staffList;
  late List<ServiceModel> _services;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _salon = widget.initialSalon;
    _staffList = List.from(widget.initialStaff);
    _services = List.from(widget.initialServices);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Salon Yönetim Paneli"),
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.store), text: "Salon"),
            Tab(icon: Icon(Icons.people), text: "Çalışanlar & Yetki"),
            Tab(icon: Icon(Icons.content_cut), text: "Hizmetler"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSalonTab(),
          _buildStaffAndPermissionsTab(),
          _buildServicesTab(),
        ],
      ),
    );
  }

  // 1. Salon Bilgileri & Çalışma Saatleri Sekmesi
  Widget _buildSalonTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("🏢 Salon Bilgileri", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text("Salon Adı"),
                  subtitle: Text(_salon.name),
                  trailing: const Icon(Icons.edit, size: 18),
                ),
                ListTile(
                  title: const Text("Çalışma Saatleri"),
                  subtitle: Text("${_salon.openTime} - ${_salon.closeTime}"),
                ),
                ListTile(
                  title: const Text("Öğle Molası"),
                  subtitle: Text("${_salon.lunchStart} - ${_salon.lunchEnd}"),
                ),
                ListTile(
                  title: const Text("İptal Kuralı Kısıtlaması"),
                  subtitle: Text("Randevuya ${_salon.cancellationWindowHours} saat kala kilitlenir"),
                  trailing: Chip(label: Text("${_salon.cancellationWindowHours} Saat")),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 2. Çalışan Kuaförler ve Yetkilendirme Matrisi Sekmesi
  Widget _buildStaffAndPermissionsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _staffList.length,
      itemBuilder: (context, index) {
        final staff = _staffList[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: CircleAvatar(backgroundImage: NetworkImage(staff.avatarUrl)),
            title: Text(staff.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(staff.title),
            children: [
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("🛡️ Personel Yetkilendirme Matrisi",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),

                    // Yetki 1: Müşteri Telefonunu Görme
                    SwitchListTile(
                      dense: true,
                      title: const Text("Müşteri Telefonunu Görebilir"),
                      subtitle: const Text("Kapatılırsa müşteri telefonları gizlenir"),
                      value: staff.permissions.canViewCustomerPhone,
                      onChanged: (val) {
                        setState(() {
                          _staffList[index] = StaffModel(
                            id: staff.id,
                            name: staff.name,
                            title: staff.title,
                            phone: staff.phone,
                            avatarUrl: staff.avatarUrl,
                            allowedServices: staff.allowedServices,
                            permissions: StaffPermissions(
                              canViewCustomerPhone: val,
                              canCancelAppointments: staff.permissions.canCancelAppointments,
                              canAddManualBreaks: staff.permissions.canAddManualBreaks,
                              canEditPrices: staff.permissions.canEditPrices,
                            ),
                          );
                        });
                      },
                    ),

                    // Yetki 2: Randevu İptal Yetkisi
                    SwitchListTile(
                      dense: true,
                      title: const Text("Randevu İptal Yetkisi"),
                      subtitle: const Text("Randevuyu tek taraflı iptal edebilme"),
                      value: staff.permissions.canCancelAppointments,
                      onChanged: (val) {
                        setState(() {
                          _staffList[index] = StaffModel(
                            id: staff.id,
                            name: staff.name,
                            title: staff.title,
                            phone: staff.phone,
                            avatarUrl: staff.avatarUrl,
                            allowedServices: staff.allowedServices,
                            permissions: StaffPermissions(
                              canViewCustomerPhone: staff.permissions.canViewCustomerPhone,
                              canCancelAppointments: val,
                              canAddManualBreaks: staff.permissions.canAddManualBreaks,
                              canEditPrices: staff.permissions.canEditPrices,
                            ),
                          );
                        });
                      },
                    ),

                    // Yetki 3: Manuel Mola Ekleme
                    SwitchListTile(
                      dense: true,
                      title: const Text("Acil Mola & Takvim Bloklama"),
                      subtitle: const Text("Kendi ajandasına acil mola saati ekleyebilme"),
                      value: staff.permissions.canAddManualBreaks,
                      onChanged: (val) {
                        setState(() {
                          _staffList[index] = StaffModel(
                            id: staff.id,
                            name: staff.name,
                            title: staff.title,
                            phone: staff.phone,
                            avatarUrl: staff.avatarUrl,
                            allowedServices: staff.allowedServices,
                            permissions: StaffPermissions(
                              canViewCustomerPhone: staff.permissions.canViewCustomerPhone,
                              canCancelAppointments: staff.permissions.canCancelAppointments,
                              canAddManualBreaks: val,
                              canEditPrices: staff.permissions.canEditPrices,
                            ),
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 3. Hizmet Kataloğu & Süreler Sekmesi
  Widget _buildServicesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        final srv = _services[index];
        return Card(
          child: ListTile(
            title: Text(srv.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("⏳ ${srv.durationMinutes} dakika  •  ${srv.category}"),
            trailing: Text(
              "${srv.price.toStringAsFixed(0)} ₺",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.amber[900],
              ),
            ),
          ),
        );
      },
    );
  }
}
