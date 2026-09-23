# 📋 PROGRESS REPORT — Sistem E-Pupuk Kabupaten Mojokerto
### Laporan Kemajuan Pengembangan Perangkat Lunak | Minggu ke-4

---

## 📌 DAFTAR ISI
1. [Capaian Utama Minggu 4](#1-capaian-utama-minggu-4)
2. [Progress Backend](#2-progress-backend)
3. [Sedang Dikerjakan (Work in Progress)](#3-sedang-dikerjakan-work-in-progress)
4. [Fitur Prioritas (Mendatang)](#4-fitur-prioritas-mendatang)
5. [Bug Kritis & Keamanan](#5-bug-kritis--keamanan)
6. [Kesimpulan Progres](#6-kesimpulan-progres)

---

## 1. Capaian Utama Minggu 4
Pada minggu ke-4 ini, tim berhasil mencapai fondasi dasar aplikasi dengan wujud visual dan operasional database awal:
- ✅ **4 Halaman Frontend Berjalan:** Antarmuka untuk Halaman Login, Dasbor Admin, Dasbor PPL, dan Dasbor Petani telah selesai dirancang dan berjalan.
- ✅ **3 Tabel Database Aktif:** Basis data mulai beroperasi dengan mengaktifkan tabel `users`, `applications` (pengajuan), dan `audit_logs`.
- ✅ **JWT Aktif:** Implementasi *JSON Web Token* untuk melindungi akses halaman dan memvalidasi sesi login berhasil diterapkan.
- ✅ **Audit Log Aktif:** Sistem pencatatan riwayat aktivitas pengguna sudah berjalan secara fungsional.

---

## 2. Progress Backend
Sisi *logic* aplikasi (API) telah memiliki kerangka kerja yang operasional. Progress pada backend meliputi:
- **REST API Sudah Berjalan:** Struktur dasar routing FastAPI sudah aktif dan siap merespons *request* dari Frontend.
- **Sistem Autentikasi:** Endpoint login terproteksi yang memisahkan akses untuk Petani, Admin, dan PPL.
- **Sistem Audit Log:** Otomatisasi pencatatan rekam jejak untuk memantau siapa yang mengakses apa (transparansi sistem).
- **Verifikasi & Approval:** Penyiapan *logic* dasar untuk alur persetujuan berkas pengajuan oleh Admin.

---

## 3. Sedang Dikerjakan *(Work in Progress)*
Saat ini, fokus pengembangan sedang dialihkan ke fitur-fitur teknis yang berinteraksi langsung dengan kondisi lapangan:
- 🚧 **Fitur Kamera Validasi di Sawah (Barcode Pembukaan):** Mengembangkan UI dan koneksi kamera browser untuk pemindaian *barcode* dari karung pupuk langsung di lahan.
- 🚧 **Peta Citra Satelit untuk PPL:** Mengganti peta dasar (*OpenStreetMap*) dengan layer citra satelit (seperti *Mapbox/Esri*) agar PPL bisa mengukur luas dan melihat wujud lahan sebenarnya.
- 🚧 **Akurasi GPS:** Mengkalibrasi penggunaan *Geolocation API* dari peramban/HP agar presisi saat melakukan pemindaian (Scan QR).
- 🚧 **Riwayat Pembukaan Pupuk:** Membuat tabel dan UI untuk menampilkan histori kapan dan di mana pupuk dibuka oleh petani.

---

## 4. Fitur Prioritas (Mendatang)
Berdasarkan diskusi sistem, berikut adalah 3 pilar fitur yang akan menjadi prioritas penyelesaian dalam minggu-minggu berikutnya:
1. **Map Citra Satelit:** Sangat penting agar validasi lahan dari PPL tidak bisa dimanipulasi.
2. **Scan Barcode di Lahan:** Esensi dari inovasi E-Pupuk ini (mencegah penyelewengan pupuk).
3. **History Pembukaan Pupuk:** Sebagai bentuk laporan akhir dan transparansi penggunaan.

---

## 5. Bug Kritis & Keamanan
Selama pengembangan minggu ke-4, ditemukan beberapa isu kritis dan masalah keamanan yang harus segera ditambal (*patch*) sebelum masuk ke tahap *testing* lanjutan:
- 🔴 **GPS Pemindai Statis:** Koordinat GPS di fitur pemindai QR saat ini masih menggunakan angka "palsu/statis" (hardcoded), belum mengambil GPS asli dari perangkat *smartphone*.
- 🔴 **Geofencing Belum Diterapkan:** Validasi jarak toleransi antara lahan dengan lokasi scan barcode belum berfungsi.
- 🔴 **Kuota Pupuk Masih Hardcoded:** Jumlah jatah pupuk belum dinamis mengambil perhitungan dari database (luas lahan × standar komoditas).
- 🔴 **Keamanan JWT:** *Secret Key* (kunci enkripsi) untuk JWT masih tertanam langsung di dalam source code, yang mana sangat rentan jika tidak segera dipindahkan ke *Environment Variable* (.env).

---

## 6. Kesimpulan Progres

Laporan Minggu 4 ini menunjukkan bahwa **fondasi (Capaian) sudah berdiri kuat**, namun aplikasi masih menghadapi **tantangan teknis (Bug Kritis)** pada fitur-fitur kompleksnya (GPS & Peta). 

Persentase keseluruhan sistem saat ini:
| Aspek Sistem | Progres | Keterangan |
|---|:---:|---|
| **Frontend UI** | **75%** | 4 Halaman Dashboard Utama selesai. |
| **Keamanan** | **25%** | Terhenti karena isu *Secret Key JWT* (Bug Kritis). |
| **Database** | **20%** | Baru 3 tabel yang beroperasi penuh. |
| **Backend API** | **20%** | REST API jalan + Logika dasar Verifikasi. |
| **Log/History** | **15%** | Fitur Audit Log aktif di backend. |
| **Integrasi** | **15%** | Baru sebatas Auth Login yang saling terhubung. |
