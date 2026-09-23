-- =======================================================
-- Database Schema for E-Pupuk Kabupaten Mojokerto
-- =======================================================
CREATE DATABASE IF NOT EXISTS epupuk CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE epupuk;

-- Drop in reverse foreign key order if needed
DROP TABLE IF EXISTS audit_logs;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS qr_scans;
DROP TABLE IF EXISTS distributions;
DROP TABLE IF EXISTS fertilizer_batches;
DROP TABLE IF EXISTS field_surveys;
DROP TABLE IF EXISTS applications;
DROP TABLE IF EXISTS lands;
DROP TABLE IF EXISTS fertilizers;
DROP TABLE IF EXISTS commodities;
DROP TABLE IF EXISTS farmers;
DROP TABLE IF EXISTS farmer_groups;
DROP TABLE IF EXISTS users;

-- 1. users
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(100) UNIQUE NOT NULL,
  email VARCHAR(150) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('PETANI','PPL','ADMIN') NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. farmer_groups (Kelompok Tani)
CREATE TABLE farmer_groups (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nama_kelompok VARCHAR(150) NOT NULL,
  ketua_id INT NULL,
  wilayah VARCHAR(200) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. farmers (Profil Petani)
CREATE TABLE farmers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNIQUE NOT NULL,
  nama VARCHAR(150) NOT NULL,
  nik VARCHAR(20) UNIQUE NOT NULL,
  kontak VARCHAR(20),
  alamat TEXT NOT NULL,
  foto_ktp_url VARCHAR(500),
  tanggal_registrasi DATE DEFAULT (CURRENT_DATE),
  farmer_group_id INT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (farmer_group_id) REFERENCES farmer_groups(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. commodities (Komoditas Pertanian)
CREATE TABLE commodities (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nama_komoditas VARCHAR(100) NOT NULL,
  standar_kebutuhan_kg_per_ha DECIMAL(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. fertilizers (Jenis Pupuk Bersubsidi)
CREATE TABLE fertilizers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nama_pupuk VARCHAR(100) NOT NULL,
  satuan VARCHAR(20) DEFAULT 'kg'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. lands (Lahan Pertanian Petani)
CREATE TABLE lands (
  id INT AUTO_INCREMENT PRIMARY KEY,
  farmer_id INT NOT NULL,
  lokasi_deskripsi VARCHAR(300),
  alamat_lahan TEXT NOT NULL,
  latitude DECIMAL(10,7),
  longitude DECIMAL(10,7),
  luas_m2 DECIMAL(12,2) NOT NULL,
  commodity_id INT,
  status_kepemilikan ENUM('MILIK','GARAP','SEWA') DEFAULT 'MILIK',
  foto_lahan_url VARCHAR(500),
  tanggal_registrasi DATE DEFAULT (CURRENT_DATE),
  FOREIGN KEY (farmer_id) REFERENCES farmers(id) ON DELETE CASCADE,
  FOREIGN KEY (commodity_id) REFERENCES commodities(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. applications (Pengajuan Subsidi Pupuk)
CREATE TABLE applications (
  id INT AUTO_INCREMENT PRIMARY KEY,
  farmer_id INT NOT NULL,
  land_id INT NOT NULL,
  fertilizer_id INT NOT NULL,
  jumlah_diajukan DECIMAL(10,2) NOT NULL,
  kuota_maksimal DECIMAL(10,2),
  status ENUM(
    'DIAJUKAN',
    'MENUNGGU_VERIFIKASI_BERKAS',
    'PERLU_PERBAIKAN_BERKAS',
    'BERKAS_TERVERIFIKASI',
    'DITUGASKAN_KE_PPL',
    'SURVEI_LAPANGAN',
    'MENUNGGU_PERSETUJUAN_AKHIR',
    'DISETUJUI',
    'DITOLAK_BERKAS',
    'DITOLAK_LAPANGAN',
    'DIJADWALKAN_DISTRIBUSI',
    'TERSALURKAN'
  ) DEFAULT 'MENUNGGU_VERIFIKASI_BERKAS',
  foto_ktp_snapshot_url VARCHAR(500),
  foto_lahan_snapshot_url VARCHAR(500),
  alamat_lahan TEXT,
  latitude DECIMAL(10,7),
  longitude DECIMAL(10,7),
  tanggal_pengajuan TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  admin_verifier_id INT NULL,
  admin_verified_at TIMESTAMP NULL,
  catatan_admin_berkas TEXT,
  assigned_ppl_id INT NULL,
  assigned_at TIMESTAMP NULL,
  catatan_penugasan TEXT,
  final_approver_id INT NULL,
  final_approved_at TIMESTAMP NULL,
  jumlah_disetujui DECIMAL(10,2),
  catatan_final_admin TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (farmer_id) REFERENCES farmers(id) ON DELETE CASCADE,
  FOREIGN KEY (land_id) REFERENCES lands(id) ON DELETE CASCADE,
  FOREIGN KEY (fertilizer_id) REFERENCES fertilizers(id),
  FOREIGN KEY (admin_verifier_id) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (assigned_ppl_id) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (final_approver_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. field_surveys (Survei Lapangan PPL)
CREATE TABLE field_surveys (
  id INT AUTO_INCREMENT PRIMARY KEY,
  application_id INT UNIQUE NOT NULL,
  ppl_id INT NOT NULL,
  tanggal_survei TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  kondisi_fisik_lahan ENUM('BAIK','CUKUP','TIDAK_LAYAK') NOT NULL,
  keterangan_fisik_lahan TEXT,
  kondisi_tanaman ENUM('SESUAI','TIDAK_SESUAI') NOT NULL,
  keterangan_tanaman TEXT,
  luas_lahan_aktual_m2 DECIMAL(12,2),
  foto_survei_urls JSON,
  catatan_ppl TEXT,
  rekomendasi ENUM('SETUJU','TOLAK') NOT NULL,
  FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE,
  FOREIGN KEY (ppl_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. fertilizer_batches (Batch Pupuk)
CREATE TABLE fertilizer_batches (
  id INT AUTO_INCREMENT PRIMARY KEY,
  batch_code VARCHAR(50) UNIQUE NOT NULL,
  fertilizer_id INT NOT NULL,
  production_date DATE,
  expired_date DATE NOT NULL,
  stok_kg DECIMAL(12,2) DEFAULT 0,
  FOREIGN KEY (fertilizer_id) REFERENCES fertilizers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10. distributions (Penyaluran dan QR Token)
CREATE TABLE distributions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  application_id INT UNIQUE NOT NULL,
  batch_id INT NULL,
  jumlah_disalurkan DECIMAL(10,2) NOT NULL,
  status_penyaluran ENUM('MENUNGGU_PENGAMBILAN','SELESAI','BATAL') DEFAULT 'MENUNGGU_PENGAMBILAN',
  qr_code_hash VARCHAR(255) UNIQUE,
  tanggal_penyaluran TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE,
  FOREIGN KEY (batch_id) REFERENCES fertilizer_batches(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 11. qr_scans (Catatan Pindai QR)
CREATE TABLE qr_scans (
  id INT AUTO_INCREMENT PRIMARY KEY,
  distribution_id INT NOT NULL,
  scanner_user_id INT NOT NULL,
  scan_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  latitude DECIMAL(10,7),
  longitude DECIMAL(10,7),
  validation_status ENUM('VALID','EXPIRED','ALREADY_CLAIMED','INVALID') NOT NULL,
  FOREIGN KEY (distribution_id) REFERENCES distributions(id) ON DELETE CASCADE,
  FOREIGN KEY (scanner_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 12. notifications (Notifikasi Petani & PPL)
CREATE TABLE notifications (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  judul VARCHAR(200) NOT NULL,
  pesan TEXT NOT NULL,
  tipe ENUM('INFO','WARNING','SUCCESS','DANGER') DEFAULT 'INFO',
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 13. audit_logs (Audit Jejak Keamanan & Akses KTP)
CREATE TABLE audit_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NULL,
  action VARCHAR(100) NOT NULL,
  resource VARCHAR(100) NOT NULL,
  resource_id INT NULL,
  details TEXT,
  ip_address VARCHAR(45),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
