import 'package:flutter/material.dart';
import 'models/salon_model.dart';
import 'models/staff_model.dart';
import 'models/service_model.dart';
import 'screens/customer/customer_booking_screen.dart';
import 'screens/customer/customer_appointments_screen.dart';
import 'screens/staff/staff_agenda_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';

void main() {
  runApp(const KuaforApp());
}

class KuaforApp extends StatelessWidget {
  const KuaforApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kuaför Randevu & Yönetim',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD97706),
          primary: const Color(0xFFD97706),
        ),
        useMaterial3: true,
      ),
      home: const RoleNavigationRoot(),
    );
  }
}

class RoleNavigationRoot extends StatefulWidget {
  const RoleNavigationRoot({super.key});

  @override
  State<RoleNavigationRoot> createState() => _RoleNavigationRootState();
}

class _RoleNavigationRootState extends State<RoleNavigationRoot> {
  // Örnek Başlangıç Verileri
  final SalonModel _salon = SalonModel(
    id: 1,
    name: "Golden Scissor Premium Kuaför",
    logoUrl: "",
    phone: "0532 555 10 20",
    address: "Bağdat Caddesi No:142, Kadıköy / İstanbul",
    openTime: "09:00",
    closeTime: "19:00",
    lunchStart: "12:30",
    lunchEnd: "13:30",
    cancellationWindowHours: 3,
  );

  final List<ServiceModel> _services = [
    ServiceModel(id: 1, name: "Saç Kesimi & Yıkama", durationMinutes: 30, price: 400, category: "Saç"),
    ServiceModel(id: 2, name: "Sakal Tıraşı & Bakım", durationMinutes: 15, price: 200, category: "Sakal"),
    ServiceModel(id: 3, name: "Saç + Sakal Paketi", durationMinutes: 45, price: 550, category: "Paket"),
    ServiceModel(id: 4, name: "Saç Boyama & Renklendirme", durationMinutes: 90, price: 1200, category: "Boya"),
    ServiceModel(id: 5, name: "Keratin & Saç Bakımı", durationMinutes: 60, price: 850, category: "Bakım"),
  ];

  late List<StaffModel> _staffList;

  @override
  void initState() {
    super.initState();
    _staffList = [
      StaffModel(
        id: 1,
        name: "Ahmet Usta",
        title: "Baş Kuaför",
        phone: "0532 111 22 33",
        avatarUrl: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&h=150&fit=crop&crop=face",
        allowedServices: [1, 2, 3, 4, 5],
        permissions: StaffPermissions(
          canViewCustomerPhone: true,
          canCancelAppointments: true,
          canAddManualBreaks: true,
          canEditPrices: true,
        ),
      ),
      StaffModel(
        id: 2,
        name: "Mehmet Kalfa",
        title: "Erkek Kuaförü",
        phone: "0533 222 33 44",
        avatarUrl: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face",
        allowedServices: [1, 2, 3], // Boya ve keratin yetkisi yok
        permissions: StaffPermissions(
          canViewCustomerPhone: false,
          canCancelAppointments: true,
          canAddManualBreaks: true,
          canEditPrices: false,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C1810), Color(0xFF150C07)],
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // HairPass Ahşap Rozet Logosu
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC89D7C).withOpacity(0.35),
                        blurRadius: 25,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFF8B5A2B),
                        child: const Icon(Icons.content_cut, size: 50, color: Color(0xFFFFF8F0)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "HAIRPASS",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Color(0xFFF3E5D8),
                  ),
                ),
                Text(
                  _salon.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFD4AF37)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  "Dijital Kimlik & Randevu Sistemi",
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 32),

                // 1. Müşteri Girişi
                _buildRoleButton(
                  icon: Icons.person,
                  title: "👤 Müşteri Girişi",
                  subtitle: "Randevu Al, İptal Et & Kuaförle Yazış",
                  color: const Color(0xFF8B5A2B),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomerMainWrapper(
                          salon: _salon,
                          staffList: _staffList,
                          services: _services,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),

                // 2. Kuaför Çalışanı Girişi
                _buildRoleButton(
                  icon: Icons.cut,
                  title: "✂️ Kuaför Çalışanı Girişi",
                  subtitle: "Kişisel Randevu Ajandası & Müşteriyle Chat",
                  color: const Color(0xFF5C4033),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StaffAgendaScreen(staff: _staffList.first),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),

                // 3. Salon Yöneticisi Girişi
                _buildRoleButton(
                  icon: Icons.admin_panel_settings,
                  title: "👑 Salon Yöneticisi (Admin)",
                  subtitle: "Salon Ayarları, Hizmet Süreleri & Yetkilendirme",
                  color: const Color(0xFF3E2723),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminDashboardScreen(
                          initialSalon: _salon,
                          initialStaff: _staffList,
                          initialServices: _services,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onTap,
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
      ),
    );
  }
}

// Müşteri Alt Menü Sarmalayıcısı
class CustomerMainWrapper extends StatefulWidget {
  final SalonModel salon;
  final List<StaffModel> staffList;
  final List<ServiceModel> services;

  const CustomerMainWrapper({
    super.key,
    required this.salon,
    required this.staffList,
    required this.services,
  });

  @override
  State<CustomerMainWrapper> createState() => _CustomerMainWrapperState();
}

class _CustomerMainWrapperState extends State<CustomerMainWrapper> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      CustomerBookingScreen(
        salon: widget.salon,
        staffList: widget.staffList,
        services: widget.services,
      ),
      CustomerAppointmentsScreen(customerId: "USER-101"),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calendar_month), label: "Randevu Al"),
          NavigationDestination(icon: Icon(Icons.list_alt), label: "Randevularım"),
        ],
      ),
    );
  }
}
