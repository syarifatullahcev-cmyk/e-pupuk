# 📋 LAPORAN DETAIL PROGRESS TEKNIS MINGGU KE-9
## Sistem E-PUPUK Kabupaten Mojokerto
### Fokus Utama Pembaruan: Sinkronisasi Admin React (Web) & Refactoring Petani Flutter (Mobile)

> **Mata Kuliah**: Workshop Pemrograman Framework  
> **Program Studi**: D3 Teknik Informatika — PENS PSDKU Lamongan  
> **Dosen Pengampu**: Amma Liesvarastranta Haz, S.Tr.T., M.T.  
> **Tim Pengembang**:
> - **Syarifatullah Ceva Efendy** (NRP: 312521002) — *Frontend Web (React 19) & Mobile App (Flutter) Developer*
> - **Selby Wafi Nurjuan** (NRP: 3125521018) — *Backend API (FastAPI) & Database Architect*
> 
> **Fokus Rilis Minggu Ke-9**: **Penyempurnaan Antarmuka Petani (Flutter Mobile) & Modul Operasional Admin Dinas (React Web)**

---

## 📌 DAFTAR ISI LAPORAN TEKNIS

1. [Sorotan Utama: Duo Sinkronisasi Admin React & Petani Flutter](#1-sorotan-utama-duo-sinkronisasi-admin-react--petani-flutter)
2. [Bedah Mendalam: Pembaruan Petani Flutter (Mobile App)](#2-bedah-mendalam-pembaruan-petani-flutter-mobile-app)
3. [Bedah Mendalam: Pembaruan Admin Dinas (React Web)](#3-bedah-mendalam-pembaruan-admin-dinas-react-web)
4. [Fondasi Pendukung: Backend API & Database MySQL 8.0](#4-fondasi-pendukung-backend-api--database-mysql-80)
5. [Matriks Sinkronisasi Antara Admin React & Petani Flutter](#5-matriks-sinkronisasi-antara-admin-react--petani-flutter)
6. [Tabel Perubahan File Kode (Changelog Faktual)](#6-tabel-perubahan-file-kode-changelog-faktual)

---

## 1. SOROTAN UTAMA: DUO SINKRONISASI ADMIN REACT & PETANI FLUTTER

Pada Minggu ke-9, fokus rekayasa terbesar diarahkan pada **dua pilar antarmuka pengguna**:
1. **Sisi Petani (Mobile Flutter)**: Menuntaskan seluruh kendala antarmuka pada layar ponsel fisik, mengeliminasi layout bug garis kuning-hitam (*overflow*), merombak Stepper pelacakan agar akurat 100%, dan menghubungkan data riil backend.
2. **Sisi Admin Dinas (React Web)**: Memperkuat panel kendali dinas dengan 10 tab operasional (Verifikasi Berkas, Disposisi PPL, Approval Kuota Pupuk, dan Audit Trail), serta sistem proteksi multi-portal role guard.

```text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│              SINKRONISASI ALUR KERJA: ADMIN REACT  ◄──►  PETANI FLUTTER                │
├───────────────────────────────────────────┬────────────────────────────────────────────┤
│         PORTAL ADMIN DINAS (REACT)        │        APLIKASI PETANI (FLUTTER)           │
├───────────────────────────────────────────┼────────────────────────────────────────────┤
│ 1. Verifikasi Berkas & KTP Petani         │ 1. Notifikasi Status Verifikasi Dokumen    │
│ 2. Disposisi Petugas PPL Lapangan         │ 2. Stepper Tahap 3: "Penugasan PPL" Aktif  │
│ 3. Review Berita Acara Survei Lahan       │ 3. Stepper Tahap 4: "Survei Lapangan"      │
│ 4. Approval Kuota & Penerbitan QR Code    │ 4. Stepper Tahap 5 Centang Hijau,          │
│    (Urea & NPK Phonska Subsidi)           │    Tahap 6: Ikon QR Scanner Biru Aktif!    │
└───────────────────────────────────────────┴────────────────────────────────────────────┘
```

---

## 2. BEDAH MENDALAM: PEMBARUAN PETANI FLUTTER (MOBILE APP)

Pengembangan mobile difokuskan pada file `mobile/lib/screens/petani/petani_dashboard_screen.dart` dan konfigurasi jaringan `mobile/lib/config/api_config.dart`:

### A. Eliminasi Total Masalah Layout (*Zero RenderFlex Overflow Bug*)
Sebelumnya, saat dijalankan pada resolusi layar ponsel Android standar (lebar 360px – 440px), muncul garis belang kuning-hitam yang mengganggu. Di Minggu ke-9, masalah ini diselesaikan 100%:
1. **Header Ringkasan Kuota Pupuk (`_buildDashboardRingkasanKuotaCard`)**:
   * *Sebelumnya:* Mengalami `RenderFlex overflowed by 78 pixels` di sisi kanan karena judul dan badge kuota bertabrakan.
   * *Solusi:* Membungkus teks judul dengan widget `Expanded` dan menerapkan `overflow: TextOverflow.ellipsis`.
2. **Baris Kuota Pupuk Urea & NPK Phonska**:
   * *Sebelumnya:* Mengalami `RenderFlex overflowed by 37 pixels` saat angka alokasi kilogram dan nama pupuk dirender berdampingan.
   * *Solusi:* Menerapkan widget `Flexible` pada kolom label pupuk dan indikator tonase sehingga otomatis menyesuaikan lebar layar perangkat secara proporsional.
3. **Kartu Profil Petani (`_buildProfilPetaniCard`)**:
   * *Sebelumnya:* Nama petani yang panjang dan label Poktan (Kelompok Tani) terpotong dan menabrak foto profil.
   * *Solusi:* Menggunakan tata letak adaptif dengan `Expanded` dan `maxLines: 1` berakhiran ellipsis (`...`).

---

### B. Perombakan Total Stepper 6 Tahapan Status Pengajuan
* **Masalah Minggu 8 (Kritis):** Kartu pengajuan `#6` sebelumnya menampilkan **6 centang hijau palsu** secara statis, padahal pupuk belum ditebus dan baru berada pada tahap penugasan/persetujuan dinas.
* **Solusi Minggu 9:** Komponen `_buildDashboardMiniStepper` ditulis ulang secara dinamis untuk membaca status riil dari backend:
  * **Tahap 1:** Pengajuan Berkas (Centang Hijau)
  * **Tahap 2:** Verifikasi Berkas Admin (Centang Hijau)
  * **Tahap 3:** Penugasan Petugas PPL (Centang Hijau)
  * **Tahap 4:** Survei Lapangan Lahan Sawah (Centang Hijau)
  * **Tahap 5:** Persetujuan Kuota Dinas (Centang Hijau)
  * **Tahap 6: Penggunaan Pupuk (Penebusan Kios):**
    * Saat status pengajuan mencapai `DIJADWALKAN_DISTRIBUSI` ("Siap Diambil (QR Terbit)"), tahap ke-6 **TIDAK menampilkan centang hijau**, melainkan lingkaran biru aktif dengan **ikon QR Code Scanner** (`Icons.qr_code_scanner`).
    * Hal ini secara visual mengedukasi petani bahwa kuota telah disetujui dinas dan voucher QR siap dibawa ke kios resmi.

```text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│             LOGIKA VISUAL STEPPER MINI DASHBOARD PETANI (FLUTTER)                      │
├────────────────────────────────────────────────────────────────────────────────────────┤
│  [✓] Pengajuan  ──►  [✓] Verifikasi  ──►  [✓] Penugasan PPL                            │
│                                                   │                                    │
│                                                   ▼                                    │
│  [▣] Penggunaan  ◄──  [✓] Persetujuan  ◄──  [✓] Survei Lapangan                        │
│   (Ikon QR Aktif!)        (Centang Hijau)                                              │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

* **Penanganan Label Tahapan (`FittedBox`)**:
  Menghilangkan masalah pembagian suku kata yang buruk (seperti kata "Penggunaan" yang terpotong menjadi "Pengguna" di baris pertama dan "an" di baris kedua) dengan membungkus teks menggunakan `FittedBox(fit: BoxFit.scaleDown)`.

---

### C. Binding Data Dinamis (*Dynamic Application Binding*)
* Menghapus kartu dummy statis hardcoded (`#6` dan `#5`).
* Kartu pengajuan kini dirender secara dinamis dari data array `_applications` hasil fetch API `/api/applications`.
* Dilengkapi *fallback* aman dan pesan *empty state* jika petani belum pernah mengajukan alokasi subsidi pupuk.

---

### D. Konfigurasi Jaringan & Pengujian HP Fisik (`api_config.dart`)
* Mengupdate `baseUrl` agar secara fleksibel mendukung pengetesan langsung di ponsel Android fisik melalui IP Wi-Fi host:
  * Browser Web: `http://127.0.0.1:8000/api`
  * Android Emulator: `http://10.0.2.2:8000/api`
  * HP Fisik (Wi-Fi LAN): `http://10.253.129.6:8000/api`

---

## 3. BEDAH MENDALAM: PEMBARUAN ADMIN DINAS (REACT WEB)

Pengembangan sisi Admin dikerjakan pada `frontend/src/pages/AdminDashboard.jsx`, komponen modal, dan sistem autentikasi `frontend/src/pages/Login.jsx`:

### A. 10 Modul Terpadu Dashboard Admin Dinas
Panel Admin Dinas kini memiliki 10 modul navigasi terintegrasi dengan sinkronisasi URL rute mandiri:
1. **Tab Dashboard (`/admin`)**: Menampilkan ringkasan KPI (Total Petani, Luas Lahan Terdata, Pengajuan Menunggu Verifikasi, Kuota Tersalurkan).
2. **Tab Verifikasi (`/admin/verifikasi`)**: Modul verifikasi dokumen pengajuan subsidi. Admin dapat memeriksa kelengkapan KTP, SPPT, dan proposal kelompok tani.
3. **Tab Penugasan (`/admin/penugasan`)**: Disposisi penugasan petugas PPL lapangan berdasarkan wilayah kecamatan/desa sawah pemohon.
4. **Tab Approval (`/admin/approval`)**: Penetapan final alokasi kuota pupuk (Urea & NPK dlm kilogram) berdasarkan rekomendasi survei PPL.
5. **Tab Petani (`/admin/petani`)**: Manajemen direktori petani Kabupaten Mojokerto berbasis NIK 16 digit.
6. **Tab Lahan (`/admin/lahan`)**: Inventarisasi titik koordinat petak sawah dan polygon pemetaan GIS.
7. **Tab Monitoring (`/admin/monitoring`)**: Pelacakan real-time alur penebusan pupuk di tingkat kios resmi.
8. **Tab Laporan (`/admin/laporan`)**: Rekapitulasi serapan pupuk bersubsidi bulanan dan triwulan.
9. **Tab Pengguna (`/admin/pengguna`)**: Manajemen akun pengguna, status keaktifan, dan hak akses.
10. **Tab Audit (`/admin/audit`)**: Log rekam jejak aktivitas operasional admin (*audit trail*) untuk akuntabilitas sistem.

---

### B. Alur Modal Aksi Interaktif Admin
Di Minggu ke-9, Admin dilengkapi jendela modal aksi yang terhubung langsung ke state backend:
* **Modal Verifikasi Berkas (`showVerifyModal`)**:
  Admin dapat menyetujui (*Approve*) atau mengembalikan berkas (*Reject / Revise*) dengan menyertakan catatan evaluasi berkas (`actionNotes`).
* **Modal Disposisi PPL (`showAssignModal`)**:
  Admin memilih nama petugas PPL yang bertugas dari daftar dropdown dinamis (`pplOfficers`) untuk meninjau fisik lahan sawah petani.
* **Modal Approval Kuota Final (`showFinalModal`)**:
  Admin memasukkan jumlah kilogram pupuk Urea dan NPK yang disetujui (`approvedKg`). Begitu tombol setujui ditekan, status pengajuan langsung berubah menjadi `DIJADWALKAN_DISTRIBUSI` dan **sistem otomatis mengenerate Voucher Kode QR** yang seketika muncul di aplikasi Petani.

---

### C. Inspeksi Berkas & Foto Lahan (`PhotoViewerModal.jsx`)
* Admin kini dapat mengklik pratinjau foto KTP petani, foto sawah, atau dokumen berita acara PPL.
* Modal penampil foto mendukung mode zoom, perbandingan foto sebelum vs sesudah survei, serta pembacaan metadata tanggal pengambilan foto.

---

### D. Keamanan Multi-Portal Role Guard (`Login.jsx` & `App.jsx`)
* **Penyekatan Tab Khusus Admin**: Di halaman login web, Admin masuk melalui tab *Portal Admin Dinas* (Aksen Biru).
* Jika akun Petani mencoba login melalui tab Admin, sistem langsung menolak dan melakukan *auto-purge* token dengan peringatan: *"Akun ini bukan akun Admin Dinas!"*.
* Rute URL `/admin/*` dibungkus dengan `<ProtectedRoute allowedRoles={['admin_dinas']} />`, sehingga URL tidak dapat diakses paksa oleh pihak luar.

---

## 4. FONDASI PENDUKUNG: BACKEND API & DATABASE MYSQL 8.0

Penyempurnaan Petani Flutter dan Admin React ditopang oleh arsitektur backend dan basis data yang tangguh:

1. **Migrasi Database ke MySQL 8.0**:
   * Menghilangkan kendala *database is locked* pada SQLite lama.
   * Menerapkan SQLAlchemy Connection Pooling (`pool_size=10, max_overflow=20`) sehingga request bersamaan dari Admin Web dan Petani Mobile dilayani tanpa hambatan.
2. **Orkestrasi Docker Compose Penuh**:
   * 4 kontainer terisolasi: `epupuk-frontend` (Nginx), `epupuk-backend` (FastAPI), `epupuk-mysql` (MySQL 8.0), dan `epupuk-phpmyadmin` (phpMyAdmin).
3. **Penyempurnaan API & Keamanan**:
   * Normalisasi *case-insensitive username* saat login.
   * Otentikasi JWT dengan role claims terverifikasi di setiap pemanggilan endpoint.

---

## 5. MATRIKS SINKRONISASI ANTARA ADMIN REACT & PETANI FLUTTER

| Tahapan Alur Bisnis | Aksi di Admin React (Web) | Reaksi Real-Time di Petani Flutter (Mobile) |
| :--- | :--- | :--- |
| **1. Pengajuan Awal** | Muncul di tab `/admin/verifikasi` dengan status `MENUNGGU_VERIFIKASI`. | Kartu pengajuan berstatus "Diajukan" (Tahap 1 aktif). |
| **2. Verifikasi Dokumen** | Admin memvalidasi KTP & Proposal di modal verifikasi. | Stepper Tahap 2 bercentang hijau, status berubah menjadi "Terverifikasi". |
| **3. Disposisi Petugas** | Admin menugaskan PPL dari dropdown di modal penugasan. | Stepper Tahap 3 bercentang hijau, nama PPL muncul pada detail pengajuan. |
| **4. Hasil Survei PPL** | Admin meninjau kesesuaian luas sawah dari berita acara PPL. | Stepper Tahap 4 bercentang hijau: "Survei Lapangan Selesai". |
| **5. Penetapan Kuota & QR** | Admin mengisi alokasi kuota Urea & NPK di modal approval final. | **Tahap 5 centang hijau, Tahap 6 menampilkan Ikon QR Scanner Biru Aktif**. Kuota terupdate di ringkasan dashboard! |

---

## 6. TABEL PERUBAHAN FILE KODE (CHANGELOG FAKTUAL)

| Komponen | File Target | Rincian Modifikasi |
| :--- | :--- | :--- |
| **Petani (Flutter)** | `mobile/lib/screens/petani/petani_dashboard_screen.dart` | • Mengatasi error layout 78px & 37px dengan `Expanded/Flexible`.<br>• Perombakan Stepper 6 tahapan dinamis.<br>• Ikon QR aktif pada status `DIJADWALKAN_DISTRIBUSI`.<br>• Pembungkus `FittedBox` label tahapan.<br>• Dynamic binding kartu pengajuan dari API. |
| **Petani (Flutter)** | `mobile/lib/config/api_config.dart` | • Konfigurasi URL dinamis untuk Web, Emulator, dan HP fisik (`10.253.129.6`). |
| **Admin (React)** | `frontend/src/pages/AdminDashboard.jsx` | • Implementasi 10 modul tab navigasi admin dinas.<br>• Pembuatan 3 modal aksi: Verifikasi Berkas, Disposisi PPL, dan Approval Final Kuota.<br>• Integrasi KPI Card & tabel rekap pengajuan. |
| **Admin (React)** | `frontend/src/components/PhotoViewerModal.jsx` | • Pratinjau interaktif dokumen KTP, foto lahan sawah, dan berita acara PPL. |
| **Keamanan Web** | `frontend/src/pages/Login.jsx` & `App.jsx` | • 3 Tab portal role guard, auto-purge token, dan proteksi rute URL `<ProtectedRoute>`. |
| **Backend & DB** | `backend/app/core/database.py` & `docker-compose.yml` | • Migrasi MySQL 8.0, connection pooling SQLAlchemy, dan kontainerisasi multi-service. |

---

> Laporan ini mendokumentasikan secara faktual bahwa sinergi antara **Portal Admin Dinas (React)** dan **Aplikasi Petani (Flutter)** pada Minggu ke-9 telah berjalan harmonis, bebas bug visual, dan siap diuji coba dalam skenario penggunaan nyata.
