# 📑 RANGKUMAN SLIDE PPT — E-PUPUK KAB. MOJOKERTO
> **Status**: 70% Selesai (Core Workflow Live) | **Tim**: Ceva (Frontend & Flutter) & Selby (Backend)

---

### SLIDE 1: JUDUL & TIM
* **Judul**: E-PUPUK KABUPATEN MOJOKERTO
* **Subjudul**: Sistem Pengajuan & Distribusi Pupuk Bersubsidi Berbasis Geofencing GPS
* **Tim**: Syarifatullah Ceva Efendy & Selby Wafi Nurjuan
* **Dosen Pengampu**: Amma Liesvarastranta Haz, S.Tr.T., M.T. (D3 TI PENS PSDKU Lamongan)
* **Capaian**: **70.0% (Core Workflow Complete)**

---

### SLIDE 2: PROGRESS KEMAJUAN (70%)
* **Database MySQL 8.0**: **90%** (13 Tabel, Foreign Key, phpMyAdmin)
* **Backend FastAPI**: **75%** (Auth JWT, Bcrypt, 8 Router API, Haversine GPS)
* **Frontend React 19**: **78%** (Multi-Portal Guard: Petani, Admin, PPL, Kios)
* **Mobile Flutter**: **80%** (8 Tab Navigasi, Stepper 6 Tahap, Satelit GPS PPL)
* **Testing & QA**: **16.7%** (Alur End-to-End manual 100% lancar, Pytest on progress)
* **Total Progres**: **70.0%** (Sisa 30% untuk QA otomatis, laporan PDF/Excel, & hosting VPS)

---

### SLIDE 3: ALUR SISTEM (HULU KE HILIR)
1. **Petani**: Daftar dengan NIK 16 digit & ajukan subsidi pupuk sesuai kuota.
2. **Admin Dinas**: Verifikasi berkas KTP & disposisikan tugas survei ke PPL.
3. **PPL**: Survei kondisi sawah/tanaman & input geotagging koordinat GPS.
4. **Admin Dinas**: Berikan persetujuan akhir (*Approval*) alokasi kuota pupuk.
5. **Kios**: Petani tebus pupuk menggunakan kode QR resmi.
6. **Petani di Sawah**: Buka karung pupuk divalidasi radius geofencing GPS (50m).

---

### SLIDE 4: PENCAPAIAN BACKEND & DATABASE (SELBY WAFI)
* **Stack**: FastAPI (Python 3.12) + SQLAlchemy ORM + MySQL 8.0.
* **Keamanan Data**: Enkripsi Passlib[bcrypt] (salt 12 rounds) + Stateless JWT (HS256) 24 jam.
* **13 Tabel Relasional**: `users`, `farmer_groups`, `farmers`, `commodities`, `fertilizers`, `lands`, `applications`, `field_surveys`, `fertilizer_batches`, `distributions`, `qr_scans`, `notifications`, `audit_logs`.
* **Implementasi 8 Router API RESTful**:
  * `auth.py`: Registrasi mandiri NIK 16 digit anti-duplikasi & login multi-peran.
  * `farmers.py`: Endpoint profil data petani (`/api/farmers/me`) & keanggotaan Poktan.
  * `lands.py`: CRUD data petak sawah: luas ($m^2$), status kepemilikan, dan koordinat GPS.
  * `applications.py`: Pengajuan kuota pupuk, validasi RDKK, engine status (`DIAJUKAN` $\rightarrow$ `DISETUJUI`), & ringkasan statistik (`/stats/petani`).
  * `admin.py`: Meja verifikasi berkas (`/queue`), disposisi penugasan PPL (`/assign-ppl`), & approval final (`/approve`).
  * `ppl.py`: Antrean tugas survei (`/tasks`) & submit berita acara evaluasi tanaman (`/submit-survey`).
  * `distributions.py`: Penerbitan voucher QR, validasi Geofencing GPS formula Haversine (radius toleransi 50–100m) saat buka sak pupuk, riwayat audit (`/scans/my`).
  * `files.py`: Upload foto e-KTP & foto lahan sawah (validasi MIME JPG/PNG, maks. 5MB).

---

