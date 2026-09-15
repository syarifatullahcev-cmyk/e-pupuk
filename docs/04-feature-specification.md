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
CRUD nama, NIK (tersamar di tampilan non-admin), kontak, alamat domisili lengkap, foto KTP (URL berkas), tanggal pendaftaran, kelompok tani.

### 2.2 Data PPL
CRUD nama, wilayah binaan (kecamatan/desa), kontak.

### 2.3 Data Admin
CRUD akun admin dengan hak akses penuh pada data master.

### 2.4 Data Kelompok Tani
CRUD nama kelompok, ketua kelompok, daftar anggota, wilayah.

## 3. Land Management

### 3.1 Data Lahan
CRUD lahan milik petani: lokasi/alamat lahan, luas, koordinat GPS (latitude, longitude), status kepemilikan, foto lahan (URL berkas), komoditas, tanggal registrasi/pembaruan.

### 3.2 Luas Lahan
Disimpan dalam satuan m² (dikonversi ke hektar saat kalkulasi kuota).

### 3.3 Komoditas
Master data komoditas (Padi, Jagung, dsb) yang menentukan standar kebutuhan pupuk.

### 3.4 Validasi Data Lahan
Luas lahan harus > 0; satu lahan hanya terkait satu petani; koordinat GPS wajib diisi; foto lahan wajib diunggah saat registrasi; perubahan luas lahan signifikan dapat ditandai untuk review admin.

### 3.5 Koordinat GPS (Latitude, Longitude)
Diinput via Leaflet map picker di frontend. Backend menyimpan dalam format desimal (mis. -7.4819, 112.5342). Digunakan sebagai referensi navigasi GPS bagi PPL yang ditugaskan survei lapangan.

## 4. Fertilizer Application (Pengajuan Subsidi Pupuk)

### 4.1 Create Application
Petani mengisi form pengajuan dengan:
- Lahan yang diajukan (dropdown dari data lahan miliknya).
- Komoditas.
- Jenis pupuk dan jumlah pengajuan (dibatasi kuota maksimal hasil kalkulasi).
- **Upload wajib foto KTP petani** (JPEG/PNG/WEBP, maks. 5MB).
- **Upload wajib foto kondisi lahan terkini** (JPEG/PNG/WEBP, maks. 5MB).
- **Alamat lahan** (textarea, isian teks lengkap).
- **Titik koordinat lokasi lahan** (Leaflet map picker — dikunci/prefill dari data lahan, dapat dikonfirmasi ulang petani).
- **Tanggal pengajuan** (auto-filled dari server, read-only bagi petani).

Backend memvalidasi: format berkas, ukuran berkas, kelengkapan semua field wajib, dan batas kuota.

### 4.2 Edit Application
Diizinkan selama status masih `DIAJUKAN` (belum masuk antrian verifikasi berkas). Edit termasuk kemampuan mengganti berkas yang diunggah.

### 4.3 Revisi Berkas (PERLU_PERBAIKAN_BERKAS)
Jika Admin menandai `PERLU_PERBAIKAN_BERKAS`:
- Petani menerima notifikasi beserta catatan detail dari Admin tentang berkas apa yang perlu diperbaiki.
- Petani dapat mengunggah ulang berkas (KTP dan/atau foto lahan) tanpa harus mengulang pengisian seluruh form pengajuan.
- Setelah petani mengunggah ulang, status kembali ke `MENUNGGU_VERIFIKASI_BERKAS` dan Admin mendapat notifikasi.

### 4.4 Cancel Application
Petani dapat membatalkan pengajuan yang berstatus `DIAJUKAN` atau `PERLU_PERBAIKAN_BERKAS`.

