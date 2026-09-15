# Product Requirements
# E-Pupuk Kabupaten Mojokerto

## 1. Overview

### 1.1 Nama Sistem
E-Pupuk — Sistem Pengajuan dan Monitoring Distribusi Subsidi Pupuk Kabupaten Mojokerto.

### 1.2 Deskripsi Sistem
E-Pupuk adalah sistem berbasis web yang mengintegrasikan pendataan petani, pemeriksaan RDKK (Rencana Definitif Kebutuhan Kelompok), pengajuan subsidi pupuk beserta kelengkapan berkas identitas (KTP, foto lahan, alamat, koordinat lokasi, dan tanggal), verifikasi berkas oleh Admin Dinas, penugasan survei lapangan kepada PPL (Penyuluh Pertanian Lapangan), verifikasi fisik lahan dan bahan tanaman oleh PPL, persetujuan akhir dan distribusi pupuk bersubsidi, serta monitoring melalui dashboard. Sistem menambahkan lapisan validasi berbasis QR Code pada setiap batch pupuk untuk mencatat penerimaan, memeriksa tanggal kedaluwarsa, dan memberi indikasi dini potensi penimbunan.

### 1.3 Latar Belakang
Proses pengajuan dan distribusi pupuk bersubsidi saat ini masih rawan terhadap: data petani dan lahan yang tidak termutakhirkan, kuota yang tidak sinkron dengan luas lahan aktual, proses verifikasi manual yang lambat, minimnya jejak distribusi hingga ke titik penerima, tidak adanya mekanisme deteksi pupuk kedaluwarsa maupun indikasi penimbunan, **tidak adanya verifikasi kelengkapan dokumen identitas petani (KTP) dan foto kondisi lahan sehingga rawan penerima fiktif atau data lahan yang tidak sesuai kondisi riil**, serta **tidak adanya mekanisme penugasan formal PPL untuk melakukan survei fisik bahan/tanaman yang akan disubsidi**.

### 1.4 Permasalahan
- Data petani, lahan, dan kelompok tani tersebar dan tidak konsisten.
- Kuota pupuk tidak selalu proporsional terhadap luas lahan/komoditas.
- Tidak ada verifikasi kelengkapan dokumen identitas petani (KTP) sebelum pengajuan subsidi diproses.
- Tidak ada foto kondisi fisik lahan aktual yang dilampirkan pada pengajuan, rawan lahan fiktif atau tidak sesuai.
- Tidak ada mekanisme formal disposisi/penugasan Admin kepada PPL untuk melakukan survei fisik lapangan.
- PPL tidak memiliki alat digital untuk mendokumentasikan dan melaporkan hasil survei lapangan (kondisi lahan dan bahan tanaman).
- Verifikasi pengajuan oleh PPL masih manual dan lambat.
- Distribusi pupuk sulit dilacak sampai ke titik serah terima.
- Tidak ada mekanisme untuk mendeteksi pupuk kedaluwarsa di titik distribusi.
- Tidak ada indikator awal untuk potensi penimbunan/penyalahgunaan pupuk subsidi.
- Pimpinan dinas tidak memiliki dashboard monitoring realtime yang terpusat.

### 1.5 Solusi yang Diusulkan
Sistem web terintegrasi (React.js + FastAPI + MySQL) dengan alur baku dua tahap verifikasi: **pengajuan + unggah berkas identitas (KTP, foto lahan, alamat, koordinat, tanggal) → verifikasi berkas oleh Admin → penugasan survei lapangan ke PPL oleh Admin → survei fisik bahan/lahan oleh PPL dengan upload foto bukti lapangan → persetujuan akhir oleh Admin → distribusi → scan QR saat serah terima → monitoring**, ditambah pengayaan dashboard melalui API/data terbuka (cuaca, geospasial, data pertanian).

## 2. Tujuan Sistem

### 2.1 Tujuan Utama
Menyediakan satu platform terpadu untuk pengajuan, verifikasi berkas dan lapangan, distribusi, dan monitoring subsidi pupuk yang transparan, terdokumentasi, dan dapat dipertanggungjawabkan.

### 2.2 Tujuan untuk Petani
- Mengajukan subsidi pupuk secara daring dengan melengkapi berkas identitas (foto KTP), foto kondisi lahan, alamat lengkap, titik koordinat lokasi lahan, dan tanggal pengajuan.
- Mengetahui estimasi kuota berdasarkan luas lahan dan komoditas secara transparan.
- Memantau status pengajuan secara realtime melalui progress stepper 6-tahap.
- Memvalidasi penerimaan pupuk melalui scan QR.

