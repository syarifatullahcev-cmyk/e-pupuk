# API, Data & Database
# E-Pupuk Kabupaten Mojokerto

## 1. Data Architecture
Data E-Pupuk terbagi menjadi dua sumber besar: **data internal** (hasil input pengguna sistem — petani, lahan, pengajuan beserta berkas foto/identitas, verifikasi berkas Admin, penugasan PPL, laporan survei lapangan, distribusi, scan QR) dan **data eksternal** (data terbuka pemerintah dan API pihak ketiga untuk pengayaan dashboard). Frontend tidak pernah memanggil API eksternal secara langsung — seluruh panggilan eksternal melalui backend agar dapat dinormalisasi, divalidasi, dan di-cache. Berkas foto (KTP, lahan, survei) disimpan di file storage terpisah dan diakses via backend proxy dengan validasi hak akses.

## 2. Data Sources

### 2.1 Internal Data
Data yang dihasilkan dari alur sistem: users, farmers (termasuk foto_ktp_url, alamat), lands (foto_lahan_url, koordinat GPS), applications (snapshot berkas, alamat, koordinat, tanggal), field_surveys (foto survei lapangan, catatan PPL), verifications, fertilizer_batches, distributions, qr_scans, notifications, audit_logs.

### 2.2 Open Government Data
Data referensi seperti RDKK dan data pertanian dari sumber data terbuka pemerintah (mis. portal data.go.id atau dinas terkait), dipakai sebagai referensi/seed — bukan sinkronisasi otomatis penuh pada versi awal.

### 2.3 External API
API cuaca dan API geospasial/peta untuk pengayaan dashboard Admin/Pimpinan.

## 3. Dataset

### 3.1 RDKK
Referensi kebutuhan pupuk per kelompok tani/komoditas — dipakai sebagai pembanding terhadap kalkulasi kuota otomatis.

### 3.2 Luas Lahan
Dataset lahan petani, idealnya tervalidasi terhadap data lahan resmi bila tersedia; pada versi awal diinput manual/diverifikasi PPL melalui survei lapangan.

### 3.3 Produksi Tanaman
Data historis produksi per komoditas (opsional, untuk pengayaan analisis Pimpinan).

### 3.4 Distribusi Pupuk
Riwayat distribusi terekam dari sistem sendiri (bukan dataset eksternal) — menjadi dataset internal utama untuk pelaporan.

### 3.5 Berkas Foto & Dokumen Identitas
Foto KTP petani, foto lahan dari pengajuan, dan foto bukti survei lapangan PPL — disimpan di file storage dengan URL aman, diakses via backend proxy dengan validasi peran.

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
      │  multipart/form-data untuk upload berkas foto
      ▼
Backend (FastAPI)
      │
      ├──► MySQL (data internal)
      ├──► File Storage (foto KTP, foto lahan, foto survei — via backend proxy)
      └──► External API (cuaca, peta, data terbuka) — dipanggil server-side, hasil dinormalisasi sebelum dikirim ke frontend
