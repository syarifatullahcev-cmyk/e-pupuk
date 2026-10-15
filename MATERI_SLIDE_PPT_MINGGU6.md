# 📊 LAPORAN LENGKAP & PANDUAN MATERI PRESENTASI MINGGU KE-6
## E-PUPUK KABUPATEN MOJOKERTO
### Sistem Terpadu Pengajuan, Verifikasi Lapangan, & Distribusi Pupuk Bersubsidi Berbasis Geofencing GPS

> **Mata Kuliah**: Workshop Pemrograman Framework — D3 TI PENS PSDKU Lamongan  
> **Tahun Akademik**: 2026 | **Status Capaian**: **70.0% (Core Workflow Complete & Dockerized)**  
> **Dosen Pengampu**: Amma Liesvarastranta Haz, S.Tr.T., M.T.  
> 
> **Tim Pengembang**:
> 1. **Syarifatullah Ceva Efendy** (NRP: 312521002) — *Frontend Web & Mobile App Developer*
> 2. **Selby Wafi Nurjuan** (NRP: 3125521018) — *Backend API & Database Architect*

---

# 📑 DAFTAR ISI LAPORAN TEKNIS
1. [Ringkasan Eksekutif & Pembobotan Realistis 70%](#1-ringkasan-eksekutif--pembobotan-realistis-70)
2. [Bedah Teknis Mendalam: Backend & Database (FastAPI & MySQL 8.0)](#2-bedah-teknis-mendalam-backend--database)
3. [Bedah Teknis Mendalam: Frontend Web (React 19 + Vite + Tailwind)](#3-bedah-teknis-mendalam-frontend-web)
4. [Bedah Teknis Mendalam: Mobile Application (Flutter)](#4-bedah-teknis-mendalam-mobile-application-flutter)
5. [Infrastruktur Docker & Akun Uji Coba Demo Live](#5-infrastruktur-docker--akun-uji-coba-demo-live)
6. [Roadmap Pekerjaan Sisa (Bobot 30%)](#6-roadmap-pekerjaan-sisa-bobot-30)
7. [Struktur 10 Slide PPT & Naskah Presentasi ke Dosen](#7-struktur-10-slide-ppt--naskah-presentasi-ke-dosen)

---

# 1. RINGKASAN EKSEKUTIF & PEMBOBOTAN REALISTIS (70%)

Sistem **E-PUPUK** telah menyelesaikan seluruh alur bisnis inti dari hulu ke hilir: mulai dari registrasi petani berbasis NIK 16 digit, pengajuan subsidi dengan batas kuota RDKK, verifikasi berkas administratif admin dinas, penugasan survei sawah oleh PPL, persetujuan alokasi kuota, hingga pemindaian kode QR di kios rekanan dan validasi geofencing GPS saat karung pupuk dibuka di sawah.

### Matriks Pembobotan Standar Rekayasa Perangkat Lunak:

| Komponen Sistem | Bobot | Progres Riil | Kontribusi | Status Operasional Teknis |
| :--- | :---: | :---: | :---: | :--- |
| **Database & Migrasi** | 15% | **90.0%** | **13.5%** | 🟢 **13 Tabel MySQL 8.0, Foreign Keys, Indexing, phpMyAdmin Live** |
| **Backend API FastAPI** | 30% | **75.0%** | **22.5%** | 🟢 **Autentikasi JWT, Bcrypt, 12-Status Engine, Haversine Geofencing** |
| **Frontend Web React 19** | 25% | **78.0%** | **19.5%** | 🟢 **Strict Multi-Portal Guard (Admin, PPL, Petani, Kios Scanner)** |
| **Aplikasi Mobile Flutter** | 15% | **80.0%** | **12.0%** | 🟢 **Sinkron 100% Web: 8 Tab, Stepper 6 Tahap, QR Scanner, Geofencing** |
| **Testing Otomatis & QA** | 15% | **16.7%** | **2.5%** | 🟡 **Pengujian End-to-End Manual Lancar, Pytest dalam tahap setup** |
| **TOTAL CAPAIAN** | **100%** | — | **70.0%** | 🟢 **70.0% MVP LENGKAP & SIAP DIDEMOKAN LIVE** |

---

# 2. BEDAH TEKNIS MENDALAM: BACKEND & DATABASE

### 🗄️ A. Arsitektur Database (MySQL 8.0 & SQLAlchemy ORM)
Database dibangun dengan relasi referensial integritas tinggi, normalisasi hingga 3NF, terdiri dari **13 Tabel Utama**:
1. **`users`**: Master akun multi-role (`id`, `username`, `email`, `hashed_password`, `role: PETANI|PPL|ADMIN|KIOSK`, `is_active`, `created_at`).
2. **`farmers`**: Profil petani (`id`, `user_id`, `nik` [16 digit unik], `nama`, `kontak`, `alamat`, `foto_ktp_url`, `kelompok_tani_id`).
3. **`farmer_groups` (Poktan)**: Kelompok tani se-Mojokerto (`id`, `nama_kelompok`, `desa`, `kecamatan`, `ketua_kelompok`).
4. **`lands`**: Data lahan sawah terdaftar (`id`, `farmer_id`, `lokasi_deskripsi`, `luas_m2`, `status_kepemilikan: MILIK|SEWA`, `latitude`, `longitude`, `foto_lahan_url`).
5. **`fertilizers`**: Katalog komoditas pupuk (`id`, `kode_pupuk: UREA|NPK`, `nama_pupuk`, `harga_subsidi`, `harga_non_subsidi`, `satuan`).
6. **`commodities`**: Jenis tanaman pertanian (`id`, `nama_komoditas: Padi|Jagung|Kedelai`, `masa_tanam`).
7. **`quotas`**: Jatah kuota resmi RDKK per musim tanam (`id`, `farmer_id`, `fertilizer_id`, `tahun`, `musim_tanam`, `kuota_maksimal_kg`, `kuota_terpakai_kg`).
8. **`applications`**: Berkas pengajuan subsidi (`id`, `farmer_id`, `land_id`, `fertilizer_id`, `jumlah_diajukan`, `status`, `tanggal_pengajuan`).
9. **`surveys`**: Hasil evaluasi faktual lapangan PPL (`id`, `application_id`, `ppl_id`, `kesesuaian_lahan`, `kondisi_tanaman`, `rekomendasi_kuota`, `foto_survei_url`, `latitude_survey`, `longitude_survey`).
10. **`distributions`**: Alokasi kupon/voucher digital (`id`, `application_id`, `jumlah_disalurkan`, `qr_code_hash`, `status_penyaluran`, `tanggal_penyaluran`).
11. **`qr_scans`**: Audit log pemindaian di kios (`id`, `distribution_id`, `scanned_by_kiosk_id`, `scanned_at`, `keterangan`).
12. **`bag_scans`**: Validasi pembukaan karung pupuk fisik di petak sawah (`id`, `farmer_id`, `distribution_id`, `qr_token`, `latitude`, `longitude`, `jarak_meter`, `is_valid_geofence`, `scanned_at`).
13. **`notifications`**: Notifikasi in-app untuk pembaruan status berkas petani (`id`, `user_id`, `judul`, `pesan`, `is_read`, `created_at`).

### 🛡️ B. Keamanan & Autentikasi (Bcrypt & JWT)
- **Password Hashing**: Menggunakan modul Python `passlib[bcrypt]` dengan salt 12 rounds.
- **Stateless Authorization**: Menggunakan standard `OAuth2PasswordBearer` + **JSON Web Token (JWT)** dengan algoritma `HS256`, masa kedaluwarsa 24 jam.
- **Strict Role Enforcement**: Middleware `Depends(get_current_active_user)` yang memeriksa role aktor sebelum memproses request ke database.

### ⚙️ C. State Machine Siklus Hidup Pengajuan (12 Status)
Siklus berkas dikelola dengan ketat mencegah loncatan tahapan:
`DIAJUKAN` $\rightarrow$ `MENUNGGU_VERIFIKASI_BERKAS` $\rightarrow$ `BERKAS_TERVERIFIKASI` $\rightarrow$ `DITUGASKAN_KE_PPL` $\rightarrow$ `SURVEI_LAPANGAN` $\rightarrow$ `MENUNGGU_PERSETUJUAN_AKHIR` $\rightarrow$ `DISETUJUI` $\rightarrow$ `DIJADWALKAN_DISTRIBUSI` $\rightarrow$ `TERSALURKAN`  
*(Dilengkapi penanganan percabangan error: `PERLU_PERBAIKAN_BERKAS`, `DITOLAK_BERKAS`, dan `DITOLAK_LAPANGAN`)*.

### 📍 D. Modul Geofencing GPS (Formula Haversine)
Untuk mencegah penyelewengan pupuk subsidi di luar lahan yang berhak, backend mengimplementasikan kalkulasi jarak geografis Haversine:
$$d = 2R \arcsin\left(\sqrt{\sin^2\left(\frac{\Delta \phi}{2}\right) + \cos(\phi_1)\cos(\phi_2)\sin^2\left(\frac{\Delta \lambda}{2}\right)}\right)$$
- Toleransi radius geofencing diatur **50 s.d. 100 meter** dari titik tengah sawah terdaftar petani.
- Jika petani memindai karung di sawah $\le 50\text{ m}$, status: `VALID (Pembukaan Berhasil)`.
- Jika karung dipindai di luar sawah (misal di rumah/gudang penimbun), status: `DITOLAK (Di Luar Lahan Terdaftar)`.

### 🌐 E. Daftar Endpoint RESTful API Utama yang Sudah Aktif:
- `POST /api/auth/register` & `POST /api/auth/login` (Autentikasi & Registrasi NIK).
- `GET /api/farmers/me` & `PUT /api/farmers/me` (Profil Petani & Kelompok Tani).
- `GET /api/lands` & `POST /api/lands` (Pengelolaan Lahan Pertanian).
- `POST /api/applications` & `GET /api/applications` (Pengajuan Subsidi & Tracking Status).
- `GET /api/admin/applications/queue` & `POST /api/admin/applications/{id}/verify` (Meja Verifikasi Admin Dinas).
- `POST /api/admin/applications/{id}/assign-ppl` & `POST /api/admin/applications/{id}/approve` (Disposisi PPL & Final Approval).
- `POST /api/ppl/applications/{id}/submit-survey` (Submit Berita Acara Survei Sawah PPL).
- `POST /api/kiosk/redeem-qr` (Pemindaian kupon voucher pupuk di kios rekanan resmi).
- `POST /api/distributions/scan-qr` & `GET /api/distributions/scans/my` (Validasi pembukaan sak pupuk di sawah).

---

# 3. BEDAH TEKNIS MENDALAM: FRONTEND WEB

### ⚛️ A. Arsitektur & Teknologi Frontend
- **Framework**: React 19 + Vite 6 + Tailwind CSS 3.4.
- **Routing & Guard**: React Router DOM v7 dengan implementasi `<ProtectedRoute allowedRoles={[...]} />`.
- **Ikonografi & Visual**: Lucide Icons + Heroicons + Gradient Emerald Palette khas Mojokerto.
- **Networking**: Axios Client dengan interceptor otomatis penyisipan header `Authorization: Bearer <token>`.

### 🏢 B. Detail 4 Portal Antarmuka Pengguna:

#### 1. Portal Petani (`PetaniDashboard.jsx`):
- **4 Kartu KPI Atas**: Menampilkan sisa kuota Urea (kg), kuota NPK (kg), total pengajuan aktif, dan jumlah pupuk terpakai.
- **8 Tab Navigasi Terpadu**:
  1. `Dashboard`: Ringkasan kuota visual chart + 2 kartu status pengajuan terkini.
  2. `Profil Saya`: Informasi KTP, Poktan, kontak, dan alamat.
  3. `Data Lahan`: Galeri lahan sawah terdaftar + tombol tambah lahan baru.
  4. `Pengajuan Subsidi`: Formulir pemilihan lahan, komoditas, jenis pupuk, dan tonase pengajuan.
  5. `Status Pengajuan`: 6-stage connected stepper status pengajuan lengkap.
  6. `Kuota Pupuk`: Grafik persentase batas kuota musim tanam berjalan.
  7. `Pembukaan Pupuk`: Antarmuka scanner kamera karung pupuk berbasis radius GPS sawah.
  8. `Riwayat Pembukaan`: Tabel audit log riwayat karung pupuk yang telah dibuka di sawah.
- **Voucher QR Code Modal**: Menampilkan kode QR resmi ber-hash unik untuk dibawa petani ke kios resmi.

#### 2. Portal Admin Dinas Pertanian (`AdminDashboard.jsx`):
- Meja kerja verifikasi berkas masuk dengan tabulasi antrean: `Semua`, `Verifikasi`, `Penugasan PPL`, `Approval Akhir`.
- Modal detail pengajuan lengkap dengan preview foto KTP dan foto lahan.
- Dropdown penugasan petugas PPL berdasarkan wilayah kecamatan setempat di Mojokerto.
- Tombol aksi terintegrasi: *Setujui Berkas*, *Minta Perbaikan Dokumen*, dan *Tolak Pengajuan*.

#### 3. Portal Petugas Lapangan PPL (`PPLDashboard.jsx`):
- Antrean tugas survei lapangan yang didisposisikan oleh dinas.
- Formulir evaluasi teknis: kesesuaian petak sawah, fase vegetatif/generatif tanaman, dan rekomendasi tonase pupuk yang disetujui.
- Pengambilan foto bukti lahan faktual langsung dari lapangan.

#### 4. Portal Kios Resmi Pengecer (`QRScannerKiosk.jsx`):
- Antarmuka pemindai kamera HTML5 untuk memvalidasi voucher QR petani.
- Pengecekan real-time kesesuaian alokasi jenis pupuk dan pencatatan transaksi penebusan pupuk.

---

# 4. BEDAH TEKNIS MENDALAM: MOBILE APPLICATION (FLUTTER)

### 📱 A. Arsitektur Kode Flutter (`mobile/lib/`)
Aplikasi mobile dibangun menggunakan **Flutter 3.x (Dart 3)** dengan pendekatan arsitektur bersih (*Clean Architecture Pattern*):
```text
mobile/lib/
├── config/             # Konfigurasi endpoint API base URL & konstanta warna
│   └── api_config.dart
├── models/             # Data class model dengan serialisasi JSON to/from
│   ├── auth_model.dart
│   ├── subsidy_models.dart   # FarmerProfile, Land, Application, Distribution, ScanHistory
│   └── ppl_task_model.dart
├── services/           # HTTP Request Layer (SubsidyService & AuthService)
│   ├── auth_service.dart
│   └── subsidy_service.dart
└── screens/            # Layar Antarmuka Pengguna
    ├── auth/           # Login & Register Screen
    ├── petani/         # PetaniDashboardScreen (8 Tab Terpadu)
    └── ppl/            # PPLDashboardScreen & SatelliteMeasureScreen
```

### 🎨 B. Keselarasan Desain 100% dengan Web (UI/UX Alignment)
Aplikasi Flutter Petani telah diselaraskan penuh dengan versi Web agar petani merasakan pengalaman visual yang identik:
1. **Custom AppBar Resmi**:
   - Ikon logo kecambah (*Sprout*) dengan warna primer `#009B69`.
   - Brand title `E-PUPUK` + chip badge hijau `KAB. MOJOKERTO`.
   - Subtitle: *Sistem Subsidi & Distribusi Pupuk*.
   - Lonceng notifikasi ber-badge angka merah (`1`), inisial avatar petani, dan tombol logout.
2. **Top Banner Khas Mojokerto**:
   - Background **Dark Emerald pekat (`#064E3B`)** dengan rounded border 22px.
   - Chip badge: `PORTAL PETANI & KELOMPOK TANI KABUPATEN MOJOKERTO`.
   - Salam sambutan dinamis: *Selamat Datang, [Nama Petani]!*
3. **8 Tab Pill Navigation Horizontal**:
   - Tersusun dalam container putih ber-border halus dengan scroll horizontal lembut (*BouncingScrollPhysics*).
   - Urutan tab identik: `Dashboard`, `Profil Saya`, `Data Lahan`, `Pengajuan Subsidi`, `Status Pengajuan`, `Kuota Pupuk`, `Pembukaan Pupuk`, `Riwayat Pembukaan`.
   - Tab khusus **`Pembukaan Pupuk`**: Dibalut border emerald halus (`#34D399`), background hijau muda (`#ECFDF5`), dan **indikator titik bulat hijau (`•`)**.
4. **4 Kartu KPI Ringkasan**:
   - Menampilkan angka sisa kuota Urea, sisa kuota NPK, pengajuan aktif, dan pupuk digunakan dalam grid 2x2 responsif.
5. **6-Stage Horizontal Connected Progress Stepper**:
   - Jalur garis penghubung horizontal kontinu dengan ketebalan **2.5px** (Hijau `#009B69` untuk tahap terlewati/aktif, Abu-abu `#E2E8F0` untuk tahap pending).
   - Checkpoint lingkaran node (26x26px):
     - **Tahap Selesai (1 s.d. 4)**: Lingkaran hijau penuh dengan centang putih (`✓`).
     - **Tahap Aktif (Tahap 5 - Persetujuan Admin)**: Lingkaran **Biru Cerah (`#2563EB`)** dengan ikon medali pita (*Award Ribbon*) dan cincin cahaya biru muda (*halo glow ring*).
     - **Tahap Pending (Tahap 6 - Penggunaan Pupuk)**: Lingkaran putih border abu-abu dengan ikon kotak kardus/karung pupuk.
   - Menggunakan `LayoutBuilder` & `SingleChildScrollView` horizontal (`minWidth: 560px`) sehingga garis tetap panjang, lebar, dan proporsional persis di web tanpa gepeng di layar HP sempit.
6. **Modul Pembukaan Pupuk & Riwayat Scan**:
   - Alur 4 tahap pembukaan pupuk fisik di petak sawah.
   - Dialog kamera scanner dengan batas toleransi radius geofencing GPS 50 meter.
   - Tab riwayat pembukaan dengan rincian waktu dan badge status *GPS Valid*.
7. **Solusi Zero-Overflow Layout**:
   - Memperbaiki bug *RenderFlex overflow 132 pixels* pada AppBar dan KPI Cards dengan menerapkan `Expanded`, `Flexible`, dan `TextOverflow.ellipsis`.

---

# 5. INFRASTRUKTUR DOCKER & AKUN UJI COBA DEMO LIVE

### 🐳 A. Stack Kontainer Docker Compose:
Sistem dapat dijalankan dengan sekali perintah `docker compose up -d`:
1. `epupuk-db`: MySQL 8.0 Engine (Port 3306) dengan penyimpanan data permanen (*persistent volume*).
2. `epupuk-phpmyadmin`: GUI Web Database (Port 8080) untuk inspeksi tabel langsung.
3. `epupuk-backend`: FastAPI Python 3.12 (Port 8000) dengan live-reload Uvicorn.
4. `epupuk-frontend`: React 19 + Nginx Reverse Proxy (Port 80).

### 👥 B. Akun Seed Data Siap Demo Langsung:
| Peran Portal | Username | Password | Skenario Alur yang Dapat Didemokan Langsung |
| :--- | :--- | :--- | :--- |
| **Admin Dinas** | `admin` | `admin123` | Audit berkas petani, disposisi tugas ke PPL, dan final approval persetujuan pupuk |
| **Petugas PPL** | `ppl_ahmad` | `ppl123` | Menerima tugas disposisi, evaluasi kondisi faktual sawah, dan input rekomendasi |
| **Petani 1** | `petani_budi` | `petani123` | Melacak berkas pengajuan aktif pada Stepper 6 tahapan & sisa kuota RDKK |
| **Petani 2** | `petani_siti` | `petani123` | Menampilkan kupon digital QR Code penebusan dan simulasi buka karung di sawah |
| **Kios Rekanan**| `kios_tani` | `kios123` | Memindai voucher kupon QR petani menggunakan kamera pemindai resmi |

---

# 6. ROADMAP PEKERJAAN SISA (BOBOT 30%)

Sisa 30% dialokasikan secara objektif untuk penyempurnaan kualitas teknis, otomasi pelaporan, dan kesiapan rilis produksi:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                   ROADMAP SISA PEKERJAAN (30.0%)                       │
│                                                                        │
│   [1] Automated Testing Pytest & QA Hardening     : 10.0% (Pekan 7)    │
│   [2] Penyempurnaan Fitur Mobile PPL Offline      :  9.0% (Pekan 8)    │
│   [3] Ekspor Dokumen Resmi Cetak PDF & Excel      :  6.0% (Pekan 8)    │
│   [4] Deployment Staging Cloud VPS & Domain SSL   :  3.0% (Pekan 8)    │
│   [5] Integrasi WhatsApp Notification Gateway     :  2.0% (Pekan 8)    │
└────────────────────────────────────────────────────────────────────────┘
```

1. **Automated Testing Suite (Pytest - 10.0%)**:
   - Penyusunan skrip unit test otomatis (`test_auth.py`, `test_quota_calculation.py`, `test_geofence.py`).
   - Penjaminan *code coverage* backend minimal 80% sebelum rilis.
2. **Fitur Lanjutan Mobile Flutter (9.0%)**:
   - Integrasi kamera native Android (camera controller) untuk scan QR karung dan sinkronisasi formulir survei PPL saat sinyal sawah minim (*offline SQLite cache*).
3. **Ekspor Laporan Resmi Cetak (PDF & Excel - 6.0%)**:
   - Otomasi pencetakan Surat Keputusan (SK) Alokasi Pupuk berformat PDF (menggunakan pustaka Python `ReportLab`).
   - Ekspor rekapitulasi distribusi bulanan ke lembar kerja Excel (`OpenPyXL`) untuk arsip Dinas Pertanian.
4. **Deployment Cloud VPS & Domain Publik (3.0%)**:
   - Setup reverse proxy Nginx publik di Cloud VPS + konfigurasi domain resmi dan sertifikat SSL Let's Encrypt (HTTPS).
5. **Gateway Notifikasi WhatsApp (2.0%)**:
   - Webhook notifikasi pesan WhatsApp otomatis ke nomor HP petani saat permohonan disetujui atau pupuk siap ditebus di kios.

---

# 7. STRUKTUR 10 SLIDE PPT & NASKAH PRESENTASI KE DOSEN

Berikut panduan slide per slide beserta **naskah ucapan (*speaker notes*)** yang dibacakan di hadapan dosen penguji:

---

### 🖥️ SLIDE 1: JUDUL & IDENTITAS PROYEK
- **Tampilan Slide**: Logo PENS + Logo E-PUPUK Kabupaten Mojokerto, Judul Proyek, Nama Tim, NRP, Dosen Pengampu, dan Capaian **70.0%**.
- **Naskah Presentasi**:
  > *"Selamat pagi/siang Bapak/Ibu dosen penguji. Kami dari tim E-PUPUK Kabupaten Mojokerto, beranggotakan saya Syarifatullah Ceva Efendy sebagai Frontend & Mobile Developer, dan rekan saya Selby Wafi Nurjuan sebagai Backend Developer, di bawah bimbingan Bapak Amma Liesvarastranta Haz. Hari ini kami akan mempresentasikan laporan kemajuan proyek minggu ke-6 dengan capaian sistem saat ini sebesar 70.0%, di mana seluruh alur bisnis inti dari pendaftaran petani hingga penebusan pupuk di kios sudah selesai dan berjalan penuh di Docker."*

---

### 🖥️ SLIDE 2: RINGKASAN EKSEKUTIF & PEMBOBOTAN REALISTIS (70%)
- **Tampilan Slide**: Tabel matriks bobot riil (Database 90%, Backend 75%, Frontend 78%, Mobile 80%, Testing 16.7%). Total akumulasi: 70%.
- **Naskah Presentasi**:
  > *"Kami melaporkan kemajuan 70.0% secara objektif dan transparan. Database relasional MySQL telah selesai 90%, Backend API FastAPI telah mencapai 75%, Frontend Web 78%, dan Aplikasi Mobile Flutter 80%. Kami sengaja membedakan secara tegas antara fungsionalitas alur bisnis utama yang sudah 100% selesai, dengan 30% sisa yang difokuskan pada pemenuhan standar non-fungsional industri seperti automated testing, cetak laporan resmi, dan deployment cloud publik."*

---

### 🖥️ SLIDE 3: ALUR BISNIS END-TO-END AKTIF
- **Tampilan Slide**: Diagram alur 6 tahap hulu-ke-hilir: Registrasi NIK $\rightarrow$ Pengajuan Kuota $\rightarrow$ Verifikasi Admin $\rightarrow$ Survei Lapangan PPL $\rightarrow$ Persetujuan Akhir $\rightarrow$ Penebusan QR Kios.
- **Naskah Presentasi**:
  > *"Bisa dilihat pada diagram, alur sistem E-PUPUK dari hulu ke hilir sudah terhubung nyata tanpa putus. Dimulai dari pendaftaran petani dengan validasi NIK 16 digit anti-duplikasi, pengajuan subsidi berbasis kuota RDKK, verifikasi berkas oleh Admin Dinas, survei fisik sawah dan geotagging koordinat oleh PPL, persetujuan akhir penerbitan SK alokasi, hingga pemindaian voucher QR digital di kios rekanan resmi."*

---

### 🖥️ SLIDE 4: PENCAPAIAN BACKEND & DATABASE (SELBY WAFI NURJUAN)
- **Tampilan Slide**: Python 3.12, FastAPI, MySQL 8.0 (13 Tabel), Bcrypt & JWT Auth, State Machine 12 Status, dan Formula Geofencing Haversine.
- **Naskah Presentasi**:
  > *"Di sisi backend, telah dibangun arsitektur database relasional MySQL 8.0 dengan 13 tabel ternormalisasi dan GUI phpMyAdmin terisolasi di Docker. Keamanan menggunakan enkripsi Bcrypt dan token JWT dengan strict role authorization. Backend juga dilengkapi state machine 12 status siklus berkas serta algoritma Geofencing Haversine dengan toleransi radius 50 meter untuk memvalidasi bahwa sak pupuk benar-benar dibuka oleh petani di petak sawah terdaftarnya."*

---

### 🖥️ SLIDE 5: PENCAPAIAN FRONTEND WEB (SYARIFATULLAH CEVA EFENDY)
- **Tampilan Slide**: React 19, Vite, Tailwind CSS, Strict Multi-Portal Guard (Admin Dinas, PPL, Petani, Kios Scanner).
- **Naskah Presentasi**:
  > *"Di sisi frontend web, kami membangun sistem berbasis React 19 dan Tailwind CSS dengan pengamanan Strict Multi-Portal Guard yang mencegah kebocoran hak akses antar aktor. Terdapat portal mandiri Petani dengan 4 kartu KPI kuota, meja kerja audit Admin Dinas untuk penugasan PPL dan persetujuan berkas, portal PPL untuk input evaluasi kondisi sawah, serta kios scanner berbasis kamera HTML5 untuk memvalidasi voucher QR penebusan pupuk."*

---

### 🖥️ SLIDE 6: PENCAPAIAN MOBILE APP FLUTTER (SYARIFATULLAH CEVA EFENDY)
- **Tampilan Slide**: Screenshot Flutter Mobile Petani: AppBar Mojokerto, Banner Dark Emerald, 8 Tab Navigasi, 6-Stage Connected Stepper (Node Biru Award Ribbon), dan Modul Pembukaan Pupuk GPS.
- **Naskah Presentasi**:
  > *"Untuk memfasilitasi kebutuhan mobilitas petani di persawahan, kami telah membangun aplikasi mobile Flutter yang diselaraskan 100% dengan versi web. Memiliki 8 tab navigasi horizontal lengkap, 4 kartu KPI ringkasan, dan 6-stage connected progress stepper responsif dengan garis kontinu dan ikon penghargaan. Aplikasi ini juga telah dilengkapi modul Pembukaan Pupuk berbasis GPS Geofencing dan riwayat pemindaian karung pupuk resmi."*

---

### 🖥️ SLIDE 7: INFRASTRUKTUR DOCKER & KESIAPAN DEMO
- **Tampilan Slide**: Arsitektur Docker Compose (4 Service: `db`, `phpmyadmin`, `backend`, `frontend`) + Tabel 4 Akun Demo (`admin`, `ppl_ahmad`, `petani_budi`, `petani_siti`).
- **Naskah Presentasi**:
  > *"Seluruh sistem telah dikontainerisasi menggunakan Docker Compose yang terdiri dari 4 service terisolasi. Sistem ini dilengkapi data seed realistis dengan 4 akun uji coba siap pakai: akun Admin Dinas, petugas PPL, petani dalam proses verifikasi, serta petani yang sudah mengantongi voucher QR siap tebus. Semua siap didemokan langsung hari ini."*

---

### 🖥️ SLIDE 8: ROADMAP SISA PEKERJAAN (ALOKASI BOBOT 30%)
- **Tampilan Slide**: Tabel alokasi sisa 30%: Pytest (10%), Fitur Mobile Offline (9%), Cetak PDF/Excel (6%), Cloud VPS (3%), WhatsApp Gateway (2%).
- **Naskah Presentasi**:
  > *"Sisa 30% pekerjaan kami petakan secara terukur menuju rilis penuh: Pekan ke-7 difokuskan pada pembuatan automated unit testing Pytest untuk mencapai standar QA. Pekan ke-8 difokuskan pada fitur offline mobile PPL, otomasi cetak SK alokasi PDF dan rekapitulasi Excel dinas, deployment ke Cloud VPS publik ber-SSL HTTPS, serta integrasi webhook notifikasi WhatsApp."*

---

### 🖥️ SLIDE 9: STRATEGI & ARGUMEN SAAT TANYA JAWAB DOSEN
- **Tampilan Slide**: Ringkasan argumen kesiapan sistem dan perbedaan antara fungsi alur bisnis vs kesiapan rilis produksi multi-platform.
- **Naskah Presentasi**:
  > *"Jika ditanyakan mengapa kami melaporkan 70%, kami tegaskan bahwa alur bisnis fungsional dari awal pengajuan hingga pupuk diterima di kios sudah 100% selesai dan teruji secara live. Namun kami membedakan secara jujur dan profesional antara fungsionalitas yang jalan di lingkungan lokal dengan kesiapan produksi penuh seperti automated test suite, cetak arsip dinas, dan hosting publik."*

---

### 🖥️ SLIDE 10: PENUTUP & PEMBUKAAN DEMO LANGSUNG
- **Tampilan Slide**: Ucapan terima kasih, sesi tanya jawab, dan pembukaan layar live demo sistem berdampingan (Web Admin & Mobile Petani).
- **Naskah Presentasi**:
  > *"Demikian presentasi laporan kemajuan minggu ke-6 proyek E-PUPUK Kabupaten Mojokerto. Sekarang kami siap mendemonstrasikan sistem secara langsung di layar dan membuka sesi tanya jawab dengan Bapak/Ibu dosen penguji. Terima kasih."*
