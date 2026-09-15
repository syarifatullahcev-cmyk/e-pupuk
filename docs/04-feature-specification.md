# Feature Specification
# E-Pupuk Kabupaten Mojokerto

## 1. Authentication

### 1.1 Login
Input email/username + password → backend verifikasi → jika valid, terbitkan JWT berisi `user_id`, `role`, `exp`.

### 1.2 Logout
Hapus token di sisi client (dan, bila diterapkan blacklist, tandai token tidak berlaku di backend).

### 1.3 Role Access
Setiap endpoint memeriksa `role` dari token terhadap matriks izin di `02-system-design.md` §6.

### 1.4 JWT
Token bertipe Bearer, masa berlaku terbatas (mis. beberapa jam), refresh token opsional untuk sesi panjang.

## 2. User Management

### 2.1 Data Petani
CRUD nama, NIK (tersamar di tampilan non-admin), kontak, alamat, kelompok tani.

### 2.2 Data PPL
CRUD nama, wilayah binaan, kontak.

### 2.3 Data Admin
CRUD akun admin dengan hak akses penuh pada data master.

### 2.4 Data Kelompok Tani
CRUD nama kelompok, ketua kelompok, daftar anggota, wilayah.

## 3. Land Management

### 3.1 Data Lahan
CRUD lahan milik petani: lokasi, luas, status kepemilikan.

### 3.2 Luas Lahan
Disimpan dalam satuan m² (dikonversi ke hektar saat kalkulasi kuota).

### 3.3 Komoditas
Master data komoditas (Padi, Jagung, dsb) yang menentukan standar kebutuhan pupuk.

### 3.4 Validasi Data Lahan
Luas lahan harus > 0; satu lahan hanya terkait satu petani; perubahan luas lahan signifikan dapat ditandai untuk review admin.

## 4. Fertilizer Application

### 4.1 Create Application
Petani memilih lahan, komoditas, jenis pupuk, dan jumlah pengajuan (dibatasi kuota maksimal hasil kalkulasi).

### 4.2 Edit Application
Diizinkan selama status masih `DIAJUKAN` (belum masuk verifikasi).

### 4.3 Cancel Application
Petani dapat membatalkan pengajuan yang belum diverifikasi.

### 4.4 Application Status
`DIAJUKAN → DIVERIFIKASI → DISETUJUI/DITOLAK → TERSALURKAN`.

## 5. Quota Calculation

### Tujuan
Menentukan batas maksimal pengajuan pupuk berdasarkan luas lahan dan komoditas.

### Input
- Luas lahan
- Komoditas
- Jenis pupuk

### Formula
```
Maksimal Kuota = Luas Lahan (ha) × Standar Kebutuhan Komoditas (kg/ha)
```
> Nilai "Standar Kebutuhan Komoditas" per jenis pupuk masih placeholder — perlu dikonfirmasi dari data resmi Dinas Pertanian sebelum dipakai sebagai acuan produksi (lihat `01-product-requirements.md` §10).

### Process
1. Petani memilih komoditas dan jenis pupuk.
2. Sistem mengambil luas lahan terdaftar milik petani.
3. Sistem mengambil standar kebutuhan dari tabel referensi komoditas.
4. Backend menghitung kuota maksimal.
5. Sistem menampilkan kuota maksimal ke petani.
6. Petani memasukkan jumlah pengajuan.
7. Backend memvalidasi jumlah terhadap kuota maksimal.

### Validation
```
Jika  pengajuan <= maksimal kuota  →  STATUS = VALID
Jika  pengajuan >  maksimal kuota  →  STATUS = OVERLIMIT
```
Status `OVERLIMIT` memblokir pengajuan otomatis dan dapat ditandai untuk review manual oleh PPL/Admin.

### 5.5 Overlimit Handling
Pengajuan overlimit tidak diteruskan ke antrean verifikasi normal; petani menerima pesan bahwa jumlah melebihi kuota dan diarahkan mengubah jumlah.

## 6. PPL Verification

### 6.1 Review Application
PPL melihat detail pengajuan (data petani, lahan, kuota, jumlah diajukan).

### 6.2 Approve
Pengajuan berubah status `DISETUJUI`, masuk antrean distribusi.

### 6.3 Reject
Pengajuan berubah status `DITOLAK`, wajib disertai catatan alasan.

### 6.4 Escalation
Pengajuan dengan indikasi anomali (mis. berulang overlimit) dapat dieskalasi ke Admin.

## 7. QR Code

### 7.1 QR Structure
Data yang dikodekan dalam QR batch:
- `batch_id`
- `fertilizer_type`
- `production_date`
- `expired_date`

