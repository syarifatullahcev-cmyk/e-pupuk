# 📊 PANDUAN MATERI & NASKAH PRESENTASI PPT (MINGGU KE-6)
## Sistem Terpadu Pengajuan & Distribusi Pupuk Bersubsidi (E-PUPUK KAB. MOJOKERTO)

> **Status Proyek**: 70.0% (Core Workflow Complete & Dockerized)  
> **Tim Pengembang**: 
> - **Syarifatullah Ceva Efendy** (Frontend Web & Mobile Flutter)
> - **Selby Wafi Nurjuan** (Backend API & Database)  
> **Mata Kuliah**: Workshop Pemrograman Framework — D3 TI PENS PSDKU Lamongan  
> **Dosen Pengampu**: Amma Liesvarastranta Haz, S.Tr.T., M.T.

---

## 🎯 DAFTAR SLIDE YANG HARUS DIMASUKKAN KE PPT

Total ada **10 Slide** yang terstruktur, padat, dan sangat meyakinkan dosen penguji:

| No Slide | Judul Slide | Konten Utama yang Dimasukkan | Rekomendasi Gambar/Screenshot |
| :---: | :--- | :--- | :--- |
| **Slide 1** | **Judul & Identitas Proyek** | Judul E-PUPUK, Anggota Tim & NRP, Dosen Pengampu, Status Capaian **70%**. | Logo PENS + Logo E-PUPUK Mojokerto |
| **Slide 2** | **Executive Summary & Bobot 70%** | Tabel pembobotan transparan: Database (90%), Backend (75%), Frontend (78%), Docker (80%), Testing (16.7%). | Grafik Pie / Progress Bar 70% |
| **Slide 3** | **Alur Bisnis End-to-End Aktif** | 6 Langkah alur dari Hulu ke Hilir: Registrasi NIK → Pengajuan → Verifikasi Admin → Survei Lapangan PPL → Persetujuan Akhir → Penebusan QR Kios. | Diagram alur panah 6 tahapan |
| **Slide 4** | **Pencapaian Backend & Database** | FastAPI Python 3.12, MySQL 8.0 (13 Tabel), Bcrypt & JWT, Engine 12 Siklus Status, API Geofencing GPS & Scan QR. | Screenshot Schema phpMyAdmin / Endpoint Swagger API |
| **Slide 5** | **Pencapaian Frontend Web** | React 19, Strict Multi-Portal Guard (Admin Dinas, PPL, Petani), Dashboard Petani dengan 4 KPI, formulir survei PPL. | Screenshot Dashboard Admin & Web Petani |
| **Slide 6** | **Pencapaian Mobile App (Flutter)** | **Update Terbaru**: 8 Tab Navigasi Horizontal, 6-Stage Progress Stepper dengan garis & ikon award/package, modul GPS Geofencing di sawah. | **Screenshot Mobile Flutter Petani** (Stepper & 8 Tab) |
| **Slide 7** | **Arsitektur Docker & Akun Demo** | 4 Kontainer Docker Compose (`db`, `phpmyadmin`, `backend`, `frontend`), Seed data 4 akun demo siap pakai. | Diagram kontainer Docker & tabel akun demo |
| **Slide 8** | **Roadmap Sisa Pekerjaan (30%)** | Alokasi objektif sisa 30%: Automated Testing Pytest (10%), Fitur Mobile Offline (9%), Cetak PDF/Excel (6%), Cloud VPS (3%), WhatsApp Gateway (2%). | Tabel Roadmap Pekan 7 & 8 |
| **Slide 9** | **Strategi Menjawab Pertanyaan Dosen** | Argumen kenapa 70%: Alur bisnis utama sudah 100% jalan, 30% adalah pematangan QA & deployment ke server publik. | Kutipan pernyataan kesiapan tim |
| **Slide 10**| **Penutup & Ajakan Live Demo** | Ucapan terima kasih, sesi tanya jawab, dan pembukaan demo langsung di layar. | Logo PENS & Tampilan Beranda E-PUPUK |

---

## 📝 RINCIAN ISI DETAIL PER SLIDE (SIAP COPY KE POWERPOINT / CANVA)

---

### SLIDE 1: JUDUL & IDENTITAS
- **Header**: LAPORAN KEMAJUAN PROYEK — MINGGU KE-6
- **Judul Utama**: E-PUPUK KABUPATEN MOJOKERTO
- **Subjudul**: Sistem Terpadu Pengajuan & Distribusi Alokasi Pupuk Bersubsidi Berbasis Verifikasi Lapangan dan Geofencing GPS
- **Status Kemajuan**: **70.0% (Core Workflow Complete & Dockerized)**
- **Disusun Oleh**:
  1. **Syarifatullah Ceva Efendy** (NRP: 312521002) — *Frontend & Mobile Developer*
  2. **Selby Wafi Nurjuan** (NRP: 3125521018) — *Backend & Database Developer*