### SLIDE 5: PENCAPAIAN FRONTEND WEB (CEVA EFENDY)
* **Stack**: React 19 + Vite 6 + Tailwind CSS 3.4 + Lucide Icons + Axios Interceptor.
* **Strict Role Guard**: Akses portal terisolasi ketat via `<ProtectedRoute />` (Admin, Petani, PPL, Kios).
* **7 Halaman Web Terintegrasi Penuh**:
  * `Landing.jsx`: Portal edukasi publik pelayanan subsidi Kabupaten Mojokerto & peta BPP.
  * `Register.jsx`: Form pendaftaran NIK 16 digit, integrasi Poktan, & upload e-KTP.
  * `Login.jsx`: Gerbang login multi-peran dengan proteksi isolasi portal otomatis.
  * `PetaniDashboard.jsx` (147 KB): 4 KPI Cards, 8 Tab Navigasi, 6-Stage Stepper visual, & Modal Voucher QR ber-hash unik.
  * `AdminDashboard.jsx` (113 KB): Meja verifikasi berkas, filter Poktan se-Mojokerto, modal audit dokumen KTP/Lahan, disposisi PPL, & tombol approval.
  * `PPLDashboard.jsx` (23 KB): Antrean tugas survei, formulir evaluasi teknis tanah/tanaman, luas aktual sawah ($m^2$), & upload bukti foto.
  * `QRScannerKiosk.jsx` (7 KB): Kamera scanner HTML5 untuk verifikasi alokasi & transaksi penebusan pupuk di kios.

---

### SLIDE 6: PENCAPAIAN MOBILE FLUTTER (CEVA EFENDY)
* **Stack**: Flutter 3.x (Dart 3) dengan pola **Clean Architecture** (`config/`, `models/`, `services/`, `screens/`).
* **Sinergi 100% Selaras Web**:
  * Custom AppBar Mojokerto (Logo kecambah `#009B69`, brand resmi, badge notifikasi `1`, avatar, logout).
  * Banner Dark Emerald (`#064E3B`) dengan chip resmi Kabupaten Mojokerto.
  * 8 Tab Pill Navigation Horizontal & 4 Kartu KPI kuota responsif.
* **6-Stage Connected Progress Stepper**:
  * Garis hijau horizontal tebal 2.5px (selesai/aktif) dan abu-abu (pending), lingkaran centang, & node biru Ribbon Award.
  * Horizontal scroll responsif (`minWidth: 560px`) bebas gepeng di layar HP.
* **Fitur Unggulan Lapangan (GPS & Satelit)**:
  * **Geofencing Buka Pupuk**: Validasi Haversine radius 100m ke sawah + simulator interaktif `[✓ Di Sawah (18m)]` vs `[✕ Luar (850m)]`.
  * **Satelit Ukur Lahan PPL**: Pengukuran luas sawah dengan citra satelit ArcGIS & polyline GPS.
  * **Zero-Overflow Layout**: Tuntas bebas error *RenderFlex overflow 132 pixels*.

---

### SLIDE 7: DOCKER & KESIAPAN DEMO
* **Stack Docker Compose**:
  * `epupuk-db` (MySQL 8.0 - Port 3306)
  * `epupuk-phpmyadmin` (GUI Database - Port 8080)
  * `epupuk-backend` (FastAPI Uvicorn - Port 8000)
  * `epupuk-frontend` (React Nginx - Port 80)
* **Akun Demo Siap Pakai**:
  * Admin: `admin` / `admin123`
  * PPL: `ppl_ahmad` / `ppl123`
  * Petani Verifikasi: `petani_budi` / `petani123`
  * Petani Siap Tebus: `petani_siti` / `petani123`

---

### SLIDE 8: ROADMAP SISA 30%
1. **Automated Testing Pytest (10%)**: Unit test API, kalkulasi kuota, & auth (Pekan 7).
2. **Fitur Mobile Offline PPL (9%)**: Form survei sawah offline cache SQLite (Pekan 8).
3. **Ekspor Dokumen Cetak (6%)**: Cetak SK PDF resmi & rekap Excel dinas (Pekan 8).
4. **Deployment Cloud VPS (3%)**: Domain publik + SSL HTTPS Nginx (Pekan 8).
5. **WhatsApp Gateway (2%)**: Notifikasi kupon terbit via nomor HP petani (Pekan 8).

---

### SLIDE 9: ARGUMEN SAAT DITANYA DOSEN
* **Pertanyaan**: *"Kenapa progresnya 70%, bukan 90% atau 100%?"*
* **Jawaban**:
  > *"Alur bisnis inti dari pendaftaran NIK, survei sawah, hingga penebusan di kios sudah **100% selesai dan teruji jalan di Docker**.*  
  > *Sisa 30% kami alokasikan secara jujur untuk standar industri: **Automated Testing Pytest**, **fitur offline mobile PPL**, **ekspor cetak PDF/Excel**, dan **hosting VPS publik**."*

---

### SLIDE 10: PENUTUP & DEMO
* **Penutup**: Terima kasih atas perhatian Bapak/Ibu dosen penguji.
* **Aksi Demo**:
  1. Tunjukkan Web Admin Dinas (Verifikasi & Approval).
  2. Tunjukkan Flutter Mobile Petani (8 Tab, Stepper Garis Hijau, & QR).
  3. Tunjukkan Web Kios (Scanner Penebusan Pupuk).