### 7.2 Scan Process
1. User membuka fitur scanner (html5-qrcode).
2. Kamera membaca QR.
3. Frontend mengirim hasil scan ke backend.
4. Backend mencari data batch berdasarkan `batch_id`.
5. Backend memeriksa `expired_date` terhadap tanggal saat ini.
6. Backend memeriksa riwayat penerimaan untuk batch/petani terkait.
7. Sistem menentukan status hasil scan.
8. Sistem menyimpan log scan (waktu, user, hasil).

### 7.3 Batch Validation
Batch harus terdaftar di sistem (hasil distribusi Admin) sebelum QR dapat divalidasi valid.

### 7.4 Expired Validation
Jika `expired_date` < tanggal scan → status `EXPIRED`, transaksi tidak dilanjutkan sebagai distribusi valid dan Admin menerima alert.

### 7.5 Timestamp
Setiap scan dicatat dengan timestamp server, bukan waktu perangkat client, untuk menjaga integritas log.

### 7.6 Duplicate Scan
Jika batch yang sama sudah pernah discan untuk transaksi/penerima yang sama → status `DUPLICATE`.

### Result
```
VALID     — batch valid, belum expired, belum pernah discan untuk transaksi ini
WARNING   — mendekati tanggal expired / mendekati ambang kuota
EXPIRED   — melewati expired_date
DUPLICATE — batch sudah pernah discan untuk transaksi yang sama
FLAGGED   — pola transaksi mencurigakan (lihat §8)
BLOCKED   — transaksi ditolak sistem karena pelanggaran aturan (mis. expired atau flagged berat)
```

## 8. Anti-Stockpiling Detection

### 8.1 Detection Rules
Indikator dihitung dari riwayat transaksi, misalnya: frekuensi penerimaan yang tidak wajar dalam periode singkat, volume kumulatif mendekati/melebihi kuota musiman, atau pola scan dari lokasi/waktu yang tidak konsisten dengan pola normal.

### 8.2 Warning
Transaksi dengan indikator ringan diberi status `WARNING`, tetap diproses tapi dicatat untuk review.

### 8.3 Flagged Transaction
Transaksi dengan indikator kuat ditandai `FLAGGED` dan masuk daftar review Admin.

### 8.4 Block Transaction
Transaksi dengan pelanggaran jelas (mis. melebihi kuota total musim) diblokir (`BLOCKED`) hingga direview manual.

### 8.5 Admin Alert
Setiap transaksi `FLAGGED`/`BLOCKED` memicu notifikasi ke Admin.

> Catatan: mekanisme ini bersifat **deteksi indikasi**, bukan jaminan mutlak mencegah penimbunan — keputusan akhir tetap memerlukan verifikasi manusia.

## 9. Fertilizer Distribution

### 9.1 Distribution
Admin mencatat penyaluran batch pupuk ke petani/kelompok tani yang pengajuannya berstatus `DISETUJUI`.

### 9.2 Confirmation
Konfirmasi distribusi final terjadi saat scan QR oleh petani/PPL di titik serah terima.

### 9.3 Distribution Status
`DIJADWALKAN → DALAM PROSES → TERSALURKAN`.

### 9.4 Distribution History
Riwayat distribusi per petani dan per batch dapat ditelusuri dari dua arah (by petani, by batch).

## 10. Dashboard

### 10.1–10.4
Lihat detail tampilan tiap dashboard peran di `03-ui-ux-design.md` §5–§8. Data yang ditampilkan bersumber dari agregasi tabel `applications`, `distributions`, `qr_scans`, ditambah data eksternal (cuaca/peta) via `05-api-data-database.md`.

## 11. Notification
Notifikasi in-app untuk: pengajuan baru (ke PPL), hasil verifikasi (ke petani), distribusi terjadwal (ke petani), serta alert expired/duplicate/flagged/blocked (ke Admin).

## 12. Audit Log
Mencatat aksi verifikasi, distribusi, perubahan data master, dan hasil scan QR — minimal berisi `user_id`, `aksi`, `entitas terkait`, `waktu`.

## 13. Acceptance Criteria
- Pengajuan yang melebihi kuota tidak dapat diteruskan tanpa status `OVERLIMIT`.
- Setiap scan QR menghasilkan salah satu dari enam status yang didefinisikan di §7.
- Setiap transaksi `FLAGGED`/`BLOCKED` memunculkan alert ke Admin dalam waktu dekat-realtime.
- Riwayat distribusi dapat ditelusuri per petani maupun per batch.
- Seluruh aksi verifikasi dan distribusi tercatat di audit log.