```

## 6. Internal REST API

Dikelompokkan per domain (bukan per fitur individual), sesuai prinsip yang sudah ditetapkan:

- **Authentication** — login, logout, refresh token.
- **Farmers** — CRUD data petani & kelompok tani (termasuk foto KTP, alamat, tanggal).
- **Lands** — CRUD data lahan (termasuk foto lahan, koordinat GPS, alamat lahan).
- **Applications** — pengajuan pupuk (create/edit/cancel/list/detail + upload berkas multipart).
- **Quota** — endpoint kalkulasi kuota (dipanggil saat petani memilih komoditas/pupuk).
- **Admin Verification** — verifikasi berkas pengajuan oleh Admin (approve/perlu perbaikan/tolak berkas).
- **PPL Assignment** — penugasan/disposisi PPL oleh Admin untuk survei lapangan.
- **Field Survey** — PPL submit laporan survei fisik lapangan (termasuk upload foto bukti lapangan).
- **Final Approval** — persetujuan akhir Admin berdasarkan laporan survei PPL.
- **QR** — validasi scan, riwayat scan.
- **Distribution** — pencatatan & riwayat distribusi.
- **Dashboard** — endpoint agregasi KPI, grafik, dan data peta.
- **Files** — akses berkas foto via proxy aman (validasi peran per berkas).

## 7. API Endpoint Specification

| Method | Endpoint | Deskripsi | Role |
|---|---|---|---|
| POST | `/auth/login` | Login, terbitkan JWT | Semua |
| POST | `/auth/logout` | Logout | Semua |
| GET | `/farmers` | Daftar petani | Admin, PPL |
| GET/POST/PUT | `/farmers/{id}` | Detail/ubah data petani (termasuk foto_ktp_url, alamat) | Admin |
| GET/POST/PUT | `/lands` | CRUD data lahan (termasuk foto_lahan_url, koordinat, alamat) | Petani (milik sendiri), Admin |
| POST | `/applications` | Ajukan pupuk (multipart/form-data: data + foto KTP + foto lahan + alamat + koordinat) | Petani |
| GET | `/applications` | Daftar pengajuan (filter wilayah/status) | Petani, PPL, Admin |
| PUT | `/applications/{id}/cancel` | Batalkan pengajuan | Petani |
| PUT | `/applications/{id}/revise-docs` | Petani mengunggah ulang berkas (multipart/form-data) saat status PERLU_PERBAIKAN_BERKAS | Petani |
| POST | `/admin/applications/{id}/verify-docs` | Admin approve/perlu perbaikan/tolak berkas administratif pengajuan | Admin |
| POST | `/admin/applications/{id}/assign-ppl` | Admin menugaskan PPL untuk survei lapangan | Admin |
| GET | `/ppl/assignments` | PPL melihat daftar tugas survei lapangan yang ditugaskan Admin | PPL |
| GET | `/ppl/assignments/{id}` | Detail tugas survei (data petani, foto referensi, koordinat GPS, instruksi) | PPL |
| POST | `/ppl/assignments/{id}/survey` | PPL submit laporan survei fisik lapangan (multipart/form-data: data laporan + foto bukti) | PPL |
| POST | `/admin/applications/{id}/final-approval` | Admin persetujuan akhir / tolak berdasar laporan survei PPL | Admin |
| GET | `/quota/calculate` | Hitung kuota maksimal | Petani |
| GET | `/files/{file_token}` | Akses berkas foto via token aman (proxy backend, validasi peran) | Admin, PPL (sesuai hak) |
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
`id, user_id, nama, nik, kontak, alamat, foto_ktp_url, tanggal_registrasi, farmer_group_id`

### 8.3 farmer_groups
`id, nama_kelompok, ketua_id, wilayah`

### 8.4 lands
`id, farmer_id, lokasi_deskripsi, alamat_lahan, latitude, longitude, luas_m2, commodity_id, status_kepemilikan, foto_lahan_url, tanggal_registrasi`

### 8.5 commodities
`id, nama_komoditas, standar_kebutuhan_kg_per_ha` *(nilai standar — placeholder, lihat catatan §11)*

### 8.6 fertilizers
`id, nama_pupuk, satuan`

### 8.7 rdkk
`id, farmer_group_id, commodity_id, periode, jumlah_referensi`

### 8.8 applications
```
id
farmer_id
land_id
fertilizer_id
jumlah_diajukan
kuota_maksimal
status                  -- enum: DIAJUKAN | MENUNGGU_VERIFIKASI_BERKAS |
                           PERLU_PERBAIKAN_BERKAS | BERKAS_TERVERIFIKASI |
                           DITUGASKAN_KE_PPL | SURVEI_LAPANGAN |
                           MENUNGGU_PERSETUJUAN_AKHIR | DISETUJUI |
                           DITOLAK_BERKAS | DITOLAK_LAPANGAN |
                           DIJADWALKAN_DISTRIBUSI | TERSALURKAN
