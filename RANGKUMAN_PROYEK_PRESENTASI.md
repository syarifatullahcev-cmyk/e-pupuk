# 🌾 RANGKUMAN EKSEKUTIF PROYEK E-PUPUK KABUPATEN MOJOKERTO
## PANDUAN RINGKAS MATERI PRESENTASI KELAS & SIDANG FRAMEWORK
### *Sistem Terpadu Pengajuan Alokasi, Verifikasi Lapangan Spasial GIS, & Distribusi Pupuk Bersubsidi Berbasis Geofencing GPS & Kode QR*

> **Mata Kuliah**: Workshop Pemrograman Framework
>
> **Program Studi**: D3 Teknik Informatika — PENS PSDKU Lamongan (2026)
>
> **Dosen Pengampu**: Amma Liesvarastranta Haz, S.Tr.T., M.T.
>
> **Status Kesiapan Sistem**: Belum dinyatakan siap produksi. Uji perangkat nyata belum dilakukan dan role Kios mandiri belum tersedia. Hasil uji kode tercatat di [panduan uji lapangan](./PANDUAN_UJI_LAPANGAN_DAN_GLADI_DEMO.md).
>
> **Tim Pengembang**:
> - **Syarifatullah Ceva Efendy** (NRP: 312521002) — *Frontend Web (React 19) & Mobile App (Flutter) Developer*
> - **Selby Wafi Nurjuan** (NRP: 3125521018) — *Backend API (FastAPI) & Database Architect*

---

## 📌 1. PROFIL & LATAR BELAKANG PROYEK

### 🎯 Masalah Nyata di Lapangan (Problem Statement)
Penyaluran pupuk bersubsidi sering mengalami kebocoran dan inefisiensi akibat:
1. **Klaim Lahan Fiktif & Ganda**: Luas lahan pengajuan sering tidak sesuai dengan fisik di sawah.
2. **Penyelewengan Pupuk Bersubsidi**: Pupuk berpindah tangan ke pihak tidak berhak atau dijual kembali ke pasar gelap (*black market*).
3. **Penebusan Tidak Terpantau**: Tidak ada bukti apakah pupuk yang diambil benar-benar ditabur di sawah yang diajukan.

### 💡 Solusi Inovasi E-PUPUK (*Closed-Loop Ecosystem*)
Membangun platform digital terpadu hulu-ke-hilir untuk Dinas Pertanian Kabupaten Mojokerto:
* **Verifikasi Berkas Kependudukan & Lahan**: Validasi NIK 16 digit dan SPPT tanah.
* **Verifikasi Lapangan Spasial PPL**: Pemetaan poligon koordinat batas sawah P1..Pn dengan kalkulasi geodesik WGS-84 (*Spherical Excess*).
* **Multi-Bag QR Packaging**: Kuota pupuk dipecah otomatis per karung fisik 25 kg beridentitas QR unik.
* **Buka Karung Geofencing GPS & Foto**: Petani wajib memindai QR dan memotret saat karung pupuk dibuka di sawah ($\le 100\text{ meter}$ dari titik lahan terdaftar).

---

## 🏗️ 2. ARSITEKTUR TEKNOLOGI & MULTI-PORTAL

```text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                          ARSITEKTUR SISTEM TERPADU E-PUPUK                             │
├──────────────────────────┬─────────────────────────────┬───────────────────────────────┤
│    KLIEN WEB (REACT)     │     MOBILE APP (FLUTTER)    │       BACKEND & DATABASE      │
├──────────────────────────┼─────────────────────────────┼───────────────────────────────┤
│ • React 19 + Vite        │ • Flutter 3.x (Dart)        │ • FastAPI (Python 3.12)       │
│ • Tailwind CSS + Lucide  │ • FlutterMap + Tile Satelit │ • MySQL 8.0 & SQLite Support  │
│ • Leaflet Interactive    │ • Mobile Scanner (QR Karung)│ • SQLAlchemy ORM & Pydantic   │
│ • Multi-Portal Guard     │ • Geodesic GeoCalc WGS-84   │ • JWT Authentication + Bcrypt │
│ • Cetak Voucher Grid     │ • Camera Image Picker       │ • 4-Service Docker Compose    │
└──────────────────────────┴─────────────────────────────┴───────────────────────────────┘
```

