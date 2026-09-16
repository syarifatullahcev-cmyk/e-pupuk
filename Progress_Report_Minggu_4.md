# Laporan Kemajuan (Progress Report) & Analisis E-Pupuk - Minggu Ke-4

## 1. Latar Belakang & Penjelasan Konsep
**E-Pupuk** adalah sistem informasi berbasis web dan mobile (kiosk/scanner) yang dirancang untuk mengelola, memonitor, dan memvalidasi distribusi pupuk bersubsidi, khususnya di Kabupaten Mojokerto. Tujuan utamanya adalah memastikan bahwa pupuk bersubsidi tepat sasaran, menghindari penyalahgunaan, dan memberikan transparansi penuh mulai dari pengajuan oleh petani hingga pupuk tersebut benar-benar digunakan di lahan yang terdaftar.

### Alur Sistem (Berdasarkan Konsep Terbaru):
1. **Pengajuan Bantuan:** Petani menginputkan data diri, data lahan, dan kebutuhan pupuk melalui sistem.
2. **Verifikasi Awal & Penugasan:** Admin Pemerintah Daerah (Pemda) memproses data yang masuk. Jika dokumen lengkap, Admin menyetujui tahap awal dan memberikan **penugasan survei** kepada PPL (Penyuluh Pertanian Lapangan) / Surveyor.
3. **Survei Lapangan (PPL):** PPL datang langsung ke lokasi lahan petani. PPL mengecek luas lahan aktual, kondisi ekonomi petani, kondisi tanaman, dan memetakan koordinat lahan menggunakan fitur **map citra satelit**.
4. **Finalisasi (Pemda):** PPL menyerahkan hasil survei dan rekomendasi ke sistem. Admin Pemda mereview hasil survei tersebut untuk finalisasi (Persetujuan Akhir).
5. **Distribusi:** Setelah disetujui, bantuan pupuk diproses dan siap didistribusikan kepada petani.
6. **Validasi Penggunaan (Scan Barcode):** Petani menerima pupuk. Saat pupuk akan dibuka/digunakan di lahannya, petani diwajibkan untuk memindai (scan) barcode yang ada di karung pupuk menggunakan perangkat/HP mereka. Sistem akan mencocokkan titik koordinat saat scan dilakukan dengan koordinat lahan hasil survei PPL.

---

## 2. Analisis Perubahan Konsep & Sanggahan (Sangat Penting)

Berdasarkan masukan dari Dosen Pembimbing, terdapat beberapa penyesuaian yang sangat baik untuk meningkatkan validitas data. Namun, ada satu hal teknis yang perlu **diluruskan (Sanggahan)** terkait mekanisme Barcode:

### ⚠️ Sanggahan Terkait Barcode di Karung Pupuk
**Pernyataan Konsep:** *"Barcode tersebut memuat informasi berupa koordinat, dan waktu petani membuka karung pupuk tersebut..."*

**Analisis Teknis & Sanggahan:**
Barcode atau QR Code yang tercetak di karung pupuk adalah benda **statis** (dicetak di pabrik atau saat pengemasan). Barcode statis **tidak mungkin** bisa menyimpan informasi dinamis seperti "Kapan karung dibuka" atau "Di mana koordinatnya" di dalam gambar barcode itu sendiri.

**Solusi Sistem yang Benar:**
1. **Isi Barcode:** Barcode di karung HANYA berisi **ID Unik Karung / Batch ID** (Misal: `PUPUK-MJK-2026-09-XYZ`).
2. **Proses Validasi:** 
   - Petani membuka aplikasi E-Pupuk di HP mereka.
   - Petani menekan tombol **"Validasi Buka Karung"** dan kamera akan memindai barcode tersebut.
   - **Aplikasi (HP Petani) lah yang bertugas mengambil data GPS (Koordinat) saat itu juga dan mencatat Waktu (Timestamp).**
   - Aplikasi mengirimkan `[ID Karung, Koordinat HP, Waktu Scan]` ke server (Backend).
   - Server membandingkan `Koordinat HP` dengan `Koordinat Lahan` dari hasil survei PPL. Jika jaraknya dekat (misal toleransi radius 50 meter), maka status validasi dinyatakan **SAH**.

### Penambahan Fitur Sesuai Permintaan Baru
- **Role Separation:** Memisahkan UI dan Wewenang secara tegas antara `Admin Pemda` (bersifat read-only untuk map, tapi memiliki hak akses persetujuan & penugasan) dan `Admin Surveyor / PPL` (bersifat operasional lapangan, input koordinat, foto, dan map citra satelit).
- **Log Activity / History:** Penambahan antarmuka (UI) **Log Aktivitas** dan **History Validasi Pupuk** di setiap dashboard masing-masing aktor agar transparan.

---

## 3. Progress Report (Hingga Minggu Ke-4)

Saat ini pengembangan berada pada minggu ke-4, setelah 3 minggu fokus pada perancangan konsep, ERD, dan persetujuan dosen.

### A. Progress Database (Schema & Model)
- ✅ **Struktur Database (MySQL/MariaDB)** telah dibuat melalui `schema.sql`.
- ✅ **Tabel Aktor:** `users`, `farmers`, `farmer_groups`.
- ✅ **Tabel Master:** `commodities`, `fertilizers`.
- ✅ **Tabel Transaksional Alur Kerja:** `lands`, `applications`, `field_surveys`, `fertilizer_batches`, `distributions`, `qr_scans`.
- ✅ **Tabel Logging:** `audit_logs` (telah disiapkan untuk mencatat semua aktivitas), `notifications`.
- *Status:* **Tuntas (90%)** - Perlu sedikit penyesuaian untuk penambahan field Radius Toleransi pada validasi koordinat di tahap selanjutnya.

