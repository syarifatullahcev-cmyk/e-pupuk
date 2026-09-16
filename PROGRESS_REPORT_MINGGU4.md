# 📋 PROGRESS REPORT — Sistem E-Pupuk Kabupaten Mojokerto
### Laporan Kemajuan Pengembangan Perangkat Lunak | Minggu ke-4 | 16 September 2026

---

## 📌 DAFTAR ISI
1. [Latar Belakang & Urgensi Sistem](#1-latar-belakang--urgensi-sistem)
2. [Konsep & Arsitektur Sistem](#2-konsep--arsitektur-sistem)
3. [Alur Proses Sistem (Terbaru Pasca Diskusi Dosen)](#3-alur-proses-sistem-terbaru-pasca-diskusi-dosen)
4. [Analisis Perubahan Konsep & Sanggahan Teknis](#4-analisis-perubahan-konsep--sanggahan-teknis)
5. [Progress Frontend](#5-progress-frontend)
6. [Progress Backend](#6-progress-backend)
7. [Progress Database](#7-progress-database)
8. [Bug Report & Isu Teknis Saat Ini](#8-bug-report--isu-teknis-saat-ini)
9. [Rencana Pengembangan Minggu 1–16](#9-rencana-pengembangan-minggu-1--16)
10. [Kesimpulan](#10-kesimpulan)

---

## 1. Latar Belakang & Urgensi Sistem

Subsidi pupuk merupakan salah satu program strategis pemerintah Indonesia untuk menjaga ketahanan pangan nasional. Namun, dalam pelaksanaannya, terdapat berbagai permasalahan struktural yang melemahkan efektivitas program ini, khususnya di tingkat kabupaten. Permasalahan utama yang menjadi landasan pengembangan sistem **E-Pupuk Kabupaten Mojokerto** antara lain:

| No | Permasalahan | Dampak |
|---|---|---|
| 1 | **Data petani tidak terverifikasi secara fisik** | Penerima bantuan tidak sesuai kenyataan di lapangan |
| 2 | **Tidak ada pelacakan setelah pupuk diserahkan** | Pupuk bersubsidi berpotensi dijual kembali ke pihak lain |
| 3 | **Alur persetujuan tidak transparan** | Petani tidak mengetahui status pengajuannya secara real-time |
| 4 | **Proses manual dan berbasis kertas** | Rentan manipulasi data, lambat, dan tidak efisien |
| 5 | **Koordinasi Pemerintah Daerah & PPL tidak terstruktur** | Penugasan survei lapangan tidak terdokumentasi dengan baik |

**E-Pupuk** hadir sebagai solusi sistem informasi terintegrasi berbasis web yang mendigitalisasi seluruh rantai proses distribusi pupuk bersubsidi — dari pengajuan, verifikasi dokumen, survei lapangan, persetujuan akhir, distribusi, hingga validasi penggunaan di lahan petani.

---

## 2. Konsep & Arsitektur Sistem

### 2.1 Teknologi yang Digunakan

#### Frontend
| Library/Framework | Versi | Fungsi |
|---|---|---|
| React | 19.x | UI Component Framework |
| Vite | 8.x | Build Tool & Dev Server |
| TailwindCSS | 4.x | Utility-first CSS Framework |
| React Router DOM | 7.x | Client-side Routing |
| Axios | 1.x | HTTP Client untuk API calls |
| React Leaflet | 5.x | Peta Interaktif (OpenStreetMap) |
| Leaflet | 1.9 | Peta engine (tile layer, marker) |
| QRCode.react | 4.x | Generate QR Code SVG |
| html5-qrcode | 2.3 | Scanner QR via Kamera Browser |
| Zustand | 5.x | Global State Management (Auth) |
| TanStack Query | 5.x | Server State & Caching |
| Recharts | 3.x | Grafik & Visualisasi Data |
| React Hot Toast | 2.x | Notifikasi Toast UI |
| Lucide React | 1.46 | Icon Library |
| Zod + React Hook Form | 4.x / 7.x | Validasi Form |

#### Backend
| Library/Framework | Versi | Fungsi |
|---|---|---|
| Python | 3.11+ | Bahasa Pemrograman Utama |
| FastAPI | 0.111+ | REST API Framework |
| Uvicorn | 0.30+ | ASGI Server |
| SQLAlchemy | 2.0+ | ORM (Object-Relational Mapping) |
| Pydantic | 2.7+ | Data Validation & Serialization |
| python-jose | 3.3+ | JWT Token (Autentikasi) |
| bcrypt | 4.0+ | Password Hashing |
| aiofiles | 24.1+ | Async File Upload |
| Pillow | 10.0+ | Image Processing |
| PyMySQL | 1.1+ | MySQL Database Driver |
| python-dotenv | 1.0+ | Environment Variables |

#### Database
| Komponen | Keterangan |
|---|---|
| **Development** | SQLite (`epupuk.db`) — untuk kemudahan testing lokal |
| **Production Target** | MySQL/MariaDB dengan charset `utf8mb4_unicode_ci` |
| **ORM** | SQLAlchemy Declarative Base |
| **Migration** | Schema SQL manual via `schema.sql` |

### 2.2 Arsitektur Sistem

```
┌─────────────────────────────────────────────────────┐
│                   PENGGUNA AKHIR                     │
│    Petani (HP)  |  Admin Pemda  |  PPL (Lapangan)   │
└──────────┬──────────────┬───────────────┬────────────┘
           │              │               │
           ▼              ▼               ▼
┌──────────────────────────────────────────────────────┐
│              FRONTEND (React + Vite)                  │
│  /petani    │   /admin     │   /ppl   │  /kiosk-scan │
│  PetaniDashboard  AdminDashboard  PPLDashboard  QRKiosk│
└──────────────────────┬───────────────────────────────┘
                       │ Axios HTTP (Vite Proxy /api → :8000)
                       ▼
┌──────────────────────────────────────────────────────┐
│              BACKEND (FastAPI + Uvicorn :8000)        │
│                                                      │
│  /api/auth   /api/applications   /api/admin          │
│  /api/ppl    /api/distributions  /api/farmers        │
│  /api/lands  /api/files                              │
│                                                      │
│  ┌─────────────────────────────────────────────┐    │
│  │ Middleware: JWT Auth | CORS | Role Guards   │    │
│  └─────────────────────────────────────────────┘    │
└──────────────────────┬───────────────────────────────┘
                       │ SQLAlchemy ORM
                       ▼
┌──────────────────────────────────────────────────────┐
│              DATABASE (SQLite → MySQL)                │
│                                                      │
│  users | farmers | lands | applications              │
│  field_surveys | distributions | qr_scans            │
│  fertilizers | fertilizer_batches | commodities      │
│  notifications | audit_logs | farmer_groups          │
└──────────────────────────────────────────────────────┘
```

### 2.3 Role & Hak Akses Sistem

```
┌────────────────────────────────────────────────────────────┐
│                     HIERARKI ROLE                          │
├─────────────┬──────────────────────────────────────────────┤
│   PETANI    │ Pengajuan bantuan, lihat status, scan QR     │
│   PPL       │ Survei lapangan, input koordinat, foto lahan │
│   ADMIN     │ Verifikasi berkas, penugasan PPL, fin.approve│
│   PIMPINAN  │ Monitoring statistik, lihat semua data       │
└─────────────┴──────────────────────────────────────────────┘
```

---

## 3. Alur Proses Sistem (Terbaru Pasca Diskusi Dosen)

Berikut adalah alur proses lengkap yang telah direvisi berdasarkan masukan dosen pembimbing, termasuk pemisahan role Admin Pemda dan PPL secara lebih tegas:

```
PETANI                  ADMIN PEMDA              PPL (SURVEYOR)           SISTEM
  │                         │                         │                      │
  ├─1. Daftar & Login ──────►│                         │                      │
  │                         │                         │                      │
  ├─2. Input Data ──────────►│                         │                      │
  │   • Data diri (NIK)     │                         │                      │
  │   • Data lahan          │                         │                      │
  │   • Upload foto KTP     │                         │                      │
  │   • Foto lahan          │                         │                      │
  │   • Koordinat GPS awal  │                         │                      │
  │   • Jenis & jumlah pupuk│                         │                      │
  │                         │                         │                      │
  │      [STATUS: MENUNGGU_VERIFIKASI_BERKAS]          │                      │
  │                         │                         │                      │
  │                         ├─3. Verifikasi Berkas    │                      │
  │                         │   • Cek foto KTP        │                      │
  │                         │   • Cek foto lahan      │                      │
  │                         │   • Cek koordinat awal  │                      │
  │                         │   • Lihat peta lokasi   │                      │
  │                         │                         │                      │
  │                    [Tolak] ─── kirim notif ke Petani (PERLU_PERBAIKAN)    │
  │                    [Approve]                       │                      │
  │                         │                         │                      │
  │      [STATUS: BERKAS_TERVERIFIKASI]                │                      │
  │                         │                         │                      │
  │                         ├─4. Penugasan PPL ───────►│                     │
  │                         │   • Pilih petugas PPL   │                      │
  │                         │   • Tambah catatan tugas│                      │
  │                         │   • Kirim notif ke PPL  │                      │
  │                         │                         │                      │
  │      [STATUS: DITUGASKAN_KE_PPL]                  │                      │
  │                         │                         │                      │
  │                         │                         ├─5. Survei Lapangan   │
  │                         │                         │   • Kunjungi lahan   │
  │                         │                         │   • Input koordinat  │
  │                         │                         │     AKTUAL via MAP   │
  │                         │                         │     (Citra Satelit)  │
  │                         │                         │   • Ukur luas lahan  │
  │                         │                         │   • Cek kondisi fisik│
  │                         │                         │   • Cek kondisi      │
  │                         │                         │     tanaman          │
  │                         │                         │   • Cek kondisi      │
  │                         │                         │     ekonomi petani   │
  │                         │                         │   • Upload foto bukti│
  │                         │                         │   • Beri rekomendasi │
  │                         │                         │     (SETUJU / TOLAK) │
  │                         │                         │                      │
  │      [STATUS: MENUNGGU_PERSETUJUAN_AKHIR]          │                      │
  │                         │                         │                      │
  │                         ├─6. Finalisasi Admin ────│                      │
  │                         │   • Review hasil survei │                      │
  │                         │   • Lihat koordinat PPL │                      │
  │                         │   • Tentukan kuota (kg) │                      │
  │                         │   • Buat QR Code unik   │                      │
  │                         │                         │                      │
  │◄────────── 7. Notifikasi Disetujui ───────────────┤                      │
  │                         │                         │                      │
  │      [STATUS: DIJADWALKAN_DISTRIBUSI]              │                      │
  │                         │                         │                      │
  ├─8. Terima Pupuk         │                         │                      │
  │   • Tampilkan QR Code   │                         │                      │
  │   • Scan di gudang/kios │                         │                      │
  │                         │                         │                      │
  │      [STATUS: TERSALURKAN]                         │                      │
  │                         │                         │                      │
  ├─9. Buka Karung di Lahan │                         │                      │
  │   • Scan barcode karung │                         │                      │
  │     via kamera HP       │                         │                      │
  │   • Sistem ambil GPS HP │─────────────────────────┼──► Cocokkan koordinat│
  │   • Catat timestamp     │                         │    PPL vs GPS scan   │
  │   • Kirim ke server     │                         │    (Geofencing)      │
  │                         │                         │                      │
  │◄────── Notif VALID / INVALID ─────────────────────┤                      │
  │                         │                         │                      │
  │                  [Log tercatat di audit_logs & qr_scans]                  │
  │                         │                         │                      │
```

---

## 4. Analisis Perubahan Konsep & Sanggahan Teknis

### 4.1 Perubahan Utama Setelah Diskusi Dosen

Berdasarkan arahan dosen pembimbing, terdapat beberapa perubahan signifikan dibandingkan konsep awal:

| Aspek | Konsep Awal | Konsep Terbaru (Post-Finalisasi) |
|---|---|---|
| **Dashboard Admin** | Satu dashboard untuk semua admin | **Dua role terpisah:** Admin Pemda (monitoring + verifikasi) dan PPL/Surveyor (survei lapangan) |
| **Tampilan Peta** | Peta dasar untuk input koordinat | PPL memiliki map **citra satelit** yang dapat mendeteksi luas lahan berdasarkan koordinat aktual |
| **Validasi Distribusi** | Sekadar scan QR di kios | Petani **wajib scan barcode di lokasi lahan** untuk membuktikan pupuk digunakan di tempat yang benar |
| **Verifikasi Lokasi** | Tidak ada geofencing | Koordinat GPS saat scan dibandingkan dengan koordinat survei PPL (toleransi radius) |
| **Kondisi Ekonomi** | Tidak ada di survei | PPL wajib menginput kondisi ekonomi petani sebagai salah satu parameter kelayakan |

### 4.2 Pemisahan Role Admin yang Diperlukan (Temuan dari Analisis Kode)

> **⚠️ TEMUAN KRITIS:** Saat ini kode frontend hanya memiliki **satu `AdminDashboard.jsx`** yang mencampur fungsi Admin Pemda dan belum ada pemisahan UI yang tegas antara peran monitoring-only (Pemda) dan peran operasional (PPL). Begitu pula pada sisi routing di `App.jsx` — role `PIMPINAN` dan `ADMIN` diarahkan ke halaman yang sama.

**Kondisi saat ini di `App.jsx`:**
```jsx
// Baris 108 — ADMIN dan PIMPINAN diarahkan ke halaman yang sama
<ProtectedRoute allowedRoles={['ADMIN', 'PIMPINAN']}>
  <AdminDashboard />
</ProtectedRoute>
```

**Yang seharusnya:** Route terpisah `/admin` dan `/pimpinan`, atau tampilan kondisional berdasarkan `user.role` di dalam `AdminDashboard`.

### 4.3 ⚠️ SANGGAHAN TEKNIS — Mekanisme Barcode di Karung Pupuk

**Pernyataan konsep dosen:** *"Barcode memuat informasi berupa koordinat dan waktu petani membuka karung pupuk tersebut."*

**Analisis teknis mendalam:**

Barcode atau QR Code yang tercetak di karung pupuk adalah benda **statis fisik** yang dicetak pada saat produksi atau pengemasan. Secara teknis, gambar barcode yang sudah tercetak **TIDAK BISA** secara mandiri menyimpan atau mengupdate informasi dinamis seperti "kapan dibuka" atau "koordinat GPS saat ini". Data tersebut bersifat tetap sejak dicetak.

**Solusi implementasi yang benar dan realistis:**

```
┌─────────────────────────────────────────────────────┐
│           ISI BARCODE DI KARUNG (STATIS)            │
│                                                      │
│  HANYA berisi: ID Unik Distribusi / QR Hash         │
│  Contoh: "EPUPUK-42-BUDI-QR2026-A8F3K"             │
│  (Format: EPUPUK-{app_id}-{nama}-{random_hash})     │
└─────────────────────────────────────────────────────┘
                         │
                         │ Petani scan via kamera HP
                         ▼
┌─────────────────────────────────────────────────────┐
│        APLIKASI E-PUPUK DI HP PETANI                │
│                                                      │
│  1. Baca ID dari barcode                            │
│  2. Ambil GPS koordinat HP saat ini (Navigator API) │
│  3. Catat timestamp saat scan                        │
│  4. Kirim [ID, GPS, Timestamp] → Server              │
└─────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────┐
│              SERVER BACKEND                          │
│                                                      │
│  1. Cari distribusi berdasarkan ID                  │
│  2. Ambil koordinat lahan dari hasil survei PPL     │
│  3. Hitung jarak GPS HP vs koordinat PPL            │
│     (Formula Haversine / GeoDjango)                 │
│  4. Jika jarak ≤ 100 meter → VALID ✅               │
│     Jika jarak > 100 meter → INVALID ❌             │
│  5. Simpan ke tabel qr_scans                        │
└─────────────────────────────────────────────────────┘
```

**Kesimpulan sanggahan:** Informasi koordinat dan timestamp bukan **isi** dari barcode, melainkan **data yang dikumpulkan oleh aplikasi saat scan** dan kemudian **diproses oleh server**. Ini adalah hal yang sangat berbeda dan penting untuk diklarifikasi dalam dokumentasi teknis agar tidak ada kesalahpahaman saat implementasi.

### 4.4 Saran Tambahan: Fitur Log & History di Setiap Dashboard

Sesuai permintaan, perlu ditambahkan:

| Dashboard | Log yang Perlu Ditambahkan |
|---|---|
| **Admin Pemda** | History semua verifikasi berkas, history penugasan PPL, history persetujuan akhir, Audit Log sistem |
| **PPL** | History survei yang pernah dikerjakan, riwayat penugasan per petani |
| **Petani** | History pengajuan, **History Pembukaan Pupuk** (kapan & di mana scan dilakukan), riwayat notifikasi |
| **Kiosk QR** | Log scan harian (waktu, hasil validasi, nama petani) |

---

## 5. Progress Frontend

### 5.1 Halaman yang Sudah Dibuat

#### ✅ Login Page (`Login.jsx`)
- Form login dengan username/password
- Validasi form dasar
- Redirect otomatis berdasarkan role setelah login
- Integrasi dengan JWT via `authStore` (Zustand)
- UI dengan gradient dan logo E-Pupuk

#### ✅ Admin Dashboard (`AdminDashboard.jsx`) — 42.9 KB, 912 baris
- **Tab Navigasi 4 tahap:** Verifikasi Berkas → Penugasan PPL → Persetujuan Akhir → Audit Log
- **KPI Cards:** Total verifikasi, penugasan PPL, persetujuan akhir, total disetujui
- **Verifikasi Berkas:** Lihat foto KTP & lahan petani via `PhotoViewerModal`, approve/reject/perbaikan
- **Penugasan PPL:** Pilih petugas PPL dari dropdown, kirim catatan penugasan
- **Persetujuan Akhir:** Review hasil survei PPL, tentukan kuota kg, generate QR Code
- **Audit Log Tab:** Tabel riwayat semua aksi admin (dari endpoint `/api/admin/audit-logs`)
- **Modal System:** Modal verifikasi, modal penugasan, modal persetujuan akhir
- **Loading Skeleton:** Animasi loading saat fetch data
- **Toast Notifications:** Feedback visual setiap aksi berhasil/gagal

> **🔴 KEKURANGAN KRITIS:** Belum ada pemisahan UI antara role `ADMIN` (Pemda yang bisa aksi) dan `PIMPINAN` (hanya monitoring). Keduanya saat ini melihat tampilan yang sama.

#### ✅ PPL Dashboard (`PPLDashboard.jsx`) — 23.5 KB, 510 baris
- **KPI Cards:** Tugas aktif, survei selesai, wilayah tugas
- **Daftar Tugas Survei:** Kartu tugas per pengajuan yang ditugaskan admin
- **Modal Input Hasil Survei:** Form kondisi lahan (BAIK/CUKUP/TIDAK_LAYAK), kondisi tanaman (SESUAI/TIDAK_SESUAI), luas aktual, catatan, rekomendasi (SETUJU/TOLAK), upload foto
- **Foto Petani Preview:** Lihat foto KTP dan foto lahan yang diupload petani
- **Riwayat Survei Selesai:** Daftar tugas yang sudah di-submit ke admin
- **Wilayah hardcoded:** "Kec. Mojosari & Trowulan" — perlu diambil dari database

> **🔴 KEKURANGAN:** Map citra satelit belum ada di PPL Dashboard. Saat ini hanya menggunakan `MapPicker` (OpenStreetMap biasa), bukan citra satelit. Komponen `MapPicker` menggunakan `TileLayer` OSM standar, belum diintegrasikan dengan layer satelit (Mapbox/Esri/Google Maps).

#### ✅ Petani Dashboard (`PetaniDashboard.jsx`) — 40.1 KB, 850 baris
- **KPI Cards:** Total pengajuan, aktif, disetujui, tersalurkan
- **Progress Stepper:** Visualisasi tahapan status pengajuan petani
- **Form Pengajuan:** Pilih lahan, jenis pupuk, jumlah, konfirmasi koordinat via `MapPicker`
- **QR Code Display:** Tampilkan QR Code pengambilan pupuk jika sudah disetujui
- **Revisi Dokumen:** Form untuk upload ulang foto KTP & lahan saat diminta perbaikan
- **PhotoViewerModal:** Lihat foto KTP dan lahan yang sudah diupload
- **FileUploadZone:** Komponen upload foto dengan preview

> **🔴 KEKURANGAN:** Belum ada fitur **"Scan Barcode Pembukaan Karung"** khusus untuk validasi penggunaan pupuk di lahan. Fitur ini sangat penting berdasarkan konsep terbaru. Fitur yang ada di `QRScannerKiosk.jsx` adalah untuk pengambilan di gudang, bukan validasi pembukaan di lahan.

#### ✅ QR Scanner Kiosk (`QRScannerKiosk.jsx`) — 7.3 KB, 179 baris
- UI kiosk gelap (dark theme, full screen)
- Input token QR secara manual
- Integrasi API `scan-qr` dengan response VALID/ALREADY_CLAIMED/INVALID
- **Koordinat hardcoded** di kode (`lat: -7.4726, lng: 112.4381`) — ini **bug serius** karena geolocation dinamis tidak digunakan

> **🔴 BUG KRITIS:** Koordinat GPS di kiosk scanner hardcoded, tidak mengambil GPS real-time dari perangkat. Ini membuat fitur geofencing tidak berfungsi.

### 5.2 Komponen Reusable yang Sudah Dibuat

| Komponen | Ukuran | Fungsi |
|---|---|---|
| `KPICard.jsx` | 2.2 KB | Card statistik angka dengan ikon, warna, badge |
| `StatusBadge.jsx` | 2.5 KB | Badge warna sesuai status aplikasi |
| `ProgressStepper.jsx` | 4.6 KB | Visualisasi langkah-langkah alur pengajuan |
| `PhotoViewerModal.jsx` | 4.5 KB | Modal fullscreen untuk lihat foto KTP & lahan |
| `FileUploadZone.jsx` | 5.3 KB | Drag-drop & preview upload gambar |
| `MapPicker.jsx` | 4.5 KB | Peta interaktif klik/geser pin koordinat |
| `Navbar.jsx` | 8.9 KB | Navigasi atas dengan notifikasi & profil |

### 5.3 State Management & Routing

- **Zustand (`authStore`):** Menyimpan state autentikasi global (token JWT, data user, role)
- **React Router v7:** Routing berbasis role dengan `ProtectedRoute` wrapper
- **Axios Interceptors:** Auto-attach Bearer token, auto-redirect saat token expired (401)
- **Vite Proxy:** Semua request `/api` dan `/files` di-proxy ke `localhost:8000`

### 5.4 Yang Belum Diimplementasikan di Frontend

| Fitur | Prioritas | Status |
|---|---|---|
| Dashboard PIMPINAN (monitoring only) | 🔴 Tinggi | Belum ada |
| Map Citra Satelit di PPL Dashboard | 🔴 Tinggi | Belum ada |
| Scan Barcode Pembukaan Karung di lahan | 🔴 Tinggi | Belum ada |
| Geolocation real-time di QR Kiosk | 🔴 Tinggi | Bug (hardcoded) |
| History Pembukaan Pupuk di Petani Dashboard | 🔴 Tinggi | Belum ada |
| Log Aktivitas PPL | 🟡 Sedang | Belum ada |
| Halaman RDKK / Kuota per Desa | 🟡 Sedang | Belum ada |
| Deteksi luas lahan via koordinat (polygon) | 🟡 Sedang | Belum ada |
| Fitur kondisi ekonomi petani di survei | 🟡 Sedang | Belum ada |
| Export data ke Excel/PDF | 🟢 Rendah | Belum ada |

---

## 6. Progress Backend

### 6.1 Struktur Proyek Backend

```
backend/
├── app/
│   ├── core/
│   │   ├── config.py          ✅ Settings, path konfigurasi
│   │   ├── database.py        ✅ SQLAlchemy engine & session
│   │   ├── dependencies.py    ✅ Auth guard, role checker, audit logger
│   │   └── security.py        ✅ JWT encode/decode, password hash
│   ├── models/
│   │   └── models.py          ✅ 12 model SQLAlchemy lengkap
│   ├── schemas/
│   │   └── schemas.py         ✅ Pydantic schemas (30+ class)
│   ├── routers/
│   │   ├── auth.py            ✅ Login, /me endpoint
│   │   ├── applications.py    ✅ CRUD pengajuan petani
│   │   ├── admin.py           ✅ Verifikasi, assign PPL, final approve, audit log
│   │   ├── ppl.py             ✅ Assigned tasks, start/submit survey
│   │   ├── distributions.py   ✅ QR scan, notifikasi
│   │   ├── farmers.py         ✅ Profil petani, kelompok tani
│   │   ├── lands.py           ✅ CRUD data lahan
│   │   └── files.py           ✅ Upload foto (KTP, lahan, survei)
│   ├── services/
│   │   └── file_storage.py    ✅ Handler penyimpanan file
│   └── main.py                ✅ FastAPI app + CORS + router mounting
├── seed_demo.py               ✅ Seed akun demo (admin, PPL, 2 petani)
├── seed_data.py               ✅ Seed data lengkap (lahan, aplikasi, dll)
├── schema.sql                 ✅ SQL schema untuk MySQL
└── requirements.txt           ✅ Dependencies Python
```

### 6.2 Endpoints yang Sudah Selesai

#### Auth (`/api/auth/`)
| Method | Endpoint | Fungsi | Status |
|---|---|---|---|
| POST | `/api/auth/login` | Login, return JWT token + role | ✅ |
| GET | `/api/auth/me` | Get current user profile | ✅ |

#### Applications (`/api/applications/`)
| Method | Endpoint | Fungsi | Status |
|---|---|---|---|
| GET | `/api/applications` | List pengajuan (filter by role) | ✅ |
| POST | `/api/applications` | Buat pengajuan baru | ✅ |
| GET | `/api/applications/{id}` | Detail pengajuan | ✅ |
| PUT | `/api/applications/{id}/revise-docs` | Revisi foto dokumen | ✅ |
| PUT | `/api/applications/{id}/cancel` | Batalkan pengajuan | ✅ |
| GET | `/api/applications/stats/petani` | Statistik dashboard petani | ✅ |

#### Admin (`/api/admin/`)
| Method | Endpoint | Fungsi | Status |
|---|---|---|---|
| GET | `/api/admin/stats` | Statistik KPI admin | ✅ |
| GET | `/api/admin/ppl-officers` | Daftar petugas PPL aktif | ✅ |
| POST | `/api/admin/applications/{id}/verify-docs` | Verifikasi berkas | ✅ |
| POST | `/api/admin/applications/{id}/assign-ppl` | Tugaskan PPL | ✅ |
| POST | `/api/admin/applications/{id}/final-approve` | Persetujuan akhir | ✅ |
| GET | `/api/admin/audit-logs` | Daftar audit log | ✅ |

#### PPL (`/api/ppl/`)
| Method | Endpoint | Fungsi | Status |
|---|---|---|---|
| GET | `/api/ppl/assigned-tasks` | Daftar tugas survei | ✅ |
| POST | `/api/ppl/applications/{id}/start-survey` | Mulai survei | ✅ |
| POST | `/api/ppl/applications/{id}/submit-survey` | Submit hasil survei | ✅ |

#### Distributions (`/api/distributions/`)
| Method | Endpoint | Fungsi | Status |
|---|---|---|---|
| GET | `/api/distributions/my` | Distribusi milik petani | ✅ |
| POST | `/api/distributions/scan-qr` | Scan & redeem QR code | ✅ |
| GET | `/api/notifications` | Notifikasi user | ✅ |
| PUT | `/api/notifications/{id}/read` | Tandai dibaca | ✅ |

#### Farmers, Lands, Files
| Method | Endpoint | Status |
|---|---|---|
| GET/POST | `/api/farmers`, `/api/farmers/me` | ✅ |
| GET/POST/PUT/DELETE | `/api/lands` | ✅ |
| POST | `/api/files/upload` | ✅ (max 5MB, JPEG/PNG/WebP) |

### 6.3 Fitur Backend yang Belum Diimplementasikan

| Fitur | Prioritas | Status |
|---|---|---|
| **Geofencing / Haversine** untuk validasi koordinat scan vs PPL | 🔴 Tinggi | ❌ Belum ada |
| **Log history pembukaan pupuk** endpoint untuk petani | 🔴 Tinggi | ❌ Belum ada |
| **Endpoint RDKK** (Rencana Definitif Kebutuhan Kelompok) | 🟡 Sedang | ❌ Belum ada |
| **Kondisi ekonomi petani** sebagai field tambahan survei | 🟡 Sedang | ❌ Belum ada |
| **Dashboard PIMPINAN** endpoint (statistik read-only) | 🟡 Sedang | ❌ Belum ada |
| **Kuota radius toleransi** geofencing (configurable) | 🟡 Sedang | ❌ Belum ada |
| **Webhook/Polling notifikasi real-time** | 🟢 Rendah | ❌ Belum ada |
| **Rate limiting** per endpoint | 🟢 Rendah | ❌ Belum ada |
| **Soft delete** untuk data petani | 🟢 Rendah | ❌ Belum ada |

### 6.4 Isu Keamanan yang Perlu Diperbaiki

1. **`CORS allow_origins=["*"]`** di `main.py` baris 25 — terlalu longgar untuk production. Harus dibatasi ke domain spesifik.
2. **Secret key default** di `config.py` baris 16 tersimpan langsung di kode (`epupuk-mojokerto-super-secret-key-2026-secure-jwt`). Harus diambil dari environment variable production saja.
3. **Token masa berlaku 24 jam** — cukup lama, pertimbangkan refresh token untuk production.

---

## 7. Progress Database

### 7.1 Deskripsi Tabel Lengkap (13 Tabel)

| No | Tabel | Baris Kunci | Fungsi | Status |
|---|---|---|---|---|
| 1 | `users` | id, username, email, role (PETANI/PPL/ADMIN/PIMPINAN), is_active | Autentikasi & otorisasi semua user | ✅ |
| 2 | `farmer_groups` | id, nama_kelompok, ketua_id, wilayah | Kelompok Tani | ✅ |
| 3 | `farmers` | id, user_id (FK), nama, nik, kontak, alamat, foto_ktp_url | Profil petani | ✅ |
| 4 | `commodities` | id, nama_komoditas, standar_kebutuhan_kg_per_ha | Jenis tanaman & standar pupuk/Ha | ✅ |
| 5 | `fertilizers` | id, nama_pupuk, satuan | Jenis pupuk bersubsidi | ✅ |
| 6 | `lands` | id, farmer_id (FK), latitude, longitude, luas_m2, commodity_id, status_kepemilikan, foto_lahan_url | Data lahan petani | ✅ |
| 7 | `applications` | id, farmer_id, land_id, fertilizer_id, jumlah_diajukan, **status** (12 enum), admin_verifier_id, assigned_ppl_id, final_approver_id | Inti alur pengajuan | ✅ |
| 8 | `field_surveys` | id, application_id (1:1), ppl_id, kondisi_fisik_lahan, kondisi_tanaman, **luas_lahan_aktual_m2**, foto_survei_urls (JSON), rekomendasi | Hasil survei PPL | ✅ |
| 9 | `fertilizer_batches` | id, batch_code, fertilizer_id, expired_date, stok_kg | Manajemen stok pupuk | ✅ |
| 10 | `distributions` | id, application_id (1:1), batch_id, jumlah_disalurkan, status_penyaluran, **qr_code_hash** (UNIQUE) | Penyaluran & token QR | ✅ |
| 11 | `qr_scans` | id, distribution_id, scanner_user_id, scan_timestamp, latitude, longitude, **validation_status** | Rekam setiap scan QR | ✅ |
| 12 | `notifications` | id, user_id, judul, pesan, tipe, is_read | Notifikasi per user | ✅ |
| 13 | `audit_logs` | id, user_id, action, resource, resource_id, details, ip_address | Log semua aksi sistem | ✅ |

### 7.2 Status Mesin Database

- **Development:** SQLite (`epupuk.db` ukuran 159 KB sudah berisi data seed) — ✅ Berjalan
- **Production Target:** MySQL dengan konfigurasi di `config.py` (env var) — ⏳ Belum di-deploy

### 7.3 Tabel yang Perlu Penyesuaian

| Tabel | Perubahan yang Diperlukan |
|---|---|
| `field_surveys` | Tambah kolom `kondisi_ekonomi TEXT` untuk mencatat kondisi ekonomi petani saat survei |
| `field_surveys` | Tambah kolom `koordinat_aktual_latitude` dan `koordinat_aktual_longitude` yang diisi PPL saat survei lapangan (BERBEDA dengan koordinat yang ada di tabel `lands` — koordinat ini adalah hasil pengukuran aktual di lapangan) |
| `qr_scans` | Tambah kolom `jarak_meter DECIMAL(10,2)` untuk menyimpan hasil kalkulasi jarak geofencing |
| `qr_scans` | Tambah kolom `catatan TEXT` untuk keterangan tambahan saat scan |
| `distributions` | Tambah kolom `qr_expired_at TIMESTAMP` untuk masa berlaku QR code |

### 7.4 ERD Ringkas

```
users ─┬─< farmers >─< lands >─< applications >─< field_surveys
       │                              │
       │                              ├─< distributions >─< qr_scans
       │                              │
       ├─[assigned_ppl_id]────────────┘
       ├─[admin_verifier_id]──────────┘
       ├─[final_approver_id]──────────┘
       │
       ├─< notifications
       └─< audit_logs

fertilizers ─< fertilizer_batches ─< distributions
commodities ─< lands
farmer_groups ─< farmers
```

---

## 8. Bug Report & Isu Teknis Saat Ini

### 🔴 Bug Kritis (Harus diperbaiki segera)

| ID | Komponen | Deskripsi Bug | Dampak | Solusi |
|---|---|---|---|---|
| BUG-001 | `QRScannerKiosk.jsx:28` | Koordinat GPS **hardcoded** (`lat: -7.4726, lng: 112.4381`). Tidak menggunakan `navigator.geolocation` secara real | Fitur geofencing tidak berfungsi sama sekali — semua scan akan dianggap dari lokasi yang sama | Gunakan `navigator.geolocation.getCurrentPosition()` sebelum submit scan |
| BUG-002 | `distributions.py:71` | Validasi scan QR **tidak melakukan geofencing** — langsung menandai distribusi SELESAI tanpa cek koordinat | Pupuk bisa di-scan dari mana saja, mengalahkan tujuan anti-penyalahgunaan | Tambahkan logika Haversine: hitung jarak antara `qr_scans.latitude` vs `field_surveys.koordinat_aktual` |
| BUG-003 | `App.jsx:108` | Role `PIMPINAN` diarahkan ke `AdminDashboard` yang sama dengan `ADMIN` — tampilan tidak dibedakan | PIMPINAN melihat tombol aksi (verifikasi, penugasan) yang tidak boleh dia gunakan | Buat route `/pimpinan` terpisah atau tambahkan kondisional UI berdasarkan `user.role` |
| BUG-004 | `admin.py:56-58` | Kuota pupuk **hardcoded** (`kuota_urea_kg: 150000, kuota_npk_kg: 120000`) — tidak dinamis dari database | Tidak mencerminkan alokasi pupuk yang sebenarnya | Buat tabel `fertilizer_quotas` atau field di `fertilizer_batches` |
| BUG-005 | `config.py:16` | Secret key JWT tersimpan langsung di kode sumber sebagai fallback string | Security vulnerability — siapapun yang bisa baca kode bisa memalsukan token | Hapus default fallback, wajibkan `SECRET_KEY` dari env variable |

### 🟡 Isu Sedang (Perlu diperbaiki sebelum release)

| ID | Komponen | Deskripsi | Solusi |
|---|---|---|---|
| ISS-001 | `main.py:25` | `allow_origins=["*"]` terlalu permisif | Batasi ke domain frontend production saja |
| ISS-002 | `applications.py:140` | Kuota maksimal pengajuan hardcoded `Decimal("500.00")` — semua petani dapat kuota sama | Hitung berdasarkan luas lahan × standar_kebutuhan_kg_per_ha dari tabel commodities |
| ISS-003 | `PPLDashboard.jsx:158` | Wilayah tugas PPL hardcoded `"Kec. Mojosari & Trowulan"` | Ambil dari database user/farmer_groups |
| ISS-004 | `ppl.py:62` | Foto survei URL diisi dummy `/files/survei/sample_survei_lahan1.jpg` saat form dibuka | Hapus default URL dummy — biarkan kosong sampai PPL benar-benar upload foto |
| ISS-005 | `distributions.py:49-55` | Cek `ALREADY_CLAIMED` tidak merekam scan ke tabel `qr_scans` | Tetap catat scan meskipun hasilnya ALREADY_CLAIMED untuk keperluan audit |
| ISS-006 | Frontend | Tidak ada handling error saat koordinat GPS tidak tersedia (pengguna menolak izin) | Tampilkan pesan yang jelas dan fallback untuk input manual |

### 🟢 Isu Minor (Nice to have)

| ID | Deskripsi |
|---|---|
| MIN-001 | MapPicker menggunakan OpenStreetMap biasa — untuk PPL perlu layer citra satelit (Esri/Mapbox/Google) |
| MIN-002 | Tidak ada pagination di endpoint audit-logs (saat ini hanya `limit: 50`) |
| MIN-003 | File upload belum compress/resize gambar — gambar besar bisa memperlambat sistem |
| MIN-004 | `requirements.txt` mengandung karakter null byte (encoding UTF-16 bukan UTF-8) |

---

## 9. Rencana Pengembangan Minggu 1–16

### Timeline Overview

```
MINGGU  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16
FASE   [──Konsep──] [──Core Dev──] [──Integrasi──] [──Lanjut──] [Test][Polish][Laporan]
SAAT INI                   ▲
                         Minggu 4
```

---

### 📅 Detail Per Minggu

| Minggu | Fase | Target Output | PIC | Status |
|---|---|---|---|---|
| **1** | Riset & Studi Literatur | Studi distribusi pupuk, review literatur sistem informasi pertanian, benchmarking aplikasi sejenis | Tim | ✅ Selesai |
| **2** | Perancangan Konsep Awal | Draft alur sistem, mockup wireframe UI, pembuatan ERD awal, proposal sistem | Tim | ✅ Selesai |
| **3** | Finalisasi & Konsultasi Dosen | Review bersama dosen: ✅ Pemisahan role Admin Pemda vs PPL, ✅ Mekanisme barcode di lahan, ✅ Konfirmasi ERD & alur proses akhir | Tim + Dosen | ✅ Selesai |
| **4** *(Saat Ini)* | Core Setup & Fondasi | Init project frontend (React+Vite+Tailwind) & backend (FastAPI), setup DB SQLite, seed data demo, halaman login, layout dashboard dasar, komponen MapPicker, API auth | Tim | 🔄 Berjalan (70%) |
| **5** | Backend API Completion | Selesaikan semua endpoint CRUD, implementasi geofencing Haversine, perbaiki BUG-001 & BUG-002, tambah kolom `kondisi_ekonomi` & `koordinat_aktual` di survei | Backend | ⏳ |
| **6** | Pemisahan Role & Routing | Buat halaman/tampilan PIMPINAN terpisah, pisahkan route `/admin` (ADMIN) vs `/pimpinan` (PIMPINAN), perbaiki BUG-003, finalisasi role guard frontend | Frontend | ⏳ |
| **7** | Integrasi Petani Dashboard | Sambungkan semua data real ke `PetaniDashboard`, tambah fitur "Scan Barcode Pembukaan Karung" (scanner kamera), tambah History Pembukaan Pupuk | Frontend + Backend | ⏳ |
| **8** | Integrasi Admin Pemda Dashboard | Sambungkan semua data real ke `AdminDashboard`, tambah map layer satelit untuk review koordinat, fitur monitoring kuota distribusi | Frontend + Backend | ⏳ |
| **9** | Integrasi PPL Dashboard & Map Satelit | Tambah map citra satelit (Esri/Mapbox tile layer) di `PPLDashboard`, fitur input koordinat aktual saat survei, input kondisi ekonomi petani, upload foto multi | Frontend + Backend | ⏳ |
| **10** | Fitur Log & History Lengkap | Implementasikan History Pembukaan Pupuk di semua dashboard, Log Aktivitas PPL, Audit Log Admin dengan filter & pagination, Kiosk Log harian | Frontend + Backend | ⏳ |
| **11** | QR Code & Geofencing | Perbaiki QRScannerKiosk (real GPS), finalisasi logika Haversine di backend, uji coba validasi koordinat dengan radius toleransi, buat QR Code expiry | Backend + Frontend | ⏳ |
| **12** | Notifikasi & Kuota Dinamis | Implementasi polling notifikasi (atau WebSocket sederhana), hitung kuota berdasarkan luas lahan × standar komoditas, halaman RDKK per kelompok tani | Backend + Frontend | ⏳ |
| **13** | Testing & UAT | Unit testing endpoint backend (pytest), User Acceptance Testing dengan aktor nyata (simulasi petani, admin dinas, PPL), perbaikan bug dari UAT | Tim | ⏳ |
| **14** | Stress Test & Security Audit | Load testing API, perbaiki semua isu keamanan (CORS, secret key, rate limiting), review SQL injection, review file upload security | Tim | ⏳ |
| **15** | Polish UI/UX & Deployment Staging | Percantik tampilan final, responsive mobile testing, deploy ke VPS/Cloud (PostgreSQL/MySQL production), setup domain & SSL | Tim + DevOps | ⏳ |
| **16** | Finalisasi Laporan & Demo | Penulisan laporan akhir skripsi/TA, penyusunan manual book aplikasi, persiapan presentasi & demo sistem | Tim | ⏳ |

---

### Prioritas Minggu 4 yang Harus Diselesaikan Sebelum Minggu 5

- [ ] **BUG-001:** Perbaiki koordinat hardcoded di QR Scanner — gunakan `navigator.geolocation`
- [ ] **BUG-003:** Buat route/tampilan terpisah untuk PIMPINAN
- [ ] **BUG-004:** Perbaiki kuota hardcoded di `admin.py`
- [ ] **ISS-002:** Kuota pengajuan dihitung dari luas lahan × standar komoditas
- [ ] Tambah kolom `koordinat_aktual_latitude/longitude` dan `kondisi_ekonomi` di tabel `field_surveys`
- [ ] Tambah komponen History Pembukaan Pupuk (tabel `qr_scans`) di `PetaniDashboard`

---

## 10. Kesimpulan

| Aspek | Kondisi Saat Ini | Target Minggu 8 |
|---|---|---|
| **Backend API** | ~75% selesai (8 router, 30+ endpoint) | 100% + geofencing |
| **Frontend UI** | ~55% selesai (4 halaman utama) | 100% + role split |
| **Database Schema** | ~85% selesai (13 tabel) | 100% + 3 kolom tambahan |
| **Integrasi Frontend↔Backend** | ~40% | 100% |
| **Fitur Keamanan** | ~30% (baru JWT & role guard) | 70% + geofencing aktif |
| **Fitur Log/History** | ~20% (audit log admin saja) | 100% semua dashboard |

### Poin Kunci yang Harus Dikomunikasikan ke Dosen Pembimbing

1. **Klarifikasi mekanisme barcode:** Barcode di karung hanya berisi ID statis — koordinat & timestamp diambil oleh aplikasi saat scan, bukan dari barcode itu sendiri. Ini perlu disetujui dalam dokumentasi teknis.
2. **Pemisahan role Admin Pemda vs PIMPINAN:** Perlu konfirmasi apakah PIMPINAN memerlukan halaman khusus atau cukup tampilan kondisional di `AdminDashboard`.
3. **Layer peta satelit PPL:** Penggunaan tile layer citra satelit (Esri World Imagery / Mapbox / Google Maps API) memerlukan API Key berbayar. Perlu keputusan anggaran atau penggunaan alternatif gratis.
4. **Toleransi radius geofencing:** Berapa meter radius yang dianggap VALID untuk scan pembukaan karung? (Saran teknis: 50–100 meter untuk mengakomodasi akurasi GPS HP di daerah pedesaan).

---

*Laporan ini dibuat berdasarkan analisis mendalam terhadap source code proyek E-Pupuk Kabupaten Mojokerto pada tanggal **16 September 2026** (Minggu ke-4 pengembangan). Laporan mencakup 13 file utama backend, 5 halaman frontend, 7 komponen reusable, dan 13 tabel database.*

*Dibuat oleh: Sistem Analisis Kode Otomatis (AGY) | Untuk keperluan internal pengembangan*
