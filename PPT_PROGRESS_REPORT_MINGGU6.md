---
marp: true
theme: default
paginate: true
backgroundColor: "#0f172a"
color: "#f1f5f9"
style: |
  section {
    font-family: 'Segoe UI', sans-serif;
    background: linear-gradient(135deg, #0f172a 0%, #14532d 100%);
  }
  h1, h2, h3 { color: #86efac; }
  .lead { text-align: center; }
  table { width: 100%; border-collapse: collapse; font-size: 0.85em; }
  th, td { border: 1px solid #334155; padding: 7px 10px; text-align: left; }
  th { background-color: #1e293b; color: #86efac; }
  strong { color: #fbbf24; }
  ul { line-height: 1.45; }
  .badge { background: #065f46; color: #6ee7b7; padding: 2px 8px; border-radius: 9999px; font-size: 0.75em; font-weight: bold; }
  .badge-red { background: #7f1d1d; color: #fca5a5; padding: 2px 8px; border-radius: 9999px; font-size: 0.75em; font-weight: bold; }
---

<!-- SLIDE 1 -->
<!-- _class: lead -->
# LAPORAN KEMAJUAN PROYEK (MINGGU KE-6)
## WORKSHOP PEMROGRAMAN FRAMEWORK — D3 TI PENS PSDKU LAMONGAN

### SISTEM TERPADU PENGAJUAN & DISTRIBUSI PUPUK BERSUBSIDI
# E-PUPUK KABUPATEN MOJOKERTO

**Status Capaian: 70.0% (Core Workflow Complete & Dockerized)**

**Frontend & Mobile App** : Syarifatullah Ceva Efendy (NRP: 312521002)  
**Backend & Database** : Selby Wafi Nurjuan (NRP: 3125521018)  
**Dosen Pengampu** : Amma Liesvarastranta Haz, S.Tr.T., M.T.  
*Tahun Akademik 2026*

---

<!-- SLIDE 2 -->
## RINGKASAN EKSEKUTIF PROGRES SISTEM (70%)

Sistem **E-PUPUK** telah mencapai tahapan **70.0% (Core Workflow Complete)**. Seluruh alur bisnis inti dari hulu ke hilir telah terhubung nyata: registrasi petani NIK 16 digit, pengajuan subsidi kuota, verifikasi admin dinas, survei lapangan PPL, hingga validasi QR penebusan.

| Dimensi Sistem | Bobot | Capaian Riil | Kontribusi | Status Operasional |
| :--- | :---: | :---: | :---: | :--- |
| **Database & Migrasi** | 15% | **90.0%** | **13.5%** | <span class="badge">100% Aktif</span> MySQL 8.0 & phpMyAdmin |
| **Backend API FastAPI** | 30% | **75.0%** | **22.5%** | <span class="badge">Core Live</span> CRUD, Auth, Geofencing & QR |
| **Frontend Web React 19** | 25% | **78.0%** | **19.5%** | <span class="badge">Multi-Portal</span> Guard 3 Aktor Berfungsi Penuh |
| **Docker & Lingkungan Dev** | 15% | **80.0%** | **12.0%** | <span class="badge">Dockerized</span> 4 Kontainer + Dev Hot-Reload |
| **Testing Otomatis & QA** | 15% | **16.7%** | **2.5%** | <span class="badge-red">Manual QA</span> Alur end-to-end teruji manual |
| **TOTAL AKUMULASI** | **100%** | — | **70.0%** | **70% MVP MATANG & SIAP DIDEMOKAN** |

---

<!-- SLIDE 3 -->
## ALUR END-TO-END YANG SUDAH 100% AKTIF

```text
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│ 1. Petani       │  ───> │ 2. Pengajuan    │  ───> │ 3. Verifikasi   │
│ Registrasi NIK  │       │ Subsidi Pupuk   │       │ Berkas (Admin)  │
└─────────────────┘       └─────────────────┘       └─────────────────┘
                                                             │
┌─────────────────┐       ┌─────────────────┐                ▼
│ 6. Penebusan &  │  <─── │ 5. Final        │  <─── ┌─────────────────┐
│ Scan QR Kios    │       │ Approval Admin  │       │ 4. Survei Sawah │
└─────────────────┘       └─────────────────┘       │ & GPS oleh PPL  │
                                                    └─────────────────┘
```

- **Pendaftaran Mandiri Petani**: Wajib NIK 16 digit anti-duplikasi & upload e-KTP.
- **Validasi Kuota RDKK**: Menghitung alokasi Urea & NPK per kelompok tani (Poktan).
- **Disposisi & Survei PPL**: Evaluasi fisik tanaman, kesesuaian lahan, dan geotagging GPS.
- **Kupon QR Digital**: Diterbitkan otomatis pasca persetujuan akhir dinas.

---

<!-- SLIDE 4 -->
## PROGRESS MINGGUAN : BACKEND & DATABASE

### Pengembang: Selby Wafi Nurjuan

1. **Arsitektur Database Relasional MySQL 8.0 & phpMyAdmin (Port 8080)**:
   - 13 tabel relasional ternormalisasi (`users`, `farmers`, `lands`, `applications`, `surveys`, `distributions`, `qr_scans`, dll).
2. **Keamanan Autentikasi & Hashing**:
   - JSON Web Token (JWT) + enkripsi kata sandi menggunakan **Bcrypt**.
   - Strict role authorization mencegah eskalasi hak akses antar aktor.
3. **Engine Siklus Pengajuan (12 Status Transisi)**:
   - Manajemen transisi status dari `DIAJUKAN`, `SURVEI_LAPANGAN`, `DISETUJUI`, hingga `TERSALURKAN`.
4. **Modul Geofencing GPS & Scanner QR Karung**:
   - Endpoint `/api/distributions/scan-qr` mencatat koordinat pembukaan sak pupuk di sawah.
   - Endpoint `/api/distributions/scans/my` untuk rekapitulasi audit log penebusan.

---

<!-- SLIDE 5 -->
## PROGRESS MINGGUAN : FRONTEND WEB

### Pengembang: Syarifatullah Ceva Efendy

1. **Strict Multi-Portal Guard (React 19 & React Router v7)**:
   - Isolasi ketat halaman: Petani dilarang mengakses meja Admin, dan sebaliknya.
2. **Dashboard Mandiri Petani (`PetaniDashboard.jsx`)**:
   - 4 Kartu KPI: Sisa Kuota Urea (kg), Kuota NPK (kg), Pengajuan Aktif, dan Pupuk Digunakan.
   - 8 Tab Menu Terpadu: Dashboard, Profil, Lahan, Pengajuan, Stepper Status, Kuota, Pembukaan, Riwayat.
3. **Dashboard Admin Dinas Pertanian (`AdminDashboard.jsx`)**:
   - Meja verifikasi berkas, filter kelompok tani Mojokerto, disposisi PPL, & final approval.
4. **Dashboard Petugas PPL & Scanner Kios (`PPLDashboard.jsx`, `QRScannerKiosk.jsx`)**:
   - Formulir survei kondisi tanaman di lapangan & kamera pemindai voucher QR di kios.

---

<!-- SLIDE 6 -->
## PROGRESS BARU : APLIKASI MOBILE FLUTTER

### Penyelarasan Penuh Mobile Petani (`mobile/lib/screens/petani/`)

Untuk mendukung kebutuhan mobilitas petani di lapangan, telah dibangun aplikasi **Flutter**:

* **8 Tab Navigasi Horizontal**: Selaras 100% dengan antarmuka web (*Dark Emerald `#064E3B`*).
* **6-Stage Progress Stepper**: Melacak status tahapan berkas secara real-time langsung dari HP.
* **Fitur Geofencing GPS & Scanner QR Karung Pupuk Fisik**:
  * Menghitung jarak Haversine lokasi HP ke titik koordinat sawah (toleransi radius 100m).
  * Dilengkapi simulator demo interaktif: **`[✓ Di Sawah (18m)]`** dan **`[✕ Luar (850m)]`**.
  * Viewfinder kamera & input token verifikasi pembukaan karung pupuk resmi.
* **Perbaikan Git Tracking**: Pemulihan konfigurasi `.gitignore` sehingga seluruh kode Flutter tersinkronisasi aman di repositori Git.

---

<!-- SLIDE 7 -->
## KONTAINERISASI DOCKER & KESIAPAN DEMO

Sistem telah berjalan penuh di lingkungan kontainer Docker terisolasi:

```text
[ Docker Compose Stack ]
 ├── epupuk-db         : MySQL 8.0 (Port 3306 - Persistent Volume)
 ├── epupuk-phpmyadmin : phpMyAdmin GUI (Port 8080)
 ├── epupuk-backend    : FastAPI Python 3.12 (Port 8000 + Uvicorn Live-Reload)
 └── epupuk-frontend   : React 19 + Nginx Production (Port 80)
```

### Akun Bawaan Siap Demo (Seed Data):
- **Admin Dinas**: `admin` / `admin123` *(Verifikasi berkas & final approval)*
- **Petugas PPL**: `ppl_ahmad` / `ppl123` *(Evaluasi kondisi sawah & rekomendasi)*
- **Petani 1**: `petani_budi` / `petani123` *(Pengajuan sedang diproses dinas)*
- **Petani 2**: `petani_siti` / `petani123` *(Voucher QR alokasi pupuk siap dicairkan)*

---

<!-- SLIDE 8 -->
## ROADMAP SISA PEKERJAAN (ALOKASI BOBOT 30%)

Sisa 30% difokuskan pada pemenuhan standar kualitas perangkat lunak menuju rilis penuh:

| No | Modul / Pekerjaan Tertunda | Bobot Sisa | Target | Rencana Penyelesaian |
| :-: | :--- | :---: | :---: | :--- |
| **1** | **Automated Testing Suite (Pytest)** | **10.0%** | Pekan 7 | Penyusunan unit test otomatis autentikasi & kalkulasi kuota |
| **2** | **Aplikasi Mobile Flutter (Petani & PPL)** | **9.0%** | Pekan 8 | Form survei lapangan PPL offline & kamera scanner Android |
| **3** | **Ekspor Laporan Resmi (PDF & Excel)** | **6.0%** | Pekan 8 | Otomasi rekapitulasi data cetak via ReportLab & OpenPyXL |
| **4** | **Deployment Cloud VPS & Domain** | **3.0%** | Pekan 8 | Setup reverse proxy Nginx publik & sertifikat SSL Let's Encrypt |
| **5** | **WhatsApp Notification Gateway** | **2.0%** | Pekan 8 | Integrasi webhook pengingat pengambilan pupuk di kios |

---

<!-- SLIDE 9 -->
## ARGUMEN KUNCI SAAT EVALUASI DOSEN

> *"Sistem E-PUPUK saat ini berada di capaian **70.0%**. Kami sengaja tidak mengklaim 90-100% karena kami membedakan secara tegas antara **fungsionalitas alur bisnis web yang sudah 100% selesai dan teruji di Docker** dengan **kesiapan produksi multi-platform penuh**.*  
> 
> *Alur bisnis utama dari registrasi NIK 16 digit, survei lapangan PPL, hingga pemindaian voucher di kios sudah 100% berfungsi. Sisa 30% dialokasikan secara objektif untuk: penyelesaian fitur lanjutan **Aplikasi Mobile (Flutter)**, pembuatan **automated testing Pytest**, ekspor cetak **PDF/Excel**, serta deployment ke **server VPS publik**."*

---

<!-- SLIDE 10 -->
<!-- _class: lead -->
# TERIMA KASIH
### ATAS PERHATIAN BAPAK/IBU DOSEN PENGUJI

**E-PUPUK KABUPATEN MOJOKERTO**  
*Sistem Terpadu Pengajuan & Distribusi Pupuk Bersubsidi Tepat Sasaran*

**Syarifatullah Ceva Efendy & Selby Wafi Nurjuan**  
D3 Teknik Informatika PSDKU Lamongan  
Politeknik Elektronika Negeri Surabaya — 2026

*SESI TANYA JAWAB & DEMO SISTEM DIBUKA*
