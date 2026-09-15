# System Architecture
# E-Pupuk Kabupaten Mojokerto

Dokumen ini melengkapi `02-system-design.md` dengan gambaran arsitektur yang lebih rinci: arsitektur sistem keseluruhan, arsitektur modul backend, arsitektur aliran data, arsitektur keamanan, dan diagram sequence alur utama. Dokumen ini adalah referensi utama saat menjelaskan sistem ke pembimbing/penguji maupun saat membuat diagram visual (mis. draw.io, Figma, atau prompt ke Google Stitch di §6).

## 1. Arsitektur Sistem Keseluruhan

```
                         ┌──────────────────────────────────┐
                         │         PENGGUNA SISTEM           │
                         │                                   │
                         │  Petani (upload KTP, foto lahan)  │
                         │  PPL    (survei lapangan fisik)   │
                         │  Admin  (verif berkas, disp. PPL) │
                         │  Pimpinan (dashboard KPI)         │
                         └────────────────┬──────────────────┘
                                          │
                                          ▼
┌────────────────────────────────────────────────────────────────────┐
│                      FRONTEND - REACT.JS                            │
│                                                                     │
│  ┌─────────────────┐ ┌──────────────────┐ ┌─────────────────────┐  │
│  │ Login/Register  │ │ Dashboard Petani  │ │ Pengajuan Subsidi   │  │
│  └─────────────────┘ └──────────────────┘ │ + Upload KTP & Lahan│  │
│  ┌─────────────────┐ ┌──────────────────┐ │ + Map Picker Koordinat│ │
│  │ Dashboard Admin │ │ Dashboard PPL    │ └─────────────────────┘  │
│  │ Verif Berkas    │ │ Tugas Survei     │ ┌─────────────────────┐  │
│  │ Penugasan PPL   │ │ Form Lap. Survei │ │ QR Scanner          │  │
│  │ Approval Akhir  │ │ Upload Foto Bkt  │ │ Status Pengajuan    │  │
│  └─────────────────┘ └──────────────────┘ └─────────────────────┘  │
└───────────────────────────────┬────────────────────────────────────┘
                                │ HTTPS / REST API
                                │ (JSON + multipart/form-data untuk berkas)
                                ▼
┌────────────────────────────────────────────────────────────────────┐
│                      BACKEND - FASTAPI                              │
│                                                                     │
│  ┌──────────────────┐  ┌──────────────────────────────────────┐    │
│  │ Authentication   │  │ User & Farmer Management              │    │
│  │ JWT + RBAC       │  │ Profile, KTP, Kelompok, Lahan         │    │
│  └──────────────────┘  └──────────────────────────────────────┘    │
│  ┌──────────────────┐  ┌──────────────────────────────────────┐    │
│  │ File Storage Svc │  │ Application Management                │    │
│  │ Upload, Proxy,   │  │ Pengajuan + Upload Berkas             │    │
│  │ Akses Berkas KTP │  │ → Verif Berkas → Disposisi PPL       │    │
│  └──────────────────┘  └──────────────────────────────────────┘    │
│  ┌──────────────────┐  ┌──────────────────────────────────────┐    │
│  │ Quota Engine     │  │ Admin Verification Service            │    │
│  │ RDKK + Luas Lhn  │  │ Review KTP, Foto Lahan, Alamat,      │    │
│  └──────────────────┘  │ Koordinat → Approve/Perbaikan/Tolak  │    │
│  ┌──────────────────┐  └──────────────────────────────────────┘    │
│  │ PPL Assignment   │  ┌──────────────────────────────────────┐    │
│  │ Dispatcher       │  │ Field Survey Service (PPL)            │    │
│  │ Auto-suggest PPL │  │ Terima Tugas, Submit Laporan,        │    │
│  │ Override Manual  │  │ Upload Foto Bukti Lapangan           │    │
│  └──────────────────┘  └──────────────────────────────────────┘    │
│  ┌──────────────────┐  ┌──────────────────────────────────────┐    │
│  │ Final Approval   │  │ Distribution & Batch Management       │    │
│  │ Service (Admin)  │  │ Batch ID, Expired, Timestamp         │    │
│  └──────────────────┘  └──────────────────────────────────────┘    │
│  ┌──────────────────┐  ┌──────────────────────────────────────┐    │
│  │ QR Validation    │  │ Reporting & Audit Trail               │    │
│  │ Expired Check    │  └──────────────────────────────────────┘    │
│  │ Stockpiling Det. │  ┌──────────────────────────────────────┐    │
│  └──────────────────┘  │ External API Integration              │    │
│                         │ Weather / Map / Open Data             │    │
│                         └──────────────────────────────────────┘    │
└──────────────────┬──────────────────────┬──────────────────────────┘
                   │                      │
                   ▼                      ▼
┌──────────────────────────────┐   ┌─────────────────────────────────┐
│      MySQL DATABASE          │   │      FILE STORAGE                │
│                              │   │                                  │
│ users                        │   │ /uploads/farmers/{id}/ktp/       │
│ farmers                      │   │ /uploads/lands/{id}/photos/      │
│ farmer_groups                │   │ /uploads/applications/{id}/      │
│ lands                        │   │   /ktp_snapshot/                 │
│ commodities                  │   │   /lahan_snapshot/               │
│ rdkk                         │   │ /uploads/field_surveys/{id}/     │
│ applications                 │   │   /photos/                       │
│ field_surveys                │   │                                  │
│ fertilizer_batches           │   └─────────────────────────────────┘
│ distributions                │
│ qr_scans                     │   ┌─────────────────────────────────┐
│ notifications                │   │    EXTERNAL DATA / API           │
│ audit_logs                   │   │                                  │
│                              │   │ Data Terbuka Pemerintah          │
└──────────────────────────────┘   │ Weather API                      │
                                   │ Geospatial / Map API             │
                                   └─────────────────────────────────┘
```

