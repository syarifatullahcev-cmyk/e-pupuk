# LAPORAN REKAPITULASI HASIL PENGUJIAN USABILITAS (SUS) & BLACK-BOX TESTING
**Sistem Informasi Pengajuan Subsidi Pupuk Kabupaten Mojokerto (E-Pupuk)**  
*Sumber Data: Google Spreadsheet Tanggapan Responden ([Link Spreadsheet](https://docs.google.com/spreadsheets/d/1Sd_IVvSoHojbggP7sOCH9ARRcw1OMflwt4xnYP1kyBc/edit?usp=sharing))*  
*Waktu Rekapitulasi: 26 November 2026*

---

## 1. Ringkasan Eksekutif Hasil Pengujian

| Parameter Pengujian | Hasil Pengujian | Keterangan / Standar Acuan |
| :--- | :---: | :--- |
| **Jumlah Responden** | **5 Responden** | Petani/Poktan (4), Siswa/Mahasiswa Peneliti (1) |
| **Rata-rata Skor SUS** | **77,00 / 100** | Di atas rata-rata industri (*Industry Average* = 68,0) |
| **Grade Skala (*Grade Scale*)** | **Grade B** | Sangat Layak (*Bangor et al., 2008*) |
| **Predikat Mutu (*Adjective*)** | **Good** | Baik & Diterima Pengguna |
| **Tingkat Penerimaan (*Acceptability*)** | **Acceptable** | Dapat Diterima Penuh oleh Pengguna Akhir |
| **Tingkat Keberhasilan *Black-box*** | **100,00%** | Seluruh skenario berhasil dieksekusi (0% Gagal) |
| **Kemandirian Skenario (*Without Assist*)** | **76,67%** | 23 dari 30 pengujian selesai sempurna tanpa bantuan |

---

## 2. Rincian Rekap Skor SUS Tiap Responden

Perhitungan kontribusi skor SUS mengacu pada formula standar John Brooke (1986):
* **Item Ganjil (Positif: Q1, Q3, Q5, Q7, Q9):** $\text{Skor Kontribusi} = \text{Nilai Jawaban} - 1$
* **Item Genap (Negatif: Q2, Q4, Q6, Q8, Q10):** $\text{Skor Kontribusi} = 5 - \text{Nilai Jawaban}$
* **Total Skor SUS:** $\left(\sum \text{Skor Kontribusi}\right) \times 2{,}5$

| No | Nama Responden | Peran / Status | Kecamatan | Nilai Mentah [Q1–Q10] | Skor Kontribusi [Q1–Q10] | Total Skor | Grade | Adjective |
| :-: | :--- | :--- | :--- | :---: | :---: | :-: | :-: | :---: |
| 1 | **Neha Anggreany Octavia** | Siswa / Peneliti | Luar Mojokerto | `[4, 2, 4, 2, 4, 2, 5, 3, 5, 2]` | `[3, 3, 3, 3, 3, 3, 4, 2, 4, 3]` | **77,50** | **Grade B** | Good |
| 2 | **Syarifatullah Ceva Efendy** | Petani / Poktan | Dawarblandong | `[5, 1, 4, 1, 5, 1, 4, 2, 5, 3]` | `[4, 4, 3, 4, 4, 4, 3, 3, 4, 2]` | **87,50** | **Grade A** | Excellent |
| 3 | **Aris** | Petani / Poktan | Mojosari | `[5, 2, 4, 2, 4, 2, 5, 1, 5, 1]` | `[4, 3, 3, 3, 3, 3, 4, 4, 4, 4]` | **87,50** | **Grade A** | Excellent |
| 4 | **Dimas** | Petani / Poktan | Kemlagi | `[4, 3, 3, 3, 4, 3, 3, 2, 3, 3]` | `[3, 2, 2, 2, 3, 2, 2, 3, 2, 2]` | **57,50** | **Grade D** | OK (Marginal) |
| 5 | **Hikam** | Petani / Poktan | Mojoanyar | `[5, 3, 4, 3, 5, 2, 5, 3, 4, 2]` | `[4, 2, 3, 2, 4, 3, 4, 2, 3, 3]` | **75,00** | **Grade B** | Good |
| \- | **RATA-RATA KESELURUHAN** | - | - | - | - | **77,00** | **Grade B** | **Good** |

---

## 3. Analisis Skor Rata-rata per Butir Pertanyaan (Q1–Q10)

| No | Tipe | Pernyataan Instrumen SUS | Rata-rata Nilai (1–5) | Rata-rata Kontribusi (0–4) | Interpretasi Responden |
| :-: | :---: | :--- | :---: | :---: | :--- |
| **Q1** | Positif | Keinginan sering menggunakan sistem E-Pupuk | **4,60** | 3,60 | Sangat tinggi, petani antusias menggunakan sistem |
| **Q2** | Negatif | Sistem terasa terlalu rumit | **2,20** | 2,80 | Rendah, sistem dinilai tidak berbelit-belit |
| **Q3** | Positif | Antarmuka mudah digunakan bagi orang awam | **3,80** | 2,80 | Cukup baik, navigasi dinilai mudah dipahami |
| **Q4** | Negatif | Membutuhkan bantuan teknis orang lain | **2,20** | 2,80 | Rendah, sebagian besar dapat mengoperasikan mandiri |
| **Q5** | Positif | Fitur-fitur terintegrasi dengan sangat baik | **4,40** | 3,40 | Sangat tinggi, keterpaduan fitur dinilai solid |
| **Q6** | Negatif | Terlalu banyak inkonsistensi antarmuka | **2,00** | 3,00 | Sangat rendah, desain dinilai konsisten |
| **Q7** | Positif | Pengguna baru dapat belajar dengan cepat | **4,40** | 3,40 | Sangat tinggi, alur mudah dipelajari rekan petani |
| **Q8** | Negatif | Sistem membingungkan saat pertama dicoba | **2,20** | 2,80 | Rendah, kebingungan minimal |
| **Q9** | Positif | Percaya diri saat mengoperasikan sistem | **4,40** | 3,40 | Sangat tinggi, pengguna yakin dengan aksinya |
| **Q10** | Negatif | Perlu belajar banyak hal sebelum lancar | **2,20** | 2,80 | Rendah, kurva belajar sistem cukup landai |

---

## 4. Rekapitulasi Pengujian Fungsional Black-Box Testing (6 Skenario)

| Skenario Pengujian | Sempurna | Dengan Bantuan | Gagal | Tingkat Keberhasilan |
| :--- | :---: | :---: | :---: | :---: |
| **Skenario 1:** Registrasi & Login Multi-Peran (RBAC) | 4 | 1 | 0 | **100,00%** |
| **Skenario 2:** Pengecekan Alokasi Kuota Pupuk Subsidi (e-RDKK) | 4 | 1 | 0 | **100,00%** |
| **Skenario 3:** Form Pengajuan Kebutuhan & Geotagging Poligon Lahan | 5 | 0 | 0 | **100,00%** |
| **Skenario 4:** Verifikasi Lapangan & Survei Faktual (Peran PPL) | 4 | 1 | 0 | **100,00%** |
| **Skenario 5:** Penerbitan Bukti Digital & Scan QR Code Kios | 3 | 2 | 0 | **100,00%** |
| **Skenario 6:** Modul Pelaporan Kendala Lapangan Siswa (Stepper) | 3 | 2 | 0 | **100,00%** |
| **TOTAL AGREGAT (30 Pengujian)** | **23 (76,67%)** | **7 (23,33%)** | **0 (0,00%)** | **100,00%** |

---

## 5. Rekapitulasi Kendala Faktual & Saran Responden

1. **Kode QR & Penebusan Kios (Syarifatullah Ceva Efendy):**
   * *Kendala:* Pemindaian kode QR terkadang membutuhkan pencahayaan yang cukup saat diuji coba.
   * *Saran:* Optimalisasi kontras tampilan QR code agar lebih responsif dibaca scanner kamera.
2. **Kinerja & Komputasi Backend (Aris - Mojosari):**
   * *Kendala:* Sistem secara umum sudah cukup baik.
   * *Saran:* Penyempurnaan pada sisi UI serta pereduksian beban komputasi/latensi respons di sisi backend.
3. **Panduan Awal untuk Pengguna Awam (Dimas - Kemlagi):**
   * *Kendala:* Sebagai pengguna awam yang baru pertama kali mencoba, sempat bingung mengenai langkah awal memulai pengajuan subsidi.
   * *Saran:* Ditambahkan fitur *onboarding guide* / langkah-langkah petunjuk penggunaan awal (*guided walkthrough*) saat pertama kali membuka aplikasi.
4. **Konsistensi Navigasi Mobile (Hikam - Mojoanyar):**
   * *Kendala:* Tampilan navigasi bilah bawah (*bottom navbar*) sempat terasa kurang konsisten di beberapa layar tertentu.
   * *Saran:* Penyeragaman letak navbar pada semua portal peran.
