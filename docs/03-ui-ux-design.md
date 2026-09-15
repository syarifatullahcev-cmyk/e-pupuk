# UI/UX Design
# E-Pupuk Kabupaten Mojokerto

## 1. Design Principles
- **Jelas dan sederhana** — istilah yang dipakai familiar bagi petani dan PPL, hindari jargon teknis.
- **Transparan** — status pengajuan/distribusi selalu terlihat (progress step 6-tahap, bukan tersembunyi).
- **Mobile-first untuk peran lapangan** — Petani dan PPL banyak mengakses dari HP, terutama saat upload foto, isi form survei, dan scan QR.
- **Data-dense namun rapi untuk Admin/Pimpinan** — dashboard boleh padat informasi tapi tetap terstruktur (KPI di atas, detail di bawah).
- **Kepercayaan dan keamanan visual** — Area yang menampilkan foto KTP dan data NIK diberi indikator visual "data sensitif" yang jelas serta pesan hak akses yang ditampilkan.

## 2. Design System

### 2.1 Typography
Font sans-serif (mis. Inter/Poppins). Hierarki: H1 untuk judul halaman, H2 untuk judul seksi/card, body untuk teks umum, caption untuk metadata (tanggal, status kecil, koordinat).

### 2.2 Color Palette
- Primary (hijau — identik pertanian) untuk aksi utama dan status positif/valid.
- Warning (kuning/oranye) untuk status mendekati batas/overlimit/warning QR/PERLU_PERBAIKAN_BERKAS.
- Danger (merah) untuk status ditolak/expired/blocked.
- Info (biru) untuk status informasional (penugasan PPL diterima, survei sedang berjalan).
- Neutral (abu-abu) untuk teks sekunder dan border.

### 2.3 Spacing
Skala spacing konsisten (mis. kelipatan 4px: 4/8/12/16/24/32) untuk padding card, gap antar elemen, dan margin section.

### 2.4 Border Radius
Radius sedang (mis. 8–12px) untuk card, button, dan input agar terasa modern tapi tidak terlalu playful.

### 2.5 Iconography
Ikon outline konsisten (mis. set Lucide/Heroicons) untuk navigasi, status, dan aksi (scan, approve, reject, alert, upload, map-pin, camera, clipboard-check).

## 3. Global Components
- **Navbar** — logo, nama sistem, profil/notifikasi.
- **Sidebar** — menu navigasi sesuai peran (berbeda untuk Petani/PPL/Admin/Pimpinan).
- **Button** — primary, secondary, outline, danger.
- **Card** — kontainer untuk ringkasan info (kuota, KPI, item pengajuan, detail survei).
- **Badge** — status (Diajukan, Verifikasi Berkas, Perlu Perbaikan, Ditugaskan PPL, Survei Lapangan, Disetujui, Tersalurkan, Ditolak, Expired, dsb).
- **Input** — text, number, select, date, file upload (dengan preview foto), dengan validasi inline.
- **File Upload Zone** — drag-and-drop area dengan preview foto, info ukuran maks., dan indikator upload progress.
- **Map Picker** — komponen Leaflet untuk memilih/menampilkan titik koordinat lokasi lahan.
- **Photo Viewer** — tampilan foto fullscreen/lightbox dengan watermark "DOKUMEN RAHASIA" untuk foto KTP.
- **Table** — daftar data dengan filter, search, pagination.
- **Modal** — konfirmasi aksi (approve/reject, hapus data, form penugasan PPL).
- **Alert** — notifikasi status (sukses, warning, error) di dalam halaman.
- **Notification** — pemberitahuan realtime (pengajuan baru, hasil verifikasi, penugasan survei, alert penimbunan).
- **Progress Stepper** — 6-tahap (Diajukan → Verifikasi Berkas → Ditugaskan PPL → Survei Lapangan → Disetujui → Tersalurkan).

