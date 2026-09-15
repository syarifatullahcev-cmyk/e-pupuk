# System Architecture
# E-Pupuk Kabupaten Mojokerto

Dokumen ini melengkapi `02-system-design.md` dengan gambaran arsitektur yang lebih rinci: arsitektur sistem keseluruhan, arsitektur modul backend, arsitektur aliran data, dan arsitektur keamanan. Dokumen ini adalah referensi utama saat menjelaskan sistem ke pembimbing/penguji maupun saat membuat diagram visual (mis. draw.io, Figma, atau prompt ke Google Stitch di §5).

## 1. Arsitektur Sistem Keseluruhan

```
                         ┌─────────────────────────────┐
                         │       PENGGUNA SISTEM        │
                         │                              │
                         │  Petani                      │
                         │  PPL                         │
                         │  Admin                       │
                         │  Pimpinan                    │
                         └──────────────┬───────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                    FRONTEND - REACT.JS                          │
│                                                                  │
│  ┌───────────────┐ ┌──────────────┐ ┌─────────────────────────┐ │
│  │ Login/Register│ │ Dashboard    │ │ Pengajuan Subsidi        │ │
│  └───────────────┘ └──────────────┘ └─────────────────────────┘ │
│  ┌───────────────┐ ┌──────────────┐ ┌─────────────────────────┐ │
│  │ QR Scanner    │ │ Status       │ │ Dashboard Admin/Pimpinan │ │
│  │ html5-qrcode  │ │ Pengajuan    │ │ Map + Grafik + KPI       │ │
│  └───────────────┘ └──────────────┘ └─────────────────────────┘ │
└──────────────────────────┬───────────────────────────────────────┘
                           │ HTTPS / REST API
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                    BACKEND - FASTAPI                             │
│                                                                   │
│  ┌────────────────┐  ┌──────────────────────────────────────┐   │
│  │ Authentication  │  │ User & Farmer Management              │   │
│  │ JWT + RBAC      │  │ Profile, Kelompok, Lahan               │   │
│  └────────────────┘  └──────────────────────────────────────┘   │
│  ┌────────────────┐  ┌──────────────────────────────────────┐   │
│  │ Quota Engine    │  │ Application Management                │   │
│  │ RDKK + Luas     │  │ Pengajuan → Verifikasi → Persetujuan  │   │
│  │ Lahan           │  └──────────────────────────────────────┘   │
│  └────────────────┘                                              │
│  ┌────────────────┐  ┌──────────────────────────────────────┐   │
│  │ QR Validation   │  │ Distribution & Batch Management       │   │
│  │ Expired Check   │  │ Batch ID, Expired, Timestamp          │   │
│  │ Stockpiling     │  └──────────────────────────────────────┘   │
│  └────────────────┘                                              │
│  ┌────────────────┐  ┌──────────────────────────────────────┐   │
│  │ Reporting       │  │ External API Integration              │   │
│  │ Audit Trail     │  │ Weather / Map / Open Data              │   │
│  └────────────────┘  └──────────────────────────────────────┘   │
└──────────────┬──────────────────────┬────────────────────────────┘
               │                      │
               ▼                      ▼
┌──────────────────────────┐   ┌─────────────────────────────────┐
│      MySQL DATABASE      │   │       EXTERNAL DATA / API        │
│                           │   │                                  │
│ users                     │   │ Data Terbuka Pemerintah          │
│ farmers                   │   │ Weather API                      │
│ farmer_groups             │   │ Geospatial / Map API              │
│ lands                     │   │                                  │
│ commodities                │   └─────────────────────────────────┘
│ rdkk                       │
│ applications                │
│ verifications                │
│ fertilizer_batches            │
│ distributions                  │
│ qr_scans                        │
│ notifications                     │
│ audit_logs                          │
└──────────────────────────┘
```

### 1.1 Alur Utama

**1) Pengguna mengakses frontend.** Petani, PPL, admin, dan pimpinan mengakses aplikasi lewat browser (desktop/mobile). Petani melihat data lahan, estimasi kuota, mengajukan subsidi, dan scan QR. PPL memverifikasi. Admin/Pimpinan memonitor.

**2) Frontend berkomunikasi dengan FastAPI.**
```
Petani klik "Ajukan Pupuk"
        ↓
React mengirim data
        ↓
FastAPI menerima request
        ↓
Backend melakukan validasi
        ↓
Backend mengambil data RDKK + lahan
        ↓
Kuota dihitung
        ↓
Data disimpan ke MySQL
        ↓
Response dikirim kembali ke React
```

**3) Backend adalah pusat logika bisnis.**
```
Data Lahan + Data Komoditas + Data RDKK
        ↓
   Quota Engine
        ↓
Perhitungan Kuota
        ↓
Hasil Kuota Petani
```
Untuk QR:
```
Scan QR → Batch ID → Backend mencari batch
        → Cek tanggal expired
        → Cek riwayat penerimaan
        → Cek indikasi penimbunan
        → Valid / Warning / Ditolak
```
> Sistem mendeteksi **indikasi** penimbunan berdasarkan riwayat penerimaan — bukan menjamin 100% mencegah penimbunan.

