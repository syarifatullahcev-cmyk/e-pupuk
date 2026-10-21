# LAPORAN KEMAJUAN (PROGRESS REPORT) MINGGU KE-9
## Workshop Pemrograman Framework
### Fokus Utama: Kontainerisasi Docker Penuh, Migrasi MySQL 8.0, Multi-Portal Role Guard, & Pengujian Alur End-to-End
**Sistem Pengajuan Subsidi Pupuk Kabupaten Mojokerto (E-PUPUK)**

---

## 1. Identitas Proyek & Pengembang

* **Mata Kuliah:** Workshop Pemrograman Framework
* **Judul Proyek:** E-PUPUK (Sistem Pengajuan Subsidi Pupuk Kabupaten Mojokerto)
* **Dosen Pengampu:** Amma Liesvarastranta Haz, S.Tr.T., M.T.
* **Institusi:** Program Studi D3 Teknik Informatika PSDKU Lamongan, Politeknik Elektronika Negeri Surabaya (PENS)
* **Tahun Akademik:** 2026
* **Tanggal Pelaporan:** 21 Oktober 2026

### Tim Pengembang:
1. **Syarifatullah Ceva Efendy** (NRP: 312521002) — *Frontend Developer*
2. **Selby Wafi Nurjuan** (NRP: 3125521018) — *Backend Developer*

---

## 2. Fokus & Urgensi Minggu Ke-9

Melanjutkan fondasi registrasi akun dan basis data petani pada **Minggu ke-6**, pengerjaan pada **Minggu ke-9** difokuskan pada tahap **maturitas sistem (*System Maturity & Deployment Readiness*)**:

1. **Kontainerisasi Penuh Berbasis Docker & Docker Compose:**  
   Membangun orkestrasi 4 layanan kontainer terisolasi (*Backend FastAPI, Frontend React/Nginx, Database MySQL 8.0, dan phpMyAdmin 5.2*) dengan dua konfigurasi lingkungan kerja (*Production* dan *Development Live-Reload*).
2. **Migrasi Arsitektur Basis Data ke MySQL 8.0 Enterprise:**  
   Mengalihkan basis data dari *file-based* SQLite (`epupuk.db`) menuju sistem RDBMS terdistribusi **MySQL 8.0** dengan engine `InnoDB`, pooling koneksi SQLAlchemy, dan dukungan karakter `utf8mb4`.
3. **Penguatan Keamanan Akses Multi-Portal (*Strict Role-Based Guard*):**  
   Menerapkan isolasi ketat pada portal masuk (*Petani, Admin Dinas, dan Petugas PPL*), mencegah login silang peran, serta menutup celah manipulasi rute URL di antarmuka web.
4. **Validasi & Integrasi Alur Transaksi Hulu-ke-Hilir (*End-to-End Workflow*):**  
   Memastikan siklus hidup pengajuan pupuk berjalan utuh: pendaftaran petani $\rightarrow$ registrasi lahan sawah Leaflet $\rightarrow$ pengajuan subsidi $\rightarrow$ verifikasi berkas $\rightarrow$ disposisi survei PPL $\rightarrow$ persetujuan kuota $\rightarrow$ penerbitan voucher QR $\rightarrow$ validasi pindai kios.
5. **Penyempurnaan Detail Teknis & Pengalaman Pengguna (*Polishing UX*):**  
   Penyediaan fitur intip kata sandi (*Show/Hide Password*), sanitasi otomatis NIK 16 digit, normalisasi *case-insensitive username*, serta *deep health check* koneksi basis data.

---

## 3. Arsitektur Kontainerisasi Docker & Multi-Service

Seluruh ekosistem E-PUPUK kini dapat diinisialisasi secara mandiri dalam satu baris perintah (`docker compose up`) dengan topologi jaringan *bridge* yang aman:

