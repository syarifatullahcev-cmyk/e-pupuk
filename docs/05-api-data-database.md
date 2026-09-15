# API, Data & Database
# E-Pupuk Kabupaten Mojokerto

## 1. Data Architecture
Data E-Pupuk terbagi menjadi dua sumber besar: **data internal** (hasil input pengguna sistem — petani, lahan, pengajuan, distribusi, scan QR) dan **data eksternal** (data terbuka pemerintah dan API pihak ketiga untuk pengayaan dashboard). Frontend tidak pernah memanggil API eksternal secara langsung — seluruh panggilan eksternal melalui backend agar dapat dinormalisasi, divalidasi, dan di-cache.

## 2. Data Sources

### 2.1 Internal Data
Data yang dihasilkan dari alur sistem: users, farmers, lands, applications, verifications, fertilizer_batches, distributions, qr_scans, audit_logs.

### 2.2 Open Government Data
Data referensi seperti RDKK dan data pertanian dari sumber data terbuka pemerintah (mis. portal data.go.id atau dinas terkait), dipakai sebagai referensi/seed — bukan sinkronisasi otomatis penuh pada versi awal.

### 2.3 External API
API cuaca dan API geospasial/peta untuk pengayaan dashboard Admin/Pimpinan.

## 3. Dataset

### 3.1 RDKK
Referensi kebutuhan pupuk per kelompok tani/komoditas — dipakai sebagai pembanding terhadap kalkulasi kuota otomatis.

### 3.2 Luas Lahan
Dataset lahan petani, idealnya tervalidasi terhadap data lahan resmi bila tersedia; pada versi awal diinput manual/diverifikasi PPL.

### 3.3 Produksi Tanaman
Data historis produksi per komoditas (opsional, untuk pengayaan analisis Pimpinan).

### 3.4 Distribusi Pupuk
Riwayat distribusi terekam dari sistem sendiri (bukan dataset eksternal) — menjadi dataset internal utama untuk pelaporan.

## 4. External API

### 4.1 Geospasial API
Untuk render peta distribusi (mis. Leaflet + tile provider) dan/atau lookup koordinat lokasi.

### 4.2 Weather API
Untuk menampilkan kondisi cuaca terkini/perkiraan sebagai konteks musim tanam di dashboard Admin/Pimpinan.

### 4.3 Other API
Slot terbuka untuk data terbuka pertanian tambahan bila dibutuhkan (mis. data harga komoditas), ditambahkan sesuai kebutuhan lanjutan.

## 5. API Architecture

```
Frontend (React)
      │  REST API (HTTPS, JWT)
      ▼
Backend (FastAPI)
      │
      ├──► MySQL (data internal)
      └──► External API (cuaca, peta, data terbuka) — dipanggil server-side, hasil dinormalisasi sebelum dikirim ke frontend
```

## 6. Internal REST API

Dikelompokkan per domain (bukan per fitur individual), sesuai prinsip yang sudah ditetapkan:

- **Authentication** — login, logout, refresh token.
- **Farmers** — CRUD data petani & kelompok tani.
- **Lands** — CRUD data lahan.
- **Applications** — pengajuan pupuk (create/edit/cancel/list/detail).
- **Quota** — endpoint kalkulasi kuota (dipanggil saat petani memilih komoditas/pupuk).
- **QR** — validasi scan, riwayat scan.
- **Distribution** — pencatatan & riwayat distribusi.
- **Dashboard** — endpoint agregasi KPI, grafik, dan data peta.

## 7. API Endpoint Specification

