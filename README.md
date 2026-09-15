# 🌾 E-Pupuk Kabupaten Mojokerto
### Sistem Verifikasi & Distribusi Pupuk Bersubsidi Terpadu Berbasis Web

[![FastAPI](https://img.shields.io/badge/Backend-FastAPI-009688?style=flat&logo=fastapi)](https://fastapi.tiangolo.com)
[![React](https://img.shields.io/badge/Frontend-React_19-61DAFB?style=flat&logo=react)](https://react.dev)
[![Vite](https://img.shields.io/badge/Bundler-Vite_8-646CFF?style=flat&logo=vite)](https://vitejs.dev)
[![MySQL](https://img.shields.io/badge/Database-MySQL_8.0-4479A1?style=flat&logo=mysql)](https://www.mysql.com)
[![Tailwind CSS](https://img.shields.io/badge/Styling-Tailwind_CSS_v4-38B2AC?style=flat&logo=tailwind-css)](https://tailwindcss.com)

---

## 📌 1. Tentang Sistem

**E-Pupuk Kabupaten Mojokerto** adalah platform terintegrasi untuk pendataan, verifikasi berkas administratif, survei fisik lapangan oleh Petugas Penyuluh Lapangan (PPL), persetujuan bertingkat, hingga penebusan pupuk bersubsidi menggunakan **QR Code** secara transparan dan akuntabel di tingkat kios resmi.

### 👥 Peran Pengguna & Hak Akses (RBAC)

1. **👨‍🌾 Petani (`PETANI`)**
   - Mengelola profil petani, kelompok tani (Poktan), dan data kepemilikan lahan (luas m², komoditas, pin koordinat GPS Leaflet, dan foto sawah).
   - Mengajukan alokasi subsidi pupuk dengan perhitungan otomatis kuota standar per hektar.
   - Mengunggah berkas identitas (KTP) dan dokumentasi lahan.
   - Memantau status verifikasi dan mengunduh/menampilkan **QR Code resmi** untuk penebusan pupuk.

2. **📋 Petugas Penyuluh Lapangan (`PPL`)**
   - Menerima tugas disposisi survei fisik lapangan dari Admin.
   - Melakukan survei lapangan langsung ke titik koordinat lahan petani.
   - Mengunggah foto bukti survei fisik serta menginput catatan kelayakan dan rekomendasi kuota.

3. **🏢 Admin Dinas Pertanian (`ADMIN`)**
   - Melakukan verifikasi berkas administratif pengajuan (KTP, legalitas lahan, kesesuaian komoditas).
   - Menugaskan (disposisi) tugas survei kepada petugas PPL berdasarkan wilayah.
   - Memberikan persetujuan akhir (*Final Approval*) pasca-survei PPL.
   - Menerbitkan batch alokasi pupuk dan menerbitkan QR Code penebusan.
   - Memantau log audit (*audit trail*) dan statistik operasional.

4. **🏛️ Pimpinan / Kepala Dinas (`PIMPINAN`)**
   - Memantau *Executive Dashboard*: ringkasan KPI, total kuota tersalurkan, status verifikasi se-kabupaten, dan peta sebaran geospasial lahan pertanian.

5. **🏪 Kios Resmi / Penyalur (`KIOSK SCANNER`)**
   - Portal mandiri untuk memindai (*scan*) QR Code petani menggunakan kamera perangkat atau input token manual.
   - Memvalidasi keaslian kuota, nomor batch pupuk, dan tanggal kedaluwarsa sebelum penyaluran dilakukan.

---

## 🛠️ 2. Prasyarat Sistem (Prerequisites)

Sebelum menjalankan sistem, pastikan perangkat Anda telah terinstal:

- **Python**: Versi `3.10.x` atau lebih baru ([Unduh Python](https://www.python.org/downloads/))
- **Node.js**: Versi `18.x`, `20.x`, atau `24.x` dan **npm** ([Unduh Node.js](https://nodejs.org/))
- **MySQL / MariaDB**: Versi `8.0+` atau `10.4+` (Bisa menggunakan XAMPP, Laragon, MySQL Standalone, atau Docker)
- **Web Browser**: Google Chrome, Microsoft Edge, atau Mozilla Firefox versi terbaru

---

## 🚀 3. Panduan Menjalankan Sistem Pertama Kali

Ikuti 4 langkah terstruktur di bawah ini untuk memulai sistem dari awal:

### 🗄️ Langkah 1: Setup Database MySQL

1. **Jalankan service MySQL** pada komputer Anda (misalnya melalui panel kontrol **XAMPP** atau **Laragon** dengan klik tombol **Start** pada Apache & MySQL).
2. Buka antarmuka manajemen database favorit Anda:
   - **phpMyAdmin**: Kunjungi `http://localhost/phpmyadmin`
   - **MySQL Workbench / DBeaver / Navicat**
   - atau melalui **Terminal / Command Prompt**
3. Impor skema database dari file `backend/schema.sql`.

> **Opsi Cepat via Terminal / Command Prompt:**
> ```bash
> mysql -u root -p < "backend/schema.sql"
> ```
> *(Jika menggunakan root tanpa password, cukup tekan tombol `Enter` saat diminta password).*

File `backend/schema.sql` akan otomatis membuat database bernama `epupuk` (jika belum ada) dan membentuk seluruh tabel relasional beserta foreign key dan indeks yang diperlukan.

---

### 🐍 Langkah 2: Setup & Konfigurasi Backend (FastAPI)

Buka terminal baru (PowerShell, Command Prompt, atau Bash) lalu navigasikan ke folder `backend`:

1. **Masuk ke folder backend**:
   ```bash
   cd backend
   ```

2. **(Direkomendasikan) Buat dan aktifkan Virtual Environment**:
   ```bash
   # Membuat virtual environment bernama .venv
   python -m venv .venv

   # Mengaktifkan di Windows PowerShell:
   .venv\Scripts\Activate.ps1

   # Atau jika menggunakan Command Prompt (CMD):
   .venv\Scripts\activate.bat

   # Atau di Linux / macOS:
   source .venv/bin/activate
   ```

3. **Install semua dependensi Python**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Konfigurasi Environment Database**:
   Salin file `.env.example` menjadi `.env`:
   ```bash
   # Windows PowerShell:
   Copy-Item .env.example .env

   # Atau Windows CMD:
   copy .env.example .env

   # Atau Linux/macOS:
   cp .env.example .env
   ```
   Buka file `.env` di teks editor, lalu sesuaikan koneksi database MySQL Anda jika menggunakan password:
   ```ini
   MYSQL_HOST=127.0.0.1
   MYSQL_PORT=3306
   MYSQL_USER=root
   MYSQL_PASSWORD=            # Isi jika MySQL Anda memiliki kata sandi
   MYSQL_DB=epupuk
   ```

5. **(Opsional) Generate Aset Gambar Sampel (KTP & Lahan)**:
   Aplikasi telah menyediakan generator otomatis berkas citra demo beresolusi tinggi:
   ```bash
   python generate_seed_media.py
   ```
   *File foto simulasi KTP dan hamparan sawah/lahan akan tersimpan di direktori `backend/uploads/`.*

6. **Inisialisasi Data Demo Awal (Seed Data)**:
   Jalankan script seed untuk mengisi akun pengguna demo, kelompok tani, data komoditas, jenis pupuk, dan sampel pengajuan:
   ```bash
   python seed_data.py
   ```
   Output sukses: `Seeding initial data for E-Pupuk... Seeding completed successfully!`

7. **Jalankan Server Backend**:
   ```bash
   python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
   # Atau cukup:
   uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
   ```
   - API Backend aktif di: `http://127.0.0.1:8000`
   - Dokumentasi Swagger UI interaktif: **`http://127.0.0.1:8000/docs`**
   - Dokumentasi ReDoc: `http://127.0.0.1:8000/redoc`

---

### ⚛️ Langkah 3: Setup & Menjalankan Frontend (React + Vite)

Buka jendela terminal baru (biarkan terminal backend tetap berjalan), lalu navigasikan ke folder `frontend`:

1. **Masuk ke folder frontend**:
   ```bash
   cd frontend
   ```

2. **Install dependensi Node.js**:
   ```bash
   npm install
   ```

3. **Jalankan Server Development Frontend**:
   ```bash
   npm run dev
   ```

4. **Buka Aplikasi di Browser**:
   Buka peramban web dan akses URL:
   👉 **`http://localhost:5173`**

*(Frontend Vite telah dikonfigurasi dengan reverse proxy otomatis untuk merutekan request `/api` dan `/files` ke backend `http://127.0.0.1:8000`).*

---

## 🔑 4. Akun Uji Coba Demo (Demo Credentials)

Gunakan akun siap pakai berikut pada halaman login (`http://localhost:5173/login`):

| Peran (Role) | Username | Password | Nama Pengguna / Instansi | Hak Akses Utama |
| :--- | :--- | :--- | :--- | :--- |
| **Admin** | `admin` | `admin123` | Administrator Dinas Pertanian | Verifikasi Berkas, Disposisi PPL, Final Approval, Audit Log |
| **Petugas PPL** | `ppl_ahmad` | `ppl123` | Ahmad Fauzi, S.P. (PPL Mojosari) | Menerima Tugas Survei Lapangan, Upload Foto Bukti, Submit Laporan |
| **Petani 1** | `petani_budi` | `petani123` | Budi Santoso (Poktan Sumber Makmur) | Kelola Lahan Padi Mojosari, Ajukan Subsidi, Tampilkan QR Code |
| **Petani 2** | `petani_siti` | `petani123` | Siti Aminah (Poktan Tani Jaya) | Kelola Lahan Jagung Trowulan, Ajukan Subsidi Pupuk |
| **Pimpinan** | `pimpinan` | `pimpinan123` | Kepala Dinas Pertanian Kab. Mojokerto | Executive Monitoring, Grafik Realisasi, Peta Geospasial Lahan |

### 📱 Kiosk QR Scanner (Penebusan di Kios)
Untuk membuka modul Kiosk pemindai QR Code di kios resmi:
👉 Akses URL: **`http://localhost:5173/kiosk-scanner`** *(Dapat diakses langsung tanpa login)*.

---

## 🔄 5. Simulasi Alur Kerja Sistem (End-to-End Workflow)

Untuk menguji seluruh fitur sistem secara lengkap, ikuti alur simulasi berikut:

```
[1. Petani]             [2. Admin]             [3. PPL]             [4. Admin]             [5. Kiosk Resmi]
 Ajukan Subsidi  ───►  Verifikasi Berkas  ───►  Survei Lapangan ───►  Final Approval  ───►  Scan QR Penebusan
 (KTP & Lahan)         & Disposisi PPL        (Foto & Catatan)      (Terbitkan QR)         (Pupuk Disalurkan)
```

1. **Tahap 1: Pengajuan oleh Petani**
   - Login sebagai `petani_budi` (`petani123`).
   - Masuk ke tab **Form Pengajuan**.
   - Pilih lahan dan jenis pupuk yang dibutuhkan. Kuota maksimal dihitung otomatis berdasarkan luas lahan dan standar komoditas.
   - Klik **Kirim Pengajuan Subsidi**. Status awal: `MENUNGGU_VERIFIKASI_BERKAS`.
2. **Tahap 2: Verifikasi Berkas & Disposisi oleh Admin**
   - Logout, lalu login sebagai `admin` (`admin123`).
   - Pada panel **Verifikasi Berkas Masuk**, periksa dokumen KTP dan foto lahan petani.
   - Klik tombol **Setujui Berkas** (Status berubah menjadi `BERKAS_TERVERIFIKASI`).
   - Lakukan **Tugaskan Petugas PPL**: pilih petugas `ppl_ahmad`, lalu klik **Kirim Tugas Lapangan** (Status menjadi `DITUGASKAN_KE_PPL`).
3. **Tahap 3: Pelaksanaan Survei Fisik oleh PPL**
   - Logout, lalu login sebagai `ppl_ahmad` (`ppl123`).
   - Buka menu **Tugas Survei Lapangan**, klik **Mulai Survei** pada pengajuan terkait.
   - Isi form laporan survei lapangan: kondisi fisik tanah/tanaman, rekomendasi kuota disetujui, dan upload foto bukti survei.
   - Klik **Kirim Laporan Survei** (Status menjadi `MENUNGGU_PERSETUJUAN_AKHIR`).
4. **Tahap 4: Persetujuan Akhir oleh Admin**
   - Login kembali sebagai `admin` (`admin123`).
   - Masuk ke bagian **Persetujuan Akhir Pengajuan**.
   - Tinjau hasil survei fisik PPL. Jika sesuai, klik **Setujui & Terbitkan Alokasi Pupuk**.
   - Sistem secara otomatis mengalokasikan batch pupuk dan menerbitkan **QR Code Digital** (Status menjadi `DIJADWALKAN_DISTRIBUSI`).
5. **Tahap 5: Penebusan di Kios Pertanian (Kiosk Scanner)**
   - Login sebagai `petani_budi`, lihat kartu pengajuan yang telah disetujui, lalu klik **Tampilkan QR Code**.
   - Buka tab peramban baru ke **`http://localhost:5173/kiosk-scanner`**.
   - Arahkan kamera ke QR Code atau salin token/kode transaksi ke kolom input manual, lalu klik **Validasi & Salurkan**.
   - Status pengajuan resmi berganti menjadi **`TERSALURKAN`** dan riwayat distribusi tercatat di log audit.

---

## 📂 6. Struktur Direktori Proyek

```
e-pupuk/
├── backend/
│   ├── app/
│   │   ├── core/                  # Konfigurasi, DB Engine, Security & Dependencies
│   │   │   ├── config.py          # Environment settings & URL builder
│   │   │   ├── database.py        # SQLAlchemy session & Base
│   │   │   ├── dependencies.py    # Auth dependencies & audit logger
│   │   │   └── security.py        # JWT & bcrypt password hashing
│   │   ├── models/                # Definisi tabel SQLAlchemy (User, Land, Application, dll.)
│   │   ├── routers/               # Endpoint REST API (auth, admin, ppl, farmers, files, dll.)
│   │   ├── schemas/               # Skema validasi Pydantic (Request & Response)
│   │   ├── services/              # File storage service & helper
│   │   └── main.py                # Inisialisasi FastAPI & Middleware CORS
│   ├── uploads/                   # Direktori penyimpanan media (KTP, lahan, survei)
│   ├── .env.example               # Template environment variables backend
│   ├── generate_seed_media.py     # Script generator citra simulasi (Pillow)
│   ├── requirements.txt           # Dependensi Python
│   ├── schema.sql                 # DDL skema database MySQL
│   └── seed_data.py               # Script data demo awal
├── frontend/
│   ├── src/
│   │   ├── components/            # Komponen UI (Navbar, Modal, Leaflet Map, Card, dll.)
│   │   ├── pages/                 # Halaman Dashboard (Admin, PPL, Petani, Login, Kiosk)
│   │   ├── services/              # Axios instance & API wrapper
│   │   ├── store/                 # Global state management Zustand (Auth)
│   │   ├── App.jsx                # Routing & Protected Route guard
│   │   ├── main.jsx               # React DOM entry point
│   │   └── index.css              # Styling Tailwind CSS
│   ├── package.json               # Dependensi & NPM scripts
│   └── vite.config.js             # Konfigurasi Vite & API Reverse Proxy
├── docs/                          # Dokumentasi arsitektur, PRD, dan spesifikasi API
├── .gitignore                     # Git ignore rules
└── README.md                      # Dokumentasi petunjuk sistem
```

---

## ❓ 7. Pemecahan Masalah (Troubleshooting)

### 🔴 Error: `Access denied for user 'root'@'...' (using password: NO/YES)`
- **Penyebab**: Konfigurasi username atau password MySQL pada file `.env` berbeda dengan konfigurasi MySQL komputer Anda.
- **Solusi**: Buka file `backend/.env`, sesuaikan nilai `MYSQL_USER` dan `MYSQL_PASSWORD` dengan kredensial MySQL lokal Anda.

### 🔴 Error: `Can't connect to MySQL server on '127.0.0.1'`
- **Penyebab**: Service MySQL belum aktif atau berjalan di port selain `3306`.
- **Solusi**: Pastikan Apache & MySQL di XAMPP / Laragon berstatus *running* (hijau). Periksa nomor port yang digunakan (standar: `3306`).

### 🔴 Error: `ModuleNotFoundError: No module named '...'`
- **Penyebab**: Belum semua dependensi Python terpasang di environment Anda.
- **Solusi**: Pastikan virtual environment aktif, lalu jalankan kembali `pip install -r requirements.txt`.

### 🔴 Permasalahan Kamera pada QR Scanner Kiosk
- **Penyebab**: Izin akses webcam pada peramban web belum diizinkan atau kamera sedang digunakan aplikasi lain.
- **Solusi**: Klik ikon gembok/kamera di sebelah kiri bilah alamat browser, pilih **Allow/Izinkan** akses kamera. Anda juga dapat menggunakan opsi **Input Token Manual** yang tersedia di halaman kiosk.

---

## 📜 Lisensi & Kontributor

Dikembangkan untuk implementasi digitalisasi distribusi pupuk bersubsidi Dinas Pertanian Kabupaten Mojokerto.
Dilisensikan di bawah lisensi terbuka untuk tujuan pengembangan dan riset.
