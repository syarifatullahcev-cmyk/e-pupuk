# 🌾 MATERI PRESENTASI SLIDE PPT (PEMBARUAN MINGGU KE-6)
## SISTEM E-PUPUK KABUPATEN MOJOKERTO
> **Status**: Progres 70.0% (Core Workflow Complete & Dockerized)  
> **Tim**: Syarifatullah Ceva Efendy (Frontend & Flutter) & Selby Wafi Nurjuan (Backend & Database)  
> **Dosen Pengampu**: Amma Liesvarastranta Haz, S.Tr.T., M.T.  
> **Program Studi**: D3 Teknik Informatika — PENS PSDKU Lamongan (2026)

---

## 📊 REVIEW KESESUAIAN MATERI UNTUK SLIDE PPT

| Bagian | Status Kesesuaian | Rekomendasi Format Slide |
| :--- | :---: | :--- |
| **Backend (8 Router & 13 Tabel)** | ⚠️ *Terlalu padat teks jika disalin mentah* | Diringkas menjadi 3 grup fungsional: **Security & Auth**, **Core Transaction (Alokasi & Lahan)**, dan **Field Engine (Geofencing & Approval)**. |
| **Frontend Web (7 Halaman)** | ⚠️ *Detail KB dan file list membingungkan audiens* | Difokuskan pada **Arsitektur Role-Guard** dan **4 Portal Operasional** (Petani, Admin Dinas, PPL, Kios). |
| **Mobile Flutter** | ⚠️ *Dua versi sebelumnya saling tumpang-tindih* | Disatukan menjadi 3 pilar: **Clean Architecture & Web Sinergi**, **Live Tracking Stepper**, dan **Inovasi Lapangan (Geofencing 18m vs 850m & Satelit PPL)**. |

---

## 🖥️ KONTEN SLIDE PPT SIAP COPY-PASTE (10 SLIDE RESMI)

---

### 🟢 SLIDE 1: JUDUL & IDENTITAS TIM
* **Judul Utama**: **E-PUPUK KABUPATEN MOJOKERTO**
* **Sub-Judul**: Sistem Digitalisasi Distribusi Pupuk Bersubsidi Berbasis Validasi Geofencing GPS & Citra Satelit Lahan
* **Tim Pengembang**:
  1. **Syarifatullah Ceva Efendy** (NRP: 312521002) — *Frontend Web & Mobile Flutter Developer*
  2. **Selby Wafi Nurjuan** (NRP: 3125521018) — *Backend FastAPI & Database Architect*
* **Dosen Pengampu**: Amma Liesvarastranta Haz, S.Tr.T., M.T.
* **Institusi**: D3 Teknik Informatika PENS PSDKU Lamongan — 2026

---

### 🟢 SLIDE 2: MATRIKS CAPAIAN PROGRES (70.0% REALISTIS)
* **Status Keseluruhan**: **70.0% MVP SELESAI & SIAP DEMO LIVE**
* **Rincian Pembobotan per Komponen**:
  1. **Database Relasional (MySQL 8.0)**: **90%** (13 Tabel, Relasi FK, phpMyAdmin Port 8080)
  2. **Backend REST API (FastAPI)**: **75%** (8 Router API, JWT 24 Jam, Bcrypt, Haversine Engine)
  3. **Frontend Web (React 19)**: **78%** (7 Halaman Web, Role Guard, Dashboard Multi-Portal)
  4. **Mobile Application (Flutter 3.x)**: **80%** (8 Tab Navigasi, Stepper 6 Tahap, GPS Geofencing, Satelit PPL)
  5. **Pengujian Otomatis & QA**: **16.7%** (Alur manual 100% lancar, Pytest dalam tahap setup)
* **Catatan**: Sisa 30% dialokasikan secara terukur untuk Automated Testing, Offline Mode Mobile, Ekspor PDF/Excel SK Dinas, dan Cloud Deployment.

---

