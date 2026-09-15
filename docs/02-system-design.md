# System Design
# E-Pupuk Kabupaten Mojokerto

## 1. System Overview
E-Pupuk dibangun dengan arsitektur three-tier klasik: **React.js (frontend)** berkomunikasi via REST API dengan **FastAPI (backend)**, yang menyimpan data ke **MySQL** dan berkomunikasi dengan **API eksternal/data terbuka** untuk memperkaya dashboard. Seluruh logika bisnis (kalkulasi kuota, validasi QR, deteksi penimbunan, verifikasi berkas, disposisi penugasan PPL) berada di backend, bukan di frontend, agar konsisten dan dapat diaudit. Berkas foto (KTP, foto lahan, foto survei lapangan) dikelola oleh layanan penyimpanan berkas terintegrasi di backend.

## 2. System Architecture

### 2.1 Frontend
React.js + Tailwind CSS. Bertanggung jawab atas tampilan, form input (termasuk upload foto multipart), picker koordinat peta (Leaflet), scan QR (via kamera perangkat), dan visualisasi (peta, grafik). Tidak menyimpan logika bisnis penting — hanya validasi input dasar dan preview berkas sebelum upload.

### 2.2 Backend
FastAPI. Menangani autentikasi, validasi, kalkulasi kuota, validasi berkas (MIME type, ukuran), penyimpanan berkas, verifikasi berkas oleh Admin, disposisi penugasan PPL, penerimaan laporan survei lapangan PPL, validasi QR/expired, deteksi indikasi penimbunan, dan orkestrasi ke database serta API eksternal.

### 2.3 Database
MySQL. Menyimpan seluruh data transaksional dan master data (lihat detail skema di `05-api-data-database.md`).

### 2.4 File Storage
Penyimpanan berkas foto (KTP, lahan, survei lapangan) menggunakan layanan penyimpanan lokal (filesystem server) atau object storage (mis. MinIO / S3-compatible) dengan:
- Akses URL berkas yang diamankan (hanya dapat diakses oleh peran yang berwenang via backend proxy).
- Validasi MIME type (JPEG/PNG/WEBP) dan ukuran maksimum (5MB per berkas) di sisi backend.
- Audit log setiap akses ke berkas foto KTP.

### 2.5 External API
Sumber data pelengkap: data terbuka pemerintah (mis. referensi RDKK/pertanian), API cuaca, dan API geospasial/peta — dipanggil oleh backend, bukan langsung oleh frontend.

### 2.6 Authentication
JWT (JSON Web Token) dengan role-based access control (RBAC) untuk empat peran: Petani, PPL, Admin, Pimpinan.

## 3. Technology Stack

| Layer | Technology | Purpose |
|---|---|---|
| Frontend | React.js | User Interface |
| Styling | Tailwind CSS | UI Styling |
| Backend | FastAPI | REST API & Business Logic |
| Database | MySQL | Data Storage |
| File Storage | Local FS / MinIO | Penyimpanan berkas foto |
| Authentication | JWT | Authentication |
| QR Scanner | html5-qrcode | QR Scanning |
| Map | Leaflet | Peta & koordinat lokasi lahan |
| Chart | Recharts | Data Visualization |

## 4. Architecture Diagram

```
React (Frontend)
      │  HTTPS / REST API (multipart/form-data untuk upload berkas)
      ▼
FastAPI (Backend)
      │
      ▼
Business Logic
  ├── Kalkulasi Kuota
  ├── Validasi & Simpan Berkas (KTP, foto lahan, foto survei)
  ├── Verifikasi Berkas Admin
  ├── Disposisi Penugasan PPL
  ├── Field Survey Service (PPL)
  ├── QR Validation
  ├── Expired Check
  ├── Deteksi Indikasi Penimbunan
  └── External API Integration
      │
      ├──► MySQL
      └──► File Storage (berkas foto)
      │
      ▼
Dashboard (Admin/Pimpinan)
```

