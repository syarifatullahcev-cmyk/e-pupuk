---
marp: true
theme: default
paginate: true
backgroundColor: "#0f172a"
color: "#f1f5f9"
style: |
  section {
    font-family: 'Segoe UI', sans-serif;
    background: linear-gradient(135deg, #0f172a 0%, #14532d 100%);
  }
  h1, h2, h3 { color: #86efac; }
  .lead { text-align: center; }
  table { width: 100%; border-collapse: collapse; }
  th, td { border: 1px solid #334155; padding: 8px; text-align: left; }
  th { background-color: #1e293b; color: #86efac; }
  strong { color: #fbbf24; }
  ul { line-height: 1.5; }
---

<!-- SLIDE 1 -->
<!-- _class: lead -->
# LAPORAN PROGRES
## WORKSHOP PEMROGRAMAN FRAMEWORK

### SISTEM PENGAJUAN SUBSIDI PUPUK
### KABUPATEN MOJOKERTO

# E-PUPUK

**Frontend**
Syarifatullah Ceva Efendy

**Backend**
Selby Wafi Nurjuan

PSDKU Lamongan D3 Teknik Informatika  
Politeknik Elektronika Negeri Surabaya  
2026

---

<!-- SLIDE 2 -->
## E-PUPUK
### Sistem Pengajuan Subsidi Pupuk Kabupaten Mojokerto

E-PUPUK merupakan sistem berbasis web untuk membantu proses pengajuan dan verifikasi subsidi pupuk secara lebih terstruktur.

### USER / PETANI
- Mengajukan subsidi pupuk
- Mengelola data lahan
- Melihat status pengajuan
- Melihat kuota
- Melakukan pembukaan pupuk melalui scan QR pada karung
- Melihat riwayat pembukaan pupuk

### PPL
- Melihat data petani yang ditugaskan
- Melakukan survei lapangan
- Memverifikasi kondisi lahan
- Mengambil koordinat GPS
- Mengirim hasil survei

### ADMIN
- Verifikasi berkas
- Menugaskan PPL
- Memberikan approval akhir
- Mengelola data petani dan lahan
- Monitoring distribusi
- Laporan
- Manajemen pengguna
- Audit log

---

<!-- SLIDE 3 -->
## FITUR UTAMA E-PUPUK

### PETANI
- Profil petani
- Data lahan
- Pengajuan subsidi
- Status pengajuan
- Kuota pupuk
- Pembukaan pupuk
- Scan QR Code pada karung pupuk
- Validasi GPS / geofencing
- Riwayat pembukaan pupuk

### PPL
- Data petani
- Daftar penugasan
- Survei lapangan
- Verifikasi lahan
- Koordinat GPS
- Foto survei
- Hasil survei
- Rekomendasi setuju / tolak

### ADMIN
- Dashboard
- Verifikasi berkas
- Penugasan PPL
- Persetujuan akhir
- Data petani
- Data lahan
- Data distribusi
- Monitoring
- Laporan
- Manajemen pengguna
- Audit log

> QR berada pada karung pupuk dan digunakan oleh Petani melalui HP saat pembukaan pupuk di lahan.

---

<!-- SLIDE 4 -->
## TIMELINE PENGEMBANGAN E-PUPUK

### MINGGU 1
Analisis kebutuhan sistem  
Penentuan masalah dan tujuan

### MINGGU 2
Perancangan sistem  
Role, fitur, alur proses dan database

### MINGGU 3
Perancangan UI/UX  
Landing page, login, register, dashboard awal

### MINGGU 4
Implementasi frontend dan backend awal  
Pengembangan dashboard dan alur pengajuan

### MINGGU 5 — CURRENT
Integrasi dan penyempurnaan fitur utama:
- Dashboard Petani
- Pengajuan subsidi
- Status pengajuan
- Dashboard Admin
- Verifikasi
- Penugasan PPL
- Approval
- Konsep pembukaan pupuk dengan QR + GPS

### MINGGU 6
Penyempurnaan integrasi frontend-backend  
Testing dan perbaikan bug

---

<!-- SLIDE 5 -->
## PROGRESS MINGGUAN : BACKEND

### Progress utama:

**1. Struktur Role**
- Petani
- PPL
- Admin

**2. Struktur Data Sistem**
- Data pengguna
- Data petani
- Data lahan
- Data pengajuan
- Data penugasan PPL
- Data survei
- Data approval
- Data distribusi
- Audit log

**3. Alur Status Pengajuan**
```text
Pengajuan
→ Verifikasi Berkas
→ Penugasan PPL
→ Survei Lapangan
→ Persetujuan Akhir
→ Distribusi
→ Pembukaan Pupuk
→ Riwayat
```

**4. Integrasi Data**
Backend dipersiapkan agar data yang digunakan frontend mengikuti role dan status proses pengajuan.

> Bagian backend masih dalam proses pengembangan dan integrasi, terutama untuk memastikan alur pengajuan dan status data konsisten.

---

<!-- SLIDE 6 -->
## PROGRESS MINGGUAN : FRONTEND

### Progress:

#### LANDING PAGE
- Informasi E-PUPUK
- Penjelasan manfaat sistem
- Tombol daftar dan login

#### AUTHENTICATION
- Login
- Register petani
- Validasi data dasar

#### DASHBOARD PETANI
- Profil
- Data lahan
- Pengajuan subsidi
- Status pengajuan
- Kuota pupuk
- Riwayat pembukaan pupuk

#### PENGAJUAN SUBSIDI
- Pilih lahan
- Pilih jenis pupuk
- Jumlah pupuk
- Alamat lahan
- Titik koordinat GPS

#### DASHBOARD ADMIN
- Verifikasi
- Penugasan PPL
- Approval
- Data petani
- Data lahan
- Distribusi
- Monitoring
- Laporan

---

<!-- SLIDE 7 -->
## ARSITEKTUR SISTEM E-PUPUK

```text
                    USER
                   PETANI
                     │
                     ▼
              ┌──────────────┐
              │   FRONTEND   │
              │  Web E-PUPUK │
              └──────┬───────┘
                     │
          ┌──────────┼──────────┐
          │          │          │
          ▼          ▼          ▼
       PETANI       PPL       ADMIN
          │          │          │
          └──────────┼──────────┘
                     ▼
              ┌──────────────┐
              │   BACKEND    │
              │ API / Logic  │
              └──────┬───────┘
                     ▼
              ┌──────────────┐
              │   DATABASE   │
              │ Data Sistem  │
              └──────────────┘
```

### Komponen pendukung
- GPS / Geolocation
- QR Code pada karung pupuk
- Data pengajuan
- Data survei
- Data distribusi
- Audit log

### CATATAN QR
QR berada pada karung pupuk dan digunakan oleh Petani melalui HP saat melakukan pembukaan pupuk di lahan.

---

<!-- SLIDE 8 -->
## KENDALA FRONTEND

### Kendala:
- Banyaknya fitur membuat dashboard menjadi terlalu padat.
- Tampilan awal belum membedakan kebutuhan setiap role secara jelas.
- Alur pembukaan pupuk dengan QR sempat ditempatkan pada konsep yang kurang tepat.
- Perlu memastikan tampilan tetap nyaman pada ukuran layar berbeda.
- Beberapa komponen perlu disesuaikan agar alur pengajuan mudah dipahami.

### Keputusan:
- Memisahkan tampilan berdasarkan 3 role: Petani, PPL, dan Admin.
- Menyederhanakan navigasi dashboard.
- Menempatkan fitur scan QR hanya pada Petani.
- QR yang digunakan adalah QR yang terdapat pada karung pupuk.
- Petani melakukan scan menggunakan HP.
- GPS HP digunakan untuk validasi lokasi / geofencing.
- Admin hanya melihat hasil pembukaan melalui monitoring dan laporan.

---

<!-- SLIDE 9 -->
## KENDALA BACKEND

### Kendala:
- Banyak status proses yang harus saling terhubung.
- Data pengajuan harus mengikuti tahapan verifikasi.
- Data Petani, lahan, PPL, survei, dan approval harus saling berkaitan.
- Perlu menjaga agar perubahan status tidak melompati tahapan proses.
- Integrasi data frontend dan backend membutuhkan penyesuaian.

### Keputusan:
Membuat alur status yang jelas:

```text
PENGAJUAN
    ↓
VERIFIKASI ADMIN
    ↓
PENUGASAN PPL
    ↓
SURVEI PPL
    ↓
APPROVAL ADMIN
    ↓
DISTRIBUSI
    ↓
PEMBUKAAN PUPUK
    ↓
RIWAYAT
```

Setiap perubahan status harus tercatat sehingga proses dapat dimonitor.

---

<!-- SLIDE 10 -->
## RENCANA PROGRESS MINGGU KE-6

### FRONTEND
- Menyempurnakan tampilan Petani, PPL, dan Admin.
- Menyempurnakan responsive design.
- Menghubungkan komponen frontend dengan data backend.
- Menyempurnakan halaman monitoring dan laporan.
- Menyempurnakan halaman pembukaan pupuk.
- Memastikan scan QR karung + GPS berjalan sesuai alur.
- Menampilkan riwayat pembukaan pupuk pada Petani.

### BACKEND
- Menyempurnakan endpoint/API yang diperlukan.
- Integrasi data pengguna, lahan, dan pengajuan.
- Integrasi status verifikasi, penugasan PPL, dan approval.
- Integrasi data survei PPL.
- Integrasi distribusi dan pembukaan pupuk.
- Penyempurnaan audit log.
- Testing alur data dari frontend sampai database.

### TARGET
```text
Frontend + Backend
       ↓
Integrasi
       ↓
Testing
       ↓
Perbaikan Bug
       ↓
Sistem E-PUPUK semakin siap digunakan
```

---

<!-- SLIDE 11 -->
## TERIMA KASIH
### ATAS KESEMPATANNYA

**E-PUPUK**  
**Sistem Pengajuan Subsidi Pupuk Kabupaten Mojokerto**

**Syarifatullah Ceva Efendy & Selby Wafi Nurjuan**