### 1.1 Alur Utama

**1) Pengguna mengakses frontend.** Petani mengakses untuk mengisi form pengajuan dan mengunggah KTP, foto lahan, alamat, dan koordinat GPS. PPL mengakses untuk melihat tugas survei dan mengisi form laporan lapangan. Admin memverifikasi berkas, menugaskan PPL, dan memberikan persetujuan akhir. Pimpinan memonitor KPI.

**2) Frontend berkomunikasi dengan FastAPI.**
```
Petani isi form + upload KTP + foto lahan + alamat + pin koordinat
        ↓
React mengirim multipart/form-data
        ↓
FastAPI menerima request
        ↓
Backend validasi berkas (MIME type, ukuran)
        ↓
Berkas disimpan ke File Storage
        ↓
Data pengajuan disimpan ke MySQL
        ↓
Notifikasi ke Admin: pengajuan baru masuk
        ↓
Response dikirim kembali ke React
```

**3) Alur Verifikasi Berkas oleh Admin.**
```
Admin buka panel Verifikasi Berkas
        ↓
Backend melayani preview foto KTP dan foto lahan via proxy aman
        ↓
Admin cek kelengkapan dan keabsahan KTP, foto lahan, alamat, koordinat
        ↓
         ┌──────────────────────────┬──────────────────────────┐
         ▼                          ▼                          ▼
 BERKAS VALID             PERLU_PERBAIKAN              DITOLAK_BERKAS
 → status berubah         → catatan ke petani          → final, notif petani
 BERKAS_TERVERIFIKASI     → petani revisi berkas
         │
         ▼
 Admin tugaskan PPL wilayah
```

**4) Alur Penugasan & Survei Lapangan PPL.**
```
Admin pilih PPL (sistem saran otomatis PPL wilayah, dapat dioverride)
        ↓
Admin isi batas waktu survei + instruksi khusus
        ↓
Status → DITUGASKAN_KE_PPL
        ↓
Notifikasi ke PPL: tugas survei baru
        ↓
PPL buka detail tugas: data petani, foto KTP referensi, foto lahan referensi,
  alamat, koordinat GPS (navigasi ke lokasi)
        ↓
PPL kunjungi lahan secara fisik
        ↓
PPL isi form laporan: kondisi lahan, kondisi bahan/tanaman,
  luas aktual, upload min. 2 foto bukti, catatan, rekomendasi
        ↓
Status → MENUNGGU_PERSETUJUAN_AKHIR
        ↓
Notifikasi ke Admin: laporan survei PPL siap direview
```