### 2.3 Tujuan untuk PPL
- Menerima penugasan resmi dari Admin Dinas untuk melakukan survei fisik lapangan terhadap lahan dan bahan/tanaman yang diajukan subsidi.
- Melakukan verifikasi fisik kondisi lahan dan tanaman secara terstruktur digital.
- Mendokumentasikan hasil survei lapangan (foto bukti fisik, catatan kelayakan, rekomendasi) melalui sistem.
- Memiliki riwayat verifikasi dan survei yang terdokumentasi.
- Mendapat notifikasi atas penugasan survei baru dari Admin.

### 2.4 Tujuan untuk Admin
- Memverifikasi kelengkapan dan keabsahan berkas administratif petani (foto KTP, foto lahan, alamat, koordinat, tanggal).
- Menugaskan PPL wilayah binaan yang sesuai untuk melakukan survei lapangan terhadap pengajuan yang lolos verifikasi berkas.
- Mengelola data master (petani, lahan, komoditas, pupuk, batch).
- Memberikan persetujuan akhir distribusi subsidi pupuk berdasarkan hasil verifikasi berkas dan laporan survei PPL.
- Memonitor distribusi dan status QR secara terpusat.
- Menerima alert atas anomali (expired, duplikasi scan, indikasi penimbunan).

### 2.5 Tujuan untuk Pimpinan
- Melihat KPI dan capaian realisasi subsidi secara ringkas.
- Mengakses peta sebaran distribusi dan laporan periodik.
- Mengambil keputusan berbasis data yang termutakhirkan.

## 3. Ruang Lingkup

### 3.1 In Scope
- Autentikasi & manajemen peran (Petani, PPL, Admin, Pimpinan).
- Pendataan petani (termasuk foto KTP, alamat, tanggal pendaftaran), lahan (foto lahan, koordinat GPS, alamat lahan), kelompok tani, dan komoditas.
- Pengajuan subsidi pupuk beserta upload berkas wajib: foto KTP, foto lahan, alamat lengkap, titik koordinat lokasi, tanggal pengajuan.
- Verifikasi berkas administratif pengajuan oleh Admin (termasuk status PERLU_PERBAIKAN_BERKAS).
- Penugasan/disposisi formal PPL oleh Admin untuk survei lapangan per pengajuan.
- Survei fisik lapangan oleh PPL: pemeriksaan kondisi lahan dan bahan/tanaman yang disubsidi, upload foto bukti lapangan, catatan rekomendasi.
- Persetujuan akhir dan alokasi distribusi oleh Admin berdasarkan laporan survei PPL.
- Kalkulasi kuota otomatis.
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
Pengguna individu pemilik/penggarap lahan yang mengajukan kebutuhan pupuk bersubsidi dengan melengkapi dokumen identitas dan data lahan secara digital.

### 4.2 PPL
Penyuluh yang menerima penugasan dari Admin Dinas untuk melakukan survei fisik lahan dan bahan/tanaman petani pemohon subsidi, serta mendokumentasikan hasilnya secara digital.

### 4.3 Admin Dinas
Pengelola data master, verifikasi berkas pengajuan, disposisi penugasan PPL, persetujuan akhir distribusi, dan pemantauan operasional harian.

### 4.4 Pimpinan Dinas
Pengambil keputusan yang memerlukan ringkasan capaian dan laporan strategis.

## 5. Permasalahan yang Diselesaikan

### 5.1 Pengelolaan Data
Sentralisasi data petani (termasuk foto KTP, alamat), lahan (foto lahan, koordinat GPS, alamat lahan), dan kelompok tani dalam satu basis data.

### 5.2 Ketidaksesuaian Kuota
Kalkulasi kuota otomatis berbasis luas lahan dan standar kebutuhan per komoditas.

### 5.3 Verifikasi Berkas Administratif
Alur verifikasi dokumen (KTP, foto lahan, alamat, koordinat, tanggal) oleh Admin dengan status yang terekam, termasuk mekanisme PERLU_PERBAIKAN_BERKAS agar petani dapat mengunggah ulang tanpa mengulang pengisian form.

### 5.4 Survei Fisik Lapangan
Alur penugasan formal PPL oleh Admin dan pelaporan hasil survei fisik lahan/tanaman secara digital (foto bukti lapangan, catatan kondisi riil, rekomendasi setuju/tolak).