## 2. Arsitektur Modul Backend

```
FASTAPI BACKEND
│
├── Authentication
│   ├── Login
│   ├── Register
│   ├── JWT
│   └── Role / Permission
│
├── Farmer Management
│   ├── Data Petani
│   ├── Kelompok Tani
│   └── Profil
│
├── Land Management
│   ├── Luas Lahan
│   ├── Lokasi Lahan
│   └── Komoditas
│
├── RDKK Management
│   ├── Data RDKK
│   ├── Kuota
│   └── Referensi Open Data
│
├── Application Management
│   ├── Pengajuan
│   ├── Status
│   └── Riwayat
│
├── Verification
│   ├── Verifikasi PPL
│   ├── Approve
│   ├── Reject
│   └── Catatan
│
├── Quota Engine
│   ├── Luas Lahan
│   ├── Komoditas
│   └── RDKK
│
├── QR & Fertilizer Batch
│   ├── QR Scan
│   ├── Batch ID
│   ├── Expired Date
│   └── Riwayat Distribusi
│
├── Distribution
│   ├── Penyaluran
│   ├── Jumlah
│   └── Penerima
│
├── Dashboard
│   ├── KPI
│   ├── Grafik
│   ├── Map
│   └── Monitoring
│
└── Audit & Notification
    ├── Audit Log
    └── Notification
```
Pembagian modul ini dipakai sebagai acuan struktur folder/service saat implementasi backend (mis. satu modul FastAPI ≈ satu router + service + schema).

## 3. Arsitektur Data

```
Open Data / RDKK
       │
       ▼
   DATA REFERENSI
       │
       ▼
┌───────────────┐
│    MySQL      │
└───────┬───────┘
        │
        ├──────────────► Data Petani
        ├──────────────► Data Lahan
        ├──────────────► Data Komoditas
        ├──────────────► Data RDKK
        ├──────────────► Data Pengajuan
        ├──────────────► Data Verifikasi
        ├──────────────► Data Pupuk
        └──────────────► Data Distribusi
                              │
                              ▼
                         DASHBOARD
```

Untuk API eksternal:
```
External API
     │
     ▼
 FastAPI
     │
     ▼
 Normalisasi / Validasi
     │
     ▼
 Dashboard
```
Frontend **tidak pernah** memanggil API eksternal secara langsung — React meminta data ke FastAPI, dan FastAPI yang berkomunikasi dengan API eksternal. Ini menjaga konsistensi format data dan memudahkan caching/rate-limit handling di satu titik.

## 4. Arsitektur Keamanan

```
                 LOGIN
                   │
                   ▼
             Authentication
                   │
                   ▼
                 JWT
                   │
                   ▼
            Role Validation
                   │
        ┌──────────┼──────────┐
        ▼          ▼          ▼
      PETANI       PPL      ADMIN/PIMPINAN
        │          │          │
        ▼          ▼          ▼
 Dashboard    Verifikasi   Monitoring
 Pengajuan    Petani       & Reporting
 QR Scan
```

| Role | Akses Utama |
|---|---|
| Petani | Profil, lahan, pengajuan, QR, status |
| PPL | Verifikasi pengajuan dan data petani |
| Admin | Kelola data, distribusi, monitoring |
| Pimpinan | Dashboard dan laporan |

Lapisan keamanan tambahan: validasi input di setiap endpoint, audit log untuk aksi sensitif (verifikasi, distribusi, perubahan data master), serta penyamaran data sensitif (mis. NIK) untuk peran yang tidak berwenang melihat detail penuh (lihat `05-api-data-database.md` §13).

## 5. Prompt untuk Google Stitch — Diagram Arsitektur
Untuk menghasilkan visual arsitektur (bukan mockup UI — untuk mockup UI lihat `03-ui-ux-design.md` §11), gunakan prompt berikut:

"Buatkan diagram arsitektur sistem berlapis (layered architecture diagram) untuk aplikasi web bernama 'E-Pupuk'. Gaya: clean, teknis, kotak-kotak dengan panah vertikal menghubungkan antar layer, palet warna hijau-abu profesional. Layer dari atas ke bawah: (1) 'Pengguna Sistem' berisi empat ikon aktor — Petani, PPL, Admin, Pimpinan; (2) 'Frontend - React.js' berisi empat modul: Login, Dashboard, Pengajuan Subsidi, QR Scanner; (3) 'Backend - FastAPI' berisi enam modul dalam grid 2 kolom: Authentication, Quota Engine, QR Validation, User Management, Application Management, Distribution Management; (4) dua kotak sejajar di bawah backend: 'MySQL Database' berisi daftar tabel kecil (users, farmers, applications, distributions, qr_scans) dan 'External API' berisi Weather API, Map API, Open Data. Hubungkan tiap layer dengan panah vertikal tebal berlabel 'REST API' antara frontend dan backend."

## 6. Referensi Silang
- Detail modul dan endpoint: `05-api-data-database.md`
- Detail alur fitur (kuota, QR, deteksi penimbunan): `04-feature-specification.md`
- Detail tampilan tiap dashboard: `03-ui-ux-design.md`
- Ruang lingkup dan requirement: `01-product-requirements.md`