**5) Alur Persetujuan Akhir & Distribusi.**
```
Admin review laporan survei PPL + foto bukti lapangan
        ↓
         ┌──────────────────────────┐
         ▼                          ▼
     DISETUJUI                 DITOLAK_LAPANGAN
     → Admin atur volume final → catatan alasan, notif petani
     → DIJADWALKAN_DISTRIBUSI
         ↓
     Admin assign batch pupuk (QR dibuat)
         ↓
     Distribusi ke petani
         ↓
     Petani scan QR saat serah terima → TERSALURKAN
```

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
│   ├── Data Petani (nama, NIK, alamat, foto_ktp_url)
│   ├── Kelompok Tani
│   └── Profil
│
├── Land Management
│   ├── Data Lahan (foto_lahan_url, koordinat GPS, alamat)
│   ├── Lokasi & Koordinat
│   └── Komoditas
│
├── RDKK Management
│   ├── Data RDKK
│   ├── Kuota
│   └── Referensi Open Data
│
├── Application Management
│   ├── Pengajuan (+ multipart upload KTP, foto lahan, alamat, koordinat)
│   ├── Status Lifecycle (6-tahap)
│   ├── Revisi Berkas (PERLU_PERBAIKAN_BERKAS)
│   └── Riwayat
│
├── File Storage Service
│   ├── Upload & Validasi Berkas (MIME, ukuran)
│   ├── Penyimpanan Berkas (Local FS / MinIO)
│   ├── Proxy Akses Berkas (token-based, role-validated)
│   └── Audit Log Akses KTP
│
├── Admin Verification Service
│   ├── Review Berkas (KTP, foto lahan, alamat, koordinat)
│   ├── Approve Berkas
│   ├── Perlu Perbaikan Berkas (+ catatan ke petani)
│   └── Tolak Berkas (final)
│
├── PPL Assignment Dispatcher
│   ├── Auto-suggest PPL Wilayah Binaan
│   ├── Manual Override oleh Admin
│   ├── Catat Penugasan (assigned_ppl_id, assigned_at, instruksi)
│   └── Notifikasi ke PPL
│
├── Field Survey Service (PPL)
│   ├── Lihat Daftar Tugas Survei
│   ├── Detail Tugas (data petani, foto referensi, koordinat GPS)
│   ├── Submit Laporan Survei (kondisi lahan, tanaman, luas aktual)
│   ├── Upload Foto Bukti Lapangan (min. 2, maks. 5 foto)
│   └── Rekomendasi (Setuju/Tolak)
│
├── Final Approval Service (Admin)
│   ├── Review Laporan Survei PPL + Foto Bukti
│   ├── Setujui + Atur Volume Akhir
│   └── Tolak Lapangan (final, + catatan alasan)
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
│   ├── KPI (termasuk metrik verifikasi berkas & survei PPL)
│   ├── Grafik
│   ├── Map
│   └── Monitoring
│
└── Audit & Notification
    ├── Audit Log (termasuk akses berkas KTP)
    └── Notification (6 tipe notifikasi baru)
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
│    MySQL      │       ┌───────────────────┐
└───────┬───────┘       │   FILE STORAGE    │
        │               │ /uploads/...      │
        ├──────────────► Data Petani        │
        │               │   ↕ foto_ktp_url ─┤
        ├──────────────► Data Lahan         │
        │               │   ↕ foto_lahan_url─┤
        ├──────────────► Data Komoditas     │
        ├──────────────► Data RDKK          │
        ├──────────────► Data Pengajuan     │
        │               │   ↕ foto_ktp_snap─┤
        │               │   ↕ foto_lhn_snap─┤
        ├──────────────► Data Verifikasi Berkas (Admin)
        ├──────────────► Data Penugasan PPL │
        ├──────────────► Data Survei Lapangan (field_surveys)
        │               │   ↕ foto_survei───┤
        ├──────────────► Data Pupuk         └───────────────────┘
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
Frontend **tidak pernah** memanggil API eksternal secara langsung, dan **tidak pernah** mengakses berkas foto langsung via URL publik — React meminta data dan berkas ke FastAPI, dan FastAPI yang berkomunikasi dengan sumber eksternal / file storage dengan validasi akses.

## 4. Arsitektur Keamanan

