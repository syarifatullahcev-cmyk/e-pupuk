# 📋 LAPORAN DETAIL PROGRESS TEKNIS MINGGU KE-9
## Sistem E-PUPUK Kabupaten Mojokerto
### Rincian Pengembangan: Frontend Web, Backend & API, Database MySQL, dan Mobile Flutter

> **Mata Kuliah**: Workshop Pemrograman Framework  
> **Program Studi**: D3 Teknik Informatika — PENS PSDKU Lamongan  
> **Dosen Pengampu**: Amma Liesvarastranta Haz, S.Tr.T., M.T.  
> **Tim Pengembang**:
> - **Syarifatullah Ceva Efendy** (NRP: 312521002) — *Frontend Web & Mobile App (Flutter) Developer*
> - **Selby Wafi Nurjuan** (NRP: 3125521018) — *Backend API & Database Architect*
> 
> **Periode Laporan**: Minggu Ke-9 (Oktober 2026)

---

## 📌 DAFTAR ISI LAPORAN

1. [Ringkasan Matriks Progress 4 Pilar](#1-ringkasan-matriks-progress-4-pilar)
2. [Progress Frontend Web (React 19 + Vite)](#2-progress-frontend-web-react-19--vite)
3. [Progress Backend & REST API (FastAPI)](#3-progress-backend--rest-api-fastapi)
4. [Progress Database & phpMyAdmin (MySQL 8.0)](#4-progress-database--phpmyadmin-mysql-80)
5. [Progress Mobile Application (Flutter)](#5-progress-mobile-application-flutter)
6. [Tabel Perubahan File Kode (Changelog Faktual)](#6-tabel-perubahan-file-kode-changelog-faktual)

---

## 1. RINGKASAN MATRIKS PROGRESS 4 PILAR

```text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                      RINGKASAN PROGRESS MINGGU KE-9 E-PUPUK                            │
├───────────────────┬───────────────────┬───────────────────────┬────────────────────────┤
│   FRONTEND WEB    │   BACKEND & API   │       DATABASE        │     FLUTTER MOBILE     │
├───────────────────┼───────────────────┼───────────────────────┼────────────────────────┤
│ • Strict Role-    │ • Docker Compose  │ • Migrasi SQLite      │ • 100% Zero Overflow   │
│   Guard Portal    │   Orchestration   │   ke MySQL 8.0        │   (Fix 78px & 37px)    │
│ • URL Interceptor │ • Health-Check    │ • Connection Pooling  │ • Stepper 6 Tahap      │
│ • Sanitasi NIK    │   Startup Loop    │   (Pool size 10)      │   Dinamis & Real-Time  │
│   & Eye Password  │ • Normalisasi     │ • phpMyAdmin 5.2      │ • Ikon QR Aktif        │
│ • Peta Leaflet    │   Case-Insensitive│   Visual Explorer     │ • Dynamic API Binding  │
└───────────────────┴───────────────────┴───────────────────────┴────────────────────────┘
```

---

## 2. PROGRESS FRONTEND WEB (REACT 19 + VITE)

Pengembangan antarmuka Web dikerjakan menggunakan **React 19, Tailwind CSS, Lucide Icons, dan Vite**. Fokus utama Minggu ke-9 adalah **keamanan akses multi-portal dan kenyamanan pengguna (UX)**:

### A. Pembagian Ketat Multi-Portal Login (`frontend/src/pages/Login.jsx`)
* **3 Tab Pintu Masuk Terpisah**: Menyediakan antarmuka khusus untuk:
  1. *Portal Petani* (Warna Hijau Pertanian)
  2. *Portal Admin Dinas* (Warna Biru Pemerintahan)
  3. *Portal Petugas PPL* (Warna Oranye Lapangan)
* **Pencegahan Login Silang (Role-Mismatch)**:
  Sistem mencocokkan data role akun dari API dengan tab portal yang dipilih:
  * Jika Petani mencoba login di Tab Admin $\rightarrow$ Sistem langsung memutus sesi, membuang token (*auto-purge*), dan menampilkan notifikasi: *"Akun ini bukan akun Admin Dinas!"*.

### B. Proteksi Rute URL Terlarang (`frontend/src/App.jsx`)
* Mengimplementasikan pembungkus rute `<ProtectedRoute allowedRoles={[...]} />`.
* Pengguna yang mencoba mengetik URL langsung di address bar browser (misal petani mengetik `/admin` atau `/ppl`) akan langsung dicegat dan dikembalikan ke portal hak aksesnya.

### C. Penyempurnaan Form Input & UX (User Experience)
* **Fitur Intip Kata Sandi (Show/Hide Password)**: Menggunakan toggle ikon `Eye` dan `EyeOff` agar petani/admin tidak salah ketik kata sandi.
* **Sanitasi Otomatis NIK 16 Digit**: Menggunakan filter regex real-time (`replace(/\D/g, '')`) sehingga form NIK menolak input huruf dan membatasi tepat 16 angka.
* **Sanitasi Nomor HP/WhatsApp**: Otomatis membersihkan karakter non-angka saat registrasi petani.
* **Normalisasi Username**: Mengubah input username menjadi huruf kecil (*case-insensitive*) dan membuang spasi (*trimming*) untuk menghindari gagal login akibat tombol CapsLock.

### D. Visualisasi Peta Lahan Petani (Leaflet GIS)
* Modul peta interaktif untuk penitikan koordinat petak sawah (Latitude & Longitude) serta visualisasi poligon batas lahan pertanian.

---

## 3. PROGRESS BACKEND & REST API (FASTAPI)

Backend dibangun menggunakan **Python 3.12, FastAPI, Uvicorn, SQLAlchemy, dan PyMySQL**. Fokus Minggu ke-9 adalah **arsitektur layanan terisolasi (kontainer) dan integritas transaksi**:

### A. Kontainerisasi Docker Penuh
* Pembuatan **`Dockerfile` backend** berbasis `python:3.12-slim` dengan instalasi dependensi otomatis via `pip`.
* Penyusunan dua skenario orkestrasi:
  * `docker-compose.yml` (Mode Produksi): Layanan terisolasi dan efisien.
  * `docker-compose.dev.yml` (Mode Development): Mendukung *bind-mount* volume dan live-reload (`uvicorn --reload`) seketika saat kode diubah.

### B. Mekanisme Startup Resilient & Database Health-Check (`backend/app/main.py`)
* Mengimplementasikan lifespan startup dengan toleransi waktu (*retry loop*). Backend akan mengecek koneksi aktif (`SELECT 1`) ke server database terlebih dahulu sebelum membuka port API, mencegah backend crash saat kontainer MySQL sedang *booting*.

### C. Normalisasi & Validasi Autentikasi
* Endpoint `/api/auth/login` disempurnakan dengan normalisasi `username.strip().lower()`.
* Otentikasi stateless menggunakan **JWT (JSON Web Token)** dengan enkripsi kata sandi menggunakan **Bcrypt**.

### D. Mesin Status Transaksi & Geofencing Haversine
* Menjalankan siklus hidup pengajuan pupuk 12 status:
  $$\text{Draft} \rightarrow \text{Diajukan} \rightarrow \text{Verifikasi Berkas} \rightarrow \text{Survei Lapangan} \rightarrow \text{Disetujui Dinas} \rightarrow \text{Voucher QR} \rightarrow \text{Ditebus di Kios}$$
* **Formula Haversine GPS**: API `/api/distributions/scan-qr` memverifikasi bahwa karung pupuk dibuka di sawah petani dengan toleransi jarak maksimal **100 meter** dari koordinat lahan terdaftar.

---

## 4. PROGRESS DATABASE & PHPMYADMIN (MYSQL 8.0)

Fokus utama Minggu ke-9 pada basis data adalah **migrasi dari basis data lokal (file) menuju database terdistribusi enterprise**:

### A. Migrasi Penuh dari SQLite ke MySQL 8.0
* **Sebelum (Minggu 8):** Menggunakan SQLite (`epupuk.db`). Memiliki kelemahan fatal *database is locked* jika diakses bersamaan oleh banyak user.
* **Sesudah (Minggu 9):** Bermigrasi ke **MySQL 8.0 Enterprise** dengan storage engine `InnoDB` dan charset `utf8mb4_unicode_ci`.

### B. Konfigurasi Connection Pooling SQLAlchemy (`backend/app/core/database.py`)
Untuk menjamin performa tinggi saat survei massal di lapangan, diterapkan parameter pooling optimal:
* `pool_size = 10`: Menyediakan 10 koneksi standby siap pakai.
* `max_overflow = 20`: Mampu menampung lonjakan hingga 30 koneksi bersamaan tanpa drop.
* `pool_pre_ping = True`: Mengecek kesehatan koneksi sebelum query dijalankan (mencegah *stale connection*).
* `pool_recycle = 3600`: Daur ulang koneksi setiap 1 jam untuk stabilitas jangka panjang di Docker.

### C. Integrasi Visual Database Explorer (phpMyAdmin 5.2)
* Kontainer `epupuk-phpmyadmin` di-bundle langsung dalam Docker Compose pada **Port 8080**.
* Dosen penguji dan developer dapat menginspeksi tabel data secara langsung:
  * Tabel `users`, `farmers`, `lands` (lahan sawah)
  * Tabel `fertilizers` (alokasi Urea & NPK)
  * Tabel `applications`, `surveys`, dan `distributions` (voucher QR).

### D. Keamanan & Persistensi Data
* Menggunakan Docker Volume `epupuk_data` sehingga data petani dan pengajuan tetap tersimpan aman dan tidak hilang meskipun kontainer di-restart atau di-stop.

---

## 5. PROGRESS MOBILE APPLICATION (FLUTTER)

Aplikasi mobile dibangun menggunakan **Flutter (Dart)** yang dikhususkan untuk **Petani dan Petugas PPL Lapangan**. Pembaruan signifikan yang diselesaikan di Minggu ke-9 meliputi:

### A. Pembersihan Total Layout Error (Zero Overflow Bug)
* **Sebelumnya:** Terdapat garis belang kuning-hitam (*RenderFlex overflowed*) di layar HP:
  * Error overflow **78 pixels** pada header kartu ringkasan kuota pupuk.
  * Error overflow **37 pixels** pada baris status kuota Urea & NPK.
  * Teks nama dan status petani bertabrakan di layar sempit (360px – 440px).
* **Perbaikan Minggu 9:** 
  * Membungkus widget teks dengan `Expanded` dan `Flexible`.
  * Menerapkan `overflow: TextOverflow.ellipsis` agar teks panjang memotong rapi dengan titik-titik (`...`) tanpa merusak layout.

### B. Sinkronisasi Stepper 6 Tahapan Status Pengajuan
* **Sebelumnya:** Komponen Stepper pelacakan kartu pengajuan masih menampilkan data statis dummy dengan **6 centang hijau palsu** (meskipun statusnya baru disetujui dinas dan pupuk belum ditebus).
* **Perbaikan Minggu 9:**
  Komponen `_buildDashboardMiniStepper` dirombak total agar membaca status riil dari backend secara dinamis:
  1. **Tahap 1:** Pengajuan Berkas (Centang Hijau)
  2. **Tahap 2:** Verifikasi Berkas (Centang Hijau)
  3. **Tahap 3:** Penugasan PPL (Centang Hijau)
  4. **Tahap 4:** Survei Lapangan PPL (Centang Hijau)
  5. **Tahap 5:** Persetujuan Kuota Dinas (Centang Hijau)
  6. **Tahap 6:** Penggunaan Pupuk $\rightarrow$ **Menampilkan Ikon QR Scanner Biru Aktif** (Bukan centang) saat status `DIJADWALKAN_DISTRIBUSI`.
* **FittedBox Label**: Menambahkan pembungkus `FittedBox` pada label teks tahapan agar kata seperti "Penggunaan" tidak terpotong menjadi dua baris jelek ("Pengguna" / "an").

### C. Binding Data Kartu Pengajuan Dinamis
* Mengganti kartu dummy statis `#6` dan `#5` dengan perulangan list riil `_applications` dari API backend.
* Dilengkapi dengan penanganan kondisi kosong (*Empty State*) dan indikator pemuatan (*Skeleton Loading*).

### D. Konfigurasi Endpoint Fleksibel (`mobile/lib/config/api_config.dart`)
* Mendukung deteksi otomatis:
  * Mode Web Browser: `http://127.0.0.1:8000/api`
  * Mode Emulator Android: `http://10.0.2.2:8000/api`
  * Mode HP Fisik / Wi-Fi LAN: `http://10.253.129.6:8000/api`

---

## 6. TABEL PERUBAHAN FILE KODE (CHANGELOG FAKTUAL)

Berikut daftar file utama yang dikerjakan dan dimodifikasi pada Minggu ke-9:

| Komponen | File / Modul | Rincian Pembaruan |
| :--- | :--- | :--- |
| **Mobile** | `mobile/lib/screens/petani/petani_dashboard_screen.dart` | Menghilangkan semua overflow 78px & 37px, dynamic rendering kartu pengajuan, Stepper dinamis 6 tahapan dengan ikon QR aktif. |
| **Mobile** | `mobile/lib/config/api_config.dart` | Multi-environment base URL untuk Web, Emulator, dan HP fisik LAN. |
| **Frontend** | `frontend/src/pages/Login.jsx` | 3 Tab portal role guard, auto-purge token, sanitasi NIK 16 digit, show/hide password toggle. |
| **Frontend** | `frontend/src/App.jsx` | Pembungkus `<ProtectedRoute>` pembatas hak akses rute URL antar role. |
| **Backend** | `docker-compose.yml` & `docker-compose.dev.yml` | Orkestrasi 4 kontainer (Frontend, Backend, MySQL, phpMyAdmin). |
| **Backend** | `backend/app/core/database.py` | Konfigurasi SQLAlchemy connection pooling (size 10, overflow 20, recycle 1 jam). |
| **Backend** | `backend/app/main.py` | Database ready health-check loop saat startup kontainer. |
| **Backend** | `backend/app/api/auth.py` | Normalisasi username case-insensitive dan penguatan claims JWT role. |
| **Database** | `backend/app/models/*.py` | Penyesuaian tipe data dan relasi foreign key untuk MySQL 8.0 InnoDB. |

---

> Laporan teknis ini disusun secara faktual berdasarkan kode sumber yang telah diimplementasikan dan siap dipresentasikan di hadapan dosen pengampu.