### 👥 4 Aktor Utama dengan Hak Akses Ketat (*Role-Based Access Control*):
1. **Petani & Poktan**: Pendaftaran akun, pengajuan alokasi musim tanam, unduh e-Kupon, pemindaian QR buka karung di sawah.
2. **Admin Verifikator Dinas**: Audit berkas NIK/SPPT, penugasan PPL, persetujuan kuota, cetak lembar voucher QR karung pupuk.
3. **Petugas Penyuluh Lapangan (PPL)**: Menerima penugasan, survei sawah, input patok batas P1..Pn, tanda tangan digital berita acara.
4. **Kios Pengecer**: Role/akun Kios mandiri belum tersedia. Endpoint penebusan saat ini hanya mengizinkan Petani pemilik QR; alur Kios resmi masih perlu dikembangkan.

---

## 🚀 3. PEMBARUAN TERKINI & FITUR UNGGULAN (HIGHLIGHTS)

### A. Landing Page Mobile Flutter (UI/UX 1:1 Selaras Versi Web)
* **Top Navigation Bar**: Identitas E-PUPUK, tombol akses cepat Masuk, Daftar Petani, dan drawer navigasi.
* **Hero Section**: Badge resmi Disperta, headline interaktif, foto Smart Farming Mojokerto, dan tombol aksi langsung.
* **Pilihan Portal Terpadu**: Kartu peran khusus Petani (Paling Populer), Petugas PPL (Mobile App), dan Admin Dinas (Desktop Web).
* **Keunggulan Sistem**: 4 pilar (Validasi NIK/SPPT, Geotagging Poligon, QR Anti-Duplikasi, Layanan Aduan).
* **4 Langkah Alur Pengajuan**: Step-by-step teratur dari daftar akun hingga ambil pupuk di kios.
* **Footer Resmi Dinas**: Alamat kantor Jl. RA Basuni Sooko, akreditasi SPBE, dan kontak resmi.

### B. Modul GIS Geospasial Presisi Tinggi (PPL Mobile)
* **Bebas Titik Palsu**: Menghapus data koordinat fiktif; PPL mulai dari daftar titik kosong (`[]`) untuk input patok riil.
* **Input Manual P1..Pn**: Validasi rentang Latitude ($-90^\circ$ s/d $90^\circ$), Longitude ($-180^\circ$ s/d $180^\circ$), pencegahan titik duplikat, dan poligon otomatis menutup ke P1.
* **Formula Geodesic Spherical Excess WGS-84**: Menghitung luas permukaan bumi riil dalam $m^2$ dan Hektare (bukan Shoelace planar Cartesian mentah).
* **Validasi Ganda Server**: Backend FastAPI memverifikasi ulang geometri poligon; deviasi luas $> 10\%$ otomatis dihitung ulang server.

### C. Alokasi Multi-Karung Fisik (25 kg per QR Code)
* Alokasi tidak lagi berupa satu kode QR borongan, melainkan dipecah otomatis per karung 25 kg.
* Misal disetujui 100 kg ➔ Terbit 4 voucher QR unik siap cetak di Dashboard Admin Dinas.

### D. Penguncian Buka Karung GPS Geofencing & Foto Fisik
* Endpoint penebusan memeriksa pemilik QR, lokasi, dan bukti foto sesuai aturan backend.
* Alur ini belum merupakan verifikasi oleh akun Kios mandiri; tes GPS/kamera di perangkat nyata masih belum dilakukan.

---

## 📊 4. HASIL VERIFIKASI TERKINI

| Pemeriksaan | Hasil terakhir |
| :--- | :--- |
| Backend workflow, generator aset, dan pengaman seed | 7 tes lulus; workflow memakai SQLite dan direktori unggahan sementara |
| React | 4 tes lulus; lint dan production build selesai, lint masih mencatat peringatan |
| Flutter | 37 tes lulus; Flutter Web release build berhasil |
| Analisis Flutter | Tidak ada error/warning; analisis workspace mencatat 214 info, analisis file PPL terkait mencatat 49 info |
| GPS, kamera, izin sistem, jaringan lemah, peta di perangkat nyata | Belum diuji |
| Role Kios mandiri dan kesiapan produksi | Belum tersedia / belum diverifikasi |