### B. Progress Backend (Python FastAPI)
- ✅ **Setup Proyek:** Lingkungan virtual (`.venv`), dependensi (`requirements.txt`), koneksi ke SQLite/MySQL.
- ✅ **Seed Data:** Skrip generator data dummy (`seed_users.py`, `seed_data.py`, `seed_demo.py`) sudah berjalan dengan baik untuk keperluan testing awal.
- 🔄 **REST API Endpoints:** (Sedang berjalan) Endpoint untuk autentikasi, manajemen pengajuan, dan log sedang dalam tahap pengkodingan dan integrasi dengan database.
- *Status:* **Berjalan (50%)** - Sedang mengimplementasikan logika pencocokan GPS (Geofencing) untuk validasi QR scan.

### C. Progress Frontend (React + Vite + TailwindCSS)
- ✅ **Setup Proyek:** Berjalan dengan Vite, TailwindCSS (v4), React Router, dan Zustand (State Management).
- ✅ **Halaman Utama (Pages):** 
  - `Login.jsx`
  - `AdminDashboard.jsx` (Role Pemda)
  - `PPLDashboard.jsx` (Role Surveyor)
  - `PetaniDashboard.jsx` (Role Petani)
  - `QRScannerKiosk.jsx`
- ✅ **Map Integrasi:** Penggunaan `react-leaflet` untuk menampilkan peta citra satelit (OpenStreetMap/Satelite layer).
- 🔄 **Fitur Baru (Log History):** Sedang disiapkan komponen untuk menampilkan tabel *Audit Log* dan *History Pembukaan Pupuk* di semua dashboard.
- *Status:* **Berjalan (60%)** - Perlu penghalusan UI/UX dan penyambungan data (Fetch/Axios) dari Backend.

---

## 4. Bug Report & Isu Saat Ini

1. **Bug/Isu Geolocation di Browser:** Terkadang fitur pengambilan koordinat HP (Geolocation API) di browser kurang akurat jika petani berada di daerah susah sinyal atau tidak menghidupkan fitur "High Accuracy" GPS di HP-nya. *Solusi: Perlu ditambahkan peringatan di UI untuk menghidupkan GPS akurasi tinggi sebelum scan.*
2. **UI Role Admin masih tergabung:** Perlu pemisahan rute (routes) yang lebih ketat di frontend antara Admin Pemda dan PPL, karena logic-nya mulai berbeda secara signifikan.
3. **Log History Kosong:** Tampilan "History Pembukaan Pupuk" belum menampilkan data riil karena endpoint log dari backend masih bersifat mock data.

---

## 5. Rencana Pengembangan (Timeline Minggu 1 - 16)

| Minggu Ke- | Fase | Deskripsi Pekerjaan | Status |
| :--- | :--- | :--- | :--- |
| **Minggu 1-2** | Konseptualisasi | Brainstorming, studi literatur, pembuatan alur sistem awal, penyusunan Proposal. | ✅ Selesai |
| **Minggu 3** | Finalisasi Desain | Review bersama dosen pembimbing. Revisi alur persetujuan, penambahan role Pemda vs PPL, dan mekanisme validasi Barcode. Pembuatan ERD final. | ✅ Selesai |
| **Minggu 4 (Saat ini)** | Setup & Core Dev | Inisialisasi frontend & backend. Pembuatan layout dasar (Admin, PPL, Petani). Setup Database & Seeders. Implementasi peta satelit dasar. | 🔄 Berjalan |
| **Minggu 5-6** | Backend API & Auth | Penyelesaian seluruh endpoint CRUD (Create, Read, Update, Delete) untuk Pengajuan, Survei, dan Distribusi. Sistem Login & JWT Role-based. | ⏳ Mendatang |
| **Minggu 7-8** | Integrasi Frontend (1) | Menyambungkan data API ke Dashboard Petani (Pengajuan) dan Dashboard Pemda (Verifikasi & Penugasan). | ⏳ Mendatang |
| **Minggu 9-10** | Fitur Survei Lapangan | Mengembangkan UI/UX khusus PPL: Input koordinat langsung di lokasi, unggah foto, dan laporan kondisi ekonomi/tanaman. | ⏳ Mendatang |
| **Minggu 11** | Fitur Validasi QR Code | Integrasi scanner kamera di frontend (HP). Logika Geofencing (menghitung jarak koordinat petani vs PPL) di backend. | ⏳ Mendatang |
| **Minggu 12** | Sistem Log & Notifikasi | Implementasi penuh `audit_logs` agar muncul di semua UI dashboard sesuai request. Sistem notifikasi real-time/polling. | ⏳ Mendatang |
| **Minggu 13-14** | Testing & Bug Fixing | Unit testing, User Acceptance Testing (UAT). Mencari bug pada sistem pemetaan koordinat dan alur kerja. | ⏳ Mendatang |
| **Minggu 15** | Polish UI/UX & Deployment | Mempercantik antarmuka. Deployment ke server production/staging (VPS/Cloud). | ⏳ Mendatang |
| **Minggu 16** | Finalisasi Laporan | Pembuatan laporan akhir Skripsi/Tugas Akhir, penyusunan manual book aplikasi. | ⏳ Mendatang |

---
*Laporan ini digenerate secara otomatis berdasarkan analisis kode dan requirement diskusi bersama dosen.*
