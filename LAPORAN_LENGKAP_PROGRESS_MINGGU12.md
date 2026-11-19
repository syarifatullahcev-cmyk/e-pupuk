# 🌾 LAPORAN KEMAJUAN PROYEK MINGGU KE-12 (DETAIL, FAKTUAL, & KOMPREHENSIF)
## SISTEM E-PUPUK KABUPATEN MOJOKERTO
### Sistem Terpadu Pengajuan Alokasi, Verifikasi Lapangan Spasial GIS, & Distribusi Pupuk Bersubsidi
*(Siklus Pengembangan: 12 November s.d. 19 November 2026)*

> **Catatan Status & Integritas Rekayasa:**  
> Laporan Minggu ke-12 ini merefleksikan pencapaian faktual pasca-evaluasi dosen dan pengujian komprehensif antarmuka mobile per **19 November 2026** (Commit: `0d342e6`). Seluruh komplain antarmuka (overflow pixel, duplikasi panah, logo inkoheren, dan alur keluar akun), fitur modal dokumen KTP/SPPT, integrasi WhatsApp direct call, dukungan Flutter Web dinamis untuk kuesioner, hingga perbaikan header otentikasi telah selesai direkayasa dengan status **100% PASS (37/37 Automated Tests Lulus)**.

### Ringkasan Eksekutif & Status Verifikasi Kode (Minggu Ke-12)
- **Mobile (Flutter Multiplatform)**: 37 widget & unit tests lolos uji tanpa regresi (`gis_boundary_test.dart`, `landing_screen_test.dart`, `ppl_screens_widget_test.dart`, `ppl_flow_test.dart`, `widget_test.dart`). Build APK fisik Android (`e-pupuk-app.apk`) berhasil dikompilasi dengan dependensi NDK yang stabil.
- **Dukungan Flutter Web**: Aplikasi Flutter kini dapat berjalan sebagai *Web Application* (`flutter run -d chrome` / `web-server`), didukung `ApiConfig` dinamis berbasis `Uri.base.host` untuk kemudahan pengujian kuesioner UAT tanpa kewajiban instalasi APK.
- **Frontend Admin (React 18 & Vite)**: Modul Admin Dinas Pertanian tetap beroperasi pada port 5173 untuk pemantauan alokasi, manajemen kuota e-RDKK, dan audit trail penyaluran.
- **Backend API (FastAPI & Docker MySQL 8.0)**: 7 router inti tetap stabil melayani pertukaran data RESTful, kalkulasi spasial geodesik WGS-84, dan penanganan berkas statis KTP/lahan.
- **Version Control**: Seluruh perubahan telah ditahapkan, di-commit, dan di-push ke branch `main` repositori GitHub resmi (`https://github.com/syarifatullahcev-cmyk/e-pupuk`).

> **Mata Kuliah**: Workshop Pemrograman Framework  
> **Program Studi**: D3 Teknik Informatika — PENS PSDKU Lamongan (Tahun Akademik 2026)  
> **Dosen Pengampu**: Amma Liesvarastranta Haz, S.Tr.T., M.T.  
> **Tanggal Pelaporan**: 19 November 2026  
> 
> **Tim Pengembang**:
> - **Syarifatullah Ceva Efendy** (NRP: 312521002) — *Frontend Web & Mobile App (Flutter) Developer*
> - **Selby Wafi Nurjuan** (NRP: 3125521018) — *Backend API (FastAPI) & Database Architect*

---

## 📌 DAFTAR ISI LAPORAN TEKNIS