---

## ⏱️ 5. PANDUAN SKRIP PRESENTASI 5 MENIT (UNTUK CEVA & SELBY)

Gunakan pembagian waktu ringkas ini saat mempresentasikan proyek di hadapan dosen:

### 🎙️ Menit 1: Pembukaan & Latar Belakang (30-60 detik)
> *"Selamat pagi/siang Bapak Dosen dan rekan-rekan. Kami dari tim E-PUPUK Kabupaten Mojokerto, Syarifatullah Ceva Efendy dan Selby Wafi Nurjuan. Proyek kami menghadirkan sistem terpadu pengajuan alokasi, audit lapangan spasial, hingga distribusi pupuk bersubsidi berbasis geofencing GPS dan kode QR unik."*

### 🎙️ Menit 2: Alur Bisnis Hulu ke Hilir (60 detik)
> *"Sistem kami memecahkan 3 masalah utama distribusi pupuk: data lahan fiktif, pupuk salah sasaran, dan penjualan ilegal di luar kelompok tani. Kami menerapkan 4 portal akses: Petani, Admin Dinas, Petugas PPL, dan Kios Rekanan."*

### 🎙️ Menit 3: Demonstrasi Fitur Unggulan — Web & Mobile (90 detik)
> *"Di sisi Web, Admin memverifikasi berkas NIK dan mencetak voucher QR per karung fisik 25 kg. Di sisi Mobile Flutter, hari ini kami telah menyelaraskan tampilan Landing Page 1:1 dengan web resmi. Petugas PPL dapat membuka peta satelit, memasukkan koordinat patok batas lahan P1 hingga P4, dan menghitung luas faktual menggunakan metode geodesik bola bumi WGS-84 tanpa manipulasi titik estimasi palsu."*

### 🎙️ Menit 4: Verifikasi Buka Karung & Geofencing GPS (60 detik)
> *"Saat pupuk dibawa ke sawah, petani wajib membuka aplikasi untuk memindai QR karung dan mengambil foto bukti fisik. Sistem menghitung jarak koordinat petani dengan formula Haversine. Jika petani berada di luar radius sawah (> 100m), sistem menolak dan transaksi tidak tervalidasi."*

### 🎙️ Menit 5: Kesiapan Sistem, Testing, & Penutup (30 detik)
> *"Pengujian kode yang sudah dilakukan mencakup tujuh tes backend, empat tes React, serta 37 tes Flutter yang lulus. Build React dan Flutter Web juga berhasil. Uji perangkat nyata dan role Kios mandiri masih menjadi pekerjaan lanjutan, jadi kami belum menyatakan sistem siap produksi. Terima kasih."*

---

## 📑 6. CHEAT SHEET TANYA JAWAB DOSEN (FAQ)

* **Q: Mengapa luas lahan tidak dihitung pakai rumus poligon biasa?**

  *A: Rumus Shoelace biasa mengasumsikan bumi datar (Cartesian). Untuk pemetaan sawah berbasis koordinat derajat (lat/lon), kelengkungan bumi di khatulistiwa menghasilkan deviasi besar jika tidak diproyeksikan. Kami menggunakan metode Geodesic Spherical Excess WGS-84 dengan jari-jari $6.378.137\text{ meter}$, diverifikasi ganda antara Flutter dan FastAPI.*

* **Q: Bagaimana jika PPL tidak ada sinyal internet saat di pelosok sawah?**

  *A: Koordinat patok dapat dimasukkan manual, tetapi penyimpanan dan sinkronisasi offline belum tersedia. Hasil survei perlu dikirim saat koneksi tersedia.*

* **Q: Mengapa kuota dipecah per 25 kg?**

  *A: Untuk mencegah pupuk dijual kembali secara ilegal. Setiap karung fisik 25 kg memiliki label QR unik yang hangus saat dibuka di sawah oleh petani yang bersangkutan.*

---

Mojokerto, 5 November 2026

**Tim Pengembang E-PUPUK Kabupaten Mojokerto**

*(Syarifatullah Ceva Efendy & Selby Wafi Nurjuan)*