foto_ktp_snapshot_url   -- URL snapshot foto KTP saat pengajuan dibuat
foto_lahan_snapshot_url -- URL snapshot foto lahan saat pengajuan dibuat
alamat_lahan            -- teks alamat lahan yang diisi petani saat pengajuan
latitude                -- koordinat GPS titik lokasi lahan (konfirmasi saat pengajuan)
longitude               -- koordinat GPS titik lokasi lahan (konfirmasi saat pengajuan)
tanggal_pengajuan       -- timestamp server saat pengajuan dibuat (UTC)
admin_verifier_id       -- FK users.id (Admin yang memverifikasi berkas)
admin_verified_at       -- timestamp verifikasi berkas oleh Admin
catatan_admin_berkas    -- catatan Admin saat verifikasi berkas (perbaikan/penolakan)
assigned_ppl_id         -- FK users.id (PPL yang ditugaskan survei lapangan)
assigned_at             -- timestamp penugasan PPL
catatan_penugasan       -- instruksi survei dari Admin ke PPL
final_approver_id       -- FK users.id (Admin yang menetapkan persetujuan akhir)
final_approved_at       -- timestamp persetujuan akhir
jumlah_disetujui        -- volume akhir yang disetujui Admin (dapat berbeda dari jumlah_diajukan)
catatan_final_admin     -- catatan Admin saat persetujuan/penolakan akhir
created_at
updated_at
```

### 8.9 field_surveys
```
id
application_id          -- FK applications.id
ppl_id                  -- FK users.id (PPL yang melaksanakan survei)
tanggal_survei          -- timestamp server saat PPL submit laporan (UTC)
kondisi_fisik_lahan     -- enum: BAIK | CUKUP | TIDAK_LAYAK
keterangan_fisik_lahan  -- teks keterangan kondisi lahan
kondisi_tanaman         -- enum: SESUAI | TIDAK_SESUAI
keterangan_tanaman      -- teks keterangan kondisi tanaman/bahan
luas_lahan_aktual_m2    -- luas lahan riil hasil pengukuran PPL di lapangan
foto_survei_urls        -- JSON array URL foto bukti lapangan (min. 2, maks. 5)
catatan_ppl             -- catatan evaluasi kelayakan dari PPL
rekomendasi             -- enum: SETUJU | TOLAK
created_at
```

### 8.10 fertilizer_batches
`id, batch_code, fertilizer_id, production_date, expired_date`

### 8.11 qr_scans
`id, batch_id, application_id, scanned_by, hasil_status, scanned_at`

### 8.12 distributions
`id, application_id, batch_id, jumlah, status, distributed_at`

### 8.13 notifications
`id, user_id, judul, pesan, link_entitas, dibaca, created_at`

### 8.14 audit_logs
`id, user_id, aksi, entitas, entitas_id, detail_json, waktu`

## 9. Entity Relationship

```
users
   │
   ├── farmers
   │       │
   │       ├── farmer_groups
   │       │
   │       └── lands ──────────────── foto_lahan (file storage)
   │               │
   │               └── applications ─── foto_ktp_snapshot (file storage)
   │                         │          foto_lahan_snapshot (file storage)
   │                         │
   │                         ├──────► field_surveys ── foto_survei (file storage)
   │                         │               │
   │                         │            ppl (users)
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
   ├── audit_logs
   │
   └── notifications