## 4. Navigation Structure
```
Petani   : Dashboard → Lahan & Profil → Pengajuan Subsidi → Scan QR → Riwayat
PPL      : Dashboard → Tugas Survei Lapangan → Riwayat Survei → Scan QR
Admin    : Dashboard → Verifikasi Berkas → Penugasan PPL → Data Master → Distribusi → Monitoring QR → Laporan
Pimpinan : Dashboard → Peta Distribusi → Grafik/KPI → Laporan
```

## 5. Dashboard User (Petani)

### 5.1 Layout & Isi
Header profil petani (nama, foto profil, ikon notifikasi), card data profil lengkap (foto KTP tersamar, alamat), card data lahan (foto lahan, luas, alamat lahan, pin koordinat), card kuota pupuk per jenis, form pengajuan subsidi pupuk (dengan upload KTP, foto lahan, alamat, koordinat, tanggal), progress stepper 6-tahap, dan riwayat distribusi.

```
┌───────────────────────────────────────────────┐
│ E-PUPUK              🔔 Notifikasi │ Profil   │
├───────────────────────────────────────────────┤
│ Selamat Datang, Bapak/Ibu [Nama Petani]       │
├───────────────────────────────────────────────┤
│ 📋 PROFIL PETANI                               │
│ [Foto KTP — tersamar sebagian]                 │
│ NIK   : 35XX-XXXX-XXXX-XXXX                   │
│ Alamat: Ds. Sumbertanggul, Kec. Mojosari       │
├───────────────────────────────────────────────┤
│ 🌾 DATA LAHAN                                  │
│ [Foto Lahan Terkini]                           │
│ Luas     : 5.000 m² (0,5 ha)                  │
│ Komoditas: Padi                                │
│ Alamat   : Blok Sawah Lor, Ds. Sumbertanggul  │
│ Koordinat: 📍 -7.4819°, 112.5342°             │
│ [Lihat di Peta]                                │
├───────────────────────────────────────────────┤
│ 🌱 KUOTA PUPUK                                 │
│ Urea : 125 kg                                  │
│ NPK  : 75 kg                                   │
├───────────────────────────────────────────────┤
│ 📝 FORM PENGAJUAN SUBSIDI PUPUK                │
│ Komoditas   : [dropdown]                       │
│ Jenis Pupuk : [dropdown]                       │
│ Jumlah      : [input kg]                       │
│ ─────────────────────────────────────────────  │
│ 📄 Upload KTP Petani *                         │
│ [Zona Upload / Preview KTP]                    │
│ 📷 Upload Foto Kondisi Lahan *                 │
│ [Zona Upload / Preview Foto Lahan]             │
│ 📍 Alamat Lahan (isian lengkap) *             │
│ [textarea alamat]                              │
│ 🗺️ Titik Lokasi Lahan *                       │
│ [Map Picker — klik untuk pin lokasi]           │
│ 📅 Tanggal Pengajuan: [auto-filled, read-only] │
│ [AJUKAN SUBSIDI]                               │
├───────────────────────────────────────────────┤
│ 📦 PENERIMAAN PUPUK                            │
│ [ SCAN QR PUPUK ]                              │
│ Batch : BCH-2026-001 │ Expired: 2027           │
│ Status: AMAN                                   │
├───────────────────────────────────────────────┤
│ 📊 STATUS PENGAJUAN #PJN-2026-0042             │
│ ✅ 1. Diajukan          (12 Sep 2026)          │
│ ✅ 2. Verifikasi Berkas  (13 Sep 2026)         │
│ ✅ 3. Ditugaskan ke PPL  (13 Sep 2026)         │
│ ⏳ 4. Survei Lapangan   (dalam proses)         │
│ ○  5. Disetujui                                │
│ ○  6. Tersalurkan                              │
└───────────────────────────────────────────────┘
```
> Catatan: angka kuota (125 kg/75 kg) pada mockup ini contoh ilustratif, bukan angka final (lihat catatan di `01-product-requirements.md` §10).