```
                 LOGIN
                   │
                   ▼
             Authentication (FastAPI)
                   │
                   ▼
                 JWT
                   │
                   ▼
            Role Validation (RBAC)
                   │
       ┌───────────┼───────────┬──────────────┐
       ▼           ▼           ▼              ▼
   PETANI         PPL        ADMIN         PIMPINAN
       │           │           │              │
       ▼           ▼           ▼              ▼
  Pengajuan    Tugas       Verifikasi     Dashboard
  Upload KTP   Survei      Berkas         KPI
  Foto Lahan   Laporan     Penugasan PPL  Laporan
  Koordinat    Upload Foto Approval Final
  QR Scan      Bukti Lap.  Data Master
               QR Scan     Distribusi
                           Monitoring
```

### 4.1 Perlindungan Data Sensitif (KTP & NIK)

| Mekanisme | Detail |
|---|---|
| Pembatasan Akses | Foto KTP hanya dapat diakses oleh Admin dan PPL yang ditugaskan pada pengajuan terkait |
| Proxy Backend | Berkas tidak diakses langsung via URL publik — selalu melewati backend dengan validasi JWT & peran |
| Token Berkas | Token akses berkas bersifat sementara (time-limited) |
| Penyamaran NIK | NIK ditampilkan tersamar (mis. 35XXXXXXXXXXXXXXX) untuk peran yang tidak berwenang melihat detail |
| Audit Log | Setiap akses ke foto KTP dicatat di `audit_logs` (user_id, waktu, berkas yang diakses) |
| Enkripsi Penyimpanan | Berkas foto KTP disimpan dengan enkripsi at-rest di file storage (rekomendasi pada implementasi produksi) |

### 4.2 Matriks Hak Akses

| Role | Akses Utama |
|---|---|
| Petani | Profil, lahan, pengajuan (milik sendiri), QR, status |
| PPL | Tugas survei wilayahnya, data petani terkait (NIK tersamar), foto referensi, submit laporan survei |
| Admin | Kelola data, verifikasi berkas (akses KTP penuh), penugasan PPL, approval akhir, distribusi, monitoring |
| Pimpinan | Dashboard dan laporan |

Lapisan keamanan tambahan: validasi input di setiap endpoint, validasi MIME type dan ukuran berkas di backend sebelum disimpan, audit log untuk aksi sensitif (verifikasi berkas, akses KTP, penugasan PPL, laporan survei, distribusi, perubahan data master), serta penyamaran data sensitif (NIK) untuk peran yang tidak berwenang.

## 5. Sequence Diagram — Alur Utama

### 5.1 Pengajuan + Verifikasi Berkas + Survei PPL + Distribusi

```
Petani     Frontend     Backend      File Storage    MySQL       Admin       PPL
  │            │            │              │            │           │          │
  │──isi form─►│            │              │            │           │          │
  │──upload────►            │              │            │           │          │
  │  KTP+Lahan  │──POST apps►              │            │           │          │
  │             │  (multipart)─upload foto►│            │           │          │
  │             │            │◄─URL berkas─│            │           │          │
  │             │            │──simpan data───────────►│           │          │
  │             │◄─201 OK────│            │            │           │          │
  │◄─notif sub──│            │            │            │──notif────►          │
  │             │            │            │            │  berkas baru         │
  │             │            │            │            │           │          │
  │             │            │◄──GET apps─────────────────────────►          │
  │             │            │──proxy foto►            │           │          │
  │             │            │◄─berkas KTP─            │           │          │
  │             │            │──response───────────────────────────►         │
  │             │            │            │            │           │          │
  │             │            │◄──POST verify-docs──────────────────►         │
  │             │            │──update status──────────►           │          │
  │◄─notif─────│            │──notif petani(BERKAS OK)►           │          │
  │             │            │            │            │           │          │
  │             │            │◄──POST assign-ppl───────────────────►         │
  │             │            │──update assigned_ppl────►           │          │
  │             │            │──notif PPL─────────────────────────────────►│
  │             │            │            │            │           │          │
  │             │            │◄──GET assignments─────────────────────────────►
  │             │            │──response tugas─────────────────────────────►│
  │             │            │            │            │           │          │
  │             │            │◄──POST survey (multipart)─────────────────────►
  │             │            │──upload foto survei───► │            │          │
  │             │            │──simpan field_surveys──────────────►│          │
  │             │            │──notif Admin───────────────────────►│          │
  │             │            │            │            │           │          │
  │             │            │◄──POST final-approval───────────────►         │
  │             │            │──update status DISETUJUI──────────►│          │
  │◄─notif─────│            │──notif petani (DISETUJUI)──────────►│          │
  │             │            │            │            │           │          │
  │──scan QR───►│──POST qr/scan►          │            │           │          │
  │             │            │──validasi batch───────►│           │          │
  │             │◄──VALID────│            │            │           │          │
  │             │            │──update TERSALURKAN──►│            │          │
```