- **Dosen Pengampu**: Amma Liesvarastranta Haz, S.Tr.T., M.T.
- **Institusi**: D3 Teknik Informatika — PENS PSDKU Lamongan (2026)

---

### SLIDE 2: RINGKASAN EKSEKUTIF PROGRES SISTEM (70%)
- **Poin Utama**: Seluruh alur inti dari registrasi NIK 16 digit sampai penebusan QR resmi telah aktif dan terhubung end-to-end.
- **Tabel Pembobotan Objektif**:
  - Database & Migrasi (Bobot 15%): **90% Selesai** (Kontribusi: 13.5%) — *13 Tabel MySQL & phpMyAdmin*
  - Backend API FastAPI (Bobot 30%): **75% Selesai** (Kontribusi: 22.5%) — *Auth JWT, CRUD, Geofencing, QR*
  - Frontend Web React 19 (Bobot 25%): **78% Selesai** (Kontribusi: 19.5%) — *Multi-Portal 3 Aktor Berjalan*
  - Docker & Environment (Bobot 15%): **80% Selesai** (Kontribusi: 12.0%) — *Docker Compose 4 Service Live*
  - QA & Testing Otomatis (Bobot 15%): **16.7% Selesai** (Kontribusi: 2.5%) — *Uji Manual End-to-End Berhasil*
  - **TOTAL CAPAIAN**: **70.0%** *(MVP Matang & Siap Didemokan)*

---

### SLIDE 3: ALUR END-TO-END SISTEM YANG SUDAH 100% BERJALAN
- **Alur 6 Langkah**:
  1. **Pendaftaran Petani**: Validasi NIK 16 digit anti-duplikasi, upload e-KTP, dan mapping ke Kelompok Tani (Poktan).
  2. **Pengajuan Subsidi**: Petani memilih lahan terdaftar & jumlah pupuk (Urea/NPK) sesuai batas kuota RDKK.
  3. **Verifikasi Berkas**: Admin Dinas memeriksa kelengkapan KTP dan riwayat kuota petani di web.
  4. **Survei Lapangan PPL**: Petugas PPL terjun ke sawah, validasi geotagging koordinat GPS, foto tanaman, & rekomendasi.
  5. **Persetujuan Akhir**: Admin Dinas menerbitkan SK alokasi & mengaktifkan status penebusan pupuk.
  6. **Pencairan QR di Kios**: Petani membawa kupon QR digital untuk dipindai oleh kios resmi.

---

### SLIDE 4: PENCAPAIAN BACKEND & DATABASE
- **Pengembang**: Selby Wafi Nurjuan
- **Teknologi**: Python 3.12, FastAPI, SQLAlchemy ORM, MySQL 8.0, Bcrypt, JWT.
- **Poin Kunci**:
  - Arsitektur 13 Tabel Relasional: `users`, `farmers`, `lands`, `commodities`, `applications`, `surveys`, `distributions`, `qr_scans`, dll.
  - Keamanan Hak Akses Ketat: Role-based authorization (`PETANI`, `PPL`, `ADMIN`, `KIOSK`).
  - State Machine 12 Status: Mengatur transisi berkas dari `DIAJUKAN` hingga `TERSALURKAN`.
  - Modul Validasi Geofencing: Menghitung jarak koordinat GPS pembukaan sak pupuk di sawah.

---

### SLIDE 5: PENCAPAIAN FRONTEND WEB
- **Pengembang**: Syarifatullah Ceva Efendy
- **Teknologi**: React 19, Vite, Tailwind CSS, Lucide Icons, Axios.
- **Poin Kunci**:
  - Strict Route Protection: Mengamankan portal masing-masing aktor agar tidak saling tembus.
  - Portal Admin Dinas: Meja audit berkas pengajuan, penugasan PPL, filter kelompok tani Mojokerto, dan approval.
  - Portal Petugas PPL: Dashboard penugasan tugas survei dan formulir evaluasi sawah petani.
  - Portal Kios Resmi: Pemindai QR voucher pupuk bersubsidi secara instan.

---

