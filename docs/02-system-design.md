# System Design
# E-Pupuk Kabupaten Mojokerto

## 1. System Overview
E-Pupuk dibangun dengan arsitektur three-tier klasik: **React.js (frontend)** berkomunikasi via REST API dengan **FastAPI (backend)**, yang menyimpan data ke **MySQL** dan berkomunikasi dengan **API eksternal/data terbuka** untuk memperkaya dashboard. Seluruh logika bisnis (kalkulasi kuota, validasi QR, deteksi penimbunan) berada di backend, bukan di frontend, agar konsisten dan dapat diaudit.

## 2. System Architecture

### 2.1 Frontend
React.js + Tailwind CSS. Bertanggung jawab atas tampilan, form input, scan QR (via kamera perangkat), dan visualisasi (peta, grafik). Tidak menyimpan logika bisnis penting — hanya validasi input dasar.

### 2.2 Backend
FastAPI. Menangani autentikasi, validasi, kalkulasi kuota, validasi QR/expired, deteksi indikasi penimbunan, dan orkestrasi ke database serta API eksternal.

### 2.3 Database
MySQL. Menyimpan seluruh data transaksional dan master data (lihat detail skema di `05-api-data-database.md`).

### 2.4 External API
Sumber data pelengkap: data terbuka pemerintah (mis. referensi RDKK/pertanian), API cuaca, dan API geospasial/peta — dipanggil oleh backend, bukan langsung oleh frontend.

### 2.5 Authentication
JWT (JSON Web Token) dengan role-based access control (RBAC) untuk empat peran: Petani, PPL, Admin, Pimpinan.

## 3. Technology Stack

| Layer | Technology | Purpose |
|---|---|---|
| Frontend | React.js | User Interface |
| Styling | Tailwind CSS | UI Styling |
| Backend | FastAPI | REST API |
| Database | MySQL | Data Storage |
| Authentication | JWT | Authentication |
| QR Scanner | html5-qrcode | QR Scanning |
| Map | Leaflet | Geospatial Visualization |
| Chart | Recharts | Data Visualization |

## 4. Architecture Diagram

```
React (Frontend)
      │  HTTPS / REST API
      ▼
FastAPI (Backend)
      │
      ▼
Business Logic
  ├── Kalkulasi Kuota
  ├── QR Validation
  ├── Expired Check
  ├── Deteksi Indikasi Penimbunan
  └── External API Integration
      │
      ▼
   MySQL
      │
      ▼
Dashboard (Admin/Pimpinan)
```

Diagram arsitektur yang lebih rinci (termasuk arsitektur modul, data, dan keamanan) ada di `06-system-architecture.md`.

## 5. System Actors
- **Petani** — pengaju subsidi, penerima pupuk, pelaku scan QR.
- **PPL** — verifikator pengajuan di wilayah binaan.
- **Admin Dinas** — pengelola data master dan distribusi, penerima alert.
- **Pimpinan Dinas** — pemantau KPI dan laporan strategis.

## 6. Role & Permission

| Modul | Petani | PPL | Admin | Pimpinan |
|---|---|---|---|---|
| Profil & Lahan Sendiri | CRUD | Read | CRUD | Read |
| Pengajuan | Create/Read (milik sendiri) | Read | Read | Read |
| Verifikasi | - | CRUD | Read | Read |
| Data Master (petani, pupuk, batch) | - | - | CRUD | Read |
| Distribusi | Read (milik sendiri) | Read | CRUD | Read |
| Scan QR | Create | Create | Read | - |
| Dashboard & Laporan | - | Terbatas (wilayah) | Penuh | Penuh |
| Audit Log | - | - | Read | Read |

## 7. Main System Flow

### 7.1 Petani
Login → lihat estimasi kuota → ajukan pupuk → pantau status pengajuan → terima pupuk & scan QR → lihat riwayat distribusi.

### 7.2 PPL
Login → lihat daftar pengajuan wilayah → buka detail pengajuan → approve/reject dengan catatan.

### 7.3 Admin
Login → kelola data master (petani, lahan, komoditas, pupuk, batch) → pantau distribusi & status QR → tindak lanjuti alert.

### 7.4 Pimpinan
Login → lihat dashboard KPI → lihat peta distribusi & grafik → unduh/lihat laporan periodik.

## 8. Data Flow

### 8.1 Input
Data petani, lahan, komoditas, pengajuan, hasil scan QR.

### 8.2 Processing
Kalkulasi kuota, validasi verifikasi, validasi QR (batch, expired, duplikasi), deteksi indikasi penimbunan.

### 8.3 Storage
Seluruh entitas disimpan di MySQL (lihat `05-api-data-database.md`) dengan audit log untuk aksi sensitif.

### 8.4 Output
Status pengajuan, hasil verifikasi, status distribusi, hasil scan QR, serta agregasi untuk dashboard (KPI, grafik, peta).

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
```

## 10. Error Handling
- Validasi input di level API (400 Bad Request untuk data tidak valid).
- Kuota melebihi batas → status `OVERLIMIT`, ditolak otomatis, dapat direview manual oleh PPL/Admin.
- QR tidak ditemukan/rusak → status `INVALID`.
- QR sudah pernah dipindai untuk transaksi yang sama → status `DUPLICATE`.
- Token kedaluwarsa/invalid → 401, redirect ke halaman login.
- Kegagalan koneksi ke API eksternal tidak menghentikan alur inti — dashboard menampilkan data terakhir yang tersedia dengan indikator "data mungkin tidak terbaru".

## 11. Security Architecture
Lihat detail lengkap alur otentikasi dan otorisasi berbasis peran di `06-system-architecture.md` bagian Arsitektur Keamanan. Prinsip dasar: JWT untuk autentikasi, RBAC untuk otorisasi per modul, audit log untuk seluruh aksi verifikasi/distribusi/perubahan data master, dan validasi input di setiap endpoint.