### 5.2 Status PERLU_PERBAIKAN_BERKAS
Jika Admin menandai pengajuan perlu perbaikan berkas, halaman pengajuan menampilkan:
```
┌───────────────────────────────────────────────┐
│ ⚠️ BERKAS PERLU DIPERBAIKI                    │
│ Catatan Admin: Foto KTP kurang jelas, mohon   │
│ unggah ulang foto KTP yang lebih terang.      │
│ [Unggah Ulang Berkas] [Lihat Catatan Lengkap] │
└───────────────────────────────────────────────┘
```

## 6. Dashboard PPL

### 6.1 Layout & Isi
Ringkasan statistik tugas (total tugas, menunggu survei, selesai), daftar tugas survei lapangan yang ditugaskan Admin (nama petani, desa, komoditas, batas waktu survei, status), detail tugas survei (data lengkap petani + foto KTP referensi + foto lahan referensi + alamat + navigasi GPS ke lokasi lahan), form laporan survei lapangan, dan riwayat survei yang sudah diselesaikan.

```
┌─────────────────────────────────────────────────────┐
│ PPL E-PUPUK                        🔔 │ Profil      │
├─────────────────────────────────────────────────────┤
│ 📋 RINGKASAN TUGAS SURVEI                           │
│ Menunggu: 3  │  Sedang Berjalan: 1  │  Selesai: 12 │
├─────────────────────────────────────────────────────┤
│ 🗂️ DAFTAR TUGAS SURVEI LAPANGAN                    │
│ [Petani A – Ds. Pacet – Padi – Batas: 16 Sep] [▶]  │
│ [Petani B – Ds. Gondang – Jagung – Batas: 17 Sep] [▶] │
│ [Petani C – Ds. Trawas – Padi – Batas: 18 Sep] [▶] │
├─────────────────────────────────────────────────────┤
│ 📌 DETAIL TUGAS: Petani A                           │
│ Nama    : Bapak Slamet Riyadi                       │
│ NIK     : 35XX-XXXX (tersamar)                     │
│ Alamat  : Ds. Pacet, Kec. Pacet                     │
│ Pupuk   : Urea 100 kg │ Komoditas: Padi             │
│ ─────────────────────────────────────────────────   │
│ 📄 Foto KTP Referensi: [Lihat KTP]                  │
│ 📷 Foto Lahan (dari pengajuan): [Lihat Foto]        │
│ 📍 Koordinat: -7.4819°, 112.5342°                   │
│ [🗺️ Buka Navigasi GPS]                              │
│ ─────────────────────────────────────────────────   │
│ 📝 LAPORAN SURVEI LAPANGAN                          │
│ Kondisi Fisik Lahan    : [dropdown/textarea]        │
│ Kondisi Bahan/Tanaman  : [dropdown/textarea]        │
│ Luas Lahan Aktual (m²) : [input]                    │
│ 📷 Upload Foto Bukti Lahan (min. 2 foto) *          │
│ [Zona Upload Foto Survei]                           │
│ Catatan Evaluasi       : [textarea]                 │
│ Rekomendasi            : ● Setujui  ○ Tolak         │
│ [SUBMIT LAPORAN SURVEI]                             │
└─────────────────────────────────────────────────────┘
```

## 7. Dashboard Admin

### 7.1 Layout & Isi
KPI ringkas (jumlah RDKK, realisasi, pengajuan masuk, menunggu verifikasi berkas, menunggu survei PPL, jumlah scan QR, jumlah alert), peta distribusi, panel info tambahan (cuaca, status QR, alert), **tab Verifikasi Berkas** (perbandingan data pengajuan vs berkas), **tab Penugasan PPL** (form disposisi ke PPL), monitoring QR, dan modul laporan.

