# UI/UX Design
# E-Pupuk Kabupaten Mojokerto

## 1. Design Principles
- **Jelas dan sederhana** — istilah yang dipakai familiar bagi petani dan PPL, hindari jargon teknis.
- **Transparan** — status pengajuan/distribusi selalu terlihat (progress step, bukan tersembunyi).
- **Mobile-first untuk peran lapangan** — Petani dan PPL banyak mengakses dari HP, terutama saat scan QR.
- **Data-dense namun rapi untuk Admin/Pimpinan** — dashboard boleh padat informasi tapi tetap terstruktur (KPI di atas, detail di bawah).

## 2. Design System

### 2.1 Typography
Font sans-serif (mis. Inter/Poppins). Hierarki: H1 untuk judul halaman, H2 untuk judul seksi/card, body untuk teks umum, caption untuk metadata (tanggal, status kecil).

### 2.2 Color Palette
- Primary (hijau — identik pertanian) untuk aksi utama dan status positif/valid.
- Warning (kuning/oranye) untuk status mendekati batas/overlimit/warning QR.
- Danger (merah) untuk status ditolak/expired/blocked.
- Neutral (abu-abu) untuk teks sekunder dan border.

### 2.3 Spacing
Skala spacing konsisten (mis. kelipatan 4px: 4/8/12/16/24/32) untuk padding card, gap antar elemen, dan margin section.

### 2.4 Border Radius
Radius sedang (mis. 8–12px) untuk card, button, dan input agar terasa modern tapi tidak terlalu playful.

### 2.5 Iconography
Ikon outline konsisten (mis. set Lucide/Heroicons) untuk navigasi, status, dan aksi (scan, approve, reject, alert).

## 3. Global Components
- **Navbar** — logo, nama sistem, profil/notifikasi.
- **Sidebar** — menu navigasi sesuai peran (berbeda untuk Petani/PPL/Admin/Pimpinan).
- **Button** — primary, secondary, outline, danger.
- **Card** — kontainer untuk ringkasan info (kuota, KPI, item pengajuan).
- **Badge** — status (Diajukan, Diverifikasi, Disetujui, Tersalurkan, Ditolak, Expired, dsb).
- **Input** — text, number, select, date, dengan validasi inline.
- **Table** — daftar data dengan filter, search, pagination.
- **Modal** — konfirmasi aksi (approve/reject, hapus data).
- **Alert** — notifikasi status (sukses, warning, error) di dalam halaman.
- **Notification** — pemberitahuan realtime (pengajuan baru, hasil verifikasi, alert penimbunan).

## 4. Navigation Structure
```
Petani   : Dashboard → Lahan Saya → Pengajuan → Scan QR → Riwayat
PPL      : Dashboard → Daftar Pengajuan → Verifikasi → Scan QR
Admin    : Dashboard → Data Master → Pengajuan → Distribusi → Monitoring QR → Laporan
Pimpinan : Dashboard → Peta Distribusi → Grafik/KPI → Laporan
```

## 5. Dashboard User (Petani)

### 5.1–5.9 Layout & Isi
Header profil dan notifikasi, ringkasan luas lahan, kuota pupuk per jenis, form pengajuan, tombol scan QR untuk penerimaan, status pengajuan bertahap (progress steps), dan riwayat distribusi.

```
┌───────────────────────────────────────────┐
│ E-PUPUK              Profil / Notifikasi  │
├───────────────────────────────────────────┤
│ Selamat Datang, Petani                    │
│ Luas Lahan: 5.000 m²                      │
├───────────────────────────────────────────┤
│ KUOTA PUPUK                                │
│ Urea : 125 kg                              │
│ NPK  : 75 kg                               │
├───────────────────────────────────────────┤
│ PENGAJUAN                                  │
│ Komoditas : Padi                           │
│ Pupuk     : Urea                           │
│ Jumlah    : 100 kg                         │
│ [Ajukan]                                   │
├───────────────────────────────────────────┤
│ PENERIMAAN                                 │
│ [ SCAN QR PUPUK ]                          │
│ Batch : BCH-2026-001                       │
│ Expired: 2027                              │
│ Status : AMAN                              │
├───────────────────────────────────────────┤
│ STATUS PENGAJUAN                           │
│ ✓ Diajukan                                 │
│ ✓ Diverifikasi                             │
│ ○ Disetujui                                │
│ ○ Tersalurkan                              │
└───────────────────────────────────────────┘
```
> Catatan: angka kuota (125 kg/75 kg) pada mockup ini contoh ilustratif, bukan angka final (lihat catatan di `01-product-requirements.md` §10).

## 6. Dashboard PPL

### 6.1–6.5
Ringkasan jumlah pengajuan menunggu verifikasi, daftar pengajuan (filter wilayah/status), detail pengajuan (data petani + lahan + kuota), aksi approve/reject dengan catatan wajib untuk reject, serta akses scan QR bila PPL turut mengonfirmasi distribusi di lapangan.