### 🟢 SLIDE 3: ALUR BISNIS SISTEM (HULU KE HILIR)
*Alur tertutup 6 tahapan untuk mencegah kebocoran pupuk bersubsidi:*
1. **Pendaftaran Petani**: Validasi NIK 16 digit anti-duplikasi + verifikasi Poktan Mojokerto.
2. **Pengajuan Subsidi**: Petani memilih petak sawah dan kuota alokasi sesuai RDKK.
3. **Verifikasi Berkas Dinas**: Admin memverifikasi e-KTP & mendisposisikan survei ke PPL.
4. **Survei Lapangan PPL**: PPL mengevaluasi kondisi tanah/tanaman & ukur lahan via satelit.
5. **Approval & Voucher QR**: Admin menerbitkan persetujuan alokasi kupon digital resmi.
6. **Penebusan & Buka Pupuk**: Penebusan di Kios resmi + validasi Geofencing GPS (radius 100m) saat karung pupuk dibuka di sawah.

---

### 🟢 SLIDE 4: PENCAPAIAN BACKEND API & DATABASE (SELBY WAFI)
* **Teknologi**: FastAPI (Python 3.12) + SQLAlchemy ORM + MySQL 8.0 + Passlib[bcrypt].
* **Keamanan Data**:
  - Stateless JWT Token (HS256) dengan masa berlaku 24 jam & role isolation.
  - Enkripsi kata sandi Bcrypt salt 12 rounds.
* **13 Tabel Relasional Database**:
  - Master Data: `users`, `farmer_groups`, `commodities`, `fertilizers`.
  - Data Operasional: `farmers`, `lands`, `applications`, `field_surveys`.
  - Distribusi & Audit: `fertilizer_batches`, `distributions`, `qr_scans`, `notifications`, `audit_logs`.
* **Implementasi 8 Router API Teruji**:
  - `auth.py`: Registrasi mandiri NIK 16 digit & login multi-peran.
  - `farmers.py`: Profil petani (`/api/farmers/me`) dan keanggotaan Poktan.
  - `lands.py`: CRUD data petak sawah, luas ($m^2$), status kepemilikan, & koordinat GPS.
  - `applications.py`: Engine pengajuan, kuota RDKK, transisi status, & `/stats/petani`.
  - `admin.py`: Meja verifikasi (`/queue`), disposisi PPL (`/assign-ppl`), & approval (`/approve`).
  - `ppl.py`: Antrean survei (`/tasks`) & submit berita acara evaluasi (`/submit-survey`).
  - `distributions.py`: Penerbitan voucher QR & Geofencing GPS Haversine (radius 50–100m).
  - `files.py`: Upload e-KTP & foto sawah (validasi MIME JPG/PNG, maks. 5MB).

---

### 🟢 SLIDE 5: PENCAPAIAN FRONTEND WEB (CEVA EFENDY)
* **Teknologi**: React 19 + Vite 6 + Tailwind CSS 3.4 + Lucide Icons + Axios Interceptor.
* **Arsitektur Keamanan**: React Router DOM v7 dengan `<ProtectedRoute />` role guard ketat (mencegah akses lintas peran).
* **7 Halaman Web Terintegrasi Penuh (`frontend/src/pages/`)**:
  1. `Landing.jsx`: Portal edukasi publik pelayanan subsidi Kabupaten Mojokerto & peta BPP.
  2. `Register.jsx`: Form pendaftaran NIK 16 digit, integrasi Poktan, & upload e-KTP.
  3. `Login.jsx`: Gerbang autentikasi multi-peran dengan isolasi portal otomatis.
  4. `PetaniDashboard.jsx` (147 KB):
     - 4 Kartu KPI Kuota (Sisa Urea, Sisa NPK, Pengajuan Aktif, Pupuk Digunakan).
     - 8 Tab Navigasi Terpadu (Dashboard, Profil, Lahan, Pengajuan, Stepper, Kuota, Buka Pupuk, Riwayat).
     - Modal Voucher QR Digital ber-hash kriptografis unik untuk kios.
  5. `AdminDashboard.jsx` (113 KB): Meja kerja dinas, tabulasi antrean status, filter Poktan se-Mojokerto, modal audit berkas KTP/Lahan, disposisi PPL, & tombol persetujuan final.
  6. `PPLDashboard.jsx` (23 KB): Antrean tugas survei, evaluasi teknis tanah/tanaman, luas aktual sawah ($m^2$), dan upload foto bukti lapangan.
  7. `QRScannerKiosk.jsx` (7 KB): Kamera scanner HTML5 untuk verifikasi alokasi & transaksi penebusan pupuk di kios rekanan.