```
┌──────────────────────────────────────────────────────────┐
│ ADMIN E-PUPUK                    Search | Filter | 🔔 Profile │
├──────────────────────────────────────────────────────────┤
│ KPI                                                       │
│ RDKK  │ REALISASI │ PENGAJUAN MASUK │ VERIFIKASI BERKAS  │
│       │           │                 │ (MENUNGGU)          │
│ PENUGASAN PPL │ QR SCAN │ ALERT                          │
│ (MENUNGGU)    │         │                                │
├────────────────────────────────┬─────────────────────────┤
│                                │ API / INFORMASI          │
│      PETA DISTRIBUSI           │ Cuaca                    │
│                                │ QR Status                │
│                                │ Alert Penimbunan         │
├────────────────────────────────┴─────────────────────────┤
│ [Tab: Verifikasi Berkas] [Tab: Penugasan PPL] [Tab: Distribusi] │
├──────────────────────────────────────────────────────────┤
│ TAB: VERIFIKASI BERKAS PENGAJUAN                         │
│ ────────────────────────────────────────────────────     │
│ Petani: Slamet Riyadi │ Pengajuan: PJN-2026-0042         │
│ ┌───────────────────┬──────────────────────────────┐    │
│ │ Foto KTP          │ Data Berkas                  │    │
│ │ [Preview KTP]     │ Nama   : Slamet Riyadi       │    │
│ │                   │ NIK    : 3514XXXXXXXX        │    │
│ │                   │ Alamat : Ds. Pacet, Mojokerto│    │
│ ├───────────────────┼──────────────────────────────┤    │
│ │ Foto Lahan        │ Alamat Lahan: Blok Sawah Lor │    │
│ │ [Preview Lahan]   │ Koordinat: 📍 lihat peta     │    │
│ │                   │ Luas    : 5.000 m²           │    │
│ │                   │ Komoditas: Padi              │    │
│ └───────────────────┴──────────────────────────────┘    │
│ Catatan Verifikasi: [textarea]                           │
│ [✅ Berkas Valid] [⚠️ Perlu Perbaikan] [❌ Tolak Berkas] │
├──────────────────────────────────────────────────────────┤
│ TAB: PENUGASAN PPL                                        │
│ ────────────────────────────────────────────────────     │
│ Pengajuan: PJN-2026-0042 │ Wilayah: Kec. Pacet           │
│ PPL Terkait Wilayah (otomatis): Bp. Tri Wahyudi           │
│ [dropdown ganti PPL jika perlu]                          │
│ Batas Waktu Survei: [date picker]                        │
│ Instruksi Khusus  : [textarea]                           │
│ [TUGASKAN PPL]                                           │
└──────────────────────────────────────────────────────────┘
```

### 7.2 Modal Persetujuan Akhir (setelah laporan survei PPL diterima)
```
┌───────────────────────────────────────────────┐
│ ✅ PERSETUJUAN AKHIR DISTRIBUSI               │
│ Pengajuan  : PJN-2026-0042                    │
│ Petani     : Slamet Riyadi                    │
│ Rekomendasi PPL: Setuju (Laporan: ...)        │
│ [Lihat Foto Survei PPL]                       │
│ ─────────────────────────────────────────     │
│ Volume Disetujui (kg): [input, default=kuota] │
│ Catatan Persetujuan   : [textarea opsional]   │
│ [✅ SETUJUI & JADWALKAN DISTRIBUSI]           │
│ [❌ TOLAK (dengan catatan wajib)]             │
└───────────────────────────────────────────────┘
```

## 8. Dashboard Pimpinan

### 8.1–8.5
KPI strategis (realisasi vs target, jumlah petani terlayani, persentase verifikasi berkas selesai, jumlah survei PPL selesai), grafik tren pengajuan/distribusi per periode, peta sebaran distribusi kabupaten, panel data cuaca (konteks musim tanam), dan ringkasan analisis/insight otomatis.

## 9. User Flow
Login → (sesuai peran) landing dashboard → aksi utama peran tersebut → konfirmasi/hasil → notifikasi. Untuk Petani: alur linear pengajuan (beserta upload berkas wajib) → verifikasi berkas Admin → penugasan PPL → survei lapangan → persetujuan → distribusi → scan QR yang selalu terlihat sebagai progress 6-tahap agar petani tahu posisi pengajuannya.

## 10. Responsive Design

