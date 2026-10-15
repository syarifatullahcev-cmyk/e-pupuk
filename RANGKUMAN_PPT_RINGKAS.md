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

### SLIDE 4: PENCAPAIAN BACKEND (SELBY WAFI)
* **Framework**: FastAPI (Python 3.12) + SQLAlchemy + MySQL 8.0.
* **Autentikasi Aman**: Hash password Bcrypt + Token JWT (HS256) 24 jam.
* **13 Tabel Database**: `users`, `farmers`, `lands`, `applications`, `surveys`, `distributions`, dll.
* **Fitur Utama**:
  * Engine status berkas (12 tahapan dari `DIAJUKAN` s.d `TERSALURKAN`).
  * Formula Haversine untuk validasi jarak pembukaan karung pupuk di petak sawah.
  * Validasi upload foto KTP dan lahan sawah (maksimal 5MB).

---

### SLIDE 5: PENCAPAIAN FRONTEND WEB (CEVA EFENDY)
* **Stack**: React 19, Vite, Tailwind CSS, Lucide Icons.
* **Strict Role Guard**: Akses portal terisolasi ketat (Admin, Petani, PPL, Kios).
* **Fitur per Portal**:
  * **Petani**: 4 Kartu KPI, 8 Tab Navigasi, pengajuan subsidi, voucher QR modal.
  * **Admin Dinas**: Meja audit berkas, filter kelompok tani Mojokerto, disposisi PPL, approval.
  * **Petugas PPL**: Antrean tugas survei & form evaluasi fisik tanaman.
  * **Kios Resmi**: Kamera scanner HTML5 untuk penebusan pupuk instan.

---

### SLIDE 6: PENCAPAIAN MOBILE FLUTTER (CEVA EFENDY)
* **Stack**: Flutter 3.x (Dart 3), Clean Architecture.
* **Desain 100% Selaras Web**:
  * AppBar resmi Mojokerto & Banner Dark Emerald `#064E3B`.
  * **8 Tab Navigasi**: Dashboard, Profil, Lahan, Pengajuan, Status, Kuota, Pembukaan Pupuk, Riwayat.
  * **6-Stage Connected Stepper**: Garis hijau horizontal tebal 2.5px, lingkaran centang, & node biru medali penghargaan (*Award Ribbon*).
  * **Pembukaan Pupuk**: Dialog kamera scanner QR dengan radius GPS geofencing sawah.
  * **Satelit Ukur Lahan PPL**: Pengukuran luas sawah dengan citra satelit ArcGIS & GPS.
  * **Bebas Overflow**: Layout responsif bebas error *RenderFlex overflow*.

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