rdkk ────────────────► applications
commodities ─────────► lands / applications
fertilizers ─────────► applications / fertilizer_batches
```
> Ini adalah fondasi struktur data berdasarkan fitur yang sudah didokumentasikan — belum berstatus ERD final; kolom dan relasi dapat berkembang saat implementasi.

## 10. File Storage Specification

### 10.1 Berkas yang Disimpan
| Jenis Berkas | Tabel Terkait | Kolom URL | Batas Ukuran | Format |
|---|---|---|---|---|
| Foto KTP Petani | farmers | foto_ktp_url | 5MB | JPEG/PNG/WEBP |
| Foto Lahan (master data) | lands | foto_lahan_url | 5MB | JPEG/PNG/WEBP |
| Foto KTP (snapshot pengajuan) | applications | foto_ktp_snapshot_url | 5MB | JPEG/PNG/WEBP |
| Foto Lahan (snapshot pengajuan) | applications | foto_lahan_snapshot_url | 5MB | JPEG/PNG/WEBP |
| Foto Survei Lapangan PPL | field_surveys | foto_survei_urls (JSON array) | 5MB/foto, maks. 5 foto | JPEG/PNG/WEBP |

### 10.2 Akses Berkas
- Berkas tidak dapat diakses langsung via URL publik.
- Akses berkas melalui endpoint `/files/{file_token}` di backend — backend memvalidasi JWT dan peran pengguna sebelum melayani berkas.
- **Foto KTP**: hanya dapat diakses oleh Admin dan PPL yang ter-assign pada `application.assigned_ppl_id` untuk pengajuan terkait. Setiap akses dicatat di `audit_logs`.

### 10.3 Struktur Direktori Penyimpanan (Contoh)
```
/uploads/
  /farmers/{farmer_id}/ktp/
  /lands/{land_id}/photos/
  /applications/{application_id}/
    /ktp_snapshot/
    /lahan_snapshot/
  /field_surveys/{survey_id}/photos/
```

## 11. Data Dictionary
Lihat rincian kolom per tabel di §8. Konvensi: `id` = primary key auto-increment, `*_id` = foreign key, timestamp dalam UTC, status disimpan sebagai enum string agar mudah dibaca di audit log, URL berkas menyimpan path relatif di sistem penyimpanan (bukan URL absolut publik).

## 12. Data Seeding
Data awal (`commodities.standar_kebutuhan_kg_per_ha`, referensi RDKK) untuk pengembangan/demo memakai **nilai contoh**, bukan data resmi. Sebelum go-live, nilai ini wajib diverifikasi/diganti dengan data resmi dari Dinas Pertanian atau sumber data terbuka yang konkret.

## 13. Data Validation
- Luas lahan > 0.
- Jumlah pengajuan ≤ kuota maksimal hasil kalkulasi (selain jalur override manual oleh Admin dengan catatan).
- Foto KTP dan foto lahan wajib ada saat membuat pengajuan (tidak boleh null/kosong).
- `latitude` dan `longitude` wajib diisi pada tabel `lands` dan `applications`; range valid: latitude -90..90, longitude -180..180.
- Format berkas foto divalidasi MIME type di backend (tidak hanya ekstensi nama file).
- Ukuran berkas maksimum 5MB per file, divalidasi di backend sebelum disimpan ke storage.
- `expired_date` batch tidak boleh lebih awal dari `production_date`.
- Satu `qr_scans` per kombinasi `batch_id` + `application_id` untuk mencegah duplikasi.
- `foto_survei_urls` di `field_surveys` harus berisi minimal 2 URL (minimal 2 foto bukti lapangan).

## 14. API Security
- Seluruh endpoint (kecuali `/auth/login`) mewajibkan JWT valid di header `Authorization`.
- Otorisasi per endpoint mengikuti matriks peran di `02-system-design.md` §6.
- Rate limiting pada endpoint autentikasi untuk mitigasi brute force.
- Data sensitif (mis. NIK) disamarkan pada response untuk peran yang tidak berhak melihat detail penuh.
- Akses berkas foto KTP dibatasi hanya untuk Admin dan PPL yang ditugaskan pada pengajuan terkait; setiap akses dicatat di audit log.
- Upload berkas divalidasi MIME type dan ukuran di backend — file tidak disimpan sebelum validasi lolos.
- Token akses berkas (`file_token`) bersifat sementara (time-limited) dan hanya berlaku untuk peran yang berwenang.
