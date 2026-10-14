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
- Relasi tabel database `users` dan `farmers`
- Integrasi halaman registrasi riil di frontend (`Register.jsx`)
- Fitur unggah foto KTP fisik pada profil petani
- **4 Perbaikan Detail Teknis (Polishing UX & Keandalan Backend)**

### MINGGU 7
- Penyempurnaan fitur lanjutan dan persiapan kontainerisasi Docker

---

<!-- SLIDE 3 -->
## PROGRESS MINGGUAN : BACKEND

### Progress Utama:

**1. API Register Petani Baru (`POST /api/auth/register`)**
- Validasi ketat format **NIK wajib 16 digit angka** dan password minimal **6 karakter**
- Pengecekan anti-duplikasi: Username dan NIK tidak boleh ganda

**2. Keamanan & Hashing Password**
- Enkripsi kata sandi menggunakan **Bcrypt** (`get_password_hash`)

**3. Struktur Database User & Petani**
- Relasi 1:1 antara akun login (`users`) dan profil kependudukan (`farmers`)
- Otomatis membuat record notifikasi sambutan selamat datang

**4. Endpoint Update Foto KTP (`PUT /api/farmers/{id}`)**
- Mendukung penyimpanan path foto KTP fisik (`foto_ktp_url`) ke database

---

<!-- SLIDE 4 -->
## PROGRESS MINGGUAN : FRONTEND

### Progress Utama:

**1. Halaman Registrasi Terintegrasi (`Register.jsx`)**
- Mengubah form registrasi dari mockup (`setTimeout`) menjadi koneksi API riil
- Validasi kesamaan kata sandi dan pembatasan NIK 16 digit

**2. Handling Respon & Feedback Pengguna**
- Menampilkan pesan error dinamis langsung dari backend via toast notification
- Redirect otomatis ke portal login petani pasca pendaftaran sukses

**3. Fitur Unggah Foto KTP di Profil (`PetaniDashboard.jsx`)**
- Komponen interaktif `FileUploadZone` pada tab **Profil Petani**
- Petani dapat mengunggah dan memperbarui foto KTP asli kapan saja dengan modal pratinjau

---

<!-- SLIDE 5 -->
## 4 PERBAIKAN DETAIL SISTEM (POLISHING NYATA)

Berikut 4 perbaikan teknis yang telah diterapkan langsung ke codebase:

**1. [Frontend] Password Visibility Toggle (Show / Hide Password)**
- Menambahkan tombol interaktif `Eye` & `EyeOff` pada form **Login** dan **Register** untuk mencegah salah ketik kata sandi petani.

**2. [Frontend] Sanitasi Real-time Input NIK & Nomor HP**
- Filter otomatis `e.target.value.replace(/\D/g, '')` pada `Register.jsx`, memastikan hanya angka yang dapat diketik pada kolom NIK (max 16 digit) dan No. HP.

**3. [Backend] Case-Insensitive & Trimmed Username Resolution**
- Pembersihan spasi liar (`.strip()`) dan pencarian username *case-insensitive* (`func.lower`) pada login dan registrasi untuk mencegah gagal login akibat autocorrect smartphone.

**4. [Backend] Deep Health Check & Live Database Ping (`/api/health`)**
- Endpoint `/api/health` kini mengeksekusi query aktif `SELECT 1` ke database engine untuk memantau status konektivitas live (`connected` / `degraded`).

---

<!-- SLIDE 6 -->
## KENDALA BACKEND & SOLUSI

### Kendala:
- Data login (`users`) dan identitas fisik (`farmers`) terpisah sehingga rawan inkonsistensi data jika salah satu gagal.
- Keyboard smartphone sering otomatis mengkapitalkan huruf awal username sehingga gagal login.
- Healthcheck endpoint bawaan belum memverifikasi ketersediaan koneksi database riil.

### Solusi & Keputusan:
- Menggunakan transaksi bertingkat (`db.flush()`) untuk memastikan integritas user dan profil petani.
- Menerapkan fungsi normalisasi `func.lower()` pada pencarian username di `auth.py`.
- Mengintegrasikan blok `try-except` eksekusi `engine.connect()` pada endpoint `/api/health`.

---

<!-- SLIDE 7 -->
## KENDALA FRONTEND & SOLUSI

### Kendala:
- Form registrasi rawan menerima karakter huruf atau spasi tidak sengaja pada kolom NIK 16 digit.
- Pengguna tidak dapat melihat kembali kata sandi yang diketikkan sebelum menekan tombol submit.
- Berkas KTP sebelumnya belum memiliki fasilitas unggah mandiri pasca registrasi.

### Solusi & Keputusan:
- Menambahkan regex filter otomatis pada handler `handleChange` di `Register.jsx`.
- Mengimplementasikan state toggle visibility kata sandi menggunakan icon `Eye` / `EyeOff` dari Lucide React.
- Mengintegrasikan zona unggah interaktif `FileUploadZone` yang terhubung ke endpoint `/api/files/upload`.

---

<!-- SLIDE 8 -->
## RENCANA PROGRESS MINGGU KE-7

### FRONTEND
- Mengintegrasikan alur pengajuan kuota pupuk subsidi bagi akun petani terdaftar
- Menyempurnakan form pendaftaran data lahan (luas m² dan titik koordinat GPS Leaflet)

### BACKEND
- Menghubungkan akun petani dengan validasi batas kuota pupuk subsidi
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

<!-- SLIDE 9 -->
<!-- _class: lead -->
# TERIMA KASIH
### ATAS KESEMPATANNYA

**E-PUPUK**  
**Sistem Pengajuan Subsidi Pupuk Kabupaten Mojokerto**

**Syarifatullah Ceva Efendy & Selby Wafi Nurjuan**  
D3 Teknik Informatika PSDKU Lamongan  
Politeknik Elektronika Negeri Surabaya  
2026