### 5.5 Distribusi
Pencatatan distribusi per batch dengan jejak yang bisa ditelusuri hingga penerima, berdasarkan persetujuan akhir Admin.

### 5.6 Pupuk Expired
Validasi tanggal kedaluwarsa saat scan QR di titik distribusi.

### 5.7 Indikasi Penimbunan
Deteksi pola transaksi tidak wajar (frekuensi/volume di luar kuota atau kewajaran) sebagai indikator awal — bukan mekanisme pencegahan mutlak.

### 5.8 Monitoring
Dashboard realtime untuk Admin dan Pimpinan dengan KPI, peta, dan grafik.

## 6. User Story

### 6.1 User Story Petani
- Sebagai petani, saya ingin melihat estimasi kuota pupuk saya berdasarkan luas lahan agar saya tahu batas pengajuan yang wajar.
- Sebagai petani, saya ingin mengajukan subsidi pupuk secara daring beserta mengunggah foto KTP dan foto kondisi lahan saya agar pengajuan terdokumentasi dengan baik.
- Sebagai petani, saya ingin menyertakan alamat lengkap dan titik lokasi lahan saya pada pengajuan agar verifikasi lapangan dapat dilakukan secara akurat.
- Sebagai petani, saya ingin memantau status pengajuan saya secara realtime (tahap verifikasi berkas, penugasan PPL, survei lapangan, persetujuan, distribusi) agar saya tahu posisi pengajuan saya.
- Sebagai petani, jika berkas saya dinyatakan perlu perbaikan, saya ingin mengunggah ulang berkas tanpa harus mengisi form pengajuan baru dari awal.
- Sebagai petani, saya ingin memindai QR saat menerima pupuk agar penerimaan saya tercatat resmi.

### 6.2 User Story PPL
- Sebagai PPL, saya ingin menerima notifikasi dan daftar tugas survei lapangan yang ditugaskan Admin kepada saya agar saya dapat merencanakan kunjungan lapangan.
- Sebagai PPL, saya ingin melihat data pengajuan petani (foto KTP, foto lahan, alamat, koordinat lokasi) sebagai referensi sebelum turun ke lapangan.
- Sebagai PPL, saya ingin mendokumentasikan dan mengunggah foto kondisi fisik lahan dan bahan/tanaman yang saya kunjungi sebagai bukti survei lapangan.
- Sebagai PPL, saya ingin mengisi catatan hasil evaluasi kondisi lahan dan tanaman, serta memberikan rekomendasi setuju atau tolak pengajuan berdasarkan fakta lapangan.
- Sebagai PPL, saya ingin menolak pengajuan dengan catatan alasan yang jelas agar petani tahu alasan penolakannya.

### 6.3 User Story Admin
- Sebagai admin, saya ingin memeriksa kelengkapan berkas pengajuan petani (foto KTP, foto lahan, alamat, koordinat, tanggal) dalam satu tampilan terpadu agar verifikasi berkas dapat dilakukan cepat dan akurat.
- Sebagai admin, saya ingin menandai pengajuan dengan status PERLU_PERBAIKAN_BERKAS disertai catatan detail apa yang perlu diperbaiki petani.
- Sebagai admin, saya ingin menugaskan PPL wilayah binaan yang sesuai untuk melakukan survei lapangan terhadap pengajuan yang lolos verifikasi berkas.
- Sebagai admin, saya ingin menerima notifikasi ketika PPL telah menyelesaikan survei lapangan agar saya dapat segera memberikan persetujuan akhir.
- Sebagai admin, saya ingin mengelola data batch pupuk agar setiap QR terhubung ke data yang valid.
- Sebagai admin, saya ingin menerima alert saat ada indikasi penimbunan agar dapat menindaklanjuti.

### 6.4 User Story Pimpinan
- Sebagai pimpinan, saya ingin melihat KPI realisasi subsidi pupuk agar dapat mengevaluasi capaian program.

## 7. Functional Requirements