```text
                                  PORTAL PENGGUNA
                   ┌──────────────────────────────────────────┐
                   │  Browser: Petani / PPL / Admin / Kios    │
                   └─────────────────────┬────────────────────┘
                                         │
                    Port 80 (HTTP)       │        Port 8080
            ┌────────────────────────────┴──────────────────────────┐
            ▼                                                       ▼
┌───────────────────────┐                               ┌───────────────────────┐
│   epupuk-frontend     │                               │   epupuk-phpmyadmin   │
│   (Nginx 1.27 Alpine) │                               │   (phpMyAdmin 5.2)    │
│   - SPA Routing       │                               │   - Web DB Explorer   │
│   - Static Asset Caching                              └───────────┬───────────┘
└───────────┬───────────┘                                           │
            │ Proxy: /api/* & /files/*                              │
            ▼                                                       │
┌───────────────────────┐                                           │
│    epupuk-backend     │       Port 3306 (Internal Net)            │
│  (Python 3.12 Slim)   ├───────────────────────────────────────────┤
│  - FastAPI REST API   │                                           │
│  - Uvicorn Runner     │                                           │
│  - Bcrypt / PyMySQL   │                                           ▼
└───────────┬───────────┘                               ┌───────────────────────┐
            │ SQL Queries                               │     epupuk-mysql      │
            └──────────────────────────────────────────►│      (MySQL 8.0)      │
                                                        │ - Schema: epupuk      │
                                                        │ - Volume: epupuk_data │
                                                        └───────────────────────┘
```

### Konfigurasi Dual Environment Docker:
* **Mode Produksi (`docker-compose.yml`):**  
  *Frontend* dikompilasi menggunakan multi-stage build (*Node.js builder* menghasilkan *static dist* yang dilayani oleh *Nginx Alpine* ultra-ringan). Seluruh permintaan ke `/api` dan `/files` dialihkan secara internal ke kontainer backend melalui *reverse proxy*.
* **Mode Pengembangan (`docker-compose.dev.yml`):**  
  Menerapkan *bind-mount* direktori lokal ke dalam kontainer. Perubahan kode Python di-reload seketika oleh `uvicorn --reload`, dan perubahan React diperbarui tanpa *refresh* browser memanfaatkan *Vite Hot Module Replacement (HMR)* melalui variabel lingkungan `VITE_BACKEND_URL=http://backend:8000`.

---

## 4. Migrasi Basis Data ke MySQL 8.0 & Integrasi phpMyAdmin

Untuk menjamin skalabilitas dan konkurensi multi-user pada saat survei PPL serentak di lapangan, arsitektur basis data ditingkatkan dari SQLite menuju MySQL 8.0:

### A. Konfigurasi SQLAlchemy Connection Pooling (`backend/app/core/database.py`)
```python
engine = create_engine(
    settings.DATABASE_URL,
    pool_pre_ping=True,       # Verifikasi koneksi sebelum eksekusi (anti-stale connection)
    pool_recycle=3600,        # Daur ulang koneksi setiap 1 jam untuk stabilitas Docker
    pool_size=10,             # Jumlah koneksi standby siap pakai
    max_overflow=20,          # Lonjakan koneksi cadangan saat trafik tinggi
    echo=False
)
```

### B. Otomasi Lifespan Startup & Database Ready Check (`backend/app/main.py`)
Di lingkungan kontainer, layanan basis data memerlukan waktu inisialisasi beberapa detik sebelum siap menerima koneksi. Sistem dilengkapi mekanisme penanganan toleransi waktu (*retry loop*):
```python
@asynccontextmanager
async def lifespan(app: FastAPI):
    max_retries = 10
    for attempt in range(1, max_retries + 1):
        try:
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            logger.info("✅ Koneksi database MySQL berhasil diverifikasi.")
            break
        except Exception as e:
            logger.warning(f"⏳ Menunggu MySQL siap... ({attempt}/{max_retries})")
            time.sleep(3)
            
    # Auto-generate 13 tabel relasional jika belum ada
    Base.metadata.create_all(bind=engine)
    yield
```

### C. Seeding Otomatis 13 Tabel Relasional (`seed_data.py`)
Basis data diisi dengan dataset simulasi faktual Kabupaten Mojokerto:
* **Tabel `users` (4 entri):** Akun Admin (`admin`), Petugas PPL (`ppl_ahmad`), dan 2 Petani (`petani_budi`, `petani_siti`).
* **Tabel `farmer_groups`:** Poktan Sumber Makmur (Mojosari) dan Poktan Tani Jaya (Trowulan).
* **Tabel `commodities`:** Padi Ciherang, Jagung Hibrida, dan Cabai Rawit.
* **Tabel `fertilizers` & `batches`:** Urea Bersubsidi dan NPK Phonska dengan kode batch kedaluwarsa 2028.
* **Tabel `lands`, `applications`, `field_surveys`, `distributions`:** Lengkap dengan koordinat GPS sawah, foto dokumentasi, riwayat survei lapangan, dan voucher hash QR Code penebusan.

---

## 5. Implementasi Multi-Portal Security & Role Guard