### SLIDE 6: PENCAPAIAN MOBILE APP PETANI (FLUTTER)
- **Tujuan**: Memfasilitasi petani dan PPL di area persawahan yang membutuhkan akses mobile langsung dari smartphone.
- **Fitur Baru yang Sudah Selaras 100% dengan Web**:
  1. **AppBar & Banner Khas Mojokerto**: Dark Emerald `#064E3B`, badge resmi, dan notifikasi real-time.
  2. **8 Tab Navigasi Horizontal**:
     - *Dashboard, Profil Saya, Data Lahan, Pengajuan Subsidi, Status Pengajuan, Kuota Pupuk, Pembukaan Pupuk (Special Dot), Riwayat Pembukaan*.
  3. **4 Kartu KPI Ringkasan**: Sisa Kuota Urea, Sisa Kuota NPK, Pengajuan Aktif, dan Pupuk Digunakan.
  4. **6-Stage Progress Stepper Persis Web**:
     - Garis penghubung hijau horizontal tebal 2.5px.
     - Node lingkaran centang untuk tahapan selesai.
     - Node biru cerah `#2563EB` dengan ikon medali pita (*Award*) untuk status aktif *Menunggu Persetujuan Akhir*.
     - Node putih berborder dengan ikon paket untuk tahap penggunaan pupuk.
  5. **Modul Pembukaan Pupuk (Geofencing GPS)**:
     - 4 tahapan alur pembukaan karung pupuk fisik di petak sawah.
     - Riwayat scan karung pupuk dengan penanda *GPS Valid*.

---

### SLIDE 7: KONTAINERISASI DOCKER & KESIAPAN LIVE DEMO
- **Docker Compose Stack (4 Kontainer Aktif)**:
  - `epupuk-db` (MySQL 8.0, Port 3306)
  - `epupuk-phpmyadmin` (GUI Database, Port 8080)
  - `epupuk-backend` (FastAPI Uvicorn, Port 8000)
  - `epupuk-frontend` (React + Nginx, Port 80)
- **Akun Bawaan (Seed Data) untuk Demo Langsung**:
  - **Admin Dinas**: `admin` / `admin123`
  - **Petugas PPL**: `ppl_ahmad` / `ppl123`
  - **Petani Aktif**: `petani_budi` / `petani123`
  - **Petani Siap Tebus QR**: `petani_siti` / `petani123`

---

### SLIDE 8: ROADMAP SISA PEKERJAAN (ALOKASI BOBOT 30%)
- **Penjelasan**: Sisa 30% difokuskan pada pengujian otomatis, pelaporan cetak, dan kesiapan rilis produksi.
- **Rincian Sisa**:
  1. **Automated Testing Suite (Pytest)** *(Bobot 10%)* — Target Pekan 7: Unit test API, auth, dan validasi kuota.
  2. **Penyempurnaan Fitur Mobile Lanjutan** *(Bobot 9%)* — Target Pekan 8: Form survei PPL offline & kamera native.
  3. **Modul Ekspor Laporan PDF & Excel** *(Bobot 6%)* — Target Pekan 8: Cetak Surat Keputusan & rekap distribusi.
  4. **Deployment Cloud VPS & Domain** *(Bobot 3%)* — Target Pekan 8: Nginx SSL HTTPS publik.
  5. **WhatsApp Notification Gateway** *(Bobot 2%)* — Target Pekan 8: Notifikasi otomatis kupon terbit.

---

### SLIDE 9: STRATEGI & ARGUMEN SAAT TANYA JAWAB DOSEN
- **Pertanyaan**: *"Mengapa persentase kemajuan dilaporkan 70%, bukan 90% atau 100%?"*
- **Jawaban Argumentatif**:
  > *"Kami melaporkan **70.0%** secara objektif dan jujur. Seluruh alur bisnis inti dari pendaftaran NIK, verifikasi berkas, survei sawah, hingga pencairan QR di kios sudah **100% selesai dan teruji secara live di Docker**.*  
  > *Sisa 30% kami alokasikan untuk aspek non-fungsional penentu standar industri, yaitu **Automated Unit Testing Pytest**, **fitur offline mobile PPL**, **ekspor cetak PDF/Excel**, dan **deployment VPS publik**."*

---

### SLIDE 10: PENUTUP & DEMO SISTEM
- **Kalimat Penutup**: *"Demikian laporan kemajuan minggu ke-6 proyek E-PUPUK Kabupaten Mojokerto. Kami siap mendemonstrasikan alur sistem secara langsung."*
- **Aksi Lanjutan**: Membuka browser (Web Admin & Web Petani) dan Emulator/HP Android (Aplikasi Mobile Flutter Petani).

---

## 💡 TIPS SUKSES SAAT PRESENTASI:
1. **Buka 3 Jendela Sekaligus Saat Demo**:
   - Jendela 1: Web Admin Dinas (`http://localhost:5173/admin`)
   - Jendela 2: Web Kios Scanner (`http://localhost:5173/kiosk`)
   - Jendela 3: Flutter Mobile Petani (Layar HP / Emulator)
2. **Tunjukkan Konsistensi Desain**:
   - Perlihatkan ke dosen bahwa desain di Flutter Mobile Petani (4 KPI, 8 Tab Navigasi, dan Stepper 6 tahapan) **sama persis dan terhubung ke backend yang sama** dengan versi web!