| ID | Kebutuhan |
|---|---|
| FR-01 | Authentication — login/logout berbasis JWT dengan kontrol peran (RBAC) |
| FR-02 | Data Petani — CRUD data petani termasuk foto KTP, alamat, dan tanggal pendaftaran |
| FR-03 | Data Lahan — CRUD data lahan termasuk foto lahan, koordinat GPS (latitude/longitude), alamat lahan, dan komoditas |
| FR-04 | Pengajuan Pupuk — pengajuan baru dengan upload wajib foto KTP, foto lahan, alamat, koordinat lokasi, dan tanggal; edit, pembatalan, dan riwayat |
| FR-05 | Kalkulasi Kuota — perhitungan otomatis berdasar luas lahan × standar kebutuhan komoditas |
| FR-06 | Verifikasi Berkas Admin — approve/reject berkas/PERLU_PERBAIKAN_BERKAS terhadap kelengkapan dan keabsahan dokumen petani |
| FR-07 | Penugasan Survei PPL — Admin menugaskan PPL wilayah binaan untuk melakukan survei fisik lapangan; sistem menyarankan PPL penanggung wilayah secara otomatis dengan opsi override manual Admin |
| FR-08 | Survei Lapangan PPL — PPL mendokumentasikan kondisi fisik lahan dan bahan/tanaman, upload foto bukti survei lapangan, catatan evaluasi, dan rekomendasi |
| FR-09 | Persetujuan Akhir Admin — Admin mengesahkan alokasi subsidi berdasarkan laporan survei PPL |
| FR-10 | Scan QR — pembacaan QR batch pupuk saat serah terima |
| FR-11 | Validasi Expired — pengecekan tanggal kedaluwarsa saat scan |
| FR-12 | Deteksi Indikasi Penimbunan — flag transaksi berdasarkan pola riwayat |
| FR-13 | Distribusi — pencatatan penyaluran per batch dan penerima |
| FR-14 | Dashboard — KPI, grafik, dan peta untuk Admin/Pimpinan |
| FR-15 | API/Data Integration — pengayaan dashboard dari data terbuka/eksternal |

## 8. Non-Functional Requirements

### 8.1 Security
Autentikasi JWT, kontrol akses berbasis peran, audit log untuk aksi sensitif, enkripsi kredensial. Berkas foto KTP dan data NIK dilindungi dengan pembatasan akses ketat (hanya Admin dan PPL yang ditugaskan pada pengajuan terkait yang dapat mengakses).

### 8.2 Performance
Waktu respons API untuk operasi umum ditargetkan di bawah beberapa detik pada beban operasional wajar tingkat kabupaten; kalkulasi kuota dan validasi QR bersifat sinkron/realtime. Upload berkas foto menggunakan validasi ukuran (maks. 5MB per file) dan format (JPEG/PNG/WEBP).

### 8.3 Responsiveness
Antarmuka dapat digunakan pada desktop, tablet, dan mobile (web responsif), mengingat scan QR dan pengisian form survei lapangan umumnya dilakukan lewat perangkat mobile.

### 8.4 Usability
Alur pengajuan dan verifikasi dirancang minim langkah, dengan istilah yang familiar bagi petani dan PPL di lapangan. Form upload berkas dilengkapi preview foto sebelum submit.

## 9. Success Criteria
- Seluruh pengajuan memiliki kelengkapan berkas identitas (KTP, foto lahan, alamat, koordinat, tanggal) yang terverifikasi Admin.
- Setiap pengajuan yang lolos verifikasi berkas memiliki jejak penugasan PPL yang terdokumentasi.
- Setiap distribusi didasarkan pada persetujuan akhir Admin yang bersumber dari laporan survei lapangan PPL.
- Kuota terhitung otomatis dan konsisten dengan data lahan.
- Setiap distribusi memiliki jejak scan QR (waktu, lokasi logis, status validasi).
- Dashboard Admin/Pimpinan menampilkan data mendekati realtime.
- Tersedia log audit untuk seluruh aksi verifikasi berkas, penugasan PPL, survei lapangan, dan distribusi.

## 10. Limitations
- Formula kalkulasi kuota dan standar kebutuhan pupuk per komoditas pada dokumen ini masih bersifat **contoh/placeholder** dan belum berstatus data resmi — perlu dikonfirmasi ke Dinas Pertanian/PPL sebelum implementasi final.
- Dataset RDKK dan luas lahan yang dipakai untuk seeding awal belum bersumber dari API/dataset resmi yang konkret; sumber aktual masih perlu ditentukan.
- Deteksi indikasi penimbunan bersifat indikatif (berbasis pola data), bukan jaminan pencegahan.
- Versi awal tidak mencakup integrasi logistik hulu (gudang ke kios) dan tidak mencakup aplikasi mobile native.
- Kualitas akurasi koordinat GPS bergantung pada perangkat yang digunakan petani saat mengisi pengajuan; validasi koordinat berbasis batas wilayah administrasi dapat ditambahkan pada versi lanjutan.
