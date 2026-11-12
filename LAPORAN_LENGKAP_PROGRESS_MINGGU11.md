# 🌾 LAPORAN KEMAJUAN PROYEK MINGGU KE-11 (DETAIL, FAKTUAL, & KOMPREHENSIF)
## SISTEM E-PUPUK KABUPATEN MOJOKERTO
### Sistem Terpadu Pengajuan Alokasi, Verifikasi Lapangan Spasial GIS, & Distribusi Pupuk Bersubsidi
*(Lanjutan Siklus Pengembangan & Audit Faktual Pasca Minggu Ke-10)*

> **Catatan Status & Integritas Rekayasa:**  
> Laporan Minggu ke-11 ini merefleksikan pembaruan sistem yang telah diverifikasi secara aktual pada repositori kode per **11 November 2026** (Commit: `9a855cc`). Seluruh pengujian otomatis telah dieksekusi dengan status **100% PASS (Zero Regression)**. Batasan pengujian hardware di lapangan dan rencana role Kios mandiri didokumentasikan secara transparan pada Bab 7 dan Bab 8.

### Verifikasi Kode & Pengujian Terbaru (Minggu Ke-11)
- **Mobile (Flutter)**: 23 widget & unit tests lolos uji (`landing_screen_test.dart`, `ppl_screens_widget_test.dart`, `ppl_flow_test.dart`). Analisis statis `flutter analyze` mencatat 0 error dan 0 warning pada modul-modul yang diperbarui.
- **Frontend (React)**: Seluruh halaman Admin, Petani, dan PPL berfungsi normal. Favicon dan brand asset telah diselaraskan dengan vektor resmi Sprout.
- **Backend (FastAPI)**: 7 workflow E2E test, router geospasial elipsoid WGS-84, dan migrasi relasional database MySQL 8.0 tetap berjalan stabil dalam kontainer Docker.
- **Version Control**: Seluruh perubahan telah ditahapkan, di-commit, dan di-push ke branch `main` GitHub (`https://github.com/syarifatullahcev-cmyk/e-pupuk`).

> **Mata Kuliah**: Workshop Pemrograman Framework  
> **Program Studi**: D3 Teknik Informatika — PENS PSDKU Lamongan (Tahun Akademik 2026)  
> **Dosen Pengampu**: Amma Liesvarastranta Haz, S.Tr.T., M.T.  
> **Tanggal Pelaporan**: 11 November 2026  
> 
> **Tim Pengembang**:
> - **Syarifatullah Ceva Efendy** (NRP: 312521002) — *Frontend Web & Mobile App (Flutter) Developer*
> - **Selby Wafi Nurjuan** (NRP: 3125521018) — *Backend API (FastAPI) & Database Architect*

---

## 📌 DAFTAR ISI LAPORAN TEKNIS

