# Product Requirements
# E-Pupuk Kabupaten Mojokerto

## 1. Overview

### 1.1 Nama Sistem
E-Pupuk — Sistem Pengajuan dan Monitoring Distribusi Subsidi Pupuk Kabupaten Mojokerto.

### 1.2 Deskripsi Sistem
E-Pupuk adalah sistem berbasis web yang mengintegrasikan pendataan petani, pemeriksaan RDKK (Rencana Definitif Kebutuhan Kelompok), pengajuan subsidi pupuk, verifikasi oleh PPL (Penyuluh Pertanian Lapangan), distribusi pupuk bersubsidi, serta monitoring melalui dashboard. Sistem menambahkan lapisan validasi berbasis QR Code pada setiap batch pupuk untuk mencatat penerimaan, memeriksa tanggal kedaluwarsa, dan memberi indikasi dini potensi penimbunan.

### 1.3 Latar Belakang
Proses pengajuan dan distribusi pupuk bersubsidi saat ini masih rawan terhadap: data petani dan lahan yang tidak termutakhirkan, kuota yang tidak sinkron dengan luas lahan aktual, proses verifikasi manual yang lambat, minimnya jejak distribusi hingga ke titik penerima, serta tidak adanya mekanisme deteksi pupuk kedaluwarsa maupun indikasi penimbunan.

### 1.4 Permasalahan
- Data petani, lahan, dan kelompok tani tersebar dan tidak konsisten.
- Kuota pupuk tidak selalu proporsional terhadap luas lahan/komoditas.
- Verifikasi pengajuan oleh PPL masih manual dan lambat.
- Distribusi pupuk sulit dilacak sampai ke titik serah terima.
- Tidak ada mekanisme untuk mendeteksi pupuk kedaluwarsa di titik distribusi.
- Tidak ada indikator awal untuk potensi penimbunan/penyalahgunaan pupuk subsidi.
- Pimpinan dinas tidak memiliki dashboard monitoring realtime yang terpusat.

### 1.5 Solusi yang Diusulkan
Sistem web terintegrasi (React.js + FastAPI + MySQL) dengan alur baku: **pengajuan → kalkulasi kuota → verifikasi PPL → distribusi → scan QR saat serah terima → monitoring**, ditambah pengayaan dashboard melalui API/data terbuka (cuaca, geospasial, data pertanian).

## 2. Tujuan Sistem

### 2.1 Tujuan Utama
Menyediakan satu platform terpadu untuk pengajuan, verifikasi, distribusi, dan monitoring subsidi pupuk yang transparan dan dapat dipertanggungjawabkan.

### 2.2 Tujuan untuk Petani
- Mengajukan subsidi pupuk secara daring tanpa proses manual berlapis.
- Mengetahui estimasi kuota berdasarkan luas lahan dan komoditas secara transparan.
- Memantau status pengajuan secara realtime.
- Memvalidasi penerimaan pupuk melalui scan QR.

### 2.3 Tujuan untuk PPL
- Memverifikasi pengajuan petani secara digital dan lebih cepat.
- Memiliki riwayat verifikasi yang terdokumentasi.
- Mendapat notifikasi atas pengajuan baru di wilayah binaannya.

### 2.4 Tujuan untuk Admin
- Mengelola data master (petani, lahan, komoditas, pupuk, batch).
- Memonitor distribusi dan status QR secara terpusat.
- Menerima alert atas anomali (expired, duplikasi scan, indikasi penimbunan).

### 2.5 Tujuan untuk Pimpinan
- Melihat KPI dan capaian realisasi subsidi secara ringkas.
- Mengakses peta sebaran distribusi dan laporan periodik.
- Mengambil keputusan berbasis data yang termutakhirkan.

## 3. Ruang Lingkup

### 3.1 In Scope
- Autentikasi & manajemen peran (Petani, PPL, Admin, Pimpinan).
- Pendataan petani, lahan, kelompok tani, dan komoditas.
- Pengajuan subsidi pupuk dan kalkulasi kuota otomatis.
- Verifikasi pengajuan oleh PPL.
- Distribusi pupuk dan pencatatan batch.
- Scan QR untuk validasi penerimaan, expired check, dan duplicate check.
- Deteksi indikasi penimbunan berbasis riwayat transaksi.
- Dashboard monitoring untuk Admin dan Pimpinan, termasuk peta dan grafik.
- Integrasi API/data terbuka (cuaca, geospasial, data pertanian pemerintah) sebagai pengayaan dashboard.
- Audit log dan notifikasi.

### 3.2 Out of Scope
- Transaksi pembayaran/e-commerce pupuk non-subsidi.
- Logistik pengiriman pupuk antar-gudang (rantai pasok hulu ke kios).
- Aplikasi mobile native (versi awal fokus web responsif).
- Integrasi otomatis penuh dengan sistem RDKK nasional (versi awal menggunakan data referensi/seed).

## 4. Target User

### 4.1 Petani
Pengguna individu pemilik/penggarap lahan yang mengajukan kebutuhan pupuk bersubsidi.

### 4.2 PPL
Penyuluh yang memverifikasi kesesuaian data pengajuan dengan kondisi lapangan.

### 4.3 Admin Dinas
Pengelola data master, distribusi, dan pemantauan operasional harian.

### 4.4 Pimpinan Dinas
Pengambil keputusan yang memerlukan ringkasan capaian dan laporan strategis.