| Method | Endpoint | Deskripsi | Role |
|---|---|---|---|
| POST | `/auth/login` | Login, terbitkan JWT | Semua |
| POST | `/auth/logout` | Logout | Semua |
| GET | `/farmers` | Daftar petani | Admin, PPL |
| GET/POST/PUT | `/farmers/{id}` | Detail/ubah data petani | Admin |
| GET/POST/PUT | `/lands` | CRUD data lahan | Petani (milik sendiri), Admin |
| POST | `/applications` | Ajukan pupuk | Petani |
| GET | `/applications` | Daftar pengajuan (filter wilayah/status) | Petani, PPL, Admin |
| PUT | `/applications/{id}/cancel` | Batalkan pengajuan | Petani |
| POST | `/applications/{id}/verify` | Approve/reject | PPL |
| GET | `/quota/calculate` | Hitung kuota maksimal | Petani |
| POST | `/qr/scan` | Validasi hasil scan QR | Petani, PPL |
| GET | `/qr/history` | Riwayat scan | Petani, Admin |
| POST | `/distributions` | Catat distribusi | Admin |
| GET | `/distributions` | Riwayat distribusi | Semua (sesuai scope) |
| GET | `/dashboard/kpi` | Data KPI | Admin, Pimpinan |
| GET | `/dashboard/map` | Data peta distribusi | Admin, Pimpinan |
| GET | `/dashboard/weather` | Data cuaca (proxy eksternal) | Admin, Pimpinan |
| GET | `/audit-logs` | Daftar audit log | Admin |

## 8. Database Design

### 8.1 users
`id, username, password_hash, role, created_at`

### 8.2 farmers
`id, user_id, nama, nik, kontak, alamat, farmer_group_id`

### 8.3 farmer_groups
`id, nama_kelompok, ketua_id, wilayah`

### 8.4 lands
`id, farmer_id, lokasi, luas_m2, commodity_id, status_kepemilikan`

### 8.5 commodities
`id, nama_komoditas, standar_kebutuhan_kg_per_ha` *(nilai standar — placeholder, lihat catatan §11)*

### 8.6 fertilizers
`id, nama_pupuk, satuan`

### 8.7 rdkk
`id, farmer_group_id, commodity_id, periode, jumlah_referensi`

### 8.8 applications
`id, farmer_id, land_id, fertilizer_id, jumlah_diajukan, kuota_maksimal, status, created_at`

### 8.9 fertilizer_batches
`id, batch_code, fertilizer_id, production_date, expired_date`

### 8.10 qr_scans
`id, batch_id, application_id, scanned_by, hasil_status, scanned_at`

### 8.11 distributions
`id, application_id, batch_id, jumlah, status, distributed_at`

### 8.12 notifications
`id, user_id, judul, pesan, dibaca, created_at`

### 8.13 audit_logs
`id, user_id, aksi, entitas, entitas_id, waktu`

## 9. Entity Relationship

```
users
   │
   ├── farmers
   │       │
   │       ├── farmer_groups
   │       │
   │       └── lands
   │               │
   │               └── applications
   │                         │
   │                         ▼
   │                    distributions
   │                         │
   │                         ▼
   │                    qr_scans
   │                         │
   │                         ▼
   │                  fertilizer_batches
   │
   └── audit_logs

rdkk ────────────────► applications
commodities ─────────► lands / applications
fertilizers ─────────► applications / fertilizer_batches
```
> Ini adalah fondasi struktur data berdasarkan fitur yang sudah didokumentasikan — belum berstatus ERD final; kolom dan relasi dapat berkembang saat implementasi.

## 10. Data Dictionary
Lihat rincian kolom per tabel di §8. Konvensi: `id` = primary key auto-increment, `*_id` = foreign key, timestamp dalam UTC, status disimpan sebagai enum string (mis. `DIAJUKAN`, `DIVERIFIKASI`, dst.) agar mudah dibaca di audit log.

## 11. Data Seeding
Data awal (`commodities.standar_kebutuhan_kg_per_ha`, referensi RDKK) untuk pengembangan/demo memakai **nilai contoh**, bukan data resmi. Sebelum go-live, nilai ini wajib diverifikasi/diganti dengan data resmi dari Dinas Pertanian atau sumber data terbuka yang konkret.

## 12. Data Validation
- Luas lahan > 0.
- Jumlah pengajuan ≤ kuota maksimal hasil kalkulasi (selain jalur override manual oleh Admin dengan catatan).
- `expired_date` batch tidak boleh lebih awal dari `production_date`.
- Satu `qr_scans` per kombinasi `batch_id` + `application_id` untuk mencegah duplikasi.

## 13. API Security
- Seluruh endpoint (kecuali `/auth/login`) mewajibkan JWT valid di header `Authorization`.
- Otorisasi per endpoint mengikuti matriks peran di `02-system-design.md` §6.
- Rate limiting pada endpoint autentikasi untuk mitigasi brute force.
- Data sensitif (mis. NIK) disamarkan pada response untuk peran yang tidak berhak melihat detail penuh.
