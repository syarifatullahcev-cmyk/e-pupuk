---
marp: true
theme: default
paginate: true
backgroundColor: "#0f172a"
color: "#f1f5f9"
style: |
  section {
    font-family: 'Segoe UI', sans-serif;
  }
  h1, h2, h3 { color: #4ade80; }
  table { width: 100%; border-collapse: collapse; }
  th, td { border: 1px solid #334155; padding: 8px; text-align: left; }
  th { background-color: #1e293b; color: #38bdf8; }
  strong { color: #fbbf24; }
---

<!-- SLIDE 1 -->
<!-- _class: lead -->
# E-PUPUK
### Laporan Progres Minggu ke-4
**Tim Pengembang & Dinas Pertanian Kab. Mojokerto**
16 September 2026

---

<!-- SLIDE 2 -->
## Timeline Keseluruhan (16 Minggu)

Pengembangan dibagi ke dalam 4 fase utama. Saat ini kita berada di awal **Fase 2**.

| Fase | Minggu | Status |
|---|:---:|---|
| Fase 1 — Perancangan & Konsep | 1–3 | ✅ Selesai |
| **Fase 2 — Core Setup & Fitur Dasar** | **4–7** | 🔄 **Berjalan 📍 (Posisi Sekarang)** |
| Fase 3 — Fitur Survei & Geofencing | 8–11 | ⬜ Belum |
| Fase 4 — Integrasi, Testing & Finalisasi | 12–16 | ⬜ Belum |

---

<!-- SLIDE 3 -->
## Ringkasan Capaian Minggu Ini

*   **Fase 1 Tuntas:** Konsep, ERD, dan alur persetujuan akhir telah disetujui (termasuk pemisahan Role Admin Pemda dan PPL).
*   **Database Setup:** 13 Tabel utama telah dibuat (SQLite untuk dev), beserta seed data demo.
*   **Backend (FastAPI):** 30+ endpoint REST API untuk Core Features (Auth, CRUD Pengajuan, Admin, PPL) sudah berjalan.
*   **Frontend (React+Vite):** Setup project selesai, 5 halaman utama (Dashboard Admin, PPL, Petani, Login, Kiosk) dan 7 komponen UI reusable telah dibuat.

---

<!-- SLIDE 4 -->
## Arsitektur Sistem (Konteks)

Diagram di bawah menunjukkan komponen yang sedang dikerjakan. Kotak dengan tanda [✅] sudah memiliki implementasi dasar, tanda [🔄] sedang dikerjakan.

```text
+-------------------------------------------------------+
|                    PENGGUNA AKHIR                     |
|  [✅] Petani   [✅] Admin Pemda   [🔄] PPL   [✅] Pim |
+------------------------+------------------------------+
                         |
                         v
+-------------------------------------------------------+
|          FRONTEND — React 19 + Vite 8                 |
| [✅] /petani | [✅] /admin | [✅] /ppl | [✅] /kiosk  |
+------------------------+------------------------------+
                         |
                         v
+-------------------------------------------------------+
|          BACKEND — FastAPI + Python                   |
| [✅] JWT Auth | [✅] Role Guard | [🔄] Geofencing     |
+------------------------+------------------------------+
                         |
                         v
+-------------------------------------------------------+
|   DATABASE — SQLite (Dev) --> MySQL (Production)      |
|  [✅] 13 Tabel (users, applications, qr_scans, dll)   |
+-------------------------------------------------------+
```

---

<!-- SLIDE 5 -->
## Fase 1: Perancangan & Konsep (Selesai)

Pekerjaan fundamental yang telah diselesaikan pada 3 minggu pertama:

**Frontend & Desain:**
*   Mockup Wireframe UI.
*   Alur sistem & UX Flow.
*   Pemisahan role **Admin Pemda** (monitoring/penugasan) dan **PPL** (operasional lapangan).
*   Perancangan mekanisme validasi **Scan Barcode** di lahan.

**Backend & Database:**
*   Studi literatur & arsitektur sistem.
*   Perancangan ERD Final (13 Tabel).
*   Pembuatan `schema.sql`.
*   Pembuatan skrip data *seeder* untuk pengujian awal.

---

<!-- SLIDE 6 -->
## Fase 2 Backend: Auth, RBAC & Core API

*   **Auth & Otorisasi:** Implementasi JWT Token, endpoint `/api/auth/login`, `/api/auth/me`.
*   **Role-Based Access Control (RBAC):** Middleware `require_role` untuk membatasi akses (Petani, PPL, Admin, Pimpinan).
*   **Manajemen Data Master:** CRUD untuk Petani, Kelompok Tani, Lahan, Komoditas, dan Pupuk.
*   **Dokumentasi API:** Tersedia otomatis via Swagger UI (`/docs`).

> *Status: Semua endpoint dasar sudah merespon dengan benar dan terhubung ke Database.*

---

<!-- SLIDE 7 -->
## Fase 2 Backend: Pengajuan & Distribusi

*   **Pengajuan Subsidi:** Pembuatan pengajuan baru oleh petani, upload snapshot foto KTP & lahan.
*   **Admin Workflow:** Endpoint untuk verifikasi berkas, penugasan PPL, dan *final approval*.
*   **PPL Workflow:** Endpoint untuk mulai survei dan submit laporan (kondisi lahan, tanaman, foto).
*   **Distribusi:** Endpoint `scan-qr` untuk memvalidasi token dari kios.
*   **Audit Trail:** Semua perubahan status dicatat di tabel `audit_logs`.

---

<!-- SLIDE 8 -->
## Fase 2 Frontend: Fondasi & Halaman Selesai

*   **Client Layer:** Axios setup dengan interceptor untuk JWT handling dan auto-redirect.
*   **State Management:** Zustand terintegrasi untuk menyimpan sesi `user` dan `token`.
*   **Halaman Selesai:**
    *   `Login.jsx`: Autentikasi dan redirect berdasarkan role.
    *   `PetaniDashboard.jsx`: Menampilkan stepper pengajuan dan QRCode penyaluran.
    *   `AdminDashboard.jsx`: Menampilkan 4 tab (Verifikasi, PPL, Approve, Audit).
    *   `QRScannerKiosk.jsx`: Kiosk untuk klaim pupuk.

---

<!-- SLIDE 9 -->
## Fase 2 Frontend: In Progress & Kendala

### Sedang Dikerjakan:
*   **PPL Dashboard (`PPLDashboard.jsx`):** Form input survei sudah ada, namun integrasi **Map Citra Satelit** masih dalam tahap riset (OpenStreetMap vs Mapbox).
*   **Validasi Scan Petani:** Alur petani scan barcode karung pupuk **di lahan** masih dikembangkan (membutuhkan API *Geolocation* dari browser HTML5).

---

<!-- SLIDE 10 -->
## Kendala & Keputusan Terbuka

Berikut adalah isu dan pertanyaan yang perlu diputuskan bersama Dosen Pembimbing:

1.  **Mekanisme Barcode:** Mengklarifikasi bahwa barcode karung bersifat statis; data koordinat (GPS) dan waktu didapat dari aplikasi HP petani saat *scan* dilakukan.
2.  **Toleransi Radius Geofencing:** Jarak maksimal yang dianggap *valid* saat petani melakukan scan di lahan (Saran: 50-100 meter).
3.  **Ketersediaan Peta Satelit:** Mapbox/Esri berbayar, opsi gratis (OSM) tidak memiliki citra satelit yang memadai untuk verifikasi PPL. Perlu keputusan terkait penggunaan API.
4.  **Kuota Pupuk:** Saat ini perhitungan kuota dan RDKK masih *hardcoded*, perlu dirumuskan formula matematis dari Luas Lahan × Standar Kebutuhan.

---

<!-- SLIDE 11 -->
## Rencana Minggu Depan

**Target Konkret (Minggu ke-5):**

*   **Frontend:**
    *   Mengintegrasikan komponen `navigator.geolocation` pada fitur Scan Petani untuk mendapatkan GPS akurat (Fix Bug Geolocation Hardcoded).
    *   Menyambungkan form Survei PPL secara penuh dengan API Backend.
*   **Backend:**
    *   Implementasi formula *Haversine* untuk *Geofencing* (membandingkan koordinat scan dengan koordinat lahan PPL).
    *   Membuat perhitungan dinamis Kuota Pupuk (RDKK).
    *   Menyimpan konfigurasi sensitif (Secret Key JWT, DB config) menggunakan variabel *environment* (`.env`).