Diagram arsitektur yang lebih rinci (termasuk arsitektur modul, data, dan keamanan) ada di `06-system-architecture.md`.

## 5. System Actors
- **Petani** — pengaju subsidi, penerima pupuk, pelaku scan QR, pengunggah KTP dan foto lahan.
- **PPL** — penerima penugasan survei lapangan dari Admin, verifikator fisik kondisi lahan dan bahan/tanaman, pengunggah foto bukti lapangan dan laporan survei.
- **Admin Dinas** — verifikator berkas administratif, pemberi penugasan PPL (disposisi), pemberi persetujuan akhir distribusi, pengelola data master dan distribusi, penerima alert.
- **Pimpinan Dinas** — pemantau KPI dan laporan strategis.

## 6. Role & Permission

| Modul | Petani | PPL | Admin | Pimpinan |
|---|---|---|---|---|
| Profil & Lahan Sendiri | CRUD | Read | CRUD | Read |
| Upload Berkas (KTP, Foto Lahan) | Create (milik sendiri) | Read (untuk penugasan) | Read | — |
| Pengajuan | Create/Read (milik sendiri) | Read | Read | Read |
| Verifikasi Berkas | — | — | CRUD | Read |
| Penugasan PPL | — | Read (tugasnya sendiri) | CRUD | Read |
| Survei Lapangan | — | CRUD (tugasnya sendiri) | Read | Read |
| Persetujuan Akhir | — | — | CRUD | Read |
| Data Master (petani, pupuk, batch) | — | — | CRUD | Read |
| Distribusi | Read (milik sendiri) | Read | CRUD | Read |
| Scan QR | Create | Create | Read | — |
| Dashboard & Laporan | — | Terbatas (wilayah) | Penuh | Penuh |
| Audit Log | — | — | Read | Read |

## 7. Main System Flow

### 7.1 Petani
Login → isi form pengajuan + unggah KTP & foto lahan + alamat + koordinat + tanggal → pantau status pengajuan (6 tahap progress stepper) → jika PERLU_PERBAIKAN_BERKAS: unggah ulang berkas → terima pupuk & scan QR → lihat riwayat distribusi.

### 7.2 PPL
Login → lihat daftar tugas survei lapangan → buka detail tugas (data petani, foto KTP referensi, foto lahan referensi, alamat, koordinat GPS) → kunjungi lahan secara fisik → isi form laporan survei (foto bukti kondisi fisik, catatan kelayakan bahan/tanaman, rekomendasi setuju/tolak) → submit laporan.

### 7.3 Admin
Login → kelola data master → **verifikasi berkas pengajuan petani** (periksa KTP, foto lahan, alamat, koordinat) → **tugaskan PPL wilayah untuk survei lapangan** → terima laporan survei PPL → **berikan persetujuan akhir & jadwalkan distribusi** → pantau distribusi & status QR → tindak lanjuti alert.

### 7.4 Pimpinan
Login → lihat dashboard KPI → lihat peta distribusi & grafik → unduh/lihat laporan periodik.

### 7.5 Alur Lengkap Pengajuan (5-Stage Lifecycle)