### 4.5 Application Status (6-Stage Lifecycle)
```
DIAJUKAN
  → MENUNGGU_VERIFIKASI_BERKAS        (setelah pengajuan diterima sistem)
  → PERLU_PERBAIKAN_BERKAS            (Admin: berkas kurang/tidak valid, petani revisi)
  → BERKAS_TERVERIFIKASI              (Admin: berkas valid)
  → DITUGASKAN_KE_PPL                 (Admin menugaskan PPL untuk survei lapangan)
  → SURVEI_LAPANGAN                   (PPL sedang melaksanakan survei)
  → MENUNGGU_PERSETUJUAN_AKHIR        (PPL submit laporan, menunggu Admin)
  → DISETUJUI                         (Admin persetujuan akhir — lanjut ke distribusi)
  → DITOLAK_BERKAS                    (Admin menolak berkas — final)
  → DITOLAK_LAPANGAN                  (Admin menolak berdasar laporan survei PPL — final)
  → DIJADWALKAN_DISTRIBUSI            (Admin jadwalkan alokasi batch)
  → TERSALURKAN                       (scan QR serah terima selesai)
```

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

## 6. Admin Document Verification (Verifikasi Berkas Administratif)

### 6.1 Review Berkas
Admin melihat tampilan terpadu pengajuan yang berisi:
- Preview foto KTP petani (dalam Photo Viewer aman).
- Data NIK, nama, alamat dari form petani.
- Preview foto kondisi lahan.
- Alamat lahan (teks) dan pin koordinat pada peta.
- Tanggal pengajuan dan detail komoditas/pupuk.

### 6.2 Berkas Valid (Approve Berkas)
- Admin mengklik "Berkas Valid".
- Status pengajuan berubah dari `MENUNGGU_VERIFIKASI_BERKAS` menjadi `BERKAS_TERVERIFIKASI`.
- Pengajuan masuk ke antrian Penugasan PPL.
- Field `admin_verifier_id` dan `admin_verified_at` diisi.

### 6.3 Perlu Perbaikan (PERLU_PERBAIKAN_BERKAS)
- Admin mengisi catatan detail berkas mana yang perlu diperbaiki (textarea wajib).
- Status berubah menjadi `PERLU_PERBAIKAN_BERKAS`.
- Petani menerima notifikasi dengan catatan tersebut.

### 6.4 Tolak Berkas (DITOLAK_BERKAS)
- Admin mengisi alasan penolakan final (textarea wajib).
- Status berubah menjadi `DITOLAK_BERKAS` (final, tidak dapat dilanjutkan).
- Petani menerima notifikasi dengan alasan penolakan.

## 7. PPL Field Assignment (Penugasan Survei Lapangan)

### 7.1 Sistem Saran PPL Otomatis
Setelah berkas diverifikasi valid, sistem secara otomatis menyarankan PPL penanggung wilayah binaan (desa/kelompok tani) yang sesuai dengan lokasi lahan pengajuan. Admin dapat menerima saran tersebut atau memilih PPL lain secara manual.

### 7.2 Form Penugasan
Admin mengisi:
- PPL yang ditugaskan (prefill otomatis, dapat diubah via dropdown).
- Batas waktu survei (date picker, wajib).
- Instruksi khusus survei (textarea, opsional).

### 7.3 Proses Penugasan
- Status berubah menjadi `DITUGASKAN_KE_PPL`.
- Field `assigned_ppl_id`, `assigned_at`, dan `catatan_penugasan` diisi.
- PPL menerima notifikasi penugasan baru beserta detail pengajuan.

## 8. PPL Field Survey (Survei Fisik Lapangan)

### 8.1 Menerima Tugas
PPL melihat daftar tugas survei yang ditugaskan kepadanya, beserta:
- Data lengkap petani (nama, NIK tersamar).
- Foto KTP referensi (tersamar).
- Foto lahan dari pengajuan (referensi visual sebelum survei).
- Alamat lahan dan koordinat GPS (tombol navigasi ke Google Maps / peta).
- Batas waktu survei.
- Catatan instruksi dari Admin.

### 8.2 Pelaksanaan Survei
PPL mendatangi lahan secara fisik dan memeriksa:
- **Kondisi fisik lahan**: kesesuaian luas aktual dengan data pengajuan, kondisi lahan (siap tanam, terbengkalai, dll).
- **Kondisi bahan/tanaman**: jenis komoditas yang ditanam/akan ditanam, kondisi pertumbuhan, kesesuaian dengan pengajuan subsidi.
- Mengambil foto kondisi fisik lahan dan tanaman sebagai bukti survei lapangan.

