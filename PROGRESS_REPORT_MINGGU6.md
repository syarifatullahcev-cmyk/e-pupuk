# LAPORAN KEMAJUAN (PROGRESS REPORT) MINGGU KE-6
## Workshop Pemrograman Framework
### Fokus Utama: Modul User Registration, Backend API, & Database Petani
**Sistem Pengajuan Subsidi Pupuk Kabupaten Mojokerto (E-PUPUK)**

---

## 1. Identitas Proyek & Pengembang

* **Mata Kuliah:** Workshop Pemrograman Framework
* **Judul Proyek:** E-PUPUK (Sistem Pengajuan Subsidi Pupuk Kabupaten Mojokerto)
* **Dosen Pengampu:** Amma Liesvarastranta Haz, S.Tr.T., M.T.
* **Institusi:** Program Studi D3 Teknik Informatika PSDKU Lamongan, Politeknik Elektronika Negeri Surabaya (PENS)
* **Tahun Akademik:** 2026

### Tim Pengembang:
1. **Syarifatullah Ceva Efendy** (NRP: 312521002) — *Frontend Developer*
2. **Selby Wafi Nurjuan** (NRP: 3125521018) — *Backend Developer*

---

## 2. Fokus & Urgensi Minggu Ke-6

Pada **Minggu ke-6**, pengerjaan proyek difokuskan secara mendalam pada **fondasi data pengguna**:
1. **Implementasi Sistem Registrasi Petani Nyata (*Real User Registration*)**
2. **Pengembangan API Backend Autentikasi (`POST /api/auth/register`)**
3. **Struktur Relasi Database Pengguna & Petani (`users` & `farmers` pada SQLite `epupuk.db`)**
4. **Validasi Kependudukan (NIK 16 Digit) dan Keamanan Password (Bcrypt)**
5. **Fitur Pengunggahan dan Pembaruan Berkas Foto KTP Fisik di Profil Petani**

> **Dasar Pemikiran:** Sebelum seorang petani dapat mengajukan subsidi pupuk dan disurvei oleh PPL di lapangan, sistem wajib memiliki mekanisme pendaftaran akun yang tervalidasi, aman, dan menyimpan data identitas kependudukan secara permanen ke dalam database.

---

## 3. Arsitektur Database: Relasi `users` dan `farmers`

Sistem memisahkan kredensial login dengan profil fisik kependudukan petani menggunakan relasi **One-to-One (1:1)**:

```text
  ┌────────────────────────────────────────────────────────┐
  │                      TABEL: users                      │
  ├───────────────────┬────────────────────────────────────┤
  │ id (PK)           │ INTEGER PRIMARY KEY AUTOINCREMENT  │
  │ username          │ VARCHAR(100) NOT NULL UNIQUE       │
  │ email             │ VARCHAR(150) NOT NULL UNIQUE       │
  │ password_hash     │ VARCHAR(255) NOT NULL (Bcrypt)     │
  │ role              │ ENUM ('PETANI', 'PPL', 'ADMIN')    │
  │ is_active         │ BOOLEAN DEFAULT TRUE               │
  │ created_at        │ TIMESTAMP DEFAULT CURRENT_TIME     │
  └───────────────────┴─────────────────┬──────────────────┘
                                        │ 1 : 1 Relation
                                        ▼
  ┌────────────────────────────────────────────────────────┐
  │                     TABEL: farmers                     │
  ├───────────────────┬────────────────────────────────────┤
  │ id (PK)           │ INTEGER PRIMARY KEY AUTOINCREMENT  │
  │ user_id (FK)      │ INTEGER NOT NULL UNIQUE            │
  │ nama              │ VARCHAR(150) NOT NULL (KTP)        │
  │ nik               │ VARCHAR(20) NOT NULL UNIQUE INDEX  │
  │ kontak            │ VARCHAR(20) NULL (No. WhatsApp)    │
  │ alamat            │ TEXT NOT NULL DEFAULT 'Mojokerto'  │
  │ foto_ktp_url      │ VARCHAR(500) NULL (Path Foto KTP)  │
  │ tanggal_registrasi│ DATE DEFAULT CURRENT_DATE          │
  │ farmer_group_id   │ INTEGER NULL (FK farmer_groups)    │
  └───────────────────┴────────────────────────────────────┘
```

### Keuntungan Desain Database Ini:
* **Keamanan:** Password pengguna tidak disimpan dalam bentuk teks biasa, melainkan di-hash dengan algoritma salt Bcrypt pada tabel `users`.
* **Integritas Data:** Kolom `nik` diberi constraint `UNIQUE` dan `INDEX` untuk memastikan tidak ada petani yang dapat mendaftar dua kali dengan NIK yang sama.
* **Fleksibilitas:** Role sistem terisolasi sehingga petani hanya memiliki hak akses (*authorization*) terhadap data lahan dan pengajuan miliknya sendiri.