---

### 🟢 SLIDE 6: PENCAPAIAN MOBILE APP FLUTTER (CEVA EFENDY)
* **Teknologi**: Flutter 3.x (Dart 3) dengan pola **Clean Architecture** (`config/`, `models/`, `services/`, `screens/`).
* **Sinergi 100% Selaras Web**:
  - Custom AppBar Mojokerto (Logo kecambah `#009B69`, brand resmi, badge notifikasi `1`, avatar).
  - Banner Dark Emerald (`#064E3B`) dengan chip resmi Kabupaten Mojokerto.
  - 8 Tab Pill Navigation Horizontal & 4 KPI Cards kuota responsif.
* **6-Stage Connected Progress Stepper**:
  - Jalur garis kontinu tebal 2.5px (Hijau `#009B69` untuk aktif/selesai, Abu-abu `#E2E8F0` untuk pending).
  - Node checkpoint adaptif: Centang hijau untuk selesai, **Biru Cerah `#2563EB` ber-ikon Ribbon Award** untuk tahap aktif dinas.
  - Horizontal scroll responsif (`minWidth: 560px`) bebas gepeng di layar HP.
* **Fitur Unggulan Lapangan (GPS & Satelit)**:
  - **Geofencing GPS Buka Pupuk**: Validasi formula Haversine toleransi radius 100m ke koordinat sawah.
  - **Live Demo Simulator Interaktif**: Uji instan status `[✓ Di Sawah (18m)]` vs `[✕ Luar Sawah (850m)]`.
  - **Citra Satelit ArcGIS PPL (`satellite_measure_screen.dart`)**: Pengukuran poligon luas petak sawah langsung via satelit GPS.
  - **Zero-Overflow Layout**: Tuntas bebas error *RenderFlex overflow 132 pixels* pada semua ukuran layar.

---

### 🟢 SLIDE 7: INFRASTRUKTUR DOCKER & KESIAPAN DEMO
* **Orkestrasi Docker Compose (`docker compose up -d`)**:
  - `epupuk-db`: MySQL 8.0 Engine (Port 3306) dengan *persistent volume*.
  - `epupuk-phpmyadmin`: GUI Database Inspector (Port 8080).
  - `epupuk-backend`: FastAPI Python 3.12 Uvicorn Server (Port 8000).
  - `epupuk-frontend`: React 19 Production Bundle Nginx (Port 80).
* **Akun Demo Bawaan Siap Uji**:
  | Peran | Username | Password | Skenario Demo |
  | :--- | :--- | :--- | :--- |
  | **Admin Dinas** | `admin` | `admin123` | Audit berkas petani, disposisi PPL, dan final approval |
  | **Petugas PPL** | `ppl_ahmad` | `ppl123` | Antrean survei sawah, evaluasi tanaman, & ukur satelit |
  | **Petani 1** | `petani_budi` | `petani123` | Pantau Stepper 6 tahapan & sisa alokasi kuota RDKK |
  | **Petani 2** | `petani_siti` | `petani123` | Tiket QR penebusan pupuk & simulasi buka karung 18m vs 850m |
  | **Kios Rekanan**| `kios_tani` | `kios123` | Pemindaian kupon QR voucher petani menggunakan kamera kios |