```
[PETANI]              [ADMIN]                   [PPL]                    [ADMIN]
    │                    │                         │                         │
    ▼                    │                         │                         │
Isi Pengajuan +          │                         │                         │
Upload KTP,              │                         │                         │
Foto Lahan,              │                         │                         │
Alamat, Koordinat,       │                         │                         │
Tanggal                  │                         │                         │
    │                    │                         │                         │
    ▼ (status: DIAJUKAN) │                         │                         │
─────────────────────────┤                         │                         │
                         ▼                         │                         │
                  Verifikasi Berkas:                │                         │
                  cek KTP, foto lahan,             │                         │
                  alamat, koordinat                │                         │
                         │                         │                         │
              ┌──────────┴──────────┐              │                         │
              ▼                     ▼              │                         │
  PERLU_PERBAIKAN_BERKAS     BERKAS_TERVERIFIKASI  │                         │
  → notif petani             → Tugaskan PPL ───────┤                         │
  → petani unggah ulang            │               │                         │
                                   ▼               ▼                         │
                         (status: DITUGASKAN) Survei Lapangan:               │
                                               Foto fisik lahan,             │
                                               cek bahan/tanaman,            │
                                               upload foto bukti,            │
                                               catatan & rekomendasi         │
                                                   │                         │
                                    ───────────────┤                         │
                                                   ▼ (laporan diterima)      ▼
                                                                    Approval Akhir &
                                                                    Alokasi Distribusi
                                                                             │
                                                               ┌────────────┴────────────┐
                                                               ▼                         ▼
                                                          DISETUJUI                  DITOLAK
                                                          → Jadwalkan                (final)
                                                            Distribusi
                                                               │
                                                               ▼
                                                          TERSALURKAN
                                                        (scan QR serah terima)
```

## 8. Data Flow

### 8.1 Input
Data petani (termasuk foto KTP, alamat, tanggal registrasi), data lahan (foto lahan, koordinat GPS, alamat lahan), pengajuan, berkas pendukung multipart, hasil survei PPL (foto lapangan, catatan, rekomendasi), hasil scan QR.

### 8.2 Processing
Validasi & penyimpanan berkas foto, kalkulasi kuota, verifikasi berkas Admin, disposisi penugasan PPL, penerimaan laporan survei lapangan, validasi QR (batch, expired, duplikasi), deteksi indikasi penimbunan.

### 8.3 Storage
Seluruh entitas disimpan di MySQL (lihat `05-api-data-database.md`) dengan audit log untuk aksi sensitif. Berkas foto disimpan di File Storage dengan URL aman yang diakses via backend proxy.

### 8.4 Output
Status pengajuan (6 tahap), hasil verifikasi berkas, laporan survei PPL, status distribusi, hasil scan QR, serta agregasi untuk dashboard (KPI, grafik, peta).

## 9. Authentication Flow

```
User submit login (email/username + password)
        │
        ▼
FastAPI verifikasi kredensial
        │
        ▼
   Password valid? ──No──► 401 Unauthorized
        │ Yes
        ▼
Generate JWT (berisi user_id + role)
        │
        ▼
Token dikirim ke frontend, disimpan di client
        │
        ▼
Setiap request berikut menyertakan token
        │
        ▼
Backend validasi token & role sebelum proses request
(Untuk akses berkas foto KTP: validasi tambahan — hanya Admin dan PPL yang ditugaskan)
```

## 10. Error Handling
- Validasi input di level API (400 Bad Request untuk data tidak valid).
- Upload berkas melebihi ukuran (> 5MB) atau format tidak didukung → 422 Unprocessable Entity dengan pesan spesifik.
- Kuota melebihi batas → status `OVERLIMIT`, ditolak otomatis, dapat direview manual oleh PPL/Admin.
- QR tidak ditemukan/rusak → status `INVALID`.
- QR sudah pernah dipindai untuk transaksi yang sama → status `DUPLICATE`.
- Token kedaluwarsa/invalid → 401, redirect ke halaman login.
- Kegagalan koneksi ke API eksternal tidak menghentikan alur inti — dashboard menampilkan data terakhir yang tersedia dengan indikator "data mungkin tidak terbaru".

## 11. Security Architecture
Lihat detail lengkap alur otentikasi dan otorisasi berbasis peran di `06-system-architecture.md` bagian Arsitektur Keamanan. Prinsip dasar: JWT untuk autentikasi, RBAC untuk otorisasi per modul, audit log untuk seluruh aksi verifikasi berkas / penugasan PPL / survei lapangan / distribusi / perubahan data master, validasi input di setiap endpoint, serta perlindungan data sensitif (NIK, foto KTP) dengan akses terbatas hanya untuk Admin dan PPL yang ditugaskan pada pengajuan terkait.
