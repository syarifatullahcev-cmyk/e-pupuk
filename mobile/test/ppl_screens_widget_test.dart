import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:epupuk_mobile/models/user_model.dart';
import 'package:epupuk_mobile/models/farmer_model.dart';
import 'package:epupuk_mobile/models/ppl_task_model.dart';
import 'package:epupuk_mobile/screens/ppl/ppl_dashboard_screen.dart';
import 'package:epupuk_mobile/screens/ppl/ppl_beranda_screen.dart';
import 'package:epupuk_mobile/screens/ppl/ppl_data_petani_screen.dart';
import 'package:epupuk_mobile/screens/ppl/ppl_detail_petani_screen.dart';
import 'package:epupuk_mobile/screens/ppl/ppl_daftar_tugas_screen.dart';
import 'package:epupuk_mobile/screens/ppl/ppl_detail_tugas_screen.dart';
import 'package:epupuk_mobile/screens/ppl/ppl_form_survei_screen.dart';
import 'package:epupuk_mobile/screens/ppl/ppl_peta_lahan_screen.dart';
import 'package:epupuk_mobile/screens/ppl/ppl_pengukuran_batas_screen.dart';
import 'package:epupuk_mobile/screens/ppl/ppl_hasil_pengukuran_screen.dart';
import 'package:epupuk_mobile/screens/auth/ppl_login_screen.dart';
import 'package:epupuk_mobile/screens/auth/login_screen.dart';

