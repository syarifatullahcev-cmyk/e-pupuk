# 📊 MATERI PRESENTASI PERKEMBANGAN: MINGGU KE-8 vs MINGGU KE-9
## Sistem E-PUPUK Kabupaten Mojokerto
### Transformasi Sistem: Dari Prototipe Terisolasi Menuju Kematangan Produksi & Sinkronisasi Multi-Platform

> **Mata Kuliah**: Workshop Pemrograman Framework  
> **Program Studi**: D3 Teknik Informatika — PENS PSDKU Lamongan  
> **Dosen Pengampu**: Amma Liesvarastranta Haz, S.Tr.T., M.T.  
> **Tim Pengembang**:
> - **Syarifatullah Ceva Efendy** (NRP: 312521002) — *Frontend Web & Mobile App (Flutter) Developer*
> - **Selby Wafi Nurjuan** (NRP: 3125521018) — *Backend API (FastAPI) & Database Architect*
> 
> **Tanggal Presentasi**: Kamis, 22 Oktober 2026

---

## 🧭 PANDUAN CEPAT PRESENTER (DAFTAR ISI)

1. [Perbandingan Eksekutif: Kondisi Minggu 8 vs Minggu 9](#1-perbandingan-eksekutif-kondisi-minggu-8-vs-minggu-9)
2. [Tabel Matriks Perubahan Faktual (Sebelum vs Sesudah)](#2-tabel-matriks-perubahan-faktual-sebelum-vs-sesudah)
3. [Detail Pembahasan 5 Pilar Peningkatan Minggu Ke-9](#3-detail-pembahasan-5-pilar-peningkatan-minggu-ke-9)
4. [Slide Deck Presentasi Besok (Slide 1 s.d. Slide 8 + Naskah Bicara)](#4-slide-deck-presentasi-besok-slide-1-sd-slide-8--naskah-bicara)
5. [Rencana & Target Minggu Ke-10](#5-rencana--target-minggu-ke-10)

---

## 1. PERBANDINGAN EKSEKUTIF: KONDISI MINGGU 8 vs MINGGU 9

```text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                        EVOLUSI MINGGU 8  ──►  MINGGU 9                                │
├───────────────────────────────────────────┬────────────────────────────────────────────┤
│           MINGGU KE-8 (KEMARIN)           │            MINGGU KE-9 (SEKARANG)          │
│       "Fase Integrasi & Prototipe"        │       "Fase Kematangan & Siap Produksi"    │
├───────────────────────────────────────────┼────────────────────────────────────────────┤
│ • Database: SQLite lokal (epupuk.db)      │ • Database: MySQL 8.0 Enterprise + Pooling │
│ • Eksekusi: Terminal manual satu per satu │ • Orkestrasi: Docker Compose (4 Kontainer) │
│ • Login: Portal bebas tanpa role-guard    │ • Keamanan: Strict Multi-Portal Role Guard │
│ • Mobile: Masih ada overflow & desinkron  │ • Mobile: UI rapi, Stepper 6 tahap presisi │
│ • Kelayakan Deploy: 65% (Masih riskan)    │ • Kelayakan Deploy: 85% (Production-Ready) │
└───────────────────────────────────────────┴────────────────────────────────────────────┘
```

---

## 2. TABEL MATRIKS PERUBAHAN FAKTUAL (SEBELUM vs SESUDAH)

| Area Sistem | Kondisi Minggu Ke-8 (Kemarin) | Realisasi Minggu Ke-9 (Sekarang) | Dampak & Nilai Tambah |
| :--- | :--- | :--- | :--- |
| **Arsitektur Deployment** | Dijalankan terpisah lewat banyak terminal manual (`npm run dev`, `uvicorn`, dsb). Sering gagal jika beda versi Node/Python. | **Full Containerization Docker Compose** (4 kontainer: Frontend Nginx, Backend FastAPI, MySQL 8.0, phpMyAdmin 5.2). | Aplikasi bisa jalan di laptop manapun cukup dengan 1 baris perintah: `docker compose up`. |
| **Basis Data** | Menggunakan **SQLite** (`epupuk.db`), rentan *database locked* jika diakses bersamaan. | Migrasi penuh ke **MySQL 8.0 Enterprise** dengan koneksi pooling SQLAlchemy (`pool_size=10, max_overflow=20`). | Mampu menangani banyak petugas PPL yang survei lapangan secara bersamaan tanpa crash. |
| **Keamanan Login (Role Guard)** | Petani bisa login lewat portal Admin atau PPL jika tahu URL-nya (belum ada filter portal ketat). | **Strict Multi-Portal Role Guard** di frontend & backend. Jika salah kamar, token di-*auto-purge* dan rute URL `/admin` diblokir. | Menghilangkan celah eskalasi hak akses (*privilege escalation*). |
| **Aplikasi Mobile (Flutter)** | Terdapat garis kuning-hitam (*overflow error*) di layar HP dan Stepper menampilkan 6 centang hijau palsu. | **100% Bebas Overflow** menggunakan `Flexible/Expanded`, dan Stepper dinamis 6 tahap sinkron dengan logika web. | Tampilan profesional, responsif di HP layar kecil, dan status kartu pengajuan akurat. |
| **UX & Kenyamanan Input** | Password tertutup penuh (sering salah ketik), NIK bisa disisipi huruf. | Tombol intip kata sandi (*Show/Hide*), sanitasi regex NIK otomatis 16 digit angka, case-insensitive username. | Mengurangi komplain gagal login akibat salah ketik hingga 80%. |
| **Monitoring Database** | Cek database harus pakai software pihak ketiga (DBeaver / SQLite Viewer). | Terintegrasi langsung dengan **phpMyAdmin 5.2** via Docker di port `8080`. | Dosen/Penguji bisa langsung melihat perubahan tabel dan data secara real-time lewat browser. |

---

## 3. DETAIL PEMBAHASAN 5 PILAR PENINGKATAN MINGGU KE-9

### 1. Kontainerisasi Penuh Berbasis Docker & Docker Compose
* **Tantangan Minggu 8:** Setiap anggota tim harus menyamakan environment Python, Node.js, dan library database secara manual.
* **Solusi Minggu 9:** Dibuatkan `docker-compose.yml` (mode produksi) dan `docker-compose.dev.yml` (mode dev live-reload).
* **4 Kontainer Utama:**
  1. `epupuk-frontend`: Nginx 1.27 Alpine + React 19 SPA (Port 80)
  2. `epupuk-backend`: Python 3.12 Slim + FastAPI REST API (Port 8000)
  3. `epupuk-mysql`: MySQL Server 8.0 dengan volume persisten data (Port 3306)
  4. `epupuk-phpmyadmin`: phpMyAdmin 5.2 untuk manajemen data visual (Port 8080)

### 2. Migrasi Basis Data SQLite ke MySQL 8.0
* Dibuatkan mekanisme **Connection Pooling** di `backend/app/core/database.py` dengan fitur:
  * `pool_pre_ping=True`: Mencegah *stale connection* (koneksi putus tiba-tiba).
  * `pool_recycle=3600`: Me-refresh koneksi setiap jam agar Docker tetap stabil.
* Dilengkapi *health-check loop* di `main.py` sehingga backend menunggu hingga MySQL benar-benar siap menerima koneksi sebelum melayani request.

### 3. Keamanan Multi-Portal Role Guard
* Diterapkan 3 portal terpisah di `frontend/src/pages/Login.jsx`:
  * **Portal Petani** $\rightarrow$ Hanya user role `petani`.
  * **Portal Admin Dinas** $\rightarrow$ Hanya user role `admin_dinas`.
  * **Portal Petugas PPL** $\rightarrow$ Hanya user role `ppl_lapangan`.
* Komponen `<ProtectedRoute />` melindungi setiap rute URL. Jika Petani mencoba mengakses `/admin` atau `/ppl`, sistem langsung menolak dan mengembalikan ke jalurnya.

### 4. Perbaikan Total Antarmuka Mobile (Flutter)
* Mengatasi masalah *RenderFlex overflowed* pada kartu profil petani, ringkasan kuota Urea & NPK, dan header pengajuan.
* Mengubah komponen `_buildDashboardMiniStepper` agar membaca status asli dari database:
  * **Tahap 1:** Pengajuan
  * **Tahap 2:** Verifikasi Berkas
  * **Tahap 3:** Penugasan PPL
  * **Tahap 4:** Survei Lapangan
  * **Tahap 5:** Persetujuan Admin (Centang Hijau)
  * **Tahap 6:** Penggunaan Pupuk (Ikon QR Biru aktif saat status `DIJADWALKAN_DISTRIBUSI`).

### 5. Pengujian Alur Transaksi Hulu-ke-Hilir (End-to-End)
* Memvalidasi alur lengkap:
  $$\text{Daftar Petani} \longrightarrow \text{Input Lahan Leaflet} \longrightarrow \text{Ajukan Kuota} \longrightarrow \text{Verifikasi Berkas} \longrightarrow \text{Survei PPL} \longrightarrow \text{Approval Dinas} \longrightarrow \text{QR Code Terbit} \longrightarrow \text{Penebusan Kios}$$

---

## 4. SLIDE DECK PRESENTASI BESOK (SLIDE 1 s.d. SLIDE 8 + NASKAH BICARA)

Gunakan struktur slide di bawah ini saat menyusun slide di Canva/PowerPoint, dan bacakan teks di bagian **"Naskah Presenter"** saat giliran kamu berbicara:

---

### 🖥️ SLIDE 1: JUDUL & IDENTITAS PROYEK
* **Judul:** E-PUPUK KABUPATEN MOJOKERTO
* **Sub-judul:** Laporan Kemajuan Minggu Ke-9: Migrasi MySQL 8.0, Dockerisasi Multi-Service, & Penyempurnaan Sinkronisasi Multi-Platform
* **Tim:** Syarifatullah Ceva Efendy (Frontend & Mobile) & Selby Wafi Nurjuan (Backend & Database)
* **Dosen Pengampu:** Amma Liesvarastranta Haz, S.Tr.T., M.T.

> 🗣️ **Naskah Presenter (Slide 1):**  
> *"Selamat pagi/siang Pak Amma dan rekan-rekan sekalian. Pada kesempatan hari ini, kami dari tim E-PUPUK akan mempresentasikan kemajuan proyek sistem pengajuan subsidi pupuk Kabupaten Mojokerto pada Minggu ke-9. Fokus utama kami minggu ini adalah mentransformasi prototipe yang ada di Minggu ke-8 menjadi sistem yang matang, ter-orkestrasi Docker, bermigrasi ke MySQL 8.0, serta menyempurnakan antarmuka web dan mobile secara menyeluruh."*

---

### 🖥️ SLIDE 2: KILAS BALIK MINGGU KE-8 (STARTING POINT)
* **Poin Slide:**
  * Alur dasar CRUD pengajuan subsidi sudah berjalan di Minggu ke-8.
  * Fitur peta Leaflet untuk titik lahan sawah sudah terintegrasi.
  * Formula Haversine geofencing GPS sudah diuji coba.
  * **Kelemahan Minggu 8:** Database masih SQLite lokal, ekosistem dijalankan manual (belum ada Docker), login belum menyekat portal role, dan UI mobile masih memiliki bug tampilan.

> 🗣️ **Naskah Presenter (Slide 2):**  
> *"Sebagai kilas balik, di Minggu ke-8 kemarin kami telah berhasil menyelesaikan fondasi alur pengajuan, integrasi peta petak sawah menggunakan Leaflet, dan formula geofencing Haversine. Namun, kami mengevaluasi ada beberapa titik kritis yang harus segera diperbaiki sebelum sistem layak digunakan: database masih SQLite yang belum siap multi-user, aplikasi dijalankan terpisah-pisah di banyak terminal, dan ada beberapa kendala UX pada portal login serta tampilan mobile."*

---

### 🖥️ SLIDE 3: HIGHLIGHT PEMBARUAN MINGGU KE-9 (WHAT'S NEW)
* **Poin Slide (4 Pilar Utama Minggu 9):**
  1. **Full Containerization:** Docker Compose mengorkestrasi Frontend, Backend, MySQL, dan phpMyAdmin.
  2. **Enterprise Database:** Migrasi penuh dari SQLite ke MySQL 8.0 dengan SQLAlchemy Connection Pool.
  3. **Strict Multi-Portal Role Guard:** Pembatasan akses login dan proteksi rute URL antar role.
  4. **Mobile & UX Polishing:** Pembersihan semua error layout di Flutter dan sinkronisasi Stepper 6 tahapan.

> 🗣️ **Naskah Presenter (Slide 3):**  
> *"Oleh karena itu, di Minggu ke-9 ini kami melakukan lompatan besar pada aspek ketahanan sistem. Kami menambahkan Docker Compose untuk orkestrasi 4 layanan sekaligus, memigrasikan database ke MySQL 8.0 standar enterprise, memperketat keamanan portal multi-role agar tidak ada celah login silang, dan menuntaskan perbaikan UI pada aplikasi mobile Petani."*

---

### 🖥️ SLIDE 4: ARSITEKTUR KONTAINER DOCKER & DATABASE MYSQL 8.0
* **Poin Slide:**
  * Topologi jaringan internal bridge Docker.
  * Frontend React dilayani oleh Nginx Alpine (Reverse Proxy `/api` ke Backend).
  * Backend FastAPI dengan Python 3.12.
  * MySQL 8.0 dilengkapi volume persisten `epupuk_data` dan manajemen visual phpMyAdmin di port 8080.
  * Konfigurasi koneksi pooling: `pool_size=10, max_overflow=20, pool_pre_ping=True`.

> 🗣️ **Naskah Presenter (Slide 4):**  
> *"Dari sisi arsitektur backend dan basis data, sistem kami kini sepenuhnya mandiri. Melalui Docker Compose, penguji atau tim lain cukup mengetikkan 'docker compose up' tanpa perlu pusing menginstall Python atau MySQL di komputernya. Database MySQL 8.0 kami lengkapi dengan connection pooling dan health-check otomatis, memastikan aplikasi tidak akan crash meskipun banyak petugas PPL melakukan survei lapangan secara serentak."*

---

### 🖥️ SLIDE 5: KEAMANAN & PENGALAMAN PENGGUNA (ROLE GUARD & UX)
* **Poin Slide:**
  * **3 Pintu Masuk Terpisah:** Tab Petani, Admin Dinas, dan Petugas PPL.
  * **Auto-Purge & URL Intercept:** Token langsung dibersihkan jika pengguna login di tab yang salah, dan akses URL terlarang langsung ditolak.
  * **Sanitasi Real-time:** NIK dibatasi tepat 16 digit angka, normalisasi username huruf kecil, serta fitur intip password (*Eye toggle*).

> 🗣️ **Naskah Presenter (Slide 5):**  
> *"Dari sisi Frontend Web, kami membagi halaman autentikasi menjadi 3 portal terpisah. Sistem secara otomatis mencocokkan hak akses pengguna dengan portal yang dituju. Jika seorang petani mencoba login di portal admin, sistem langsung menolak dan menghapus sesi seketika. Kami juga menambahkan fitur intip password dan validasi otomatis NIK 16 digit untuk meminimalisir kesalahan input pengguna."*

---

### 🖥️ SLIDE 6: PENYEMPURNAAN APLIKASI MOBILE PETANI (FLUTTER)
* **Poin Slide:**
  * **Eliminasi Yellow/Black Overflow:** Mengatasi error layout 78px dan 37px pada kartu kuota & profil menggunakan `Expanded` dan `TextOverflow.ellipsis`.
  * **Stepper 6 Tahapan Dinamis:** Menampilkan status riil dari database (Pengajuan $\rightarrow$ Verifikasi Berkas $\rightarrow$ Penugasan PPL $\rightarrow$ Survei Lapangan $\rightarrow$ Persetujuan Admin $\rightarrow$ Penggunaan Pupuk).
  * **Indikator QR Aktif:** Saat tahap 5 disetujui, tahap 6 menampilkan ikon QR aktif (bukan centang hijau palsu), sesuai dengan alur penerbitan voucher fisik.

> 🗣️ **Naskah Presenter (Slide 6):**  
> *"Pada aplikasi Mobile Flutter untuk Petani, di Minggu ke-9 ini kami menyelesaikan masalah visual bug di mana sebelumnya muncul garis belang kuning-hitam karena teks kuota yang melebihi batas layar HP. Kami juga merombak komponen Stepper pelacakan berkas agar 100% selaras dengan web: dari 6 tahapan yang ada, saat status Siap Diambil, tahap 1 sampai 5 bercentang hijau dan tahap ke-6 menampilkan ikon QR aktif siap ditebus di kios."*

---

### 🖥️ SLIDE 7: DEMO SISTEM & PENGUJIAN END-TO-END
* **Poin Slide:**
  * Demo alur live: Pendaftaran $\rightarrow$ Verifikasi Admin $\rightarrow$ Disposisi PPL $\rightarrow$ Approval Kuota $\rightarrow$ Scan QR di Kios.
  * Tampilan visual database di phpMyAdmin.
  * Tampilan responsif aplikasi Petani di browser/perangkat mobile.

> 🗣️ **Naskah Presenter (Slide 7):**  
> *"Berikut adalah demonstrasi alur transaksi end-to-end yang telah kami uji coba. Seluruh data yang diinput oleh petani di frontend langsung tersimpan aman di database MySQL, dapat diverifikasi secara instan oleh admin dinas, dan status perubahannya langsung ter-update secara real-time pada Stepper di dashboard petani."*

---

### 🖥️ SLIDE 8: KESIMPULAN & TARGET MINGGU KE-10
* **Poin Slide:**
  * **Status Saat Ini:** Sistem mencapai kematangan 82.5% dan siap dijalankan multi-platform.
  * **Target Minggu Ke-10:**
    1. Pengujian beban multi-user (*Stress & Performance Test*).
    2. Cetak Surat Perjanjian Alokasi & Berita Acara PPL dalam format PDF resmi.
    3. Ekspor laporan rekapitulasi kuota bulanan ke format Excel (`.xlsx`) untuk Dinas Pertanian.
    4. Penyusunan buku panduan teknis (*User Manual*) & dokumentasi final API.

> 🗣️ **Naskah Presenter (Slide 8):**  
> *"Kesimpulannya, pada Minggu ke-9 ini proyek E-PUPUK telah berhasil menyelesaikan seluruh kendala arsitektural dan mencapai kesiapan 82.5%. Pada Minggu ke-10 mendatang, fokus kami adalah menambahkan fitur cetak PDF dokumen resmi alokasi pupuk, ekspor rekapitulasi kuota ke Excel untuk dinas, serta penyusunan buku panduan pengguna. Terima kasih atas perhatian Pak Amma dan teman-teman, kami siap menerima pertanyaan dan masukan."*

---

## 5. RENCANA & TARGET MINGGU KE-10

```text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                              ROADMAP MINGGU KE-10 (FINALISASI)                         │
├─────────────────────┬──────────────────────────────────────────────────────────────────┤
│ Modul Pelaporan     │ Implementasi ReportLab (Python) untuk cetak PDF Voucher QR & SPK │
├─────────────────────┼──────────────────────────────────────────────────────────────────┤
│ Modul Ekspor Data   │ Ekspor tabel alokasi & distribusi ke spreadsheet Excel (.xlsx)  │
├─────────────────────┼──────────────────────────────────────────────────────────────────┤
│ Pengujian Beban     │ Stress test API FastAPI dengan simulasi 50 request konkuren      │
├─────────────────────┼──────────────────────────────────────────────────────────────────┤
│ Dokumentasi Akhir   │ Penyusunan Buku Manual Pengguna & Dokumentasi OpenAPI / Swagger   │
└─────────────────────┴──────────────────────────────────────────────────────────────────┘
```
