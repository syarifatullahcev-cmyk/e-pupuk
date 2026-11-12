# Panduan Uji Lapangan dan Gladi Demo E-Pupuk

Dokumen ini membedakan hasil uji otomatis dari hal yang masih harus dibuktikan di perangkat dan lingkungan lapangan. Jangan menyebut proyek 100% siap sebelum seluruh pemeriksaan yang relevan selesai.

## Status verifikasi kode

- Backend: workflow E2E, generator media, dan pengaman seed lulus dengan `python -m unittest test_e2e_workflow test_generate_seed_media test_seed_data`. E2E memakai SQLite dan direktori unggahan sementara; tidak memakai database kerja.
- React: `npm test` lulus (4 tes), `npm run lint` dan `npm run build` selesai. Lint masih melaporkan peringatan yang sudah ada.
- Flutter: `flutter test --no-pub` lulus (37 tes) dan `flutter build web --release --no-pub` berhasil. Analisis lima file PPL terkait mencatat 49 diagnostik kategori info, tanpa error/warning.
- Generator aset demo: diuji ke direktori sementara; membuat lima gambar yang memakai watermark DUMMY/CONTOH.
- Uji kamera, GPS, izin sistem, unggah pada jaringan lemah, dan peta di perangkat fisik: **BELUM DIUJI**.
- React dan Flutter sama-sama membatasi bukti survei ke 2-5 foto; React memilih file dan Flutter mengambil foto dari kamera.

## Batasan yang harus disampaikan saat demo

1. Belum ada akun atau role Kios mandiri. API penebusan saat ini hanya mengizinkan Petani pemilik QR; halaman web juga memerlukan login Petani, input token manual, GPS, dan foto pupuk.
2. React dan Flutter mengirim foto, hasil pemeriksaan, luas, dan poligon dalam satu laporan PPL. Di Flutter, layar pengukuran mengembalikan poligon ke formulir utama; koordinat GPS perangkat hanya referensi dan tidak menggantikan poligon batas.
3. Dukungan peta saat sinyal lemah/offline dan keberhasilan tile satelit belum dibuktikan. Jangan menjanjikan peta offline.
   Pada Flutter widget test, tile ArcGIS eksternal mengembalikan HTTP 400; tes lain tetap jalan, tetapi tampilan tile perlu diverifikasi dengan jaringan/perangkat lapangan.
4. Tidak ada hasil uji perangkat nyata dalam sesi ini. Tabel uji lapangan di bawah harus diisi ketika perangkat tersedia.
5. Backend belum menyediakan endpoint simpan draf survei. Aplikasi Flutter hanya mengirim laporan setelah data wajib lengkap; tombol draf yang sebelumnya mengirim laporan final sudah dihapus agar tidak menyesatkan.

## Aturan keamanan data demo

- Jalankan uji alur otomatis dengan basis data sementara terisolasi, bukan database produksi atau database kerja.
- Script `backend/seed_data.py` hanya berjalan dengan `--demo-only` dan database lokal bernama persis `epupuk_demo`; isinya identitas, alamat, dan lahan fiktif. Jangan arahkan ke database produksi.
- Gunakan hanya akun dan data sintetis pada database uji. Jangan unggah KTP, NIK, sertifikat, foto petani, atau foto lahan sungguhan ke demo.
- Gambar yang dibuat `backend/generate_seed_media.py` adalah ilustrasi ber-watermark dan **tidak sah untuk verifikasi**. Jika perlu membuatnya, arahkan output ke direktori sementara; jangan jalankan generator dengan output default ke `backend/uploads`.
- Uji GPS hanya boleh memakai lokasi yang disetujui di lingkungan uji. Jangan gunakan foto contoh sebagai bukti pengambilan pupuk atau survei.

## Skenario alur ujung-ke-ujung

1. **Petani mengajukan**
   - Masuk ke lingkungan uji sebagai Petani sintetis.
   - Pilih lahan/komoditas uji dan kirim pengajuan.
   - Pastikan respons dan penyimpanan menunjukkan status `MENUNGGU_VERIFIKASI_BERKAS`.
2. **Admin memeriksa dan menugaskan**
   - Verifikasi berkas uji, lalu tugaskan PPL uji.
   - Pastikan status berubah berurutan menjadi `BERKAS_TERVERIFIKASI` lalu `DITUGASKAN_KE_PPL`.