void main() {
  final sampleUser = UserModel(
    id: 3,
    username: 'ppl_ahmad',
    nama: 'Ahmad Hidayat, S.P.',
    role: 'PPL',
  );

  final sampleTask = PPLTaskModel(
    id: 12,
    farmerId: 2,
    landId: 5,
    fertilizerId: 1,
    jumlahDiajukan: 240.0,
    status: 'DITUGASKAN_KE_PPL',
    namaPetani: 'Siti Aminah',
    nikPetani: '3516082104850002',
    kontakPetani: '0812-3456-78XX',
    namaPupuk: 'Urea Bersubsidi',
    lokasiLahan: 'Sawah Blok Timur Kebondalem',
    alamatLahan: 'Dsn. Sumberarum, Ds. Tanjungrejo, Kec. Mojosari',
    luasLahanM2: 8000.0,
    latitude: -7.526412,
    longitude: 112.534218,
    komoditas: 'Padi Inpari 32',
    hasSurvey: false,
    taskIdCode: 'SRV-2025-014',
    jadwal: '14 Feb 2025 • Pagi',
    poktan: 'Poktan Tani Makmur Wilbin',
    desaKecamatan: 'Desa Tanjungrejo, Kec. Mojosari',
    statusLabel: 'Menunggu Survei',
  );

  final sampleFarmer = FarmerModel(
    id: 2,
    userId: 3,
    nama: 'Siti Aminah',
    nik: '3516082104850002',
    kontak: '0812-3456-78XX',
    alamat: 'Dsn. Sumberarum RT 02 RW 01, Ds. Tanjungrejo, Kec. Mojosari',
    desa: 'Tanjungrejo',
    kecamatan: 'Mojosari',
    poktan: 'Poktan Sumber Makmur',
    statusVerifikasi: 'Menunggu',
    jumlahLahan: 2,
    totalLuasHa: 1.4,
  );

  Widget makeTestable(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  testWidgets('Test Shell Navigation PPL dengan 5 Menu Bottom Nav', (tester) async {
    await tester.pumpWidget(makeTestable(PPLDashboardScreen(user: sampleUser)));
    await tester.pump();

    expect(find.text('Beranda'), findsAtLeastNWidgets(1));
    expect(find.text('Petani'), findsAtLeastNWidgets(1));
    expect(find.text('Survei'), findsAtLeastNWidgets(1));
    expect(find.text('Aktivitas'), findsAtLeastNWidgets(1));
    expect(find.text('Profil'), findsAtLeastNWidgets(1));
  });

  testWidgets('Test Layar 1: Beranda PPL', (tester) async {
    await tester.pumpWidget(makeTestable(PPLBerandaScreen(user: sampleUser, onTabChange: (_) {})));
    await tester.pump();

    expect(find.text('Beranda'), findsOneWidget);
  });

  testWidgets('Test Layar 2: Data Petani', (tester) async {
    await tester.pumpWidget(makeTestable(PPLDataPetaniScreen(user: sampleUser)));
    await tester.pump();

    expect(find.text('Data Petani'), findsAtLeastNWidgets(1));
  });

  testWidgets('Test Layar 3: Detail Petani', (tester) async {
    await tester.pumpWidget(makeTestable(PPLDetailPetaniScreen(farmer: sampleFarmer)));
    await tester.pump();

    expect(find.text('Detail Petani'), findsAtLeastNWidgets(1));
    expect(find.text('Siti Aminah'), findsAtLeastNWidgets(1));
  });

  testWidgets('Test Layar 4: Daftar Tugas Survei', (tester) async {
    await tester.pumpWidget(makeTestable(PPLDaftarTugasScreen(user: sampleUser)));
    await tester.pump();

    expect(find.text('Daftar Tugas Survei'), findsOneWidget);
  });

  testWidgets('Test Layar 5: Detail Tugas Survei', (tester) async {
    await tester.pumpWidget(makeTestable(PPLDetailTugasScreen(task: sampleTask)));
    await tester.pump();

    expect(find.text('Detail Tugas Survei'), findsOneWidget);
    expect(find.text('Siti Aminah'), findsOneWidget);
    expect(find.text('SRV-2025-014'), findsOneWidget);
  });

  testWidgets('Test Layar 6: Formulir Hasil Survei', (tester) async {
    await tester.pumpWidget(makeTestable(PPLFormSurveiScreen(task: sampleTask)));
    await tester.pump();

    expect(find.text('Formulir Hasil Survei'), findsOneWidget);
    expect(find.text('Hasil Pemeriksaan Lapangan'), findsOneWidget);
    expect(find.text('Koordinat & Lokasi Lapangan'), findsOneWidget);
    expect(find.text('Dokumentasi Foto Lapangan'), findsOneWidget);
    expect(find.text('Simpan Hasil Survei'), findsOneWidget);
  });

  testWidgets('Test Layar 7: Peta dan Lokasi Lahan', (tester) async {
    await tester.pumpWidget(makeTestable(PPLPetaLahanScreen(task: sampleTask)));
    await tester.pump();

    expect(find.text('TAHAP 4 DARI 5'), findsOneWidget);
    expect(find.text('Input Koordinat & Batas Lahan'), findsOneWidget);
  });

  testWidgets('Test Layar 8: Pengukuran Batas Lahan', (tester) async {
    await tester.pumpWidget(makeTestable(PPLPengukuranBatasScreen(task: sampleTask)));
    await tester.pump();

    expect(find.text('PENGUKURAN BATAS LAHAN'), findsOneWidget);
    expect(find.text('Daftar Titik Batas Valid'), findsOneWidget);
    expect(find.text('Lihat Hasil Pengukuran'), findsOneWidget);
  });

  testWidgets('Test Layar 9: Hasil Pengukuran Lahan', (tester) async {
    final points = [
      const LatLng(-7.526210, 112.534015),
      const LatLng(-7.526180, 112.534820),
      const LatLng(-7.527010, 112.534850),
      const LatLng(-7.527020, 112.534025),
    ];

    await tester.pumpWidget(makeTestable(
      PPLHasilPengukuranScreen(
        task: sampleTask,
        measuredAreaM2: 7850.0,
        polygonPoints: points,
      ),
    ));
    await tester.pump();

    expect(find.text('Hasil Pengukuran Lahan'), findsOneWidget);
    expect(find.text('LUAS POLIGON TERTUTUP'), findsOneWidget);
    expect(find.text('Perbandingan & Analisis Selisih'), findsOneWidget);
    expect(find.text('Simpan Hasil Pengukuran'), findsOneWidget);
  });

  testWidgets('Test Layar: PPLLoginScreen render dan validasi', (tester) async {
    await tester.pumpWidget(makeTestable(const PPLLoginScreen()));
    await tester.pump();

    // Pastikan elemen branding PPL ada
    expect(find.text('E-PUPUK MOBILE'), findsOneWidget);
    expect(find.text('Portal Petugas Penyuluh Lapangan (PPL)'), findsOneWidget);
    expect(find.text('Masuk Petugas PPL'), findsOneWidget);
    expect(find.text('NIP / Username Petugas'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);
    expect(find.text('Masuk Portal PPL'), findsOneWidget);
    expect(find.text('Masuk sebagai Petani'), findsOneWidget);

    // Coba submit form kosong untuk cek validator
    await tester.tap(find.text('Masuk Portal PPL'));
    await tester.pump();

    expect(find.text('NIP atau username petugas wajib diisi'), findsOneWidget);
  });

  testWidgets('Test Layar: LoginScreen menampilkan link Portal PPL', (tester) async {
    await tester.pumpWidget(makeTestable(const LoginScreen()));
    await tester.pump();

    expect(find.text('e-Pupuk Mobile'), findsOneWidget);
    expect(find.text('Masuk sebagai Petani'), findsOneWidget);
    expect(find.text('Daftar Petani'), findsOneWidget);
    expect(find.text('Masuk sebagai Petugas PPL'), findsOneWidget);
  });
}