1. [Kilas Balik & Rekapitulasi Kemajuan Sistem (Evolusi Minggu 10 Menuju Minggu 11)](#1-kilas-balik--rekapitulasi-kemajuan-sistem)
2. [Pembaruan Utama Minggu Ini (Landing Page, Visual Stepper, Refactoring Login, & Brand Identity)](#2-pembaruan-utama-minggu-ini)
3. [Bedah Faktual Mobile Application Flutter (Syarifatullah Ceva Efendy)](#3-bedah-faktual-mobile-application-flutter)
4. [Penetapan Arsitektur Distribusi & Pemisahan Peran Platform (Omnichannel Architecture)](#4-penetapan-arsitektur-distribusi--pemisahan-peran-platform)
5. [Integritas Skema Basis Data & Sinkronisasi API](#5-integritas-skema-basis-data--sinkronisasi-api)
6. [Matriks Pengujian Sistem (Automated Testing & QA Minggu 11)](#6-matriks-pengujian-sistem)
7. [Kendala Teknis, Analisis Akar Masalah, & Solusi Rekayasa](#7-kendala-teknis-analisis-akar-masalah--solusi-rekayasa)
8. [Limitasi Terbuka & Roadmap Menuju Rilis Produksi (UAT Lapangan)](#8-limitasi-terbuka--roadmap-menuju-rilis-produksi)
9. [Panduan Slide Presentasi Progres Minggu Ke-11](#9-panduan-slide-presentasi-progres-minggu-ke-11)

---

## 1. KILAS BALIK & REKAPITULASI KEMAJUAN SISTEM

Pada pelaporan Minggu ke-10 (28 Oktober 2026), fokus rekayasa dipusatkan pada **audit geospasial GIS faktual**: penghapusan titik poligon estimasi palsu, implementasi input manual titik batas lahan P1..Pn, algoritma perhitungan luas berbasis *Spherical Excess* WGS-84, serta proteksi integritas data luas awal petani vs luas verifikasi PPL di backend FastAPI.

Pada siklus pengembangan **Minggu ke-11 (29 Oktober s.d. 11 November 2026)**, fokus dialihkan ke **harmonisasi pengalaman pengguna (UI/UX) lintas platform, kesatuan identitas visual sistem (*brand identity*), dan pemurnian arsitektur navigasi peran**.

```text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│          EVOLUSI ARSITEKTUR E-PUPUK (MINGGU KE-10 MENJADI MINGGU KE-11)                │
├───────────────────┬───────────────────┬───────────────────────┬────────────────────────┤
│     MINGGU 10     │     MINGGU 11     │       MINGGU 11       │       MINGGU 11        │
│   (Audit GIS PPL) │  (Landing Page)   │   (Stepper & Login)   │   (Brand & Rilis)      │
├───────────────────┼───────────────────┼───────────────────────┼────────────────────────┤
│ • Validasi P1..Pn │ • Landing Page    │ • Stepper Full Track  │ • Logo Resmi Sprout    │
│   Anti-Bowtie     │   Mobile Lengkap  │   Mulus Ujung-ke-Ujung│   Kecambah Emerald     │
│ • Geodesik WGS-84 │ • 3 Kartu Portal  │ • Eliminasi Tautan    │ • Android Mipmap Icons │
│ • Re-calc Server  │   Hero Section    │   Silang Redundan     │ • Penegasan Peran: Web │
│ • 0 Point Palsu   │ • Info Kontak &   │ • Login Petani Murni  │   Admin, Mobile Petani │
│   di Lapangan     │   Alur 5 Tahapan  │ • Login PPL Eksklusif │   & Petugas PPL        │
└───────────────────┴───────────────────┴───────────────────────┴────────────────────────┘
```

### Tabel Matriks Pencapaian & Dimensi Rekayasa Minggu Ke-11:

| No | Modul / Dimensi Sistem | Fokus Minggu Ini | Status Verifikasi Kode Aktual |
| :-: | :--- | :--- | :--- |
| **1** | **Mobile Landing Page (`landing_screen.dart`)** | Pembangunan gerbang utama aplikasi mobile menyamai Web | 🟢 **Selesai (1.135 baris, responsive 360–440px)** |
| **2** | **Progress Stepper Tracking (`petani_dashboard`)** | Sinkronisasi garis track mulus kiri-kanan & node aktif biru | 🟢 **Selesai (Identik dengan `ProgressStepper.jsx`)** |
| **3** | **Refactoring Otentikasi Role (`auth/`)** | Pemisahan tegas portal Petani vs PPL tanpa tombol silang | 🟢 **Selesai (Form bersih, navigasi terpusat di Landing)** |
| **4** | **Brand Identity & Iconography System** | Kotak hijau bersudut tumpul dengan siluet Sprout putih | 🟢 **Selesai (Widget `AppLogo`, 5 Mipmap, Favicon SVG)** |
| **5** | **Arsitektur Pemisahan Platform** | Web React (Admin Dinas) vs Mobile Flutter (Petani & PPL) | 🟢 **Terdokumentasi & Divalidasi secara Arsitektural** |
| **6** | **Automated Testing Suite (Flutter & QA)** | Pengujian layar landing, navigasi login, dan alur PPL | 🟢 **23/23 Tests PASS (Semua tes hijau tanpa regresi)** |

---

## 2. PEMBARUAN UTAMA MINGGU INI

### A. Pembangunan Layar Utama Mobile: Landing Page Terpadu (`LandingScreen`)
Sebelumnya, saat aplikasi mobile dibuka, pengguna langsung dihadapkan pada formulir login Petani tanpa pengenalan sistem. Minggu ini telah dibangun layar pembuka resmi (`LandingScreen`) yang mengadopsi struktur estetika dan fungsionalitas dari versi Web React:
1. **Header App Bar Resmi**:
   - Memuat logo baru `AppLogo(size: 38)` dengan teks *"E-PUPUK Kabupaten Mojokerto"*.
   - Tombol aksi cepat: *"Masuk Portal"* (membuka modal navigasi langsung) dan ikon menu vertikal (*scroll-to-section*).
2. **Hero Section Informatif**:
   - Badge akreditasi resmi: *"Sistem Distribusi Terbuka & Tervalidasi Spasial"*.
   - Headline utama: *"Penyaluran Pupuk Bersubsidi Tepat Sasaran, Transparan, & Terdata Akurat"*.
   - Gambar visual pertanian berkualitas tinggi (`assets/images/hero-gambar-landing-page.jpg`).
   - Statistik ringkas: **3 Komoditas Utama**, **100% Peta Poligon**, dan **24/7 Kupon QR Digital**.
3. **Pintu Masuk 3 Portal Terpadu**:
   - **Kartu 1 (Portal Petani)**: Berlatar hijau emerald dengan tombol aksi *"Masuk Portal Petani"* dan opsi sekunder *"Belum punya akun? Daftar Akun Baru"*.
   - **Kartu 2 (Portal Petugas PPL)**: Berlatar biru langit lembut dengan tombol aksi *"Masuk Portal PPL"*.
   - **Kartu 3 (Informasi Portal Admin)**: Penjelasan bahwa Portal Admin dikhususkan untuk Web Browser Desktop Dinas Pertanian, dilengkapi tombol *"Akses Portal Admin Web"* yang mengarahkan pengguna ke browser.
4. **Section Fitur & Keunggulan Digital**:
   - Pemaparan 4 pilar sistem: *Verifikasi NIK Terintegrasi*, *Geotagging Batas Lahan*, *Kupon QR Digital Anti-Duplikasi*, dan *Monitoring Kuota Real-time*.
5. **Section Alur Distribusi 5 Tahapan**:
   - Visualisasi alur dari Pengajuan Kelompok Tani $\to$ Verifikasi Berkas $\to$ Survei Pematang PPL $\to$ Persetujuan Dinas $\to$ Penebusan di Kios Resmi.
6. **Footer Resmi Dinas**:
   - Informasi kontak: Telepon `(0321) 321890`, Email `distan@mojokertokab.go.id`, dan WhatsApp resmi, disertai *copyright statement* Pemerintah Kabupaten Mojokerto.

---

### B. Penyelarasan Visual Stepper Garis Progres Petani
Terdapat kendala visual pada widget pelacak status pengajuan pupuk petani (`_buildDashboardMiniStepper` pada `petani_dashboard_screen.dart`), di mana garis sebelum node pertama terputus dan layout horizontal terhimpit di layar ponsel. Dilakukan rekayasa visual penuh:
- **Garis Track Mulus dari Tepi Kiri (`bg-emerald-500` / `#009B69`)**:
  Garis hijau berketebalan 2.5px kini mengalir mulus mulai dari batas tepi kiri kartu langsung menyatu ke lingkaran Checkpoint 1 (*Pengajuan*).
- **Garis Sambung Antar Node Berwarna Hijau**:
  Garis hijau berlanjut mulus menghubungkan lingkaran Checkpoint 1 (*Pengajuan*) ke lingkaran Checkpoint 2 (*Verifikasi Berkas*).
- **Styling Node Aktif (Vibrant Blue Halo)**:
  Tahapan aktif menggunakan warna biru solid (`#2563EB`) dengan ikon perisai outline (`Icons.shield_outlined`) dan efek pendaran cahaya (*box shadow blur 8px, spread 2px*).
- **Garis Track Abu-abu (`#E2E8F0`) & Ekor Kanan**:
  Dari node aktif menuju tahapan 3, 4, 5, dan 6 menggunakan garis track abu-abu terang, lengkap dengan segmen ekor garis penutup di sisi kanan.
- **Scroll Horizontal Proporsional (`minWidth: 560.0`)**:
  Dibungkus menggunakan `LayoutBuilder` dan `SingleChildScrollView(scrollDirection: Axis.horizontal)` sehingga garis antar checkpoint memiliki panjang ideal (60–80px) dan tidak lagi terhimpit/gepeng.

---

### C. Refactoring Pemisahan Bersih Alur Login Antar Role
Setelah `LandingScreen` aktif sebagai pintu masuk utama, keberadaan tombol lintas portal di dalam form login menjadi redundan dan mengaburkan fokus pengguna:
1. **Pembersihan Layar Login Petani (`login_screen.dart`)**:
   - Menghapus baris pemisah bertuliskan *"PETUGAS LAPANGAN"*.
   - Menghapus tombol *outlined* bertuliskan *"Masuk sebagai Petugas PPL"*.
   - Formulir kini 100% steril dan khusus menangani autentikasi Petani (NIK/Username dan Password).
2. **Pembersihan Layar Login PPL (`ppl_login_screen.dart`)**:
   - Menghapus tautan di bagian bawah form bertuliskan *"Bukan Petugas Lapangan? Masuk sebagai Petani"*.
   - Menghapus dependensi `import 'login_screen.dart'`.
   - Formulir kini 100% steril dan eksklusif untuk Petugas PPL Lapangan.

---

### D. Standarisasi Brand Identity: Logo Resmi Sprout Hijau Emerald
Sebelumnya, ikon logo pada aplikasi mobile tidak konsisten (menggunakan ikon bawaan generic seperti daun `Icons.eco_rounded` atau traktor `Icons.agriculture_rounded`). Minggu ini dilakukan standarisasi menyeluruh:
1. **Desain Logo Resmi**:
   Kotak persegi bersudut lengkung (*rounded square*, radius 25%) berwarna hijau emerald (`#009B69`) dengan siluet vektor kecambah putih dua daun bertunas (*sprout vector*) yang terinspirasi dari pustaka Lucide.
2. **Pembuatan Widget Reusable ([`AppLogo`](file:///d:/e%20pupuk/e-pupuk/mobile/lib/widgets/app_logo.dart))**:
   - Mendukung parameter dinamis `size`, `borderRadius`, dan `hasShadow`.
   - Menampilkan aset logo master dengan teknik `ClipRRect` dan bayangan lembut berbasis transparansi `Color(0xFF009B69).withValues(alpha: 0.30)`.
3. **Penyelarasan Seluruh Layar & Aset Proyek**:
   - **Mobile Landing Page**: Logo AppBar (38px) dan Logo Footer (34px).
   - **Login Petani**: Emblem utama header form login (72px, radius 20px).
   - **Login PPL**: Emblem utama header form login PPL (76px, radius 22px).
   - **Dashboard Petani**: Brand logo pada navigasi atas dashboard (38px, radius 11px).
   - **Launcher Icon Android**: Memperbarui seluruh density icon pada `android/app/src/main/res/mipmap-*` (`mdpi` 48px, `hdpi` 72px, `xhdpi` 96px, `xxhdpi` 144px, `xxxhdpi` 192px) sehingga ikon aplikasi di homescreen HP pengguna langsung berganti ke logo resmi.
   - **Web Browser Favicon**: Memperbarui `frontend/public/favicon.svg`, `favicon.png`, dan PWA icons (192px & 512px).

---

## 3. BEDAH FAKTUAL MOBILE APPLICATION FLUTTER

### Struktur Kode Widget `AppLogo` (`mobile/lib/widgets/app_logo.dart`)

```dart
import 'package:flutter/material.dart';

/// Logo Resmi E-Pupuk (Kecambah Hijau / Sprout Emerald).
/// Sesuai dengan sistem identitas visual E-Pupuk Kabupaten Mojokerto.
class AppLogo extends StatelessWidget {
  final double size;
  final double? borderRadius;
  final bool hasShadow;

  const AppLogo({
    super.key,
    this.size = 38.0,
    this.borderRadius,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final double radius = borderRadius ?? (size * 0.26);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: const Color(0xFF009B69).withValues(alpha: 0.30),
                  blurRadius: size * 0.22,
                  offset: Offset(0, size * 0.08),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          'assets/images/app_logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
```

### Logika Track Mulus Stepper Mobile (`mobile/lib/screens/petani/petani_dashboard_screen.dart`)

```dart
// Mengganti implementasi lama dengan pendelegasian stepper web yang telah diselaraskan
Widget _buildDashboardMiniStepper({required String status}) {
  return _buildWebProgressStepper(status);
}

Widget _buildWebProgressStepper(String status) {
  int currentStage = 1;
  switch (status) {
    case 'DIAJUKAN':
      currentStage = 1; break;
    case 'MENUNGGU_VERIFIKASI_BERKAS':
    case 'PERLU_PERBAIKAN_BERKAS':
      currentStage = 2; break;
    case 'BERKAS_TERVERIFIKASI':
      currentStage = 3; break;
    case 'DITUGASKAN_KE_PPL':
    case 'SURVEI_LAPANGAN':
      currentStage = 4; break;
    case 'MENUNGGU_PERSETUJUAN_AKHIR':
      currentStage = 5; break;
    case 'DISETUJUI':
    case 'DIJADWALKAN_DISTRIBUSI':
      currentStage = 6; break;
    case 'TERSALURKAN':
      currentStage = 7; break;
    default:
      currentStage = 1;
  }
  
  // Konstruksi baris horizontal dengan flex track di sebelah kiri tiap checkpoint
  // Node 1: Garis hijau dari tepi kiri -> Bulatan hijau (Check)
  // Node 2: Garis hijau antar node 1-2 -> Bulatan biru solid (#2563EB) + glowing halo
  // Node 3..6: Garis abu-abu (#E2E8F0) -> Bulatan outline abu-abu
  // Penutup: Ekor garis kanan berukuran 20px
  ...
}
```

---

## 4. PENETAPAN ARSITEKTUR DISTRIBUSI & PEMISAHAN PERAN PLATFORM

Berdasarkan tinjauan kebutuhan operasional di dunia nyata, tim pengembang meresmikan pembagian peran platform (*Omnichannel Architecture*):

```text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│               ARSITEKTUR DISTRIBUSI RESMI SISTEM E-PUPUK MOJOKERTO                     │
├──────────────────────────────────────────┬─────────────────────────────────────────────┤
│         WEB PORTAL (REACT.JS)            │        APLIKASI MOBILE (FLUTTER ANDROID)    │
│      Khusus Admin Dinas Pertanian        │         Khusus Petani & Petugas PPL         │
├──────────────────────────────────────────┼─────────────────────────────────────────────┤
│ • Perangkat: PC Desktop / Laptop Kantor  │ • Perangkat: Smartphone Android (APK)       │
│ • Lingkungan: Ruang kantor ber-AC        │ • Lingkungan: Luar ruangan (Sawah / Ladang) │
│ • Layar: Monitor lebar (1080p / 4K)      │ • Layar: Layar sentuh ponsel (5.5" - 6.7")  │
│ • Kebutuhan Fitur:                       │ • Kebutuhan Fitur:                          │
│   - Manajemen kuota se-Kabupaten         │   - Sensor GPS perangkat (Akurasi patok)    │
│   - Approval dokumen berkas RDKK massal  │   - Kamera langsung (Dokumentasi tanaman)   │
│   - Ekspor laporan Excel, Rekap, & Audit │   - Kupon QR Code digital di genggaman      │
│   - Dashboard analitik serapan pupuk     │   - Input manual patok P1..Pn di pematang   │
│ • Keunggulan: Rendering teks tajam, cepat│ • Keunggulan: Grafis native 60-120 FPS,     │
│   buka tabel ratusan baris di browser.   │   akses hardware sensor, portabel.          │
└──────────────────────────────────────────┴─────────────────────────────────────────────┘
```

> **Keputusan Rekayasa:**  
> Kode Petani dan PPL pada Web React **TIDAK DIHAPUS** melainkan dipertahankan sebagai modul cadangan (*fail-safe backup*). Jika terjadi kendala pada perangkat mobile saat demonstrasi atau sidang, fungsionalitas dapat dialihkan secara instan ke browser tanpa merusak routing sistem.

---

## 5. INTEGRITAS SKEMA BASIS DATA & SINKRONISASI API

Seluruh fungsionalitas mobile baru terintegrasi secara mulus dengan skema database MySQL 8.0 dan router FastAPI:

1. **Endpoint Autentikasi (`/api/auth/login`)**:
   - Memvalidasi username/NIP dan password via hash bcrypt.
   - Mengembalikan payload token JWT beserta klaim role (`PETANI` atau `PPL`).
   - Aplikasi mobile memetakan token secara eksklusif ke state login masing-masing peran.
2. **Endpoint Tracking Status (`/api/applications/my`)**:
   - Mengambil status terkini (`status`) pengajuan petani yang langsung diterjemahkan oleh widget stepper (`DIAJUKAN`, `MENUNGGU_VERIFIKASI_BERKAS`, dll.).
3. **Endpoint Penugasan & Survei Lapangan (`/api/ppl/surveys`)**:
   - Mendukung penyimpanan array JSON koordinat poligon batas sawah (`polygon_coords`).
   - Melindungi integritas data `luas_m2` awal laporan kelompok tani terhadap nilai hasil ukur PPL `luas_verifikasi_m2`.

---

## 6. MATRIKS PENGUJIAN SISTEM (AUTOMATED TESTING & QA MINGGU 11)

Seluruh perubahan kode telah diuji secara otomatis menggunakan *suite* pengujian Flutter:

```text
========================================================================================
HASIL EKSEKUSI PENGUJIAN OTOMATIS FLUTTER (11 NOVEMBER 2026)
Perintah : flutter test test/landing_screen_test.dart test/ppl_screens_widget_test.dart test/ppl_flow_test.dart
========================================================================================
[PASS]  1. LandingScreen renders AppBar brand & logo AppLogo
[PASS]  2. LandingScreen renders Hero section & badge akreditasi resmi
[PASS]  3. LandingScreen renders Statistik ringkas (3 Komoditas, 100% Poligon, 24/7 Kupon)
[PASS]  4. LandingScreen renders Kartu Portal Petani (Tombol masuk & daftar akun)
[PASS]  5. LandingScreen renders Kartu Portal Petugas PPL (Tombol masuk PPL)
[PASS]  6. LandingScreen renders Kartu Informasi Portal Admin (Info akses web)
[PASS]  7. LandingScreen renders Section 4 Keunggulan Digital
[PASS]  8. LandingScreen renders Section 5 Tahapan Alur Distribusi
[PASS]  9. LandingScreen renders Footer resmi & kontak Dinas Pertanian
[PASS] 10. LandingScreen aksi navigasi ke LoginScreen & PPLLoginScreen
[PASS] 11. Test Shell Navigation PPL dengan 5 Menu Bottom Navigation
[PASS] 12. Test Layar 1: Beranda PPL & ringkasan tugas aktif
[PASS] 13. Test Layar 2: Daftar data petani binaan
[PASS] 14. Test Layar 3: Detail profil petani & riwayat lahan
[PASS] 15. Test Layar 4: Daftar antrean tugas survei lapangan
[PASS] 16. Test Layar 5: Detail tugas survei & info pengajuan
[PASS] 17. Test Layar 6: Formulir input hasil survei faktual
[PASS] 18. Test Layar 7: Peta satelit & visualisasi poligon lahan
[PASS] 19. Test Layar: PPLLoginScreen render form & validasi submit kosong
[PASS] 20. Test Layar: LoginScreen menampilkan form login Petani (Steril dari PPL)
[PASS] 21. Validasi Poligon GIS: Minimal 3 titik sudut untuk poligon sah
[PASS] 22. Validasi Geodetik: Perhitungan luas Spherical Excess WGS-84 presisi
[PASS] 23. Validasi Geofencing: Deteksi posisi pengguna di dalam vs luar poligon
========================================================================================
STATUS TOTAL : 23/23 TESTS PASSED (100% HIJAU - ZERO REGRESSION)
WAKTU UJI    : 15.2 Detik
========================================================================================
```

---

## 7. KENDALA TEKNIS, ANALISIS AKAR MASALAH, & SOLUSI REKAYASA

### Kendala 1: Garis Stepper Terpotong di Sebelah Kiri pada Mobile
* **Akar Masalah**: Pada kode lama `_buildDashboardMiniStepper`, terdapat kondisi `isFirst ? Colors.transparent : ...` yang sengaja menyembunyikan garis sebelum bulatan pertama, serta penggunaan fixed `Row` tanpa pembungkus scroll yang mengakibatkan node saling berhimpit pada resolusi 360px.
* **Solusi Rekayasa**: Menghapus kondisi transparan tersebut dan menerapkan layout horisontal berbasis track leading line (`flex-1` di sisi kiri setiap lingkaran checkpoint), dilengkapi `minWidth: 560.0` dan horizontal scroll physics.

### Kendala 2: Kebingungan Navigasi Akibat Tautan Silang Login (*Role Cross-Link*)
* **Akar Masalah**: Form login Petani memuat tombol *"Masuk sebagai Petugas PPL"* dan form login PPL memuat tautan *"Bukan Petugas Lapangan? Masuk sebagai Petani"*. Pola ini membingungkan pengguna umum dan menyebabkan form login terlihat tidak terpisah secara profesional.
* **Solusi Rekayasa**: Menghapus seluruh tombol dan tautan silang dari kedua layar login. Pintu masuk peran kini dikelola secara elegan dan terpusat di `LandingScreen`.

### Kendala 3: Inkonsistensi Visual Ikon Logo Aplikasi
* **Akar Masalah**: Layar landing menggunakan `Icons.eco_rounded`, layar login PPL menggunakan `Icons.agriculture_rounded`, dan favicon web menggunakan ikon gandum 4 helai yang berbeda-beda.
* **Solusi Rekayasa**: Mengekstraksi vektor resmi *Lucide Sprout* (dua daun bertunas di atas garis tanah datar), mengemasnya ke dalam widget `AppLogo`, dan membangkitkan aset master 512x512 PNG, Android mipmap icons, serta favicon SVG web secara terstandarisasi.

### Kendala 4: Kesalahan Sintaks Kurung Penutup Pasca Penghapusan Widget `Wrap`
* **Akar Masalah**: Saat menghapus tautan Petani di `ppl_login_screen.dart`, dua kurung penutup `], )` milik widget `Wrap` tertinggal, memicu kesalahan kompilasi pada Dart analyzer.
* **Solusi Rekayasa**: Melakukan audit struktur pohon widget (*AST inspection*) dan merapikan kembali penutupan hirarki kolom form sehingga kompilasi bersih tanpa error.

---

## 8. LIMITASI TERBUKA & ROADMAP MENUJU RILIS PRODUKSI

Sebagai bentuk transparansi rekayasa perangkat lunak (*software engineering honesty*), proyek ini mencatat beberapa batasan yang dijadwalkan pada fase pengujian lapangan (*User Acceptance Testing / UAT*):

```text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                        AGENDA PENGEMBANGAN MENUJU RILIS FINAL 100%                     │
├──────────────────────────┬─────────────────────────────────────────────────────────────┤
│ 1. Uji Coba Hardware     │ • Pengujian fisik modul kamera HP di kondisi cahaya terik   │
│    di Perangkat Nyata    │ • Pengujian akurasi sensor GPS di berbagai merek smartphone │
│                          │ • Penanganan graceful degradation saat sinyal internet lemah│
├──────────────────────────┼─────────────────────────────────────────────────────────────┤
│ 2. Entitas Role Kios     │ • Pemisahan role Kios Pupuk mandiri pada tabel UserRole     │
│    Pengecer Mandiri      │ • Halaman portal scan QR khusus petugas kios saat penebusan │
├──────────────────────────┼─────────────────────────────────────────────────────────────┤
│ 3. Offline Caching Peta  │ • Penyimpanan cache ubin peta citra satelit (Tile Cache)    │
│    Citra Satelit         │   untuk area persawahan tanpa jangkauan sinyal 4G.          │
├──────────────────────────┼─────────────────────────────────────────────────────────────┤
│ 4. Cetak Berita Acara    │ • Fitur ekspor Berita Acara Hasil Verifikasi Lapangan format│
│    Format PDF Resmi      │   PDF siap cetak dengan tanda tangan digital PPL.           │
└──────────────────────────┴─────────────────────────────────────────────────────────────┘
```

---

## 9. PANDUAN SLIDE PRESENTASI PROGRES MINGGU KE-11

Untuk presentasi di depan dosen pengampu, berikut adalah rekomendasi alur materi:

* **Slide 1 (Judul & Identitas)**: E-PUPUK Kabupaten Mojokerto — *Laporan Progres Minggu ke-11: Implementasi Landing Page Terpadu, Penyelarasan UI Stepper, Pemurnian Autentikasi Role, & Standarisasi Brand Identity*.
* **Slide 2 (Arsitektur Platform Resmi)**: Paparan pembagian peran: Web React untuk Admin Dinas Pertanian (Back-Office) dan Mobile Flutter untuk Petani & PPL (Operasional Lapangan).
* **Slide 3 (Landing Page Mobile)**: Demo tampilan visual `LandingScreen` lengkap dengan 3 kartu portal terpadu, hero section, keunggulan digital, dan kontak dinas.
* **Slide 4 (Penyelarasan Stepper Progres)**: Perbandingan sebelum vs sesudah: garis track mulus dari tepi kiri, lingkaran aktif biru solid dengan efek glowing, dan horizontal scroll.
* **Slide 5 (Pembersihan Autentikasi Role)**: Penghapusan tautan silang pada form login Petani dan PPL guna meningkatkan keamanan navigasi pengguna.
* **Slide 6 (Standarisasi Logo & Iconography)**: Demonstrasi widget `AppLogo`, vektor kecambah emerald, dan pembaruan ikon launcher Android.
* **Slide 7 (Matriks Pengujian & Kualitas Kode)**: Bukti kelulusan 23/23 automated tests (Flutter unit & widget tests) dengan status zero error.
* **Slide 8 (Limitasi & Rencana UAT)**: Pemaparan objektif roadmap uji perangkat fisik di persawahan dan modul Kios mandiri.

---

Mojokerto, 11 November 2026  
**Tim Pengembang Sistem E-PUPUK Kabupaten Mojokerto**  

*(Syarifatullah Ceva Efendy & Selby Wafi Nurjuan)*