### 8.3 Submit Laporan Survei
PPL mengisi form laporan survei:
- **Kondisi Fisik Lahan** (dropdown: Baik/Cukup/Tidak Layak + textarea keterangan).
- **Kondisi Bahan/Tanaman** (dropdown: Sesuai/Tidak Sesuai + textarea keterangan).
- **Luas Lahan Aktual** (input m², hasil pengukuran lapangan).
- **Upload Foto Bukti Lapangan** (minimal 2 foto, maks. 5 foto, masing-masing maks. 5MB).
- **Catatan Evaluasi** (textarea, wajib).
- **Rekomendasi** (radio: Setujui / Tolak).
- Tanggal survei (auto-filled dari server).

Setelah submit:
- Status berubah menjadi `MENUNGGU_PERSETUJUAN_AKHIR`.
- Data survei disimpan ke tabel `field_surveys`.
- Admin menerima notifikasi laporan survei siap direview.

### 8.4 Batas Waktu Survei
Jika PPL belum submit laporan sebelum batas waktu yang ditetapkan Admin, sistem mengirimkan reminder notifikasi ke PPL dan alert ke Admin.

## 9. Admin Final Approval (Persetujuan Akhir)

### 9.1 Review Laporan Survei PPL
Admin melihat ringkasan laporan survei PPL beserta foto bukti lapangan, catatan evaluasi, dan rekomendasi.

### 9.2 Setujui (DISETUJUI)
- Admin dapat menyesuaikan volume akhir yang disetujui (tidak boleh melebihi kuota maksimal kalkulasi).
- Mengisi catatan persetujuan (opsional).
- Status berubah menjadi `DISETUJUI`, kemudian `DIJADWALKAN_DISTRIBUSI`.
- Field `final_approver_id` dan `final_approved_at` diisi.

### 9.3 Tolak (DITOLAK_LAPANGAN)
- Admin mengisi alasan penolakan berdasar laporan survei (wajib).
- Status berubah menjadi `DITOLAK_LAPANGAN` (final).
- Petani menerima notifikasi dengan alasan penolakan dari lapangan.

## 10. QR Code

### 10.1 QR Structure
Data yang dikodekan dalam QR batch:
- `batch_id`
- `fertilizer_type`
- `production_date`
- `expired_date`

### 10.2 Scan Process
1. User membuka fitur scanner (html5-qrcode).
2. Kamera membaca QR.
3. Frontend mengirim hasil scan ke backend.
4. Backend mencari data batch berdasarkan `batch_id`.
5. Backend memeriksa `expired_date` terhadap tanggal saat ini.
6. Backend memeriksa riwayat penerimaan untuk batch/petani terkait.
7. Sistem menentukan status hasil scan.
8. Sistem menyimpan log scan (waktu, user, hasil).

### 10.3 Batch Validation
Batch harus terdaftar di sistem (hasil distribusi Admin) sebelum QR dapat divalidasi valid.

### 10.4 Expired Validation
Jika `expired_date` < tanggal scan → status `EXPIRED`, transaksi tidak dilanjutkan sebagai distribusi valid dan Admin menerima alert.

### 10.5 Timestamp
Setiap scan dicatat dengan timestamp server, bukan waktu perangkat client, untuk menjaga integritas log.

### 10.6 Duplicate Scan
Jika batch yang sama sudah pernah discan untuk transaksi/penerima yang sama → status `DUPLICATE`.

### Result
```
VALID     — batch valid, belum expired, belum pernah discan untuk transaksi ini
WARNING   — mendekati tanggal expired / mendekati ambang kuota
EXPIRED   — melewati expired_date
DUPLICATE — batch sudah pernah discan untuk transaksi yang sama
FLAGGED   — pola transaksi mencurigakan (lihat §11)
BLOCKED   — transaksi ditolak sistem karena pelanggaran aturan (mis. expired atau flagged berat)
```

## 11. Anti-Stockpiling Detection