## 5. Permasalahan yang Diselesaikan

### 5.1 Pengelolaan Data
Sentralisasi data petani, lahan, dan kelompok tani dalam satu basis data.

### 5.2 Ketidaksesuaian Kuota
Kalkulasi kuota otomatis berbasis luas lahan dan standar kebutuhan per komoditas.

### 5.3 Verifikasi Pengajuan
Alur verifikasi digital oleh PPL dengan status dan catatan yang terekam.

### 5.4 Distribusi
Pencatatan distribusi per batch dengan jejak yang bisa ditelusuri hingga penerima.

### 5.5 Pupuk Expired
Validasi tanggal kedaluwarsa saat scan QR di titik distribusi.

### 5.6 Indikasi Penimbunan
Deteksi pola transaksi tidak wajar (frekuensi/volume di luar kuota atau kewajaran) sebagai indikator awal — bukan mekanisme pencegahan mutlak.

### 5.7 Monitoring
Dashboard realtime untuk Admin dan Pimpinan dengan KPI, peta, dan grafik.

## 6. User Story

### 6.1 User Story Petani
- Sebagai petani, saya ingin melihat estimasi kuota pupuk saya berdasarkan luas lahan agar saya tahu batas pengajuan yang wajar.
- Sebagai petani, saya ingin mengajukan subsidi pupuk secara daring agar tidak perlu datang berulang kali.
- Sebagai petani, saya ingin memindai QR saat menerima pupuk agar penerimaan saya tercatat resmi.

### 6.2 User Story PPL
- Sebagai PPL, saya ingin melihat daftar pengajuan di wilayah saya agar dapat memverifikasi dengan cepat.
- Sebagai PPL, saya ingin menolak pengajuan dengan catatan agar petani tahu alasan penolakan.

### 6.3 User Story Admin
- Sebagai admin, saya ingin mengelola data batch pupuk agar setiap QR terhubung ke data yang valid.
- Sebagai admin, saya ingin menerima alert saat ada indikasi penimbunan agar dapat menindaklanjuti.

### 6.4 User Story Pimpinan
- Sebagai pimpinan, saya ingin melihat KPI realisasi subsidi pupuk agar dapat mengevaluasi capaian program.

## 7. Functional Requirements

| ID | Kebutuhan |
|---|---|
| FR-01 | Authentication — login/logout berbasis JWT dengan kontrol peran (RBAC) |
| FR-02 | Data Petani — CRUD data petani dan keanggotaan kelompok tani |
| FR-03 | Data Lahan — CRUD data lahan, luas, lokasi, dan komoditas |
| FR-04 | Pengajuan Pupuk — pengajuan baru, edit, pembatalan, riwayat |
| FR-05 | Kalkulasi Kuota — perhitungan otomatis berdasar luas lahan × standar kebutuhan komoditas |
| FR-06 | Verifikasi PPL — approve/reject pengajuan dengan catatan |
| FR-07 | Scan QR — pembacaan QR batch pupuk saat serah terima |
| FR-08 | Validasi Expired — pengecekan tanggal kedaluwarsa saat scan |
| FR-09 | Deteksi Indikasi Penimbunan — flag transaksi berdasarkan pola riwayat |
| FR-10 | Distribusi — pencatatan penyaluran per batch dan penerima |
| FR-11 | Dashboard — KPI, grafik, dan peta untuk Admin/Pimpinan |
| FR-12 | API/Data Integration — pengayaan dashboard dari data terbuka/eksternal |

## 8. Non-Functional Requirements

### 8.1 Security
Autentikasi JWT, kontrol akses berbasis peran, audit log untuk aksi sensitif, enkripsi kredensial.

### 8.2 Performance
Waktu respons API untuk operasi umum ditargetkan di bawah beberapa detik pada beban operasional wajar tingkat kabupaten; kalkulasi kuota dan validasi QR bersifat sinkron/realtime.

### 8.3 Responsiveness
Antarmuka dapat digunakan pada desktop, tablet, dan mobile (web responsif), mengingat scan QR umumnya dilakukan lewat perangkat mobile.

### 8.4 Usability
Alur pengajuan dan verifikasi dirancang minim langkah, dengan istilah yang familiar bagi petani dan PPL di lapangan.

## 9. Success Criteria
- Seluruh pengajuan tercatat digital dengan status yang dapat dilacak.
- Kuota terhitung otomatis dan konsisten dengan data lahan.
- Setiap distribusi memiliki jejak scan QR (waktu, lokasi logis, status validasi).
- Dashboard Admin/Pimpinan menampilkan data mendekati realtime.
- Tersedia log audit untuk seluruh aksi verifikasi dan distribusi.

## 10. Limitations
- Formula kalkulasi kuota dan standar kebutuhan pupuk per komoditas pada dokumen ini masih bersifat **contoh/placeholder** dan belum berstatus data resmi — perlu dikonfirmasi ke Dinas Pertanian/PPL sebelum implementasi final.
- Dataset RDKK dan luas lahan yang dipakai untuk seeding awal belum bersumber dari API/dataset resmi yang konkret; sumber aktual masih perlu ditentukan.
- Deteksi indikasi penimbunan bersifat indikatif (berbasis pola data), bukan jaminan pencegahan.
- Versi awal tidak mencakup integrasi logistik hulu (gudang ke kios) dan tidak mencakup aplikasi mobile native.
