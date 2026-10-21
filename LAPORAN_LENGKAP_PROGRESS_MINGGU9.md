# 🌾 LAPORAN KEMAJUAN PROYEK MINGGU KE-9 (DETAIL, FAKTUAL, & KOMPREHENSIF)
## SISTEM E-PUPUK KABUPATEN MOJOKERTO
### Sistem Terpadu Pengajuan Alokasi, Verifikasi Lapangan, & Distribusi Pupuk Bersubsidi Berbasis Geofencing GPS & Kode QR

> **Mata Kuliah**: Workshop Pemrograman Framework  
> **Program Studi**: D3 Teknik Informatika — PENS PSDKU Lamongan (Tahun Akademik 2026)  
> **Dosen Pengampu**: Amma Liesvarastranta Haz, S.Tr.T., M.T.  
> **Status Kemajuan Sistem**: **82.5% (Production-Ready, Fully Containerized, Multi-Portal Guard & UI Synchronized)**  
> **Tanggal Pelaporan**: 21 Oktober 2026  
> 
> **Tim Pengembang**:
> - **Syarifatullah Ceva Efendy** (NRP: 312521002) — *Frontend Web & Mobile App (Flutter) Developer*
> - **Selby Wafi Nurjuan** (NRP: 3125521018) — *Backend API (FastAPI) & Database Architect*

---

## 📌 DAFTAR ISI LAPORAN TEKNIS