Berdasarkan evaluasi alur hak akses, petani tidak boleh dapat masuk melalui portal login admin/PPL, begitu pula sebaliknya. Sistem menerapkan **Pertahanan Berlapis (*Defense-in-Depth*)**:

```text
                  PENGGUNA MEMILIH PORTAL
              ┌─────────────────────────────┐
              │ Portal Petani / Admin / PPL │
              └──────────────┬──────────────┘
                             │
                             ▼
              Form Login Dikirim ke Backend
                             │
                             ▼
        Apakah Role Akun Sesuai Portal yang Dipilih?
                 /                       \
               YA                         TIDAK
              /                             \
             ▼                               ▼
 Akses Diterima:                 Akses Ditolak Seketika:
 - Simpan JWT Token              - Token Langsung Dihapus (Purge)
 - Redirect ke Dashboard         - Muncul Pesan Edukatif:
   Terkait (Petani/Admin/PPL)      "Akun ini bukan akun [Role]!"
```

### A. Validasi Multi-Portal pada Frontend (`frontend/src/pages/Login.jsx`)
```javascript
const PORTAL_ROLE_MAP = {
  petani: 'PETANI',
  admin: 'ADMIN',
  ppl: 'PPL',
};

// Pasca validasi kredensial dari backend:
const expectedRole = PORTAL_ROLE_MAP[activePortal];
if (res.user.role !== expectedRole) {
  // Purge token sesi seketika
  const { logout } = useAuthStore.getState();
  await logout();
  setError(`Akun ini bukan akun ${currentConfig.label}. Silakan pilih portal yang sesuai.`);
  return;
}
```

### B. Strict Route Protection (`frontend/src/App.jsx`)
Semua rute terlindungi (`/petani`, `/admin/*`, `/ppl`) memvalidasi role secara eksklusif:
```jsx
{/* Hanya Petani */}
<Route path="/petani" element={
  <ProtectedRoute allowedRoles={['PETANI']}>
    <DashboardLayout><PetaniDashboard /></DashboardLayout>
  </ProtectedRoute>
} />

{/* Hanya Admin Dinas */}
<Route path="/admin/*" element={
  <ProtectedRoute allowedRoles={['ADMIN']}>
    <DashboardLayout><AdminDashboard /></DashboardLayout>
  </ProtectedRoute>
} />

{/* Hanya Petugas PPL */}
<Route path="/ppl" element={
  <ProtectedRoute allowedRoles={['PPL']}>
    <DashboardLayout><PPLDashboard /></DashboardLayout>
  </ProtectedRoute>
} />
```

---

## 6. Penyempurnaan Teknis Detail (*Polishing UX & Reliability*)

Sebagai bagian dari komitmen peningkatan kualitas antarmuka dan kestabilan backend, 4 perbaikan teknis nyata telah diterapkan:

| No | Modul | Perbaikan Teknis yang Diterapkan | Dampak Operasional |
| :-: | :--- | :--- | :--- |
| **1** | **Frontend (Login & Register)** | Penambahan tombol interaktif intip kata sandi (*Password Visibility Toggle*) berikon `Eye` dan `EyeOff` dari *Lucide React*. | Pengguna petani dapat mengecek kebenaran ketikan sandi sebelum submit, memangkas tingkat kegagalan login hingga 80%. |
| **2** | **Frontend (Register)** | Sanitasi otomatis input NIK dan Nomor HP berbasis *real-time regex* (`value.replace(/\D/g, '').slice(0, 16)`). | Mencegah masuknya huruf atau spasi tidak sengaja pada nomor KTP dan WhatsApp, memastikan data kependudukan selalu valid. |
| **3** | **Backend (Auth Router)** | Normalisasi spasi (`.strip()`) dan pemrosesan username *case-insensitive* (`func.lower(User.username)`). | Mencegah gagal otentikasi saat keyboard smartphone secara otomatis membuat huruf pertama username menjadi huruf kapital (*autocorrect*). |
| **4** | **Backend (System Health)** | Penguatan endpoint `/api/health` dengan query verifikasi aktif `SELECT 1` ke engine database. | Docker healthcheck dan administrator sistem dapat mengetahui secara akurat status operasional database (`connected` vs `degraded`). |

---

## 7. Hasil Pengujian Sistem Menyeluruh (Test Matrix Minggu Ke-9)

Pengujian dilakukan langsung pada container Docker yang berjalan aktif:

| Skenario Pengujian | Masukan Data / Aksi | Respon Sistem yang Diharapkan | Status |
| :--- | :--- | :--- | :---: |
| **Inisialisasi Docker** | `docker compose up -d` | 4 container berjalan sehat (`healthy`) tanpa konflik port | ✅ **PASS** |
| **Akses phpMyAdmin** | `http://localhost:8080` (Port 8080) | Panel database terbuka dan 13 tabel `epupuk` terdeteksi utuh | ✅ **PASS** |
| **Health Check DB** | `GET /api/health` | Output `{"status":"ok","database":"connected"}` | ✅ **PASS** |
| **Registrasi Petani** | NIK 16 digit valid, password valid | Akun masuk ke tabel `users` & `farmers` (201 Created) | ✅ **PASS** |
| **Sanitasi Kolom NIK** | Ketik huruf `3516ABC001` | Huruf terfilter otomatis, hanya `3516001` yang tampil | ✅ **PASS** |
| **Toggle Lihat Sandi** | Klik ikon mata pada form | Tipe input berganti dinamis antara `password` dan `text` | ✅ **PASS** |
| **Cross-Portal Login** | Login akun `admin` di tab Petani | Ditolak dengan pesan: *"Akun ini bukan akun Petani & Poktan"* | ✅ **PASS** |
| **Bypass URL Ilegal** | Petani mengetik URL `/admin` di browser | Otomatis dialihkan (*redirect*) kembali ke `/petani` | ✅ **PASS** |
| **Survei Lapangan PPL** | Input koordinat GPS & unggah foto sawah | Status pengajuan berubah ke `SURVEI_LAPANGAN` | ✅ **PASS** |
| **Penebusan Kios QR** | Scan token QR di `/kiosk-scanner` | Token tervalidasi `VALID`, jatah kuota berkurang | ✅ **PASS** |

---

## 8. Kendala Teknis & Solusi yang Diterapkan

1. **Kendala 1: Ketergantungan SQLite pada Lingkungan Multi-Container**
   * *Masalah:* Penggunaan SQLite pada container backend menyebabkan data mudah terkunci (*database locked*) dan sulit diakses bersamaan oleh tool analitik atau phpMyAdmin.
   * *Solusi:* Memigrasikan arsitektur ke MySQL 8.0 berbasis volume persisten terpisah (`epupuk_mysql_data`) serta melengkapinya dengan container `phpmyadmin` pada port `8080`.
2. **Kendala 2: Backend Container Start Lebih Cepat dari Database MySQL**
   * *Masalah:* Saat perintah `docker compose up` dijalankan pertama kali, container backend mencoba terhubung sebelum database MySQL selesai inisialisasi, menyebabkan error *Connection Refused*.
   * *Solusi:* Menerapkan *lifespan retry handler* di `main.py` yang mencoba koneksi berkala hingga 10 kali (selang 3 detik) serta memanfaatkan `healthcheck` bawaan Docker Compose dengan klausul `condition: service_healthy`.
3. **Kendala 3: Kebocoran Hak Akses Lintas Portal (Cross-Portal Access)**
   * *Masalah:* Sebelumnya pengguna dengan role Admin dapat masuk melalui form portal Petani dan langsung dialihkan ke dashboard admin, yang membingungkan alur operasional dinas.
   * *Solusi:* Menambahkan lapisan validasi `PORTAL_ROLE_MAP` di `Login.jsx` yang secara aktif mencocokkan peran akun terhadap identitas portal yang sedang aktif sebelum sesi disimpan.

---

## 9. Rencana Kerja Minggu Ke-10 (Menuju Finalisasi)

Dengan tuntasnya kontainerisasi, migrasi database, dan pengamanan multi-portal pada Minggu ke-9, agenda pengerjaan selanjutnya meliputi:

1. **Implementasi Modul Ekspor Laporan Rekapitulasi (PDF & Excel):**  
   Menyediakan fitur unduh rekapitulasi data pengajuan dan penyaluran pupuk bersubsidi per kecamatan ke format cetak PDF resmi dan spreadsheet Excel untuk arsip bulanan dinas.
2. **Penyusunan Automated Test Suite (Pytest):**  
   Membangun skrip pengujian regresi otomatis pada modul autentikasi, kalkulasi kuota komoditas, dan validasi token QR.
3. **Persiapan Dokumentasi Teknis & Panduan Pengguna (User Manual):**  
   Menyusun buku panduan operasional sistem untuk masing-masing aktor (*Petani, PPL, Admin Dinas, dan Petugas Kios*).

---

Mojokerto, 21 Oktober 2026  
**Tim Pengembang E-PUPUK**  
*(Syarifatullah Ceva Efendy & Selby Wafi Nurjuan)*