## 6. Prompt untuk Google Stitch — Diagram Arsitektur

Untuk menghasilkan visual arsitektur sistem (bukan mockup UI — untuk mockup UI lihat `03-ui-ux-design.md` §11), gunakan prompt berikut:

**Prompt Arsitektur Sistem Lengkap:**
"Buatkan diagram arsitektur sistem berlapis (layered architecture diagram) untuk aplikasi web bernama 'E-Pupuk'. Gaya: clean, teknis, kotak-kotak dengan panah vertikal dan horizontal menghubungkan antar layer dan komponen, palet warna hijau-abu profesional. Layer dari atas ke bawah: (1) 'Pengguna Sistem' berisi empat ikon aktor — Petani (upload KTP & foto lahan), PPL (survei lapangan), Admin (verifikasi berkas & penugasan PPL), Pimpinan; (2) 'Frontend - React.js' berisi enam modul: Login, Dashboard Petani (upload KTP/lahan + map picker), Dashboard Admin (verifikasi berkas + penugasan PPL + approval akhir), Dashboard PPL (tugas survei + form laporan), QR Scanner, Status Pengajuan; (3) 'Backend - FastAPI' berisi delapan modul dalam grid: Authentication/JWT, File Storage Service, Admin Verification Service, PPL Assignment Dispatcher, Field Survey Service, Quota Engine, QR Validation & Stockpiling, Distribution Management; (4) tiga kotak sejajar di bawah backend: 'MySQL Database' (daftar tabel: users, farmers, lands, applications, field_surveys, distributions), 'File Storage' (berisi ikon folder: /uploads/ktp, /uploads/lahan, /uploads/survei), dan 'External API' (Weather API, Map API, Open Data). Hubungkan tiap layer dengan panah berlabel, tambahkan panah horizontal dari Backend ke File Storage berlabel 'Akses Aman via Proxy' dan dari Backend ke External API berlabel 'Server-side Call'."

**Prompt Diagram Alur Verifikasi Bertahap:**
"Buatkan flowchart horizontal berwarna hijau-abu untuk alur verifikasi pengajuan subsidi pupuk E-Pupuk dengan 5 tahap utama: (1) PETANI: isi form + upload KTP + upload foto lahan + isi alamat + pin koordinat GPS + tanggal → klik Ajukan; (2) ADMIN: review KTP + foto lahan + alamat + koordinat → 3 cabang: Berkas Valid → lanjut, Perlu Perbaikan → balik ke petani, Tolak Berkas → selesai; (3) ADMIN → PPL: tugaskan PPL wilayah (sistem auto-suggest PPL), isi batas waktu dan instruksi; (4) PPL: kunjungi lahan fisik, isi form laporan (kondisi lahan, kondisi bahan/tanaman, luas aktual, upload foto bukti min. 2 foto) → kirim rekomendasi Setuju/Tolak; (5) ADMIN: review laporan PPL → Setujui (atur volume akhir) → jadwalkan distribusi → QR scan serah terima → Tersalurkan, atau Tolak Lapangan → selesai. Gunakan warna hijau untuk jalur sukses, kuning untuk percabangan, merah untuk penolakan, dan abu-abu untuk koneksi antar aktor."

## 7. Referensi Silang
- Detail modul dan endpoint: `05-api-data-database.md`
- Detail alur fitur (kuota, verifikasi berkas, survei lapangan, QR, deteksi penimbunan): `04-feature-specification.md`
- Detail tampilan tiap dashboard: `03-ui-ux-design.md`
- Ruang lingkup dan requirement: `01-product-requirements.md`
- Alur sistem dan role & permission: `02-system-design.md`
