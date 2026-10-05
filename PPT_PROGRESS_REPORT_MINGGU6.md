---
marp: true
theme: default
paginate: true
backgroundColor: "#0f172a"
color: "#f1f5f9"
style: |
  section {
    font-family: 'Segoe UI', sans-serif;
    background: linear-gradient(135deg, #0f172a 0%, #14532d 100%);
  }
  h1, h2, h3 { color: #86efac; }
  .lead { text-align: center; }
  table { width: 100%; border-collapse: collapse; }
  th, td { border: 1px solid #334155; padding: 8px; text-align: left; }
  th { background-color: #1e293b; color: #86efac; }
  strong { color: #fbbf24; }
  ul { line-height: 1.5; }
---

<!-- SLIDE 1 -->
<!-- _class: lead -->
# LAPORAN PROGRES
## WORKSHOP PEMROGRAMAN FRAMEWORK

### SISTEM PENGAJUAN SUBSIDI PUPUK
### KABUPATEN MOJOKERTO

# E-PUPUK
**Fokus: Modul User Register & Database Petani**

**Frontend**  
Syarifatullah Ceva Efendy  

**Backend**  
Selby Wafi Nurjuan  

PSDKU Lamongan D3 Teknik Informatika  
Politeknik Elektronika Negeri Surabaya  
2026

---

<!-- SLIDE 2 -->
## TIMELINE PENGEMBANGAN E-PUPUK

### MINGGU 1 - 3
- Analisis kebutuhan sistem dan perancangan database awal
- Desain UI/UX halaman utama dan alur pengguna

### MINGGU 4
- Setup arsitektur frontend (React Vite) & backend (FastAPI)
- Pembuatan tabel database awal dan struktur halaman

### MINGGU 5
- Eksplorasi alur pengajuan dan peran aktor sistem

### MINGGU 6 — CURRENT
- **Fokus Utama: Modul User Register & Database Petani**
- Implementasi API backend pendaftaran akun petani (`POST /api/auth/register`)
- Relasi tabel database `users` dan `farmers` pada SQLite
- Integrasi halaman registrasi riil di frontend (`Register.jsx`)
- Fitur unggah foto KTP fisik pada profil petani

### MINGGU 7
- Penyempurnaan fitur lanjutan dan persiapan kontainerisasi Docker

---

<!-- SLIDE 3 -->
## PROGRESS MINGGUAN : BACKEND

### Progress Utama:

**1. API Register Petani Baru (`POST /api/auth/register`)**
- Membuat endpoint khusus pendaftaran akun petani
- Validasi ketat format **NIK wajib 16 digit angka**
- Validasi panjang kata sandi minimal **6 karakter**
- Pengecekan anti-duplikasi: Username dan NIK tidak boleh ganda

**2. Keamanan & Hashing Password**
- Menerapkan enkripsi kata sandi menggunakan **Bcrypt** (`get_password_hash`)
- Password mentah tidak pernah tersimpan di database

**3. Struktur Database User & Petani**
- Menyimpan akun login ke tabel `users` (Role: `PETANI`)
- Menyimpan profil identitas ke tabel `farmers` (Relasi 1:1)
- Otomatis membuat notifikasi sambutan selamat datang di tabel `notifications`

**4. Endpoint Update Foto KTP (`PUT /api/farmers/{id}`)**
- Menambahkan dukungan atribut `foto_ktp_url` pada skema update petani agar berkas KTP fisik dapat tersimpan ke database

---

<!-- SLIDE 4 -->
## PROGRESS MINGGUAN : FRONTEND

### Progress Utama:

**1. Halaman Registrasi Terintegrasi (`Register.jsx`)**
- Mengubah form registrasi dari simulasi mockup (`setTimeout`) menjadi pemanggilan API riil
- Menghubungkan form input dengan service `authApi.register()`
- Validasi kesamaan kata sandi dan konfirmasi kata sandi di sisi klien
- Pembatasan input NIK maksimal 16 digit

**2. Handling Respon & Feedback Pengguna**
- Menampilkan pesan error dinamis langsung dari backend jika data tidak valid (misal: *"NIK ini sudah terdaftar"* atau *"Username sudah digunakan"*)
- Notifikasi toast sukses dan redirect otomatis ke halaman login petani

**3. Fitur Unggah Foto KTP di Profil (`PetaniDashboard.jsx`)**
- Menambahkan komponen interaktif `FileUploadZone` pada tab **Profil Petani**
- Petani baru yang belum memiliki foto KTP dapat langsung memilih file foto KTP asli
- File otomatis terunggah ke backend `/api/files/upload` dan tersimpan ke profil petani
- Menyediakan tombol **"Ubah Foto"** dan pratinjau foto KTP resolusi penuh

---

<!-- SLIDE 5 -->
## KENDALA BACKEND

### Kendala:
- Sebelumnya backend belum memiliki endpoint pendaftaran akun petani (`POST /register`), baru tersedia login saja.
- Data kredensial login (`users`) dan data identitas fisik petani (`farmers`) berada pada tabel terpisah sehingga rawan inkonsistensi jika proses insert gagal di tengah jalan.
- Perlu memastikan validasi NIK benar-benar 16 digit angka dan unik agar tidak ada petani yang terdaftar ganda.
- Skema update petani sebelumnya belum mendukung penyimpanan path foto KTP (`foto_ktp_url`).

### Keputusan:
- Membangun endpoint `POST /api/auth/register` dengan transaksi ganda (simpan ke `users` lalu flush ID ke `farmers`).
- Menerapkan validasi ketat NIK 16 digit angka dan hashing Bcrypt pada kata sandi sebelum disimpan ke database SQLite.
- Menambahkan atribut `foto_ktp_url: Optional[str] = None` pada skema `FarmerUpdate` di `schemas.py`.

---

<!-- SLIDE 6 -->
## KENDALA FRONTEND

### Kendala:
- Tombol "Buat Akun" pada halaman register sebelumnya hanya bersifat simulasi waktu (`setTimeout`) tanpa benar-benar mengirim data ke server.
- Belum ada integrasi service API auth register di file `services/api.js`.
- Petani yang baru mendaftar tidak memiliki fasilitas untuk mengunggah foto KTP di halaman profilnya, hanya menampilkan gambar statis placeholder.
- Validasi pesan error dari backend belum terhubung dengan baik ke tampilan toast frontend.

### Keputusan:
- Menghubungkan form `Register.jsx` langsung ke backend menggunakan `authApi.register()`.
- Menambahkan fungsi `register` pada objek `authApi` di `api.js`.
- Mengintegrasikan komponen `FileUploadZone` interaktif pada kartu profil petani di `PetaniDashboard.jsx`, sehingga petani dapat mengunggah dan mengubah foto KTP kapan saja.
- Menangkap pesan error spesifik dari backend (`err.response.data.detail`) dan menampilkannya langsung melalui notifikasi toast.

---

<!-- SLIDE 7 -->
## RENCANA PROGRESS MINGGU KE-7

### FRONTEND
- Mengintegrasikan alur pengajuan kuota pupuk subsidi bagi akun petani yang sudah terdaftar
- Menyempurnakan form pendaftaran data lahan milik petani (input luas m² dan titik koordinat GPS)
- Menyempurnakan responsive tampilan form dan dashboard petani

### BACKEND
- Menghubungkan akun petani terdaftar dengan kuota alokasi pupuk bersubsidi
- Optimalisasi endpoint manajemen lahan milik petani
- Mempersiapkan konfigurasi kontainerisasi Docker (`Dockerfile` dan `docker-compose.yml`)

### TARGET
```text
User Register & Database Petani (Selesai)
                   ↓
Pengajuan Subsidi & Pendaftaran Lahan
                   ↓
Testing Alur Petani End-to-End
                   ↓
Sistem E-PUPUK Siap Digunakan
```

---

<!-- SLIDE 8 -->
<!-- _class: lead -->
# TERIMA KASIH
### ATAS KESEMPATANNYA

**E-PUPUK**  
**Sistem Pengajuan Subsidi Pupuk Kabupaten Mojokerto**

**Syarifatullah Ceva Efendy & Selby Wafi Nurjuan**  
D3 Teknik Informatika PSDKU Lamongan  
Politeknik Elektronika Negeri Surabaya  
2026