| Breakpoint | Perilaku |
|---|---|
| Desktop | Sidebar tetap terbuka, tabel penuh, peta/grafik berdampingan, panel verifikasi berkas dua-kolom |
| Tablet | Sidebar collapsible, tabel scroll horizontal, panel verifikasi berkas satu kolom bertumpuk |
| Mobile | Sidebar jadi bottom nav/hamburger, card bertumpuk vertikal, form upload foto full-screen, scan QR full-screen, map picker full-screen |

## 11. Mockup Specification & Prompt Google Stitch
Untuk membuat mockup visual awal (Google Stitch atau tools sejenis), gunakan prompt berikut per layar — sesuaikan warna/gaya sesuai palet di §2.2.

**Prompt — Dashboard Petani:**
"Desain UI mobile-first untuk dashboard aplikasi web pertanian bernama 'E-Pupuk'. Tema hijau agrikultur, bersih, rounded corner. Tampilkan: header dengan sapaan nama petani dan ikon notifikasi; card profil petani berisi foto KTP tersamar sebagian dan alamat domisili; card data lahan berisi foto lahan, luas lahan, alamat lahan, dan koordinat GPS dengan tombol 'Lihat di Peta'; card kuota pupuk (Urea, NPK) dengan angka besar; form pengajuan pupuk (dropdown komoditas, dropdown jenis pupuk, input jumlah); zona upload foto KTP dan foto kondisi lahan (dengan drag-and-drop dan preview); input alamat lahan (textarea) dan map picker interaktif untuk pin lokasi lahan; tombol 'Ajukan Subsidi' berwarna hijau penuh; tombol besar 'Scan QR Pupuk'; progress stepper horizontal 6 tahap (Diajukan, Verifikasi Berkas, Ditugaskan PPL, Survei Lapangan, Disetujui, Tersalurkan) dengan status tercentang."

**Prompt — Dashboard PPL:**
"Desain UI web/tablet/mobile untuk dashboard PPL penyuluh pertanian lapangan. Tema hijau agrikultur. Tampilkan: kartu ringkasan tugas (menunggu, sedang berjalan, selesai); daftar tugas survei lapangan dalam bentuk card dengan nama petani, desa/kelurahan, komoditas, batas waktu, dan badge status; panel detail tugas yang mencakup: data petani (nama, NIK tersamar), foto KTP referensi (tersamar), foto lahan dari pengajuan, alamat dan koordinat GPS dengan tombol navigasi; form laporan survei lapangan berisi: dropdown kondisi fisik lahan, dropdown kondisi bahan/tanaman, input luas aktual, zona upload foto bukti lapangan (minimal 2 foto), textarea catatan evaluasi, radio pilihan rekomendasi (Setujui/Tolak), dan tombol submit laporan."

**Prompt — Dashboard Admin:**
"Desain UI web dashboard admin untuk sistem distribusi pupuk subsidi. Layout: baris atas berisi 7 kartu KPI (Total RDKK, Realisasi, Pengajuan Masuk, Menunggu Verifikasi Berkas, Menunggu Penugasan PPL, Total Scan QR, Jumlah Alert); di bawahnya layout dua kolom — kiri peta distribusi, kanan panel informasi cuaca dan alert; di bawahnya sistem tab dengan tiga tab: 'Verifikasi Berkas' (tampilan dua panel: kiri preview foto KTP dan foto lahan, kanan data petani dan lahan dengan tombol aksi Berkas Valid/Perlu Perbaikan/Tolak), 'Penugasan PPL' (form disposisi tugas survei ke PPL wilayah), dan 'Distribusi' (tabel data pengajuan yang sudah disetujui)."

**Prompt — Dashboard Pimpinan:**
"Desain UI web dashboard eksekutif untuk pimpinan dinas pertanian. Gaya profesional, banyak white space, data visualization-forward. Tampilkan: kartu KPI besar di atas (realisasi vs target dalam persen, jumlah petani terlayani, persentase survei PPL selesai); grafik garis/batang tren distribusi pupuk per bulan; peta sebaran distribusi kabupaten dalam ukuran besar; panel kecil data cuaca terkini; ringkasan analisis/insight dalam bentuk poin singkat di bagian bawah."