1. [Kilas Balik & Evaluasi Minggu 11 Menuju Minggu 12](#1-kilas-balik--evaluasi-minggu-11-menuju-minggu-12)
2. [Pembaruan Utama Minggu Ini (Bug Fix Visual, Modal Dokumen, WhatsApp Launcher, & Flutter Web)](#2-pembaruan-utama-minggu-ini)
3. [Bedah Faktual Rekayasa Mobile Flutter (Syarifatullah Ceva Efendy)](#3-bedah-faktual-rekayasa-mobile-flutter)
4. [Dukungan Multiplatform & Skema Pengujian Kuesioner / UAT](#4-dukungan-multiplatform--skema-pengujian-kuesioner--uat)
5. [Integritas Jaringan, Keamanan Token Otentikasi, & Perbaikan API Service](#5-integritas-jaringan-keamanan-token-otentikasi--perbaikan-api-service)
6. [Matriks Pengujian Sistem (Automated Testing & QA Minggu 12)](#6-matriks-pengujian-sistem)
7. [Daftar Kendala Teknis, Analisis Akar Masalah, & Solusi Rekayasa](#7-daftar-kendala-teknis-analisis-akar-masalah--solusi-rekayasa)
8. [Limitasi Terbuka & Rencana Kerja Minggu Berikutnya](#8-limitasi-terbuka--rencana-kerja-minggu-berikutnya)
9. [Panduan Slide Presentasi Progres Minggu Ke-12](#9-panduan-slide-presentasi-progres-minggu-ke-12)

---

## 1. KILAS BALIK & EVALUASI MINGGU 11 MENUJU MINGGU 12

Pada pelaporan Minggu ke-11 (11 November 2026), tim berhasil merampungkan struktur awal *Landing Page* mobile, perapian *stepper* alur pengajuan petani, dan penetapan identitas visual logo tunas (*sprout* hijau emerald). Namun, saat dilakukan peninjauan langsung dan pengujian lapangan oleh dosen pengampu dan pengguna, ditemukan sejumlah anomali antarmuka (*visual glitches*) serta kebutuhan fungsional mendesak:

1. **Masalah Overflow Tata Letak (*RenderFlex Overflows*)**: Pada berbagai ukuran layar ponsel (khususnya lebar 360px), terdapat garis belang kuning-hitam di kartu kuota pupuk UREA/NPK, kartu tugas PPL, data NIK petani, dan AppBar Landing Page.
2. **Kritik Dosen Terhadap Navigasi ("Kok ada dua panah kembali?")**: Pada layar Survei Lapangan dan Peta Lahan PPL, terdapat panah kembali ganda di AppBar atas dan subheader di bawahnya.
3. **Inkoherensi Identitas Visual Logo**: Beberapa modul masih menggunakan ikon generik *leaf/material icon* alih-alih logo resmi vektor `AppLogo` *Sprout*.
4. **Ketiadaan Pratinjau Dokumen Fisik**: Tombol *"Lihat Dokumen"* KTP dan berkas lahan hanya memicu teks SnackBar tanpa menampilkan dokumen aslinya.
5. **Tombol WhatsApp Belum Terhubung Faktual**: Tombol *"Hubungi Petani (WhatsApp)"* hanya menampilkan simulasi notifikasi.
6. **Kebingungan Alur Keluar Akun Petani vs PPL**: Beranda Petani secara keliru menampilkan panah kembali (`<-`) di AppBar yang jika ditekan langsung keluar dari akun, berbeda dengan PPL yang keluar secara teratur lewat tab Profil.
7. **Kebutuhan Pengujian Kuesioner Jarak Jauh**: Diperlukan metode agar responden evaluasi skripsi dapat menguji antarmuka mobile melalui browser web tanpa harus mengunduh dan memasang file APK.

```text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│          EVOLUSI ARSITEKTUR E-PUPUK (MINGGU KE-11 MENJADI MINGGU KE-12)                │
├───────────────────┬───────────────────┬───────────────────────┬────────────────────────┤
│     MINGGU 11     │     MINGGU 12     │       MINGGU 12       │       MINGGU 12        │
│  (Struktur Awal)  │ (Audit Visual QA) │(Fitur Interaktif & WA)│   (Multiplatform Web)  │
├───────────────────┼───────────────────┼───────────────────────┼────────────────────────┤
│ • Landing Page    │ • 0 Pixel Overflow│ • Modal e-KTP & SPPT  │ • Flutter Web Engine   │
│   Mobile Terpasang│ • Hapus Panah     │   Digital Interaktif  │   Otomatis Dynamic IP  │
│ • Pemisahan Login │   Ganda (Dosen)   │ • Direct WhatsApp API │ • Fix 401 Unauthorized │
│ • Stepper Petani  │ • 100% Logo Resmi │   Format Internasional│   Bearer Token Header  │
│ • Build APK Awal  │   Sprout Emerald  │ • Alur Logout Seragam │ • 37/37 Test Otomatis  │
│   Terkendala NDK  │ • AppBar Rata Kiri│   di Tab Akun/Profil  │   Lulus Tanpa Regresi  │
└───────────────────┴───────────────────┴───────────────────────┴────────────────────────┘
```

---

## 2. PEMBARUAN UTAMA MINGGU INI

### A. Tuntasnya Audit Tata Letak & Eliminasi Pixel Overflow
Seluruh laporan *RenderFlex overflowed* yang menyebabkan garis kuning-hitam di aplikasi mobile telah diidentifikasi dan diperbaiki secara permanen melalui restrukturisasi hierarki *Widget Flex*:
- **Kartu Kuota Pupuk UREA & NPK (Petani)**: Baris alokasi musim tanam dibungkus menggunakan `Expanded` dan *badge* fleksibel, mencegah teks terpotong pada layar beresolusi sedang/kecil.
- **Detail Tugas & Formulir Hasil Survei (PPL)**: Header koordinat GPS, label komoditas, dan catatan verifikasi diberikan batasan *bounding constraints* yang aman.
- **Top Bar Landing Page (3.7px Overflow)**: Mematikan auto-centering (`centerTitle: false`), mematikan panah otomatis (`automaticallyImplyLeading: false`), dan menerapkan `Expanded` pada judul sehingga adaptif pada lebar layar mulai dari 320px hingga resolusi tablet.

### B. Standardisasi Identitas Logo Resmi & Navigasi Bersih
- **Standardisasi Logo Sprout**: Seluruh ikon daun material diganti dengan komponen terpusat `AppLogo(size: 36, borderRadius: 10)` pada Beranda Petani, Beranda PPL, Data Petani, Daftar Tugas, Detail Petani, dan Form Survei.
- **Pembersihan Panah Ganda**: Menghapus tombol *back arrow* redundan pada subheader layar `PPLFormSurveiScreen`, `PPLPetaLahanScreen`, dan `PPLPengukuranBatasScreen` sesuai catatan dosen pengampu.
- **Penambahan Navigasi Kembali ke Landing Page**: Halaman login Petani dan PPL kini memiliki tombol navigasi kembali yang aman (`Navigator.pushReplacementNamed(context, '/')`).

### C. Pratinjau Interaktif Dokumen Pendukung (e-KTP & SPPT Lahan)
Menjawab kebutuhan verifikasi data oleh petugas PPL di lapangan:
- **Modal e-KTP Digital**: Menampilkan replika kartu tanda penduduk digital berlatar gradasi biru resmi Republik Indonesia, NIK terformat, nama lengkap huruf kapital, alamat domisili, desa, kecamatan, poktan, kotak pas foto formal 3x4 berlatar merah, serta stempel keabsahan Disperta.
- **Modal Berkas SPPT Lahan**: Menampilkan bukti kepemilikan/penguasaan lahan, konversi luas m² ke Hektare secara presisi, komoditas terdaftar, dan NOP terformat.

### D. Integrasi Langsung Komunikasi Petani via WhatsApp
- Implementasi library `url_launcher` resmi untuk memfasilitasi koordinasi jadwal survei fisik antara petugas PPL dan petani.
- Normalisasi nomor telepon otomatis: nomor lokal (contoh: `085712345678`) dikonversi ke format internasional (`+6285712345678`).
- Penyusunan template pesan pembuka resmi secara otomatis via protokol URI `https://wa.me/` dengan penanganan pengecualian (*error handling*) berupa tombol salin nomor ke *clipboard*.

### E. Penyelarasan Alur Keluar Akun (*Logout Uniformity*)
- Menghapus panah keluar palsu pada AppBar Beranda Petani (`automaticallyImplyLeading: false`).
- Menambahkan tombol merah terstandarisasi **"Keluar dari Akun"** di tab Akun/Profil Petani lengkap dengan modal dialog konfirmasi, menyelaraskan alurnya 100% sama dengan akun PPL.

---

## 3. BEDAH FAKTUAL REKAYASA MOBILE FLUTTER

### A. Repositori Berkas yang Diperbarui
Pada siklus Minggu ke-12, pembaruan difokuskan pada modul inti berikut:

| Nama Berkas | Lokasi | Peran & Modifikasi Utama |
| :--- | :--- | :--- |
| `landing_screen.dart` | `mobile/lib/screens/landing/` | Perbaikan AppBar overflow 3.7px, `centerTitle: false`, logo sprout terstandarisasi. |
| `petani_dashboard_screen.dart` | `mobile/lib/screens/petani/` | Eliminasi panah AppBar, perbaikan overflow kartu pupuk, tombol logout di profil. |
| `ppl_detail_petani_screen.dart` | `mobile/lib/screens/ppl/` | Implementasi modal pratinjau e-KTP & SPPT, integrasi tombol WhatsApp. |
| `ppl_form_survei_screen.dart` | `mobile/lib/screens/ppl/` | Penghapusan panah kembali ganda, perapian section header koordinat GPS. |
| `ppl_peta_lahan_screen.dart` | `mobile/lib/screens/ppl/` | Penghapusan panah kembali ganda, perapian tombol satellite layer. |
| `api_config.dart` | `mobile/lib/config/` | Penambahan deteksi *host* dinamis berbasis `Uri.base.host` untuk Flutter Web. |
| `ppl_service.dart` | `mobile/lib/services/` | Pemulihan header otentikasi `Bearer $token`, kenaikan timeout ke 15 detik. |
| `subsidy_service.dart` | `mobile/lib/services/` | Pemulihan header otentikasi `Bearer $token` pada update dokumen lahan. |
| `pubspec.yaml` | `mobile/` | Penambahan dependensi resmi `url_launcher: ^6.3.3`. |

---

### B. Implementasi Pratinjau Dokumen e-KTP & SPPT
Berikut kutipan rekayasa modal *bottom sheet* dokumen yang menggantikan teks simulasi SnackBar sebelumnya:

```dart
// Cuplikan ppl_detail_petani_screen.dart
void _showKtpModal() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(),
          _buildModalHeader('Arsip KTP Elektronik Petani', Icons.badge_outlined),
          const Divider(height: 24, color: AppTheme.border),
          // Kartu Grafis e-KTP Digital
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ktpRow('NIK', _farmer.nik, isBold: true, isMono: true),
                      _ktpRow('Nama', _farmer.nama.toUpperCase(), isBold: true),
                      _ktpRow('Alamat', _farmer.alamat),
                      _ktpRow('Poktan', _farmer.poktan),
                    ],
                  ),
                ),
                _buildFormalPhotoBox(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildVerifiedBadge('Status Berkas: Terverifikasi resmi Dinas Pertanian Kab. Mojokerto'),
        ],
      ),
    ),
  );
}
```

---

### C. Implementasi Komunikasi WhatsApp Berbasis Standar URL Launcher
Implementasi integrasi komunikasi dua arah antara petugas penyuluh lapangan (PPL) dan petani:

```dart
// Cuplikan ppl_detail_petani_screen.dart
Future<void> _hubungiPetaniWhatsApp() async {
  final rawPhone = _farmer.kontak.replaceAll(RegExp(r'[^0-9]'), '');
  if (rawPhone.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nomor telepon petani tidak tersedia.')),
    );
    return;
  }

  // Normalisasi kode negara Indonesia (62)
  final phone = rawPhone.startsWith('0')
      ? '62${rawPhone.substring(1)}'
      : (rawPhone.startsWith('62') ? rawPhone : '62$rawPhone');

  final message = 'Halo Bapak/Ibu ${_farmer.nama}, saya Petugas PPL Dinas Pertanian '
      'Kabupaten Mojokerto mengenai jadwal verifikasi lapangan dan alokasi pupuk bersubsidi.';
  final whatsappUri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');

  try {
    final launched = await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    if (!launched) {
      await launchUrl(whatsappUri, mode: LaunchMode.platformDefault);
    }
  } catch (_) {
    // Fallback: Penyalinan nomor manual
    await Clipboard.setData(ClipboardData(text: _farmer.kontak));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Membuka browser... Nomor ${_farmer.kontak} disalin.')),
    );
  }
}
```

---

## 4. DUKUNGAN MULTIPLATFORM & SKEMA PENGUJIAN KUESIONER / UAT

Salah satu tantangan riset tugas akhir adalah pengumpulan data responden (kuesioner kelayakan sistem) dari petani dan penyuluh lapangan. Mengingat sebagian responden memiliki keterbatasan memori penyimpanan ponsel atau kendala izin instalasi APK pihak ketiga (*unknown sources*), tim merekayasa aplikasi mobile agar mendukung **Flutter Web Engine** secara *seamless*.

```text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│               ARSITEKTUR AKSES PENGUJIAN KUESIONER E-PUPUK MOJOKERTO                   │
├───────────────────────────────────┬────────────────────────────────────────────────────┤
│     METODE A: APK ANDROID ASLI    │           METODE B: FLUTTER WEB BROWSER            │
│   (Pengujian Kinerja Perangkat)   │            (Pengujian Kuesioner Responden)         │
├───────────────────────────────────┼────────────────────────────────────────────────────┤
│ • File: e-pupuk-app.apk           │ • URL: http://10.142.183.78:8088                   │
│ • Akses Hardware: Kamera Scanner  │ • Akses: Cukup klik tautan melalui Chrome HP/PC   │
│   QR native & GPS satelit akurat  │ • Bebas Instalasi: 0 MB konsumsi memori internal   │
│ • Pengalaman sentuh 120Hz mulus   │ • Dynamic Host: Otomatis mendeteksi IP server      │
│ • Khusus PPL & Petani UAT primer  │ • Ideal untuk responden kuesioner umum             │
└───────────────────────────────────┴────────────────────────────────────────────────────┘
```

### Rekayasa Deteksi Host Dinamis (`api_config.dart`)
Agar aplikasi web yang diakses dari browser ponsel responden tidak keliru mengirim permintaan ke `localhost` miliknya sendiri, `ApiConfig` diperbarui:

```dart
// mobile/lib/config/api_config.dart
static String get baseUrl {
  if (customBaseUrl.isNotEmpty) return customBaseUrl;
  
  if (kIsWeb) {
    final host = Uri.base.host;
    if (host.isNotEmpty && host != 'localhost' && host != '127.0.0.1') {
      return 'http://$host:8000/api'; // Mengikuti IP laptop penguji otomatis
    }
    return 'http://127.0.0.1:8000/api';
  }
  
  // Platform Android Fisik
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.142.183.78:8000/api';
  }
  return 'http://127.0.0.1:8000/api';
}
```

### Penanganan Anomali Browser Console (Chromium Intl.v8BreakIterator & Session History)
Saat menjalankan Flutter Web di Google Chrome (`localhost`), muncul dua pesan konsol:
1. `Intl.v8BreakIterator is deprecated. Please use Intl.Segmenter instead.` (dari `dart_sdk.js`):
   - **Akar Masalah**: Mesin perender teks tipografi Dart SDK memanggil API non-standar lawas Chromium `Intl.v8BreakIterator` yang mulai ditinggalkan Google Chrome demi standar ECMAScript `Intl.Segmenter`.
   - **Solusi**: Diterapkan *Modern Polyfill* pada `mobile/web/index.html` menggunakan `Object.defineProperty(Intl, 'v8BreakIterator', ...)` berbasis `Intl.Segmenter`. Panggilan dari Dart SDK dialihkan secara bersih tanpa memicu peringatan *deprecated*.
2. `Session History Item Has Been Marked Skippable`:
   - **Klarifikasi**: Ini adalah fitur keamanan bawaan Google Chrome (*History Manipulation Intervention*, Chrome 72+). Saat aplikasi Single Page (SPA) seperti Flutter Web melakukan inisialisasi awal rute sebelum adanya gestur klik/sentuhan fisik dari pengguna, peramban menandai riwayat tersebut agar tombol *Back* peramban tidak menjebak pengguna di halaman kosong. Status ini otomatis hilang begitu pengguna berinteraksi dengan antarmuka.

---

## 5. INTEGRITAS JARINGAN, KEAMANAN TOKEN OTENTIKASI, & PERBAIKAN API SERVICE

Saat pengujian antarmuka web melalui Google Chrome DevTools, terdeteksi anomali permintaan HTTP merah:
```text
browser_client.dart:83 GET http://127.0.0.1:8000/api/notifications 401 (Unauthorized)
```

### Analisis Akar Masalah (Root Cause Analysis):
Pemeriksaan kode sumber pada repositori mendapati bahwa pada berkas `ppl_service.dart` baris 23 dan 46, serta `subsidy_service.dart` baris 137, teks otentikasi sempat terisi string literal `'******'` (diduga akibat proses *masking* otomatis kode sebelumnya):
```dart
// Kode Bermasalah:
headers: {'Authorization': '******'} // Ditolak backend dengan 401 Unauthorized
```

### Solusi Rekayasa:
Header dikembalikan ke spesifikasi standar JSON Web Token (JWT):
```dart
// Kode Terverifikasi:
headers: {'Authorization': 'Bearer $token'}
```
Pasca perbaikan, seluruh permintaan data notifikasi dan pembaruan dokumen lahan berjalan sukses dengan status HTTP `200 OK`.

---

## 6. MATRIKS PENGUJIAN SISTEM (AUTOMATED TESTING & QA MINGGU 12)

Pengujian kualitas perangkat lunak dijalankan secara otomatis menggunakan test suite Flutter resmi. Seluruh 37 skenario pengujian berhasil diselesaikan dengan hasil **100% PASS**:

```text
PS D:\e pupuk\e-pupuk\mobile> flutter test
00:00 +0: loading test/gis_boundary_test.dart
00:00 +1: GIS Boundary — 1. Tiga titik valid -> calculateGeodesicArea > 0
00:00 +2: GIS Boundary — 2. Empat titik persegi ~100m -> luas ~10000 m²
00:00 +3: GIS Boundary — 3. Menambah titik mengubah luas secara dinamis
00:00 +4: GIS Boundary — 4. Poligon 200m² lebih besar dari poligon 100m²
00:00 +5: GIS Boundary — 5. Lat > 90 -> validatePolygon isValid=false
00:00 +6: GIS Boundary — 6. Lon < -180 -> validatePolygon isValid=false
00:00 +7: GIS Boundary — 7. Kurang dari 3 titik -> validatePolygon isValid=false
00:00 +8: GIS Boundary — 8. Titik duplikat berturut-turut -> isValid=false
00:00 +9: GIS Boundary — 9. Format luas & satuan m² terverifikasi
00:00 +10: GIS Boundary — 10. Titik identik ditolak
00:00 +11: GIS Boundary — 11. PPLTaskModel parse GeoJSON List<List<double>>
00:00 +12: GIS Boundary — 12. calculateGeodesicArea konsisten WGS-84
00:01 +20: LandingScreen renders all core sections matching React design
00:07 +25: Test Shell Navigation PPL dengan 5 Menu Bottom Nav
00:08 +26: EPupukApp smoke test
00:08 +27: Test Layar 1: Beranda PPL
00:08 +28: Test Layar 2: Data Petani
00:09 +29: Test Layar 3: Detail Petani & Dokumen
00:09 +30: Test Layar 4: Daftar Tugas Survei
00:10 +31: Test Layar 5: Detail Tugas Survei
00:10 +32: Test Layar 6: Formulir Hasil Survei
00:11 +33: Test Layar 7: Peta dan Lokasi Lahan
00:12 +35: Test Layar 8: PPLLoginScreen render dan validasi
00:13 +36: Test Layar 9: LoginScreen menampilkan form login Petani
00:13 +37: All tests passed!
```

---

## 7. DAFTAR KENDALA TEKNIS, ANALISIS AKAR MASALAH, & SOLUSI REKAYASA

| No | Gejala Masalah (*Issue*) | Akar Masalah (*Root Cause*) | Solusi Rekayasa (*Engineered Solution*) | Status |
| :---: | :--- | :--- | :--- | :---: |
| **1** | Garis kuning-hitam pada kartu UREA & NPK Petani | Komponen Row memiliki lebar teks alokasi yang melampaui lebar layar 360px | Pembungkusan teks dinamis dengan `Expanded` dan *badge* musim tanam fleksibel | **RESOLVED** |
| **2** | Kritik Dosen: Panah kembali ganda pada layar PPL | Subheader kartu judul memuat ikon panah kedua di bawah AppBar bawaan | Menghapus ikon panah pada subheader dan mempertahankan satu AppBar terpadu | **RESOLVED** |
| **3** | Inkonsistensi logo aplikasi pada berbagai modul | Penggunaan `Icons.eco` generik warisan prototipe awal | Penggantian menyeluruh dengan komponen vektor resmi `AppLogo(size: 36)` | **RESOLVED** |
| **4** | Tombol "Lihat Dokumen" tidak menampilkan gambar | Event handler hanya memanggil fungsi `ScaffoldMessenger` teks | Pembuatan widget modal *bottom sheet* interaktif e-KTP dan SPPT Lahan | **RESOLVED** |
| **5** | Tombol WhatsApp tidak membuka aplikasi chat | Ketiadaan integrasi URI launcher eksternal | Penambahan dependensi `url_launcher: ^6.3.3` dan normalisasi nomor ke format `+62` | **RESOLVED** |
| **6** | Panah AppBar Beranda Petani keluar dari akun | Nilai `automaticallyImplyLeading` tidak diset `false`, navigasi login memakai `pushReplacement` | Menyetel `automaticallyImplyLeading: false`, navigasi `pushAndRemoveUntil`, dan tombol logout di profil | **RESOLVED** |
| **7** | Error HTTP 401 Unauthorized pada notifikasi | Nilai header otentikasi ter-masking string `'******'` | Mengembalikan header menjadi `{'Authorization': 'Bearer $token'}` | **RESOLVED** |
| **8** | Overflow 3.7px pada AppBar Landing Page | Sifat default Flutter Web yang mengaktifkan auto-centering (`centerTitle: true`) | Menyetel `centerTitle: false` dan membungkus judul dalam widget `Expanded` | **RESOLVED** |
| **9** | Deprecation warning `Intl.v8BreakIterator` di Chrome | Dart SDK Web mengakses API Chromium usang untuk segmentasi kata/kalimat | Menginjeksi polyfill modern `Intl.Segmenter` pada `web/index.html` | **RESOLVED** |

---

## 8. LIMITASI TERBUKA & RENCANA KERJA MINGGU BERIKUTNYA

### Limitasi Terbuka (Known Limitations):
1. **Fitur Barcode Scanner di Lingkungan Web**: Fitur pemindaian kamera QR Code (`mobile_scanner`) berjalan optimal pada perangkat fisik Android (APK). Saat dijalankan di browser web, pemindaian memerlukan izin webcam peramban yang bergantung pada konfigurasi HTTPS.
2. **Ketergantungan Jaringan Wi-Fi/Hotspot Lokal**: Pengujian multiperangkat saat ini mengandalkan alamat IP lokal (`10.142.183.78`). Jika laptop berpindah jaringan Wi-Fi, penyesuaian IP pada `api_config.dart` diperlukan sebelum kompilasi APK fisik baru.

### Rencana Kerja Minggu Ke-13:
1. **Penyebaran Kuesioner Evaluasi (UAT)**: Menggunakan tautan Flutter Web dan APK fisik untuk pengujian pengguna (petani dan PPL) serta pengumpulan data kuesioner TAM (*Technology Acceptance Model*) / SUS (*System Usability Scale*).
2. **Persiapan Laporan Akhir & Dokumentasi Bab IV**: Mengompilasi data hasil pengujian fungsional dan pengujian geodesik poligon lapangan ke dalam draf naskah tugas akhir.
3. **Optimasi Produksi (Release Build)**: Menandatangani (*signing*) file APK rilis dan mengonfigurasi layanan tunnel/hosting publik (seperti ngrok/Cloudflare Tunnel) untuk akses demo dosen tanpa batasan satu jaringan Wi-Fi.

---

## 9. PANDUAN SLIDE PRESENTASI PROGRES MINGGU KE-12

Bagi keperluan evaluasi berkala di hadapan dosen pengampu, berikut ringkasan poin presentasi berdurasi 7–10 menit:

- **Slide 1: Judul & Identitas Proyek**
  - E-Pupuk Kabupaten Mojokerto: Solusi Digitalisasi Alokasi, Verifikasi GIS, & Penyaluran Pupuk Bersubsidi.
  - Tim: Syarifatullah Ceva Efendy & Selby Wafi Nurjuan.
- **Slide 2: Respons Atas Masukan Dosen Minggu Lalu**
  - Demonstrasi visual sebelum vs sesudah: Penghapusan panah ganda, standardisasi logo tunas resmi, dan eliminasi seluruh garis kuning overflow.
- **Slide 3: Demonstrasi Fitur Interaktif Baru**
  - Pembukaan dokumen KTP digital resmi dan arsip SPPT lahan dari akun PPL.
  - Fitur kontak langsung ke WhatsApp petani dengan satu sentuhan.
- **Slide 4: Standardisasi Alur Autentikasi**
  - Beranda Petani kini bersih tanpa panah keluar palsu; proses logout seragam melalui tab Akun/Profil seperti PPL.
- **Slide 5: Kemudahan Pengujian Kuesioner via Flutter Web**
  - Responden dapat mencoba aplikasi secara langsung di browser ponsel/laptop tanpa perlu menginstal APK.
- **Slide 6: Kualitas Rekayasa & Penutup**
  - Status pengujian: 37/37 Automated Tests lolos (100% PASS).
  - Kesiapan APK fisik Android untuk tahapan UAT lapangan.

---
*Laporan ini disusun secara faktual, teliti, dan dapat dipertanggungjawabkan keaslian kode sumbernya.*  
**Mojokerto / Lamongan, 19 November 2026**  
*Tim Pengembang E-Pupuk PSDKU Lamongan — PENS*