### 11.1 Detection Rules
Indikator dihitung dari riwayat transaksi, misalnya: frekuensi penerimaan yang tidak wajar dalam periode singkat, volume kumulatif mendekati/melebihi kuota musiman, atau pola scan dari lokasi/waktu yang tidak konsisten dengan pola normal.

### 11.2 Warning
Transaksi dengan indikator ringan diberi status `WARNING`, tetap diproses tapi dicatat untuk review.

### 11.3 Flagged Transaction
Transaksi dengan indikator kuat ditandai `FLAGGED` dan masuk daftar review Admin.

### 11.4 Block Transaction
Transaksi dengan pelanggaran jelas (mis. melebihi kuota total musim) diblokir (`BLOCKED`) hingga direview manual.

### 11.5 Admin Alert
Setiap transaksi `FLAGGED`/`BLOCKED` memicu notifikasi ke Admin.

> Catatan: mekanisme ini bersifat **deteksi indikasi**, bukan jaminan mutlak mencegah penimbunan — keputusan akhir tetap memerlukan verifikasi manusia.

## 12. Fertilizer Distribution

### 12.1 Distribution
Admin mencatat penyaluran batch pupuk ke petani/kelompok tani yang pengajuannya berstatus `DIJADWALKAN_DISTRIBUSI`.

### 12.2 Confirmation
Konfirmasi distribusi final terjadi saat scan QR oleh petani/PPL di titik serah terima.

### 12.3 Distribution Status
`DIJADWALKAN → DALAM_PROSES → TERSALURKAN`.

### 12.4 Distribution History
Riwayat distribusi per petani dan per batch dapat ditelusuri dari dua arah (by petani, by batch).

## 13. Dashboard

### 13.1–13.4
Lihat detail tampilan tiap dashboard peran di `03-ui-ux-design.md` §5–§8. Data yang ditampilkan bersumber dari agregasi tabel `applications`, `field_surveys`, `distributions`, `qr_scans`, ditambah data eksternal (cuaca/peta) via `05-api-data-database.md`.

## 14. Notification
Notifikasi in-app untuk:
- Pengajuan baru masuk (ke Admin).
- Berkas pengajuan perlu perbaikan (ke Petani — beserta catatan Admin).
- Berkas terverifikasi valid (ke Petani).
- Penugasan survei lapangan baru (ke PPL — beserta detail tugas).
- Reminder batas waktu survei mendekati (ke PPL dan Admin).
- Laporan survei PPL siap direview (ke Admin).
- Hasil persetujuan akhir (ke Petani — disetujui atau ditolak beserta alasan).
- Distribusi terjadwal (ke Petani).
- Alert expired/duplicate/flagged/blocked (ke Admin).

## 15. Audit Log
Mencatat aksi verifikasi berkas, penugasan PPL, submit laporan survei lapangan, persetujuan akhir, distribusi, perubahan data master, akses berkas foto KTP, dan hasil scan QR — minimal berisi `user_id`, `aksi`, `entitas terkait`, `waktu`.

## 16. Acceptance Criteria
- Pengajuan yang melebihi kuota tidak dapat diteruskan tanpa status `OVERLIMIT`.
- Setiap pengajuan wajib menyertakan foto KTP, foto lahan, alamat lengkap, dan koordinat GPS sebelum dapat diproses.
- Setiap pengajuan yang lolos verifikasi berkas Admin wajib melewati tahap penugasan dan laporan survei PPL sebelum dapat disetujui.
- Foto KTP hanya dapat diakses oleh Admin dan PPL yang ditugaskan pada pengajuan terkait, dan setiap akses tercatat di audit log.
- Setiap scan QR menghasilkan salah satu dari enam status yang didefinisikan di §10.
- Setiap transaksi `FLAGGED`/`BLOCKED` memunculkan alert ke Admin dalam waktu dekat-realtime.
- Riwayat distribusi dapat ditelusuri per petani maupun per batch.
- Seluruh aksi verifikasi berkas, penugasan PPL, survei lapangan, persetujuan akhir, dan distribusi tercatat di audit log.