3. **PPL mengirim hasil**
   - Mulai survei pada tugas yang ditugaskan.
   - Lengkapi hasil pemeriksaan, ukur poligon valid, serta ambil dan unggah 2–5 foto uji.
   - Kirim satu laporan dan pastikan foto, luas/poligon, catatan, rekomendasi, serta status tersimpan.
4. **Admin menyetujui hasil**
   - Tinjau hasil PPL dan setujui jumlah alokasi uji.
   - Pastikan distribusi/QR terbentuk dan status menjadi `DIJADWALKAN_DISTRIBUSI`.
5. **Penebusan sesuai batasan API**
   - Uji dengan akun Petani pemilik QR, GPS uji yang cocok, dan foto pupuk uji.
   - Tebus seluruh distribusi; pastikan duplikasi QR ditolak dan status pengajuan menjadi `TERSALURKAN` setelah semua penebusan selesai.
   - Jangan menyebut langkah ini sebagai uji akun Kios: role Kios belum tersedia.

### Perintah uji otomatis backend

Dari folder `backend`:

```powershell
python -m unittest test_e2e_workflow
```

Tes tersebut membuat serta membersihkan database SQLite dan unggahan sementara sendiri. Jangan mengganti tes ini dengan skrip yang memakai akun/data produksi.

## Checklist uji perangkat lapangan

Jalankan pada perangkat Android yang akan dipakai untuk demo. Ulangi setidaknya sekali dengan jaringan baik dan sekali dengan jaringan lemah.

| Pemeriksaan | Hasil | Perangkat/OS, waktu, catatan |
|---|---|---|
| Izin kamera: izinkan, tolak, lalu izinkan kembali dari pengaturan | BELUM DIUJI | |
| Ambil dua foto survei dari kamera; pastikan nama/preview dan unggah berhasil | BELUM DIUJI | |
| Izin lokasi: izinkan, tolak, dan pemulihan setelah izin ditolak | BELUM DIUJI | |
| GPS di area terbuka: akurasi dan koordinat masuk akal | BELUM DIUJI | |
| Poligon: tiga titik atau lebih, luas tidak nol, batas invalid ditolak | BELUM DIUJI | |
| Putuskan jaringan saat unggah; pastikan error terlihat dan pengiriman tidak sukses palsu | BELUM DIUJI | |
| Jaringan lemah: waktu tunggu, retry, dan status unggah tidak membingungkan | BELUM DIUJI | |
| Peta/tile ketika sinyal hilang dan pulih; catat bahwa offline mungkin tidak tersedia | BELUM DIUJI | |
| Foto pupuk dan lokasi untuk penebusan QR di lingkungan uji | BELUM DIUJI | |

Lampirkan hasil dengan data sintetis saja. Jangan masukkan kredensial, NIK, atau foto identitas/lahan asli ke laporan demo.

## Checklist gladi demo

- [ ] Pastikan `.env` menunjuk ke database uji dan backup tersedia; jangan membuka database kerja/produksi.
- [ ] Periksa role pada akun demo: Admin dan PPL, serta Petani pemilik QR. Tidak ada akun Kios mandiri.
- [ ] Jalankan `python -m unittest test_e2e_workflow` dari `backend`.
- [ ] Jalankan `npm test`, `npm run lint`, dan `npm run build` dari `frontend`.
- [ ] Jalankan `flutter test --no-pub` dan `flutter build web --release --no-pub` dari `mobile`.
- [ ] Latih alur pengajuan → verifikasi/disposisi → survei/unggah → persetujuan → penebusan.
- [ ] Pastikan QR diuji hanya dengan token Petani pemilik, koordinat uji yang disepakati, dan foto sintetis yang jelas ditandai.
- [ ] Siapkan rekaman/screenshot dari data sintetis jika internet/demo langsung tidak tersedia; beri label **DEMO**.
- [ ] Sampaikan batasan role Kios, alur poligon Flutter yang terpisah, dan status uji perangkat nyata secara terbuka.
- [ ] Catat hasil, tanggal, versi aplikasi, perangkat, OS, dan masalah yang ditemukan; jangan mengarang persentase progres.