---

### 🟢 SLIDE 8: ROADMAP SISA 30% MENUJU RILIS LENGKAP
*Alokasi sisa 30% secara terukur dan objektif:*
1. **Automated Testing Pytest (Bobot: 10.0% - Target: Pekan 7)**:
   - Unit test registrasi NIK, kalkulasi sisa kuota, dan validasi radius Haversine.
2. **Offline-First Mode Mobile PPL (Bobot: 9.0% - Target: Pekan 8)**:
   - Penyimpanan lokal *SQLite cache* saat survei sawah di daerah blankspot sinyal.
3. **Ekspor Dokumen Resmi PDF & Excel (Bobot: 6.0% - Target: Pekan 8)**:
   - Cetak SK Alokasi Pupuk ber-barcode (`ReportLab`) & ekspor rekap distribusi ke Dinas Pertanian (`OpenPyXL`).
4. **Deployment Cloud VPS & SSL HTTPS (Bobot: 3.0% - Target: Pekan 8)**:
   - Konfigurasi domain resmi dengan sertifikat Let's Encrypt SSL.
5. **Gateway Notifikasi WhatsApp (Bobot: 2.0% - Target: Pekan 8)**:
   - Pengiriman otomatis nomor resi voucher ke WhatsApp petani saat disetujui dinas.

---

### 🟢 SLIDE 9: ARGUMEN KUAT TANYA-JAWAB DOSEN PENGUJI

> **Dosen**: *"Mengapa progres Anda 70%, bukan 90% atau 100%?"*  
> **Jawaban Mahasiswa**:  
> *"Izin menjelaskan Bapak Amma. Alur proses bisnis inti dari hulu ke hilir—mulai dari pendaftaran mandiri NIK 16 digit, pengajuan subsidi, verifikasi berkas dinas, survei lapangan PPL, approval dinas, hingga penebusan kupon QR di kios dan validasi buka karung di sawah—**sudah 100% selesai dan terintegrasi nyata di Docker**.*  
>  
> *Angka 70% kami sampaikan secara objektif dan jujur karena standar rekayasa perangkat lunak yang matang masih membutuhkan 30% sisa untuk: **Automated Unit Testing (Pytest)**, **fitur offline mobile PPL**, **cetak laporan SK PDF/Excel**, dan **hosting publik VPS** yang dijadwalkan tuntas pada Pekan 7 dan 8."*

---

### 🟢 SLIDE 10: SESI DEMO LANGSUNG & TANYA JAWAB
* **Langkah Skenario Live Demo (3 Menit)**:
  1. **Layar Kiri (Web Admin Dinas)**: Buka antrean berkas, lakukan audit foto KTP/lahan, disposisi ke PPL Ahmad, dan berikan persetujuan akhir.
  2. **Layar Tengah (Mobile Flutter Petani)**: Tunjukkan 8 tab navigasi, Stepper live ber-node biru Ribbon Award, dan buka modal Voucher QR.
  3. **Fitur Pembuka Sak Sawah**: Klik simulator `[✓ Di Sawah (18m)]` $\rightarrow$ Berhasil tervalidasi GPS; lalu klik `[✕ Luar Sawah (850m)]` $\rightarrow$ Muncul penolakan Geofencing.
  4. **Layar Kanan (Web Kios)**: Pindai voucher QR untuk menyelesaikan transaksi penebusan resmi.

---

## 💡 TIPS PRESENTASI SUKSES:
1. Bagi peran secara tegas: **Selby** menjelaskan Slide 3 & 4 (Alur, Backend, Database), **Ceva** menjelaskan Slide 5, 6, dan Demo Langsung (Frontend Web, Flutter Mobile, Live Demo).
2. Tunjukkan simulator **18 meter vs 850 meter** saat sesi demo—dosen sangat mengapresiasi visualisasi logika Geofencing yang berfungsi secara nyata!
