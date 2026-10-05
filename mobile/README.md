# e-Pupuk Mobile (Flutter)

Aplikasi mobile untuk platform e-Pupuk bersubsidi, dirancang khusus untuk pengguna **Petani** dan **Petugas PPL** sesuai arahan arsitektur multi-platform (Mobile & Web).

## 📁 Struktur Folder

```text
mobile/
├── lib/
│   ├── main.dart                          # Titik awal aplikasi & pengecekan sesi login
│   ├── config/
│   │   └── api_config.dart                # Konfigurasi URL Backend FastAPI
│   ├── models/
│   │   └── user_model.dart                # Model data akun & profil petani
│   ├── services/
│   │   └── auth_service.dart              # Integrasi API Register, Login, & Sesi
│   └── screens/
│       ├── auth/
│       │   ├── login_screen.dart          # Layar login akun petani
│       │   └── register_screen.dart       # Layar pendaftaran petani (Validasi NIK 16 digit & password)
│       └── petani/
│           └── petani_dashboard_screen.dart # Dashboard mobile petani (Profil, Sisa Kuota, Layanan)
├── pubspec.yaml                           # Dependensi Flutter (http, shared_preferences, etc.)
└── README.md
```

## 🔌 Integrasi Backend FastAPI

Aplikasi Flutter ini langsung terhubung ke backend FastAPI e-Pupuk:
- **Pendaftaran Petani:** `POST /api/auth/register`
- **Login Petani:** `POST /api/auth/login`
- **Cek Profil:** `GET /api/auth/me`

### Catatan Pengaturan Host URL (`api_config.dart`):
* **Android Emulator:** Menggunakan `http://10.0.2.2:8000/api` (karena Android emulator memetakan localhost host machine ke `10.0.2.2`).
* **HP Fisik (USB Debugging / Wi-Fi):** Ganti dengan IP lokal laptop (contoh: `http://192.168.1.15:8000/api`).
* **Chrome / Windows App:** Menggunakan `http://127.0.0.1:8000/api`.

## 🚀 Cara Menjalankan Aplikasi

1. Pastikan Flutter SDK sudah terpasang di komputer Anda.
2. Buka terminal di dalam folder `mobile`:
   ```bash
   cd mobile
   flutter pub get
   ```
3. Pastikan backend FastAPI sedang berjalan (`uvicorn app.main:app --reload`).
4. Jalankan aplikasi:
   ```bash
   flutter run
   ```
