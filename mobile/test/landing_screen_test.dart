import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epupuk_mobile/screens/landing/landing_screen.dart';

void main() {
  testWidgets('LandingScreen renders all core sections matching React design', (WidgetTester tester) async {
    // Set screen size for test
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: LandingScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Navigation Bar
    expect(find.text('E-PUPUK'), findsWidgets);
    expect(find.text('Kabupaten Mojokerto'), findsWidgets);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Daftar'), findsOneWidget);

    // 2. Hero Section
    expect(find.text('Portal Resmi Alokasi Pupuk Bersubsidi'), findsOneWidget);
    expect(find.text('Minta Subsidi'), findsOneWidget);
    expect(find.text('Pilih Portal'), findsOneWidget);

    // 3. Section Pilih Portal
    expect(find.text('AKSES LAYANAN TERPADU'), findsOneWidget);
    expect(find.text('Pilih Portal Sesuai Peran Anda'), findsOneWidget);
    expect(find.text('Portal Petani'), findsOneWidget);
    expect(find.text('Portal Petugas PPL'), findsOneWidget);
    expect(find.text('Portal Admin Dinas'), findsOneWidget);
    expect(find.text('Masuk Portal Petani'), findsOneWidget);
    expect(find.text('Masuk Portal PPL'), findsOneWidget);
    expect(find.text('Informasi Portal Admin'), findsOneWidget);

    // 4. Section Keunggulan Sistem
    expect(find.text('KEUNGGULAN SISTEM'), findsOneWidget);
    expect(find.text('Mengapa Menggunakan E-PUPUK?'), findsOneWidget);
    expect(find.text('Validasi NIK & SPPT'), findsOneWidget);
    expect(find.text('Geotagging GPS Poligon'), findsOneWidget);
    expect(find.text('QR Code Anti-Duplikasi'), findsOneWidget);
    expect(find.text('Layanan Aduan Cepat'), findsOneWidget);

    // 5. Section Alur Pengajuan
    expect(find.text('ALUR PENGAJUAN'), findsOneWidget);
    expect(find.text('4 Langkah Mudah Pengajuan Alokasi'), findsOneWidget);
    expect(find.text('Daftar Akun Petani'), findsOneWidget);
    expect(find.text('Ajukan Data Lahan'), findsOneWidget);
    expect(find.text('Survei Lapangan PPL'), findsOneWidget);
    expect(find.text('Penebusan di Kios'), findsOneWidget);

    // 6. Footer
    expect(find.text('KANTOR PELAYANAN'), findsOneWidget);
    expect(find.text('KONTAK RESMI'), findsOneWidget);
  });
}