---

## 4. Implementasi Backend API (`POST /api/auth/register`)

Endpoint pendaftaran petani dibangun menggunakan framework **FastAPI** di dalam file [backend/app/routers/auth.py](file:///d:/e/pupuk/e-pupuk/backend/app/routers/auth.py).

### A. Skema Pydantic (`RegisterRequest`):
```python
class RegisterRequest(BaseModel):
    username: str
    password: str
    nama: str
    nik: str
    kontak: Optional[str] = None
    email: Optional[EmailStr] = None
    alamat: Optional[str] = "Kabupaten Mojokerto"
    farmer_group_id: Optional[int] = None
```

### B. Tahapan Logika Pendaftaran pada Backend:
1. **Validasi NIK 16 Digit:**  
   Sistem memeriksa apakah NIK yang dimasukkan tepat berjumlah 16 digit dan seluruhnya berupa angka (`isdigit()`). Jika tidak, sistem melempar `HTTP 400 Bad Request`.
2. **Validasi Panjang Password:**  
   Sistem mewajibkan password minimal 6 karakter demi keamanan akun petani.
3. **Pengecekan Duplikasi Akun:**  
   - Memeriksa apakah `username` sudah digunakan di tabel `users`.
   - Memeriksa apakah `nik` sudah terdaftar di tabel `farmers`.
4. **Hashing Password dengan Bcrypt:**  
   Password mentah di-hash menggunakan fungsi `get_password_hash()`:
   ```python
   password_hash = get_password_hash(request.password)
   ```
5. **Penyimpanan Transaksional Ganda:**  
   - Membuat entri akun di tabel `users` dengan `role = UserRole.PETANI`.
   - Melakukan `db.flush()` untuk memperoleh `new_user.id`.
   - Membuat profil petani di tabel `farmers` yang merujuk pada `user_id` tersebut.
6. **Notifikasi Sambutan Otomatis:**  
   Sistem membuat record di tabel `notifications` untuk menyambut petani baru.
7. **Audit Log:**  
   Mencatat aktivitas `REGISTER` ke tabel `audit_logs` untuk transparansi sistem.

---

## 5. Implementasi Frontend: Form Registrasi Petani

Pada sisi antarmuka pengguna [frontend/src/pages/Register.jsx](file:///d:/e/pupuk/e-pupuk/frontend/src/pages/Register.jsx), form registrasi dihubungkan secara langsung ke API backend:

### A. Elemen Form yang Disediakan:
* **Nama Lengkap:** Input nama lengkap petani sesuai KTP.
* **NIK (Nomor Induk Kependudukan):** Input 16 digit angka dengan pembatasan `maxLength={16}`.
* **Nomor HP / WhatsApp:** Untuk kebutuhan verifikasi dan koordinasi petugas PPL.
* **Username:** Nama akun untuk login ke aplikasi.
* **Kata Sandi & Konfirmasi Sandi:** Validasi kesamaan password langsung di sisi klien sebelum data dikirim.

### B. Integrasi Service API:
Kode simulasi lama (`setTimeout`) diganti dengan pemanggilan nyata:
```javascript
const res = await authApi.register({
  nama: formData.namaLengkap.trim(),
  nik: formData.nik.trim(),
  kontak: formData.nomorHp.trim(),
  username: formData.username.trim(),
  password: formData.password,
});

toast.success('Pendaftaran akun petani berhasil! Silakan masuk.');
navigate('/login/petani');
```

---

## 6. Fitur Pengelolaan Berkas KTP pada Profil Petani

Setelah berhasil mendaftar dan masuk ke sistem, petani dapat melengkapi berkas fisik pada halaman **Profil** di [frontend/src/pages/PetaniDashboard.jsx](file:///d:/e/pupuk/e-pupuk/frontend/src/pages/PetaniDashboard.jsx):

1. **Deteksi Berkas Otomatis:**  
   Jika profil petani belum memiliki foto KTP (`foto_ktp_url === null`), halaman profil otomatis memunculkan komponen interaktif **`FileUploadZone`** (*"Unggah Foto KTP Asli"*).
2. **Pengunggahan File ke Server:**  
   File foto KTP (format JPG, PNG, WEBP dengan ukuran maksimal 5MB) dikirim ke endpoint `/api/files/upload`.
3. **Penyimpanan Permanen ke Database:**  
   URL foto yang dihasilkan server disimpan ke tabel `farmers` melalui API `PUT /api/farmers/{id}` dengan payload `{ foto_ktp_url: url }`.
4. **Pratinjau & Ubah Foto:**  
   - Foto KTP asli langsung tampil pada kartu profil.
   - Petani dapat mengklik foto untuk memperbesar gambar (modal lightbox).
   - Disediakan tombol **"Ubah Foto"** jika petani ingin memperbarui foto KTP di kemudian hari.

---

## 7. Hasil Pengujian Modul User & Petani (Test Matrix)

Pengujian komprehensif dilakukan untuk memastikan modul registrasi dan profil berjalan tanpa celah:

| Skenario Pengujian | Input Data | Respon Sistem / HTTP Status | Hasil |
| :--- | :--- | :--- | :---: |
| **Registrasi Normal** | NIK: 16 digit valid, Username unik, Password $\ge$ 6 | Akun dibuat di `users` & `farmers` (201 Created) | ✅ **PASS** |
| **NIK Kurang dari 16 Digit** | NIK: `12345` (5 digit) | Pesan: *"NIK wajib berisi 16 digit angka"* (400) | ✅ **PASS** |
| **Password Kurang dari 6 Karakter** | Password: `123` | Pesan: *"Kata sandi minimal berisi 6 karakter"* (400) | ✅ **PASS** |
| **Duplikasi Username** | Username yang sudah ada di database | Pesan: *"Username sudah digunakan"* (400) | ✅ **PASS** |
| **Duplikasi NIK** | NIK yang sudah terdaftar sebelumnya | Pesan: *"NIK ini sudah terdaftar dalam sistem"* (400) | ✅ **PASS** |
| **Login Akun Baru** | Username & password yang baru didaftarkan | Token JWT berhasil diterbitkan (200 OK) | ✅ **PASS** |
| **Akses Profil Petani** | Token JWT petani baru | Menampilkan profil lengkap nama, NIK, alamat (200 OK) | ✅ **PASS** |
| **Unggah Foto KTP** | Upload file gambar KTP asli | URL foto tercatat permanen di database (200 OK) | ✅ **PASS** |
| **Kompilasi Frontend** | `npm run build` | Bundle client Vite sukses (1.64 detik, 0 error) | ✅ **PASS** |

---

## 8. Kendala Teknis & Solusi yang Diterapkan

1. **Kendala 1: Form Registrasi Masih Berupa Mockup**
   * *Masalah:* Tombol registrasi sebelumnya hanya menjalankan animasi timer tanpa menyimpan data apapun ke database.
   * *Solusi:* Membangun endpoint `POST /api/auth/register` lengkap dengan hashing Bcrypt dan integrasi langsung ke frontend.
2. **Kendala 2: Petani Baru Belum Bisa Mengunggah KTP di Profil**
   * *Masalah:* Karena saat pendaftaran tidak diwajibkan upload KTP langsung, halaman profil petani tidak memiliki fasilitas untuk mengunggah foto KTP setelah login.
   * *Solusi:* Menambahkan atribut `foto_ktp_url` pada skema `FarmerUpdate` dan mengintegrasikan komponen `FileUploadZone` interaktif di menu profil petani.
3. **Kendala 3: Sinkronisasi Master Data Petani ke Dashboard Admin**
   * *Masalah:* Petani baru yang belum mengajukan subsidi pupuk sempat tidak terlihat di tabel admin karena admin hanya membaca petani yang sudah memiliki nomor pengajuan.
   * *Solusi:* Menghubungkan dashboard admin langsung ke endpoint master `farmersApi.getAll()`, sehingga setiap petani baru yang mendaftar langsung tampil di admin.

---

## 9. Rencana Kerja Minggu Ke-7

Setelah modul registrasi dan database user petani selesai sempurna, langkah pengembangan berikutnya adalah:
1. **Pemanfaatan Akun Petani untuk Pengajuan Kuota Pupuk:**  
   Petani terdaftar dapat memilih jenis pupuk bersubsidi (Urea / NPK) dan mengajukan permohonan alokasi.
2. **Pendaftaran Lahan Pertanian Milik Petani:**  
   Menghubungkan akun petani dengan data lahan dan titik koordinat GPS sawah sebagai dasar survei lapangan PPL.
3. **Persiapan Docker:**  
   Membuat `Dockerfile` dan `docker-compose.yml` agar aplikasi frontend, backend, dan database dapat dijalankan secara instan di laptop siapa pun.

---

Mojokerto, September 2026  
**Tim Pengembang E-PUPUK**  
*(Syarifatullah Ceva Efendy & Selby Wafi Nurjuan)*
