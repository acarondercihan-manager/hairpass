# ✂️ Kuaför Randevu & Yönetim Mobil Uygulaması (Flutter + Firebase)

Bu proje; kuaför salonlarının, kuaför çalışanlarının ve müşterilerin tek bir ekosistemde buluştuğu modern, çok rollü bir **Android & iOS** mobil uygulamasıdır.

---

## 🌟 Ana Modüller ve Özellikler

1. **Dinamik Süreye Göre Boş Saat Hesaplama:**
   * Hizmetlerin süreleri dinamiktir (ör. Saç 30 dk, Sakal 15 dk, Boya 90 dk).
   * Müşteri hizmet(ler)i seçtiğinde toplam süre hesaplanır ve `SlotCalculatorService` kuaförün takviminde kesintisiz bu süreye sahip boş saatleri anlık olarak filtreler.

2. **3 Saat Öncesi İptal Kısıtlaması:**
   * Randevuya 3 saatten fazla süre varken müşteri iptal edebilir.
   * 3 saatten az kaldığında sistem butonu otomatik kilitler.
   * Bu kural sadece mobil ekranda değil, `firestore.rules` veritabanı seviyesinde de korunmaktadır.

3. **Çalışan Kuaför Yetkilendirme Matrisi:**
   * Yönetici panelinden her çalışanın yapabileceği hizmetler, müşteri telefonunu görüp göremeyeceği ve randevu iptal yetkisi açılıp kapatılabilir.

4. **Kuaför - Müşteri Canlı Mesajlaşma (Chat):**
   * Randevu alan müşteri kuaförüyle uygulama içinden canlı yazışabilir (ör. gecikme bildirimi, model fotoğrafı).

---

## 📁 Proje Dosya Yapısı

```
kuafor_app/
├── lib/
│   ├── models/
│   │   ├── salon_model.dart            # Salon, logo, çalışma saatleri & iptal penceresi
│   │   ├── staff_model.dart            # Kuaför personeli & yetkilendirme modeli
│   │   ├── service_model.dart          # Hizmet kataloğu & süreler
│   │   ├── appointment_model.dart      # Randevu & 3 saat iptal doğrulama
│   │   └── chat_message_model.dart     # Canlı mesaj modeli
│   ├── services/
│   │   ├── slot_calculator_service.dart # Dinamik boş slot hesaplama algoritması
│   │   ├── appointment_service.dart    # Çakışma önleyici Firestore transaction & iptal
│   │   └── chat_service.dart           # Anlık mesajlaşma servisi
│   ├── screens/
│   │   ├── customer/                   # Müşteri randevu, iptal ve chat ekranları
│   │   ├── staff/                      # Kuaför ajandası ve müşteri detayları
│   │   └── admin/                      # Salon yönetimi & personel yetki matrisi
│   └── main.dart                       # Rol tabanlı navigasyon kökü
├── firestore.rules                     # Sunucu taraflı 3 saat güvenlik kuralları
└── pubspec.yaml                        # Kütüphane bağımlılıkları
```

---

## 📲 Kurulum ve Çalıştırma Adımları

### 1. Bağımlılıkları Yükleme
```bash
cd kuafor_app
flutter pub get
```

### 2. Firebase Entegrasyonu
1. [Firebase Console](https://console.firebase.google.com/) üzerinden yeni bir proje oluşturun.
2. **Android için:** `android/app/` klasörüne `google-services.json` dosyasını ekleyin.
3. **iOS için:** `ios/Runner/` klasörüne `GoogleService-Info.plist` dosyasını ekleyin.
4. `firestore.rules` dosyasını Firebase Firestore konsoluna yapıştırıp yayınlayın.

### 3. Uygulamayı Başlatma
```bash
flutter run
```

### 4. Mağaza Çıktısı Alma (APK & iOS)
* **Android APK:** `flutter build apk --release` (veya Google Play için `flutter build appbundle`)
* **iOS:** `flutter build ipa`
