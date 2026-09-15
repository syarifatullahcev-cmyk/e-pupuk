# 🌾 E-Pupuk Mojokerto - Frontend

Antarmuka web klien untuk **Sistem Verifikasi & Distribusi Pupuk Bersubsidi Kabupaten Mojokerto**, dibangun menggunakan React 19, Vite, dan Tailwind CSS v4.

Untuk panduan lengkap arsitektur dan cara menjalankan sistem secara keseluruhan dari awal (backend, database, dan frontend), silakan merujuk ke [README Utama di Root Project](../README.md).

---

## 🚀 Menjalankan Frontend Secara Mandiri

### 1. Instalasi Dependensi
Pastikan Node.js (v18+) dan npm telah terpasang:
```bash
npm install
```

### 2. Menjalankan Server Development
```bash
npm run dev
```
Aplikasi dapat diakses pada browser di: `http://localhost:5173`

> **Catatan Konfigurasi Proxy:**
> Frontend Vite telah dikonfigurasi dengan reverse proxy otomatis (`vite.config.js`) yang meneruskan request `/api` dan `/files` ke backend FastAPI di `http://127.0.0.1:8000`. Pastikan server backend sudah berjalan.

### 3. Build untuk Produksi
```bash
npm run build
```

### 4. Linting
```bash
npm run lint
```

---

## 📦 Daftar Halaman Utama

- **Login (`/login`)**: Halaman autentikasi terpusat untuk semua peran (Admin, PPL, Petani, Pimpinan).
- **Dashboard Petani (`/petani`)**: Pengelolaan data lahan, form pengajuan kuota subsidi, kalkulator pupuk, upload berkas, dan kartu QR Code.
- **Dashboard Admin (`/admin`)**: Verifikasi dokumen administratif, penugasan PPL, persetujuan akhir, rekapitulasi KPI, dan log audit.
- **Dashboard PPL (`/ppl`)**: Daftar tugas survei lapangan, form laporan hasil cek fisik sawah, dan upload foto bukti lapangan.
- **Kiosk Scanner (`/kiosk-scanner`)**: Modul pemindai kamera QR Code realtime untuk verifikasi penebusan di kios resmi.
