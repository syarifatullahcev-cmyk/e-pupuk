# 🌾 LAPORAN KEMAJUAN PROYEK MINGGU KE-6 (DETAIL & FAKTUAL)
## SISTEM E-PUPUK KABUPATEN MOJOKERTO
### Sistem Terpadu Pengajuan Alokasi, Verifikasi Lapangan, & Distribusi Pupuk Bersubsidi

> **Mata Kuliah**: Workshop Pemrograman Framework  
> **Program Studi**: D3 Teknik Informatika — PENS PSDKU Lamongan (Tahun Akademik 2026)  
> **Dosen Pengampu**: Amma Liesvarastranta Haz, S.Tr.T., M.T.  
> **Status Kemajuan Sistem**: **70.0% (Core Workflow Complete & Dockerized)**  
> 
> **Tim Pengembang**:
> - **Syarifatullah Ceva Efendy** (NRP: 312521002) — *Frontend Web & Mobile App (Flutter) Developer*
> - **Selby Wafi Nurjuan** (NRP: 3125521018) — *Backend API (FastAPI) & Database Architect*

---

## 📌 DAFTAR ISI LAPORAN TEKNIS
1. [Status Capaian & Matriks Pembobotan 70% Realistis](#1-status-capaian--matriks-pembobotan-70-realistis)
2. [Bedah Faktual Backend API & Database (Selby Wafi Nurjuan)](#2-bedah-faktual-backend-api--database)
3. [Bedah Faktual Frontend Web (Syarifatullah Ceva Efendy)](#3-bedah-faktual-frontend-web)
4. [Bedah Faktual Mobile Application Flutter (Syarifatullah Ceva Efendy)](#4-bedah-faktual-mobile-application-flutter)
5. [Infrastruktur Docker & Akun Demo Siap Uji](#5-infrastruktur-docker--akun-demo-siap-uji)
6. [Roadmap 30% Sisa Menuju Rilis Penuh](#6-roadmap-30-sisa-menuju-rilis-penuh)
7. [Panduan Slide Presentasi PPT (10 Slide Siap Pakai)](#7-panduan-slide-presentasi-ppt-10-slide-siap-pakai)

---

## 1. STATUS CAPAIAN & MATRIKS PEMBOBOTAN 70% REALISTIS

Sistem **E-PUPUK** telah menyelesaikan seluruh alur bisnis inti dari hulu ke hilir. Seluruh data transaksi dari pendaftaran petani NIK 16 digit, pengajuan subsidi, audit berkas admin, survei lapangan PPL, approval dinas, hingga penebusan kupon QR di kios rekanan telah terhubung nyata ke database MySQL.

Sisa **30.0%** dialokasikan secara objektif untuk pengujian otomatis (Pytest), fitur offline mobile PPL di sawah, cetak laporan dinas (PDF/Excel), serta hosting ke Cloud VPS publik.

### Tabel Matriks Pembobotan Faktual:

| No | Modul / Dimensi Sistem | Bobot | Realisasi | Kontribusi | Status Operasional Berdasarkan Kode |
| :-: | :--- | :---: | :---: | :---: | :--- |
| **1** | **Database & Migrasi** | 15% | **90.0%** | **13.5%** | 🟢 **13 Tabel MySQL 8.0, Relasi FK, phpMyAdmin Port 8080** |
| **2** | **Backend API FastAPI** | 30% | **75.0%** | **22.5%** | 🟢 **8 File Router REST API, Auth JWT, Bcrypt, Haversine GPS** |
| **3** | **Frontend Web React 19** | 25% | **78.0%** | **19.5%** | 🟢 **7 Halaman Web, Multi-Portal Guard (Admin, PPL, Petani, Kios)** |
| **4** | **Mobile App Flutter** | 15% | **80.0%** | **12.0%** | 🟢 **7 Screen Dart: 8 Tab Petani, Stepper 6 Tahap, Satelit GPS PPL** |
| **5** | **Testing Otomatis & QA** | 15% | **16.7%** | **2.5%** | 🟡 **Manual End-to-End Sukses, Pytest dalam tahap setup** |
| | **TOTAL CAPAIAN** | **100%** | — | **70.0%** | 🟢 **70.0% MVP LENGKAP & SIAP DIDEMOKAN LIVE** |

---

## 2. BEDAH FAKTUAL BACKEND API & DATABASE (Selby Wafi Nurjuan)

### 🗄️ A. Skema Database Relasional (`backend/schema.sql` - 13 Tabel Utama)
Struktur database telah diuji dan berjalan di kontainer MySQL 8.0:
1. **`users`**: Manajemen autentikasi multi-peran (`id`, `username`, `email`, `password_hash`, `role: PETANI|PPL|ADMIN`, `is_active`, `created_at`).
2. **`farmer_groups`**: Master data Kelompok Tani (Poktan) se-Kabupaten Mojokerto (`id`, `nama_kelompok`, `ketua_id`, `wilayah`, `created_at`).
3. **`farmers`**: Profil kependudukan petani (`id`, `user_id`, `nik` [16 digit unik], `nama`, `kontak`, `alamat`, `foto_ktp_url`, `farmer_group_id`).
4. **`commodities`**: Master komoditas pertanian (`id`, `nama_komoditas`, `standar_kebutuhan_kg_per_ha`).
5. **`fertilizers`**: Katalog pupuk bersubsidi resmi pemerintah (`id`, `nama_pupuk: Urea / NPK Phonska`, `satuan: kg`).
6. **`lands`**: Data petak sawah petani terdaftar (`id`, `farmer_id`, `lokasi_deskripsi`, `latitude`, `longitude`, `luas_m2`, `commodity_id`, `status_kepemilikan: MILIK|GARAP|SEWA`, `foto_lahan_url`).
7. **`applications`**: Berkas pengajuan subsidi (`id`, `farmer_id`, `land_id`, `fertilizer_id`, `jumlah_diajukan`, `kuota_maksimal`, `status`, `catatan_admin_berkas`, `catatan_penugasan`, `catatan_final_admin`).
8. **`field_surveys`**: Berita acara hasil survei faktual PPL (`id`, `application_id`, `ppl_id`, `kondisi_fisik_lahan`, `kondisi_tanaman`, `luas_lahan_aktual_m2`, `foto_survei_urls`, `rekomendasi`).
9. **`fertilizer_batches`**: Lot produksi dan masa berlaku stok pupuk (`id`, `batch_code`, `fertilizer_id`, `production_date`, `expired_date`, `stok_kg`).
10. **`distributions`**: Alokasi kupon digital resmi (`id`, `application_id`, `batch_id`, `jumlah_disalurkan`, `status_penyaluran`, `qr_code_hash`, `tanggal_penyaluran`).
11. **`qr_scans`**: Transaksi pemindaian kupon di kios & verifikasi pembukaan karung pupuk (`id`, `distribution_id`, `scanner_user_id`, `scan_timestamp`, `latitude`, `longitude`, `validation_status`).
12. **`notifications`**: Layanan notifikasi in-app perkembangan status berkas (`id`, `user_id`, `judul`, `pesan`, `tipe`, `is_read`).
13. **`audit_logs`**: Rekam jejak audit keamanan akses data KTP & approval dinas (`id`, `user_id`, `action`, `resource`, `resource_id`, `ip_address`).

### ⚙️ B. Implementasi 8 Router API (`backend/app/routers/`)
Backend dibangun berbasis FastAPI dengan keamanan standar industri:
* **`auth.py`**: Registrasi mandiri petani dengan validasi NIK 16 digit anti-duplikasi, enkripsi kata sandi menggunakan `passlib[bcrypt]` (salt 12 rounds), dan login multi-role menghasilkan stateless JWT Token (HS256) dengan masa berlaku 24 jam.
* **`farmers.py`**: Endpoint `GET /api/farmers/me` untuk profil data petani, validasi identitas NIK, dan asosiasi keanggotaan Kelompok Tani (Poktan).
* **`lands.py`**: CRUD data petak sawah: input luas ($m^2$), status kepemilikan (Milik/Garap/Sewa), dan penentuan titik koordinat GPS sawah.
* **`applications.py`**: Pengajuan alokasi kuota pupuk, validasi batas kuota musim tanam berjalan (RDKK), engine transisi status berkas dari `DIAJUKAN` hingga `DISETUJUI`, serta ringkasan statistik dashboard (`/stats/petani`).
* **`admin.py`**: Meja kerja dinas untuk verifikasi berkas (`/api/admin/applications/queue`), disposisi penugasan PPL (`/api/admin/applications/{id}/assign-ppl`), dan final approval persetujuan penerbitan pupuk (`/api/admin/applications/{id}/approve`).
* **`ppl.py`**: Pengambilan antrean tugas survei lapangan (`/api/ppl/tasks`) dan pengiriman berita acara evaluasi tanaman & geotagging koordinat sawah (`/api/ppl/applications/{id}/submit-survey`).
* **`distributions.py`**: Penerbitan voucher QR penebusan pupuk di kios, validasi Geofencing GPS pembukaan sak pupuk di sawah (`/api/distributions/scan-qr`) berbasis formula Haversine dengan radius toleransi 50–100 meter, dan audit riwayat pembukaan karung pupuk (`/api/distributions/scans/my`).
* **`files.py`**: Upload dokumen foto e-KTP dan foto lahan sawah dengan validasi ekstensi MIME (JPG/PNG) dan batas ukuran maksimal 5MB.

---

## 3. BEDAH FAKTUAL FRONTEND WEB (Syarifatullah Ceva Efendy)

### ⚛️ A. Arsitektur & Teknologi Frontend
* **Core Framework**: React 19 + Vite 6 + Tailwind CSS 3.4.
* **Routing & Proteksi**: React Router DOM v7 dengan implementasi `<ProtectedRoute />` role guard (isolasi ketat agar Petani tidak bisa mengakses meja Admin, dan sebaliknya).
* **Visual & Ikon**: Lucide Icons & Tailwind Modern UI Theme.
* **Komunikasi Data**: Axios Client dengan interceptor injeksi token JWT otomatis.

### 💻 B. 7 Halaman Web Terintegrasi Penuh (`frontend/src/pages/`)
1. **`Landing.jsx` (26 KB)**:
   - Portal informasi publik pelayanan digital pupuk bersubsidi Kabupaten Mojokerto.
   - Penjelasan 4 alur mudah pengajuan subsidi dan peta kontak Balai Penyuluhan Pertanian (BPP) kecamatan.
2. **`Register.jsx` (17 KB)**:
   - Formulir pendaftaran mandiri petani: Validasi regex NIK 16 digit, pemilihan Kelompok Tani (Poktan) wilayah setempat, dan upload dokumen foto e-KTP.
3. **`Login.jsx` (18 KB)**:
   - Autentikasi multi-peran dengan proteksi isolasi (Petani, PPL, Admin, dan Kios Penyalur).
4. **`PetaniDashboard.jsx` (147 KB - Modul Utama Petani)**:
   - **4 KPI Cards**: Sisa Kuota Urea (kg), Sisa Kuota NPK (kg), Pengajuan Aktif, dan Pupuk Digunakan.
   - **8 Tab Navigasi Terpadu**:
     1. *Dashboard*: Ringkasan kuota terpakai + kartu pengajuan aktif dengan Stepper 6 tahapan visual.
     2. *Profil Saya*: Data identitas KTP, nomor kontak, dan nama Kelompok Tani (Poktan).
     3. *Data Lahan*: Galeri daftar petak sawah + modal input pendaftaran petak lahan baru.
     4. *Pengajuan Subsidi*: Formulir permohonan dengan pemilihan petak sawah, jenis pupuk, dan tonase pengajuan.
     5. *Status Pengajuan*: 6-stage connected progress stepper status pengajuan live.
     6. *Kuota Pupuk*: Grafik dan persentase jatah kuota musim tanam berjalan.
     7. *Pembukaan Pupuk*: Scanner kamera karung pupuk fisik berbasis validasi GPS geofencing sawah.
     8. *Riwayat Pembukaan*: Tabel audit log karung pupuk yang telah dibuka dan diverifikasi di sawah.
   - **Modal Voucher QR Digital**: Menampilkan tiket QR resmi ber-hash kriptografis unik untuk dibawa ke kios penyalur.
5. **`AdminDashboard.jsx` (113 KB - Meja Kerja Dinas)**:
   - Tabulasi antrean status berkas: *Semua, Verifikasi Berkas, Penugasan PPL, Final Approval*.
   - Filter cerdas berdasarkan kelompok tani se-Mojokerto dan jenis pupuk subsidi.
   - Modal audit dokumen: Preview foto KTP, foto lahan sawah, dan riwayat sisa kuota petani.
   - Disposisi tugas survei ke petugas PPL kecamatan setempat.
   - Tombol keputusan: *Setujui Berkas*, *Minta Perbaikan Dokumen*, dan *Tolak Pengajuan*.
6. **`PPLDashboard.jsx` (23 KB - Meja Petugas Lapangan)**:
   - Daftar antrean tugas survei lapangan sawah dari dinas.
   - Formulir evaluasi teknis: kondisi fisik tanah, kesesuaian tanaman, luas aktual sawah ($m^2$), dan upload foto bukti lapangan.
7. **`QRScannerKiosk.jsx` (7 KB - Meja Pengecer Kios)**:
   - Kamera scanner HTML5 untuk memindai voucher QR kuota pupuk petani secara real-time.
   - Pengecekan status alokasi dan pencatatan transaksi penebusan pupuk resmi.

---

## 4. BEDAH FAKTUAL MOBILE APPLICATION FLUTTER (Syarifatullah Ceva Efendy)

### 📱 A. Arsitektur Kode Flutter (`mobile/lib/`)
Aplikasi mobile dibangun dengan **Flutter 3.x (Dart 3)** menggunakan pola *Clean Architecture*:
```
mobile/lib/
├── config/api_config.dart          # Endpoint URL & konfigurasi palet warna sistem
├── models/
│   ├── auth_model.dart             # Model autentikasi & token JWT
│   ├── subsidy_models.dart         # FarmerProfile, Land, Application, Distribution, ScanHistory
│   └── ppl_task_model.dart         # Model tugas survei sawah PPL
├── services/
│   ├── auth_service.dart           # Service login & register mobile
│   └── subsidy_service.dart        # Service API data lahan, pengajuan, stepper, scan QR
└── screens/
    ├── auth/login_screen.dart & register_screen.dart
    ├── petani/
    │   ├── petani_dashboard_screen.dart   # Dashboard 8 Tab selaras 100% Web (88 KB)
    │   ├── pengajuan_pupuk_screen.dart    # Formulir pengajuan subsidi di HP
    │   └── riwayat_pengajuan_screen.dart  # Riwayat permohonan & tiket QR digital
    └── ppl/
        ├── ppl_dashboard_screen.dart      # Task survei lapangan PPL di HP
        └── satellite_measure_screen.dart  # Pengukuran luas sawah dengan citra satelit GPS
```

### 🎨 B. Keselarasan Fitur Mobile Petani 100% dengan Web
1. **Custom AppBar Mojokerto**:
   - Logo kecambah hijau `#009B69`, brand *E-PUPUK KAB. MOJOKERTO*, lonceng notifikasi ber-badge angka merah (`1`), inisial avatar profil, dan tombol logout.
2. **Top Banner Dark Emerald (`#064E3B`)**:
   - Chip badge resmi: *PORTAL PETANI & KELOMPOK TANI KABUPATEN MOJOKERTO* dengan greeting dinamis.
3. **8 Tab Pill Navigation Horizontal (Persis Web)**:
   - Tab navigasi geser: *Dashboard, Profil Saya, Data Lahan, Pengajuan Subsidi, Status Pengajuan, Kuota Pupuk, Pembukaan Pupuk* (Special: border emerald halus `#34D399` & dot hijau bulat), dan *Riwayat Pembukaan*.
4. **4 Kartu KPI Ringkasan**:
   - Menampilkan angka sisa kuota Urea (kg), sisa kuota NPK (kg), pengajuan aktif, dan pupuk digunakan dalam grid responsif.
5. **6-Stage Horizontal Connected Progress Stepper**:
   - Jalur garis horizontal kontinu tebal 2.5px (Hijau `#009B69` untuk selesai/aktif, Abu-abu `#E2E8F0` untuk pending).
   - Checkpoint node lingkaran (26x26px):
     - **Tahap Selesai (1–4)**: Lingkaran hijau penuh dengan ikon centang putih (✓).
     - **Tahap Aktif (Tahap 5 - Persetujuan Admin)**: Lingkaran Biru Cerah (`#2563EB`) dengan ikon medali pita (*Award*) dan cincin cahaya biru muda (*soft glow ring*).
     - **Tahap Pending (Tahap 6 - Penggunaan Pupuk)**: Lingkaran putih border abu-abu dengan ikon kotak karung pupuk.
   - Dibungkus `LayoutBuilder` horizontal scroll (`minWidth: 560px`) sehingga garis tetap panjang, lebar, dan proporsional persis di web tanpa gepeng di layar HP.
6. **Modul Pembukaan Pupuk & Riwayat Scan**:
   - Alur 4 tahap pembukaan pupuk fisik di petak sawah.
   - Dialog kamera scanner dengan batas toleransi radius geofencing GPS 50–100 meter.
   - Tab riwayat pembukaan dengan rincian waktu dan badge status *GPS Valid*.
7. **Fitur Unggulan Petugas PPL (`satellite_measure_screen.dart`)**:
   - Pengukuran luas petak sawah langsung di lapangan menggunakan citra satelit ArcGIS dan kalkulasi poligon polyline GPS.
8. **Bebas Error Overflow (Zero-Overflow Layout)**:
   - Mengatasi error *RenderFlex overflow 132 pixels* pada AppBar dan KPI Cards dengan penerapan `Expanded`, `Flexible`, dan `TextOverflow.ellipsis`.

---

## 5. INFRASTRUKTUR DOCKER & AKUN DEMO SIAP UJI

### 🐳 A. Stack Kontainer Docker Compose:
Sistem dapat dijalankan dengan perintah `docker compose up -d`:
- `epupuk-db`: MySQL 8.0 Engine (Port 3306) dengan penyimpanan data permanen.
- `epupuk-phpmyadmin`: GUI Web Database (Port 8080) untuk inspeksi tabel langsung.
- `epupuk-backend`: FastAPI Python 3.12 (Port 8000) dengan live-reload Uvicorn.
- `epupuk-frontend`: React 19 + Nginx Reverse Proxy (Port 80).

### 👥 B. Akun Seed Data Siap Uji Coba:
| Peran Portal | Username | Password | Skenario yang Dapat Didemokan Langsung |
| :--- | :--- | :--- | :--- |
| **Admin Dinas** | `admin` | `admin123` | Audit berkas petani, disposisi tugas ke PPL, dan final approval persetujuan pupuk |
| **Petugas PPL** | `ppl_ahmad` | `ppl123` | Menerima tugas survei sawah, evaluasi kondisi tanaman, dan submit rekomendasi |
| **Petani 1** | `petani_budi` | `petani123` | Melacak status pengajuan aktif pada Stepper 6 tahapan & sisa kuota RDKK |
| **Petani 2** | `petani_siti` | `petani123` | Menampilkan kupon digital QR Code penebusan dan simulasi buka karung di sawah |
| **Kios Rekanan**| `kios_tani` | `kios123` | Memindai voucher kupon QR petani menggunakan kamera pemindai resmi |

---

## 6. ROADMAP 30% SISA MENUJU RILIS PENUH

Sisa 30% dialokasikan secara terukur untuk pemenuhan standar kualitas perangkat lunak:
1. **Automated Testing Pytest (Bobot: 10.0% - Target: Pekan 7)**:
   - Penyusunan unit test otomatis untuk autentikasi NIK, kalkulasi sisa kuota, dan validasi radius geofencing.
2. **Penyempurnaan Fitur Mobile Offline (Bobot: 9.0% - Target: Pekan 8)**:
   - Mekanisme penyimpanan lokal (*SQLite cache*) pada formulir survei PPL saat berada di area sawah minim sinyal internet.
3. **Ekspor Dokumen Resmi Cetak PDF & Excel (Bobot: 6.0% - Target: Pekan 8)**:
   - Cetak Surat Keputusan (SK) Alokasi Pupuk resmi format PDF (`ReportLab`).
   - Ekspor rekapitulasi distribusi bulanan ke format Excel (`OpenPyXL`) untuk arsip Dinas Pertanian.
4. **Deployment Cloud VPS & Domain SSL (Bobot: 3.0% - Target: Pekan 8)**:
   - Konfigurasi reverse proxy Nginx publik ber-sertifikat SSL Let's Encrypt (HTTPS).
5. **Gateway Notifikasi WhatsApp (Bobot: 2.0% - Target: Pekan 8)**:
   - Webhook notifikasi WhatsApp otomatis ke nomor HP petani saat permohonan disetujui atau pupuk siap ditebus.

---

## 7. PANDUAN SLIDE PRESENTASI PPT (10 SLIDE SIAP PAKAI)

### 📌 Ringkasan 10 Slide PPT:
- **Slide 1: Judul & Identitas Tim**: E-PUPUK Kabupaten Mojokerto, Tim Ceva & Selby, Dosen Pak Amma, Capaian **70.0%**.
- **Slide 2: Executive Summary**: Tabel pembobotan transparan (Database 90%, Backend 75%, Frontend 78%, Mobile 80%, Testing 16.7%).
- **Slide 3: Alur Bisnis End-to-End**: 6 Langkah aktif: Pendaftaran Petani $\rightarrow$ Pengajuan Kuota $\rightarrow$ Verifikasi Admin $\rightarrow$ Survei Lapangan PPL $\rightarrow$ Persetujuan Akhir $\rightarrow$ Penebusan QR Kios.
- **Slide 4: Bedah Backend & Database**: FastAPI Python 3.12, 13 Tabel MySQL, Bcrypt, JWT, 8 Router API, dan formula Geofencing Haversine.
- **Slide 5: Bedah Frontend Web**: React 19, Strict Multi-Portal Guard, 7 Halaman Web (PetaniDashboard 147 KB, AdminDashboard 113 KB, PPLDashboard, QRScannerKiosk).
- **Slide 6: Bedah Mobile App Flutter**: Dart 3, 7 Screen (8 Tab Navigasi, Stepper 6 Tahapan bergaris hijau/abu-abu dengan node award ribbon, modul Geofencing GPS sawah, dan Satelit Ukur Lahan PPL).
- **Slide 7: Infrastruktur Docker & Demo**: 4 Kontainer Docker Compose + 4 Akun Demo bawaan siap uji coba.
- **Slide 8: Roadmap Sisa 30%**: Alokasi objektif: Pytest (10%), Mobile Offline (9%), Cetak PDF/Excel (6%), Cloud VPS (3%), WhatsApp Gateway (2%).
- **Slide 9: Argumen Tanya-Jawab Dosen**: Alasan kenapa 70%: Alur bisnis inti sudah 100% jalan di Docker, sisa 30% adalah pemenuhan standar QA, PDF/Excel, dan hosting publik.
- **Slide 10: Penutup & Demo Langsung**: Pembukaan sesi tanya jawab dan live demo sistem berdampingan (Web Admin Dinas & Mobile Petani).
