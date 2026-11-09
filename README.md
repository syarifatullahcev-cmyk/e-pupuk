# 🌾 E-Pupuk Kabupaten Mojokerto
### Sistem Verifikasi & Distribusi Pupuk Bersubsidi Terpadu Berbasis Web

[![FastAPI](https://img.shields.io/badge/Backend-FastAPI-009688?style=flat&logo=fastapi)](https://fastapi.tiangolo.com)
[![React](https://img.shields.io/badge/Frontend-React_19-61DAFB?style=flat&logo=react)](https://react.dev)
[![Vite](https://img.shields.io/badge/Bundler-Vite_8-646CFF?style=flat&logo=vite)](https://vitejs.dev)
[![MySQL](https://img.shields.io/badge/Database-MySQL_8.0-4479A1?style=flat&logo=mysql)](https://www.mysql.com)
[![Tailwind CSS](https://img.shields.io/badge/Styling-Tailwind_CSS_v4-38B2AC?style=flat&logo=tailwind-css)](https://tailwindcss.com)

---

## 📌 1. Tentang Sistem

**E-Pupuk Kabupaten Mojokerto** adalah platform untuk pendataan, verifikasi berkas, survei PPL, persetujuan bertingkat, dan alokasi pupuk melalui **QR Code**. Validasi penebusan saat ini masih dilakukan oleh akun Petani pemilik QR; portal/role Kios mandiri belum tersedia.

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
   - Portal Admin saat ini tersedia di web; aplikasi Flutter ditujukan untuk Petani dan PPL.
   - Melakukan verifikasi berkas administratif pengajuan (KTP, legalitas lahan, kesesuaian komoditas).
   - Menugaskan (disposisi) tugas survei kepada petugas PPL berdasarkan wilayah.
   - Memberikan persetujuan akhir (*Final Approval*) pasca-survei PPL.
   - Menerbitkan batch alokasi pupuk dan menerbitkan QR Code penebusan.
   - Memantau log audit (*audit trail*) dan statistik operasional.

4. **🏪 Penebusan QR (belum ada akun/peran Kios mandiri)**
   - Endpoint penebusan saat ini mengizinkan Petani pemilik QR untuk mengirim token, lokasi GPS aktual, dan foto pupuk.
   - Role `KIOS` dan alur pemindaian QR dengan kamera kios belum tersedia; jangan operasikan modul ini sebagai portal kios produksi.

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
   MYSQL_DB=epupuk_demo
   ```

5. **(Opsional) Generate Aset Gambar Demo**:
   Aset yang dihasilkan adalah ilustrasi fiktif ber-watermark DUMMY, bukan dokumen atau bukti lapangan. Untuk menghindari penulisan ke `backend/uploads`, arahkan output ke direktori sementara:
   ```powershell
   python generate_seed_media.py --output-dir "$env:TEMP\e-pupuk-demo-media"
   ```
   Jangan gunakan gambar ini untuk verifikasi identitas/lahan, pengujian lapangan, atau data produksi.
   Untuk menampilkan gambar demo secara lokal, gunakan direktori unggahan yang memang terisolasi untuk demo, dan tambahkan `--allow-uploads` bila output diarahkan ke `backend/uploads`. Generator menolak menimpa file yang sudah ada. Jangan jalankan pada server/penyimpanan produksi atau direktori yang berisi dokumen pengguna.

6. **Inisialisasi Data Demo Awal (Seed Data)**:
   Seed hanya menerima database lokal bernama `epupuk_demo` dan membutuhkan konfirmasi eksplisit. Data nama, NIK, kontak, alamat, dan lahan di dalamnya fiktif; jangan gunakan seed atau dokumen demo untuk verifikasi maupun produksi.
   ```bash
   python seed_data.py --demo-only
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
| **Petugas PPL** | `ppl_ahmad` | `ppl123` | PPL CONTOH | Menerima tugas demo, mengunggah foto dummy, dan mengirim laporan |
| **Petani 1** | `petani_budi` | `petani123` | PETANI CONTOH 1 (POKTAN CONTOH 1) | Kelola lahan demo, ajukan subsidi, dan tampilkan QR |
| **Petani 2** | `petani_siti` | `petani123` | PETANI CONTOH 2 (POKTAN CONTOH 2) | Kelola lahan demo dan ajukan subsidi |

Akun ini hanya tersedia setelah seeding berhasil ke database demo yang terisolasi. Seluruh identitas dan dokumen contoh tidak nyata dan tidak sah untuk verifikasi.

### 📱 Kiosk QR Scanner (Penebusan di Kios)
Route **`http://localhost:5173/kiosk-scanner`** saat ini hanya dapat dibuka oleh akun `PETANI` yang login. Token dimasukkan manual; browser meminta GPS dan foto karung sebelum mengirim ke API. Endpoint membatasi QR ke Petani pemiliknya. Ini bukan role atau akun Kios mandiri.

---

## 🔄 5. Simulasi Alur Kerja Sistem (End-to-End Workflow)

Untuk menguji seluruh fitur sistem secara lengkap, ikuti alur simulasi berikut:

```
[1. Petani]             [2. Admin]             [3. PPL]             [4. Admin]             [5. Penebusan oleh pemilik QR]
 Ajukan Subsidi  ───►  Verifikasi Berkas  ───►  Survei Lapangan ───►  Final Approval  ───►  Scan QR Penebusan
 (KTP & Lahan)         & Disposisi PPL        (Foto & Catatan)      (Terbitkan QR)         (Pupuk Disalurkan)
```

1. **Tahap 1: Pengajuan oleh Petani**
   - Login sebagai `petani_budi` (`petani123`).
   - Masuk ke tab **Form Pengajuan**.
   - Pilih lahan dan jenis pupuk yang dibutuhkan. Kuota maksimal dihitung otomatis berdasarkan luas lahan dan standar komoditas.
   - Klik **Kirim Pengajuan Subsidi**. Status awal: `MENUNGGU_VERIFIKASI_BERKAS`.
   - Pada demo lokal, dokumen gambar dapat berupa ilustrasi DUMMY; jangan anggap sebagai bukti identitas atau dasar verifikasi nyata.
2. **Tahap 2: Verifikasi Berkas & Disposisi oleh Admin**
   - Logout, lalu login sebagai `admin` (`admin123`).
   - Pada panel **Verifikasi Berkas Masuk**, periksa alur tampilan dokumen. Aset DUMMY hanya untuk demo dan tidak boleh dipakai untuk verifikasi nyata.
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
5. **Tahap 5: Uji penebusan sesuai API saat ini**
   - Login sebagai `petani_budi`, lihat kartu pengajuan demo yang telah disetujui, lalu klik **Tampilkan QR Code**.
   - Buka **`http://localhost:5173/kiosk-scanner`** dalam sesi Petani yang sama, masukkan token secara manual, izinkan GPS dan unggah foto uji yang diberi label DEMO.
   - Sistem menerima pemindaian hanya jika QR adalah milik Petani login dan lokasi sesuai lahan. Kamera untuk membaca QR oleh petugas Kios belum didukung; jangan anggap uji demo sebagai penyaluran pupuk nyata.
   - Status pengajuan menjadi **`TERSALURKAN`** setelah seluruh jatah pada pengajuan tersebut ditebus.

> **Uji perangkat nyata belum dilakukan.** Langkah di atas adalah alur kode/API; izin kamera, GPS, kualitas foto, koneksi lemah, dan peta di perangkat lapangan tetap perlu diuji langsung. Lihat [panduan uji lapangan dan gladi demo](./PANDUAN_UJI_LAPANGAN_DAN_GLADI_DEMO.md).

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
- Halaman web saat ini tidak membaca QR dengan kamera. Masukkan token manual, aktifkan izin lokasi, lalu ambil/unggah foto pupuk. Untuk membaca QR memakai kamera kios dan akun Kios khusus diperlukan implementasi terpisah.

---

## 📜 Lisensi & Kontributor

Dikembangkan untuk implementasi digitalisasi distribusi pupuk bersubsidi Dinas Pertanian Kabupaten Mojokerto.
Dilisensikan di bawah lisensi terbuka untuk tujuan pengembangan dan riset.