## 7. Dashboard Admin

### 7.1–7.7
KPI ringkas (jumlah RDKK, realisasi, jumlah scan QR, jumlah alert), peta distribusi, panel info tambahan (cuaca, status QR, alert), tabel data pengajuan dengan aksi, monitoring QR (valid/warning/expired/duplicate/flagged/blocked), dan modul laporan (ekspor periodik).

```
┌─────────────────────────────────────────────────────┐
│ ADMIN E-PUPUK             Search | Filter | Profile │
├─────────────────────────────────────────────────────┤
│ KPI                                                  │
│ RDKK │ REALISASI │ QR SCAN │ ALERT                   │
├───────────────────────────────┬─────────────────────┤
│                                │ API / INFORMASI     │
│      PETA DISTRIBUSI           │ Cuaca               │
│                                │ QR Status           │
│                                │ Alert               │
├───────────────────────────────┴─────────────────────┤
│ DATA PENGAJUAN                                       │
│ Petani | Lahan | Pengajuan | Kuota | Status | Aksi  │
└─────────────────────────────────────────────────────┘
```

## 8. Dashboard Pimpinan

### 8.1–8.5
KPI strategis (realisasi vs target, jumlah petani terlayani), grafik tren pengajuan/distribusi per periode, peta sebaran distribusi kabupaten, panel data cuaca (konteks musim tanam), dan ringkasan analisis/insight otomatis.

## 9. User Flow
Login → (sesuai peran) landing dashboard → aksi utama peran tersebut → konfirmasi/hasil → notifikasi. Untuk Petani: alur linear pengajuan → verifikasi → distribusi → scan QR yang selalu terlihat sebagai progress steps agar petani tahu posisi pengajuannya.

## 10. Responsive Design

| Breakpoint | Perilaku |
|---|---|
| Desktop | Sidebar tetap terbuka, tabel penuh, peta/grafik berdampingan |
| Tablet | Sidebar collapsible, tabel scroll horizontal |
| Mobile | Sidebar jadi bottom nav/hamburger, card bertumpuk vertikal, scan QR full-screen |

## 11. Mockup Specification & Prompt Google Stitch
Untuk membuat mockup visual awal (Google Stitch atau tools sejenis), gunakan prompt berikut per layar — sesuaikan warna/gaya sesuai palet di §2.2.

**Prompt — Dashboard Petani:**
"Desain UI mobile-first untuk dashboard aplikasi web pertanian bernama 'E-Pupuk'. Tema hijau agrikultur, bersih, rounded corner. Tampilkan: header dengan sapaan nama petani dan ikon notifikasi; card ringkasan luas lahan; card kuota pupuk (Urea, NPK) dengan angka besar; form pengajuan pupuk sederhana (dropdown komoditas, dropdown jenis pupuk, input jumlah, tombol Ajukan berwarna hijau penuh); tombol besar 'Scan QR Pupuk' dengan ikon kamera; progress stepper horizontal berisi 4 tahap (Diajukan, Diverifikasi, Disetujui, Tersalurkan) dengan status tercentang."

**Prompt — Dashboard PPL:**
"Desain UI web/tablet untuk dashboard verifikasi penyuluh pertanian. Tema hijau agrikultur. Tampilkan: daftar pengajuan dalam bentuk card/list dengan nama petani, komoditas, jumlah pupuk diajukan, dan badge status; panel detail pengajuan di sisi kanan berisi data lahan dan kuota maksimal; dua tombol aksi besar 'Setujui' (hijau) dan 'Tolak' (merah) dengan field catatan wajib untuk penolakan."

**Prompt — Dashboard Admin:**
"Desain UI web dashboard admin untuk sistem distribusi pupuk subsidi. Layout: baris atas berisi 4 kartu KPI (Total RDKK, Realisasi, Total Scan QR, Jumlah Alert); di bawahnya layout dua kolom — kolom kiri lebih lebar berisi peta distribusi (marker titik distribusi), kolom kanan berisi panel informasi cuaca dan daftar alert terbaru; di bagian bawah tabel data pengajuan dengan kolom Petani, Lahan, Pengajuan, Kuota, Status, Aksi, lengkap dengan search bar dan filter status di atas tabel."

**Prompt — Dashboard Pimpinan:**
"Desain UI web dashboard eksekutif untuk pimpinan dinas pertanian. Gaya profesional, banyak white space, data visualization-forward. Tampilkan: kartu KPI besar di atas (realisasi vs target dalam persen); grafik garis/batang tren distribusi pupuk per bulan; peta sebaran distribusi kabupaten dalam ukuran besar; panel kecil data cuaca terkini; ringkasan analisis/insight dalam bentuk poin singkat di bagian bawah."