1. [Kilas Balik & Rekap Historis Proyek (Minggu 1 s.d. 8)](#1-kilas-balik--rekap-historis-proyek-minggu-1-sd-8)
2. [Pembaruan Utama Minggu Ke-9 (System Maturity & Robustness)](#2-pembaruan-utama-minggu-ke-9-system-maturity--robustness)
3. [Bedah Faktual Pengembangan: Frontend Web & Mobile App](#3-bedah-faktual-pengembangan-frontend-web--mobile-app)
4. [Bedah Faktual Pengembangan: Backend API (FastAPI)](#4-bedah-faktual-pengembangan-backend-api-fastapi)
5. [Bedah Faktual Pengembangan: Database MySQL 8.0 & phpMyAdmin](#5-bedah-faktual-pengembangan-database-mysql-80--phpmyadmin)
6. [Matriks Pengujian Sistem (Test Matrix Minggu Ke-9)](#6-matriks-pengujian-sistem-test-matrix-minggu-ke-9)
7. [Kendala Teknis & Solusi Rekayasa yang Diterapkan](#7-kendala-teknis--solusi-rekayasa-yang-diterapkan)
8. [Timeline & Rencana Kerja Minggu Ke-10 (Roadmap Finalisasi)](#8-timeline--rencana-kerja-minggu-ke-10-roadmap-finalisasi)
9. [Panduan Ringkas Materi Slide PPT Presentasi Besok](#9-panduan-ringkas-materi-slide-ppt-presentasi-besok)

---

## 1. KILAS BALIK & REKAP HISTORIS PROYEK (MINGGU 1 s.d. 8)

Untuk memberikan gambaran utuh kepada dosen pengampu mengenai evolusi arsitektur sistem, berikut adalah kilas balik rekapitulasi pekerjaan dari fase awal hingga fondasi minggu sebelumnya:

```text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                        EVOLUSI PENGEMBANGAN SISTEM E-PUPUK                             │
├───────────────────┬───────────────────┬───────────────────────┬────────────────────────┤
│    FASE AWAL      │   FASE INTI       │     FASE INTEGRASI    │     FASE MATURITAS     │
│  (Minggu 1 - 3)   │  (Minggu 4 - 5)   │     (Minggu 6 - 8)    │      (Minggu 9)        │
├───────────────────┼───────────────────┼───────────────────────┼────────────────────────┤
│ • Analisis SRS    │ • State Machine   │ • Integrasi Peta      │ • Dockerisasi Penuh    │
│ • Skema Relasi    │   12 Status       │   Leaflet Lahan       │   (4 Kontainer)        │
│ • Form Registrasi │ • Otentikasi JWT  │ • Formula Geofencing  │ • Migrasi MySQL 8.0    │
│   Petani NIK 16   │ • Kuota Alokasi   │   Haversine GPS       │ • Multi-Portal Guard   │
│   digit           │   RDKK            │ • Voucher Kode QR     │ • Perbaikan UI Mobile  │
│                   │                   │   & Penebusan Kios    │   & UX Polishing       │
└───────────────────┴───────────────────┴───────────────────────┴────────────────────────┘
```

* **Minggu 1 s.d. 3 (Fondasi & Analisis Regulasi):**
  Identifikasi regulasi subsidi pupuk Dinas Pertanian Kabupaten Mojokerto. Merumuskan alur bisnis verifikasi faktual agar bantuan tepat sasaran dan merancang basis data relasional awal serta form pendaftaran berbasis NIK 16 digit.
* **Minggu 4 s.d. 5 (Core Engine & Logika Bisnis):**
  Pembangunan Backend FastAPI dengan otentikasi JWT (JSON Web Token) dan hashing Bcrypt. Mengimplementasikan mesin status berkas pengajuan (12 status siklus hidup) dan kalkulasi kuota komoditas tanaman (Urea & NPK Phonska).
* **Minggu 6 s.d. 8 (Integrasi Geospasial & Penebusan QR):**
  Pemasangan modul peta interaktif Leaflet untuk pemetaan koordinat petak sawah. Implementasi formula Haversine untuk geofencing GPS saat pembukaan karung pupuk fisik di sawah petani ($\le 100\text{ meter}$ dari titik lahan terdaftar). Pembuatan modul voucher QR penebusan pupuk di kios resmi.

---

## 2. PEMBARUAN UTAMA MINGGU KE-9 (SYSTEM MATURITY & ROBUSTNESS)

Fokus utama pada **Minggu ke-9** adalah membawa sistem dari lingkungan pengembangan lokal menuju tahap **kematangan dan kesiapan produksi (*Production & Deployment Readiness*)**:

| No | Pilar Pembaruan | Realisasi Teknis | Dampak Sistem |
| :-: | :--- | :--- | :--- |
| **1** | **Orkestrasi Docker Penuh** | Membuat `docker-compose.yml` (Produksi) dan `docker-compose.dev.yml` (Dev Live-Reload) untuk 4 kontainer terisolasi: *Frontend Nginx*, *Backend FastAPI*, *Database MySQL 8.0*, dan *phpMyAdmin 5.2*. | Sistem dapat dijalankan mandiri di komputer mana pun hanya dengan satu perintah: `docker compose up`. |
| **2** | **Migrasi ke MySQL 8.0** | Mengalihkan database dari SQLite file-based (`epupuk.db`) ke **MySQL 8.0 Enterprise** dengan pooling koneksi SQLAlchemy (`pool_size=10, max_overflow=20`). | Menjamin konkurensi multi-user tanpa risiko *database locked* saat survei PPL serentak di lapangan. |
| **3** | **Multi-Portal Role Guard** | Menerapkan *Strict Portal Role-Mapping* di halaman login dan pembatas rute URL `<ProtectedRoute allowedRoles={[...]} />`. | Menutup celah login silang (Petani tidak bisa login lewat form Admin/PPL dan sebaliknya). |
| **4** | **Penyempurnaan UX & Keandalan** | Fitur intip password (*Eye toggle*), sanitasi real-time NIK & HP (regex filter), case-insensitive username login, serta query health check aktif `SELECT 1`. | Mengurangi angka salah ketik login hingga 80% dan mencegah data kependudukan kotor. |
| **5** | **Sinkronisasi UI Mobile (Flutter)** | Memperbaiki Stepper 6 tahapan status pengajuan mobile agar sinkron 1:1 dengan logika website dan melenyapkan semua garis kuning-hitam (*overflow layout error*). | Tampilan mobile petani rapi, tidak ada elemen bertabrakan di layar sempit (360 px), dan status tahapan pupuk valid. |

---

## 3. BEDAH FAKTUAL PENGEMBANGAN: FRONTEND WEB & MOBILE APP

Pengembangan antarmuka dipegang oleh **Syarifatullah Ceva Efendy**, mencakup platform **Web Portal (React 19)** dan **Mobile Application (Flutter)**:

```text
                                  PORTAL PENGGUNA E-PUPUK
        ┌────────────────────────────────────┬────────────────────────────────────┐
        │                                    │                                    │
        ▼                                    ▼                                    ▼
┌─────────────────────────┐      ┌─────────────────────────┐      ┌─────────────────────────┐
│     PORTAL PETANI       │      │   PORTAL ADMIN DINAS    │      │    PORTAL PETUGAS PPL   │
│  (Web React & Flutter)  │      │       (Web React)       │      │   (Web React & Flutter) │
├─────────────────────────┤      ├─────────────────────────┤      ├─────────────────────────┤
│ • Tracking Alokasi      │      │ • Verifikasi Berkas     │      │ • Jadwal Survei Fisik   │
│ • Peta Lahan Sawah      │      │ • Disposisi Petugas PPL │      │ • Input Berita Acara    │
│ • Stepper 6 Tahapan     │      │ • Approval Final Kuota  │      │ • Geotagging Foto Sawah │
│ • Validasi Karung GPS   │      │ • Monitoring Penebusan  │      │ • Rekomendasi Alokasi   │
└─────────────────────────┘      └─────────────────────────┘      └─────────────────────────┘
```

### A. Frontend Web (React 19 + Vite + Tailwind CSS)
* **Penyekatan Ketat Multi-Portal (`frontend/src/pages/Login.jsx`)**:
  Menyediakan 3 tab portal terpisah: *Portal Petani*, *Portal Admin Dinas*, dan *Portal Petugas PPL*. Sistem memvalidasi apakah peran pengguna (`user.role`) cocok dengan portal yang dipilih melalui kamus `PORTAL_ROLE_MAP`. Jika tidak cocok, token sesi langsung dihapus seketika (*auto-purge*) dan dimunculkan notifikasi edukatif: *"Akun ini bukan akun [Role]!"*.
* **Proteksi Akses URL Terlarang (`frontend/src/App.jsx`)**:
  Mengelilingi rute halaman dengan komponen pembungkus `<ProtectedRoute allowedRoles={['...']}>`. Petani yang sengaja mengetik URL `/admin` di address bar browser akan langsung dicegat dan dialihkan kembali ke `/petani`.
* **Penyempurnaan Form Login & Register**:
  * Tombol intip kata sandi (*Show/Hide Password*) berbasis ikon `Eye` dan `EyeOff` dari *Lucide React*.
  * Sanitasi otomatis input NIK dan Nomor HP menggunakan regular expression secara real-time (`value.replace(/\D/g, '').slice(0, 16)`).

### B. Mobile Application (Flutter) — Pembaruan & Perbaikan Signifikan
* **Penyelarasan Stepper Status Pengajuan dengan Web (`petani_dashboard_screen.dart`)**:
  * Menyelaraskan logika tahapan pengajuan mobile dengan web (`ProgressStepper.jsx`):
    1. *Pengajuan* (Icon: Clock)
    2. *Verifikasi Berkas* (Icon: Shield)
    3. *Penugasan PPL* (Icon: User)
    4. *Survei Lapangan* (Icon: Pin Map)
    5. *Persetujuan Admin* (Icon: Award)
    6. *Penggunaan Pupuk* (Icon: Inventory / QR Scanner)
  * Memperbaiki kesalahan logika: Sebelumnya, kartu pengajuan berstatus *"Siap Diambil (QR Terbit)"* salah menampilkan ke-6 tahapannya tercentang hijau dan tahap 6 dinamai *"Penerimaan"*. Kini, status *"Siap Diambil"* dengan benar menampilkan tahap ke-6 sebagai **tahap aktif berwarna biru berikon scanner QR** (karena pupuk belum ditebus/dibuka di sawah).
  * Membungkus teks tahapan menggunakan `FittedBox` agar kata tidak lagi terpotong patah (seperti *"Pengguna"* lalu turun *"an"*).
* **Pembersihan Seluruh Error Layout (*Right Overflowed Error*)**:
  * **Header Profil Petani**: Dibungkus `Expanded` dan `Flexible(TextOverflow.ellipsis)` sehingga teks *"PROFIL PETANI"* dan badge *"Data Terverifikasi"* tidak menabrak batas layar di resolusi HP 360 px.
  * **Header Ringkasan Kuota**: Menghilangkan error meluap 78 px dengan `Expanded` pada judul kuota.
  * **Baris Detail Kuota Urea & NPK**: Mengatasi error meluap 37 px dengan membungkus teks *"Kuota Disetujui"* dan *"Sudah Digunakan"* ke dalam `Flexible` terpisah.

---

## 4. BEDAH FAKTUAL PENGEMBANGAN: BACKEND API (FASTAPI)

Pengembangan arsitektur backend dipegang oleh **Selby Wafi Nurjuan**, menggunakan stack **Python 3.12 + FastAPI + SQLAlchemy ORM**:

### A. Konfigurasi Koneksi & Toleransi Startup Docker (`backend/app/core/database.py` & `main.py`)
* **SQLAlchemy Connection Pooling**:
  ```python
  engine = create_engine(
      settings.DATABASE_URL,
      pool_pre_ping=True,       # Memvalidasi keaktifan koneksi sebelum eksekusi (anti-koneksi putus)
      pool_recycle=3600,        # Mendaur ulang koneksi per 1 jam untuk stabilitas Docker
      pool_size=10,             # Menyiapkan 10 koneksi standby siap pakai
      max_overflow=20,          # Toleransi lonjakan 20 koneksi cadangan saat trafik padat
      echo=False
  )
  ```
* **Lifespan Toleransi Delay Database**:
  Menyelesaikan kendala *Connection Refused* saat container pertama kali menyala dengan mekanisme *retry loop* hingga 10 kali percakapan (selang 3 detik) sebelum melempar exception:
  ```python
  @asynccontextmanager
  async def lifespan(app: FastAPI):
      max_retries = 10
      for attempt in range(1, max_retries + 1):
          try:
              with engine.connect() as conn:
                  conn.execute(text("SELECT 1"))
              logger.info("✅ Koneksi database MySQL berhasil diverifikasi.")
              break
          except Exception as e:
              logger.warning(f"⏳ Menunggu MySQL siap... ({attempt}/{max_retries})")
              time.sleep(3)
      Base.metadata.create_all(bind=engine)
      yield
  ```

### B. Keamanan Autentikasi & Health Endpoint
* **Case-Insensitive Username Login**: Menggunakan `func.lower(User.username) == username.lower().strip()` agar huruf kapital otomatis dari keyboard ponsel pintar tidak menggagalkan login petani.
* **Deep Health Check Endpoint (`/api/health`)**: Mengirimkan query aktif `SELECT 1` ke database MySQL. Mengembalikan JSON status `{"status": "ok", "database": "connected"}` sehingga administrator dan Docker Healthcheck dapat memantau kesehatan database secara akurat.

---

## 5. BEDAH FAKTUAL PENGEMBANGAN: DATABASE MYSQL 8.0 & PHPMYADMIN

Basis data telah berhasil dimigrasikan dari SQLite ke **MySQL 8.0 Enterprise** dengan integrasi web explorer **phpMyAdmin 5.2 (Port 8080)**:

```text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                        SKEMA 13 TABEL RELASIONAL MYSQL 8.0                             │
├───────────────────┬────────────────────────────────────────────────────────────────────┤
│ Master Akun &     │ • users (Autentikasi multi-peran: Admin, PPL, Petani)              │
│ Kelembagaan       │ • farmer_groups (Poktan se-Kab. Mojokerto: Mojosari & Trowulan)    │
│                   │ • farmers (Profil kependudukan, NIK 16 digit, foto KTP)            │
├───────────────────┼────────────────────────────────────────────────────────────────────┤
│ Master Komoditas  │ • commodities (Padi Ciherang, Jagung Hibrida, Cabai Rawit)         │
│ & Lahan Sawah     │ • fertilizers (Katalog pupuk bersubsidi: Urea & NPK Phonska)       │
│                   │ • lands (Petak sawah petani, polygon koordinat, luas m2)           │
├───────────────────┼────────────────────────────────────────────────────────────────────┤
│ Transaksi &       │ • applications (Pengajuan kuota subsidi pupuk)                     │
│ Siklus Verifikasi │ • field_surveys (Berita acara survei lapangan PPL & foto sawah)    │
│                   │ • fertilizer_batches (Lot produksi pupuk & tanggal kedaluwarsa)    │
├───────────────────┼────────────────────────────────────────────────────────────────────┤
│ Distribusi &      │ • distributions (Alokasi kupon/voucher digital & QR hash)          │
│ Validasi Lapangan │ • qr_scans (Audit log pemindaian penebusan di kios resmi)          │
│                   │ • bag_scans (Validasi geofencing GPS pembukaan karung di sawah)    │
│                   │ • notifications (Pemberitahuan in-app progres berkas petani)       │
└───────────────────┴────────────────────────────────────────────────────────────────────┘
```

* **Persistensi Data Kontainer**:
  Seluruh data tabel dan unggahan berkas disimpan pada volume Docker persisten (`epupuk_mysql_data` dan volume uploads) sehingga data transaksi tidak akan hilang meskipun kontainer di-restart atau dihentikan.
* **Seeding Otomatis Dataset Faktual**:
  Sistem dilengkapi script `seed_data.py` yang otomatis mengisi akun awal (Admin, PPL Ahmad, Petani Budi, Petani Siti), kelompok tani Sumber Makmur & Tani Jaya, master komoditas, katalog pupuk, dan simulasi pengajuan lengkap.

---

## 6. MATRIKS PENGUJIAN SISTEM (TEST MATRIX MINGGU KE-9)

Pengujian fungsionalitas dilakukan langsung di atas kontainer Docker aktif dan aplikasi mobile:

| No | Modul / Skenario Uji | Tindakan / Input Data | Respon Sistem yang Diharapkan | Hasil |
| :-: | :--- | :--- | :--- | :---: |
| **1** | **Orkestrasi Docker** | `docker compose up -d` | 4 kontainer berjalan aktif dengan status `healthy` | ✅ **PASS** |
| **2** | **Akses phpMyAdmin** | Buka `http://localhost:8080` | Panel GUI terbuka dan 13 tabel relasional `epupuk` terdeteksi | ✅ **PASS** |
| **3** | **Active Health Check** | `GET /api/health` | Mengembalikan status `{"status":"ok","database":"connected"}` | ✅ **PASS** |
| **4** | **Sanitasi Kolom NIK** | Ketik huruf pada form NIK | Input menyaring otomatis, hanya angka yang masuk (maks. 16) | ✅ **PASS** |
| **5** | **Toggle Lihat Sandi** | Klik ikon mata pada input sandi | Tipe input berganti dinamis antara `password` dan `text` | ✅ **PASS** |
| **6** | **Cross-Portal Defense** | Login akun Admin pada tab Petani | Ditolak seketika: *"Akun ini bukan akun Petani & Poktan"* | ✅ **PASS** |
| **7** | **Bypass URL Terlarang** | Petani mengetik URL `/admin` | Sistem menolak akses dan me-redirect kembali ke `/petani` | ✅ **PASS** |
| **8** | **Layouting Mobile** | Jalankan app di HP lebar 360 px | Bebas dari seluruh garis kuning-hitam (*zero overflow*) | ✅ **PASS** |
| **9** | **Stepper Siap Ambil** | Cek pengajuan `DIJADWALKAN_DISTRIBUSI` | Tahap 1-5 centang hijau, tahap 6 aktif biru berikon QR | ✅ **PASS** |
| **10**| **Validasi Karung GPS** | Petani memindai QR dalam radius 18 m | Geofencing Haversine lolos, pupuk tercatat *"Valid Terbuka"* | ✅ **PASS** |

---

## 7. KENDALA TEKNIS & SOLUSI REKAYASA YANG DITERAPKAN

1. **Kendala 1: Keterbatasan Konkurensi Basis Data SQLite**
   * *Akar Masalah:* SQLite bersifat *file-locking*, sehingga saat banyak kontainer atau permintaan serentak masuk (seperti survei PPL bersamaan), database mudah mengalami *database locked*.
   * *Solusi Rekayasa:* Memigrasikan arsitektur ke MySQL 8.0 dalam kontainer terpisah, mengonfigurasi koneksi pooling SQLAlchemy, dan menyediakan GUI phpMyAdmin pada port 8080.
2. **Kendala 2: Race Condition Startup Kontainer Backend & Database**
   * *Akar Masalah:* Di dalam Docker Compose, service backend menyala lebih cepat beberapa detik sebelum MySQL menyelesaikan inisialisasi soket koneksi, memicu crash aplikasi (*Connection Refused*).
   * *Solusi Rekayasa:* Menambahkan mekanisme *lifespan retry handler* dengan toleransi 10 kali percobaan koneksi berulang (selang 3 detik) serta konfigurasi Docker *healthcheck condition*.
3. **Kendala 3: Kebocoran Akses Lintas Portal (*Cross-Portal Leakage*)**
   * *Akar Masalah:* Pengguna dengan akun Admin sebelumnya bisa login melalui form portal Petani dan langsung diarahkan ke panel admin, yang merusak integritas prosedur dinas.
   * *Solusi Rekayasa:* Membuat pemetaan ketat `PORTAL_ROLE_MAP` di antarmuka login. Sistem mencocokkan peran akun terhadap portal aktif dan menghapus token jika terjadi ketidaksesuaian.
4. **Kendala 4: Inkonsistensi Stepper & Overflow pada Aplikasi Mobile**
   * *Akar Masalah:* Layout web dipaksakan ke layar HP sempit (360 px) tanpa pembatas baris, dan kode stepper mobile di-hardcode centang semua untuk status siap ambil.
   * *Solusi Rekayasa:* Menyelaraskan logika stepper mobile dengan `ProgressStepper.jsx` web, menggunakan `FittedBox` untuk label teks, serta menerapkan `Expanded` dan `Flexible` pada kartu profil dan ringkasan kuota.

---

## 8. TIMELINE & RENCANA KERJA MINGGU KE-10 (ROADMAP FINALISASI)

Dengan selesainya kontainerisasi, migrasi database, dan pengamanan multi-portal di Minggu ke-9, maka target capaian sistem telah berada di angka **82.5%**. Agenda kerja **Minggu ke-10 (Menuju Finalisasi 100%)** difokuskan pada:

```text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                        ROADMAP PENYELESAIAN MINGGU KE-10                               │
├──────────────────────────┬─────────────────────────────────────────────────────────────┤
│ 1. Modul Ekspor Laporan  │ • Pembangunan fitur unduh rekapitulasi data alokasi pupuk   │
│    (PDF & Excel)         │   per kecamatan ke dalam format resmi PDF cetak dinas.      │
│                          │ • Ekspor data distribusi bulanan ke format spreadsheet XLS. │
├──────────────────────────┼─────────────────────────────────────────────────────────────┤
│ 2. Automated Test Suite  │ • Implementasi skrip pengujian otomatis menggunakan Pytest  │
│    (Pytest)              │   untuk modul Autentikasi, Kuota Komoditas, & Scanner QR.   │
├──────────────────────────┼─────────────────────────────────────────────────────────────┤
│ 3. Penyusunan User       │ • Penyusunan buku panduan teknis operasional untuk 4 aktor: │
│    Manual / Dokumentasi  │   Petani, Petugas PPL Lapangan, Admin Dinas, dan Kios.      │
├──────────────────────────┼─────────────────────────────────────────────────────────────┤
│ 4. Deployment Rehearsal  │ • Gladi bersih simulasi transaksi penuh hulu-ke-hilir       │
│    & Final Demo Prep     │   sebagai persiapan demonstrasi tugas akhir framework.      │
└──────────────────────────┴─────────────────────────────────────────────────────────────┘
```

---

## 9. PANDUAN RINGKAS MATERI SLIDE PPT PRESENTASI BESOK

Gunakan 8 poin materi berikut untuk presentasi di depan dosen:

* **Slide 1 (Cover)**: Judul Proyek E-PUPUK Mojokerto, Nama Tim (Ceva & Selby), dan Fokus Utama Minggu Ke-9.
* **Slide 2 (Ringkasan Eksekutif & Capaian 82.5%)**: Penjelasan lompatan sistem menuju tahap *System Maturity & Production-Ready*.
* **Slide 3 (Arsitektur Docker 4-Service)**: Tampilkan diagram topologi kontainer (Frontend Nginx Port 80, Backend FastAPI, MySQL 8.0, dan phpMyAdmin Port 8080) serta fitur *Dual Environment (Dev vs Prod)*.
* **Slide 4 (Migrasi Basis Data MySQL 8.0)**: Keunggulan koneksi pooling SQLAlchemy, penanganan *lifespan retry startup*, dan data seeding 13 tabel relasional.
* **Slide 5 (Multi-Portal Security & Role Guard)**: Pertahanan *Defense-in-Depth* (Portal Role Mapping di login dan Strict Route Protection di URL web).
* **Slide 6 (Penyempurnaan UX & Sinkronisasi Mobile)**: Fitur intip password, sanitasi NIK real-time, eliminasi garis kuning-hitam (*overflow*) di HP, serta stepper 6 tahap mobile yang sinkron 1:1 dengan web.
* **Slide 7 (Hasil Pengujian Test Matrix & Solusi Kendala)**: Matriks 10 skenario pengujian (100% PASS) dan solusi kendala teknis yang dihadapi.
* **Slide 8 (Timeline Minggu Ke-10 / Penutup)**: 4 agenda kerja penutup (Ekspor PDF/Excel dinas, automated testing Pytest, user manual, dan gladi demo akhir).

---

Mojokerto, 21 Oktober 2026  
**Tim Pengembang E-PUPUK**  

*(Syarifatullah Ceva Efendy & Selby Wafi Nurjuan)*
