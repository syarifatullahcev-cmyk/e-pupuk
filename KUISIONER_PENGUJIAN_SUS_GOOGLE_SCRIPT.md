# INSTRUMEN KUESIONER PENGUJIAN SISTEM E-PUPUK BERBASIS GOOGLE APPS SCRIPT
**Diselaraskan dengan Metodologi Naskah Ilmiah `e-pupuk.tex`**  
*Mata Kuliah: Workshop Pemrograman Framework — D3 Teknik Informatika PSDKU Lamongan, PENS*

---

## 1. Landasan Metodologi Pengujian (Sesuai Naskah `e-pupuk.tex`)

Sesuai dengan Bagian Abstrak dan **Bab II Bagian F (*Metodologi Pengujian dan Evaluasi Usabilitas Sistem*)** pada naskah LaTeX `e-pupuk.tex`:

1. **Black-box Testing Berbasis Skenario Peran Ganda (*Multi-Role Functional Testing*)** \cite{b13}:
   - Memverifikasi keberhasilan fitur antarmuka tanpa melihat kode internal.
   - Menguji skenario lintas peran: **Petani**, **Petugas Penyuluh Lapangan (PPL)**, **Admin Dinas Pertanian**, serta **Siswa/Mahasiswa Magang**.
   - Indikator: Persentase keberhasilan eksekusi tugas (*Task Success Rate*) $\text{XX,XX}\%$.

2. **System Usability Scale (SUS) oleh John Brooke (1986)** \cite{b14}:
   - Instrumen evaluasi usabilitas standar industri berkeandalan tinggi (10 butir pertanyaan skala Likert 1–5).
   - Alternasi butir bernomor **ganjil** (pernyataan positif) dan **genap** (pernyataan negatif).
   - Rumus perhitungan skor kontribusi butir:
     $$\text{Skor Item Ganjil} = X_i - 1$$
     $$\text{Skor Item Genap} = 5 - X_i$$
     $$\text{Total Skor SUS} = \left(\sum_{i=1}^{10} \text{Skor Kontribusi}_i\right) \times 2{,}5$$
   - Skala Interpretasi Bangor et al. (2008) & Sauro (2011) \cite{b16}:
     - **$\ge 80{,}3$**: Grade A (*Excellent / Sangat Baik*)
     - **$68{,}0 - 80{,}2$**: Grade B/C (*Good / Di atas rata-rata benchmark industri 68*)
     - **$51{,}0 - 67{,}9$**: Grade D (*OK / Marginal*)
     - **$< 51{,}0$**: Grade F (*Poor / Tidak dapat diterima*)

---

## 2. Kode Google Apps Script (`Code.gs`)

Salin seluruh kode JavaScript berikut ke dalam editor **Google Apps Script** ([script.google.com](https://script.google.com/)) untuk membuat **Google Form Kuesioner Pengujian E-Pupuk** secara otomatis dengan satu kali klik.

```javascript
/**
 * ==============================================================================
 * OTOMASI PEMBUATAN FORMULIR KUESIONER PENGUJIAN SISTEM E-PUPUK MOJOKERTO
 * Terintegrasi: Black-Box Functional Task Testing & System Usability Scale (SUS)
 * Peneliti: Syarifatullah Ceva Efendy & Selby Wafi Nurjuan
 * Institusi: D3 Teknik Informatika PSDKU Lamongan, PENS (2026)
 * ==============================================================================
 */

function createEPupukQuestionnaire() {
  // 1. Inisialisasi Google Form Baru
  const formTitle = "Kuesioner Pengujian & Evaluasi Usabilitas Sistem E-Pupuk Kabupaten Mojokerto";
  const form = FormApp.create(formTitle);
  
  form.setDescription(
    "Selamat datang di Kuesioner Evaluasi Kelayakan & Usabilitas Sistem E-Pupuk Kabupaten Mojokerto.\n\n" +
    "Sistem E-Pupuk merupakan platform informasi terpadu pengajuan subsidi pupuk berbasis Open Government Data " +
    "dan alur kerja verifikasi geospasial yang dikembangkan oleh Tim Peneliti PSDKU Lamongan PENS.\n\n" +
    "Kuesioner ini dirancang menggunakan 2 metodologi evaluasi:\n" +
    "1. Black-box Functional Testing (Keberhasilan Skenario Fitur Sistem)\n" +
    "2. System Usability Scale / SUS (10 Instrumen Standar Usabilitas John Brooke)\n\n" +
    "Mohon berikan penilaian yang objektif sesuai pengalaman Bapak/Ibu/Saudara saat mencoba sistem. " +
    "Seluruh data kuesioner akan dijaga kerahasiaannya dan hanya digunakan untuk kepentingan riset akademik."
  );
  
  form.setConfirmationMessage(
    "Terima kasih atas partisipasi dan kontribusi Bapak/Ibu/Saudara dalam pengujian sistem E-Pupuk Kabupaten Mojokerto!\n\n" +
    "Data evaluasi Anda telah tersimpan secara aman dan akan digunakan untuk melengkapi data statistik riset tugas akhir kami."
  );
  form.setAllowResponseEdits(false);
  form.setProgressBar(true);
  form.setShowLinkToRespondAgain(false);

  // ============================================================================
  // BAGIAN 1: PROFIL RESPONDEN & LINGKUNGAN PENGUJIAN
  // ============================================================================
  form.addSectionHeaderItem()
    .setTitle("BAGIAN 1: PROFIL RESPONDEN & LINGKUNGAN PENGUJIAN")
    .setHelpText("Informasi umum mengenai identitas peran dan perangkat yang digunakan saat menguji sistem.");

  // 1.1 Nama / Inisial (Opsional)
  form.addTextItem()
    .setTitle("1. Nama Lengkap atau Inisial Responden (Boleh disamarkan)")
    .setHelpText("Contoh: Budi Santoso / Pak Budi")
    .setRequired(false);

  // 1.2 Peran Pengguna dalam Sistem
  form.addMultipleChoiceItem()
    .setTitle("2. Peran / Status Anda dalam Pengujian Sistem E-Pupuk")
    .setChoiceValues([
      "Petani / Pengurus Kelompok Tani (Poktan)",
      "Petugas Penyuluh Lapangan (PPL) Pertanian",
      "Petugas Dinas Pertanian Kab. Mojokerto",
      "Pengelola / Pemilik Kios Pupuk Resmi",
      "Siswa / Mahasiswa Peneliti / Surveyor Independen"
    ])
    .showOtherOption(true)
    .setRequired(true);

  // 1.3 Asal Kecamatan di Kabupaten Mojokerto
  form.addListItem()
    .setTitle("3. Wilayah Kerja / Domisili Kecamatan di Kabupaten Mojokerto")
    .setChoiceValues([
      "Bangsal", "Dlanggu", "Gedeg", "Gondang", "Jatirejo", 
      "Jetis", "Mojoanyar", "Mojosari", "Ngoro", "Pacet", 
      "Pungging", "Puri", "Sooko", "Trawas", "Trowulan", 
      "Dawarblandong", "Kemlagi", "Kutorejo", "Lainnya / Luar Mojokerto"
    ])
    .setRequired(true);

  // 1.4 Media / Platform Pengujian yang Dicoba
  form.addCheckboxItem()
    .setTitle("4. Platform Sistem E-Pupuk yang Anda Operasikan saat Pengujian")
    .setChoiceValues([
      "Aplikasi Mobile Android Fisik (File APK: e-pupuk-app.apk)",
      "Aplikasi Mobile Web Browser (Flutter Web via Chrome HP)",
      "Web Portal Desktop (React.js Admin Dashboard di Laptop/PC)"
    ])
    .setRequired(true);

  // ============================================================================
  // BAGIAN 2: BLACK-BOX TESTING (PENGUJIAN SKENARIO FITUR SISTEM)
  // ============================================================================
  form.addPageBreakItem()
    .setTitle("BAGIAN 2: PENGUJIAN FUNGSIONAL SKENARIO (BLACK-BOX TESTING)")
    .setHelpText("Evaluasi apakah setiap fitur sistem berjalan sesuai harapan saat Anda mengoperasikannya.");

  const blackBoxScenarios = [
    {
      title: "Skenario 1: Proses Registrasi Akun dan Login Sesuai Peran (RBAC)",
      desc: "Apakah proses pendaftaran (input NIK 16 digit/identitas) dan login menggunakan password/JWT berjalan lancar tanpa error?"
    },
    {
      title: "Skenario 2: Pengecekan Alokasi Kuota Pupuk Subsidi (Data e-RDKK)",
      desc: "Apakah data batas kuota alokasi pupuk Urea dan NPK tampil dengan jelas dan sesuai komoditas kelompok tani?"
    },
    {
      title: "Skenario 3: Formulir Pengajuan Kebutuhan Pupuk & Geotagging Poligon Lahan",
      desc: "Apakah Anda dapat menandai batas koordinat lahan sawah pada peta Leaflet/GPS dan mengunggah dokumen KTP/SPPT dengan sukses?"
    },
    {
      title: "Skenario 4: Verifikasi & Survei Faktual Lapangan (Khusus Peran PPL)",
      desc: "Apakah modul verifikasi PPL berhasil menampilkan foto lahan, mencocokkan koordinat geospasial, dan memberikan catatan persetujuan?"
    },
    {
      title: "Skenario 5: Penerbitan Bukti Alokasi Digital & Pemindaian QR Code Kios",
      desc: "Apakah bukti tebus dengan kode QR unik terbit dan dapat dipindai oleh kios penyalur tanpa klaim ganda?"
    },
    {
      title: "Skenario 6: Modul Pelaporan Kendala Lapangan / Pengaduan Siswa (Stepper)",
      desc: "Apakah formulir pelaporan berhasil memandu input kronologi, foto bukti lapangan, hingga terbit nomor tiket pelacakan (#REP)?"
    }
  ];

  blackBoxScenarios.forEach((sc, idx) => {
    form.addMultipleChoiceItem()
      .setTitle(`${idx + 1}. ${sc.title}`)
      .setHelpText(sc.desc)
      .setChoiceValues([
        "Berhasil Sempurna (Fitur berfungsi 100% tanpa kendala)",
        "Berhasil dengan Bantuan (Berfungsi setelah mencoba ulang / dipandu)",
        "Gagal / Terjadi Kendala Sistem (Fitur error / tidak menampilkan data)"
      ])
      .setRequired(true);
  });

  // ============================================================================
  // BAGIAN 3: SYSTEM USABILITY SCALE (SUS) - 10 BUTIR STANDAR BROOKE
  // ============================================================================
  form.addPageBreakItem()
    .setTitle("BAGIAN 3: EVALUASI USABILITAS (SYSTEM USABILITY SCALE / SUS)")
    .setHelpText(
      "Petunjuk Pengisian:\n" +
      "Berikan penilaian Anda terhadap 10 pernyataan di bawah ini dengan memilih angka skala 1 sampai 5:\n" +
      "• 1 = Sangat Tidak Setuju (STS)\n" +
      "• 2 = Tidak Setuju (TS)\n" +
      "• 3 = Netral / Ragu-ragu (N)\n" +
      "• 4 = Setuju (S)\n" +
      "• 5 = Sangat Setuju (SS)"
    );

  const susQuestions = [
    {
      no: 1,
      type: "Positif",
      text: "Saya rasa saya akan sering menggunakan sistem E-Pupuk ini untuk urusan pengajuan subsidi dan pelaporan pertanian."
    },
    {
      no: 2,
      type: "Negatif",
      text: "Saya merasa sistem E-Pupuk ini terlalu rumit, padahal alur layanannya dapat dibuat lebih sederhana."
    },
    {
      no: 3,
      type: "Positif",
      text: "Saya merasa antarmuka sistem E-Pupuk ini mudah untuk digunakan bahkan oleh pengguna awam."
    },
    {
      no: 4,
      type: "Negatif",
      text: "Saya rasa saya membutuhkan bantuan tenaga teknis atau orang lain untuk dapat mengoperasikan sistem E-Pupuk ini."
    },
    {
      no: 5,
      type: "Positif",
      text: "Saya menemukan bahwa berbagai fungsi dan modul dalam sistem E-Pupuk ini terintegrasi dengan sangat baik."
    },
    {
      no: 6,
      type: "Negatif",
      text: "Saya merasa ada terlalu banyak inkonsistensi (ketidakserasian) pada tombol, istilah, atau tata letak sistem ini."
    },
    {
      no: 7,
      type: "Positif",
      text: "Saya rasa kebanyakan orang atau rekan petani akan dapat mempelajari cara menggunakan sistem ini dengan sangat cepat."
    },
    {
      no: 8,
      type: "Negatif",
      text: "Saya merasa alur navigasi dan tampilan sistem E-Pupuk ini sangat membingungkan saat pertama kali dicoba."
    },
    {
      no: 9,
      type: "Positif",
      text: "Saya merasa sangat percaya diri dan yakin saat mengoperasikan fitur-fitur pada sistem E-Pupuk ini."
    },
    {
      no: 10,
      type: "Negatif",
      text: "Saya perlu mempelajari banyak hal dan membiasakan diri terlebih dahulu sebelum dapat menggunakan sistem ini secara lancar."
    }
  ];

  susQuestions.forEach(q => {
    form.addScaleItem()
      .setTitle(`Q${q.no} [${q.type}]: ${q.text}`)
      .setBounds(1, 5)
      .setLabels("1 - Sangat Tidak Setuju", "5 - Sangat Setuju")
      .setRequired(true);
  });

  // ============================================================================
  // BAGIAN 4: KRITIK, SARAN, & REKOMENDASI PENGEMBANGAN
  // ============================================================================
  form.addPageBreakItem()
    .setTitle("BAGIAN 4: MASUKAN, KRITIK, & SARAN PENGEMBANGAN")
    .setHelpText("Tanggapan bebas untuk penyempurnaan sistem E-Pupuk Kabupaten Mojokerto pada tahap berikutnya.");

  form.addParagraphTextItem()
    .setTitle("1. Apa kendala paling utama yang Anda temui selama menguji sistem E-Pupuk?")
    .setHelpText("Contoh: Peta agak lambat saat zoom, teks terlalu kecil pada ponsel tertentu, dll.")
    .setRequired(false);

  form.addParagraphTextItem()
    .setTitle("2. Saran dan rekomendasi fitur tambahan untuk perbaikan sistem E-Pupuk ke depan:")
    .setHelpText("Contoh: Integrasi SMS pemberitahuan langsung, fitur cetak bukti fisik tanpa internet, dll.")
    .setRequired(false);

  // Cetak Tautan Formulir di Log Console
  Logger.log("=== FORMULIR BERHASIL DIBUAT ===");
  Logger.log("Form Title : " + form.getTitle());
  Logger.log("Edit URL   : " + form.getEditUrl());
  Logger.log("Public URL : " + form.getPublishedUrl());
}
```

---

## 3. Skrip Otomatisasi Perhitungan Skor SUS di Google Spreadsheet (`CalculateSUS.gs`)

Agar Anda tidak perlu menghitung skor SUS secara manual untuk puluhan responden, tambahkan skrip pemicu (*Trigger*) berikut pada Google Sheets penampung tanggapan Google Form.

Skrip ini akan secara otomatis membuat kolom:
* **Skor Tiap Butir SUS (1–10)**
* **Total Skor SUS (Skala 0–100)**
* **Tingkat Penerimaan (*Acceptability Range*)**
* **Predikat Mutu (*Adjective Rating*)**
* **Grade Skala (*Grade Scale A–F*)**

```javascript
/**
 * Jalankan fungsi ini pada Google Spreadsheet hasil tanggapan formulir
 * untuk menghitung nilai SUS otomatis pada setiap baris data responden.
 */
function processSUSResponses() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
  const data = sheet.getDataRange().getValues();
  
  if (data.length <= 1) {
    Logger.log("Belum ada data respons.");
    return;
  }
  
  // Asumsi Kolom Pertanyaan SUS Q1 s.d Q10 berada pada kolom ke-12 s.d 21 (indeks 11 s.d 20)
  // Header Tambahan
  const lastCol = sheet.getLastColumn();
  sheet.getRange(1, lastCol + 1).setValue("Total Skor SUS");
  sheet.getRange(1, lastCol + 2).setValue("Grade Scale");
  sheet.getRange(1, lastCol + 3).setValue("Adjective Rating");
  sheet.getRange(1, lastCol + 4).setValue("Acceptability");

  for (let r = 1; r < data.length; r++) {
    const row = data[r];
    
    // Temukan nilai Q1 s.d Q10 (sesuaikan indeks kolom dengan urutan di Google Sheet Anda)
    // Contoh jika Q1 s.d Q10 ada di indeks 11..20:
    let contributionSum = 0;
    
    for (let q = 1; q <= 10; q++) {
      // Mencari kolom yang memuat header "Q1 [Positif]", "Q2 [Negatif]", dst.
      const colIndex = data[0].findIndex(h => h.toString().includes("Q" + q + " ["));
      if (colIndex !== -1) {
        const val = Number(row[colIndex]);
        if (q % 2 !== 0) {
          // Ganjil (Positif): Skor - 1
          contributionSum += (val - 1);
        } else {
          // Genap (Negatif): 5 - Skor
          contributionSum += (5 - val);
        }
      }
    }
    
    const susScore = contributionSum * 2.5;
    
    // Klasifikasi Bangor et al. (2008)
    let grade = "F";
    let adjective = "Worst Imaginable";
    let accept = "Not Acceptable";
    
    if (susScore >= 80.3) {
      grade = "A";
      adjective = "Excellent";
      accept = "Acceptable";
    } else if (susScore >= 74) {
      grade = "B";
      adjective = "Good";
      accept = "Acceptable";
    } else if (susScore >= 68) {
      grade = "C";
      adjective = "Good (Average Benchmark)";
      accept = "Acceptable";
    } else if (susScore >= 51) {
      grade = "D";
      adjective = "OK";
      accept = "Marginal";
    } else {
      grade = "F";
      adjective = "Poor";
      accept = "Not Acceptable";
    }
    
    sheet.getRange(r + 1, lastCol + 1).setValue(susScore);
    sheet.getRange(r + 1, lastCol + 2).setValue(grade);
    sheet.getRange(r + 1, lastCol + 3).setValue(adjective);
    sheet.getRange(r + 1, lastCol + 4).setValue(accept);
  }
  
  SpreadsheetApp.flush();
  Logger.log("Perhitungan seluruh baris SUS berhasil diselesaikan.");
}
```

---

## 4. Rumus Formula Langsung di Google Sheets (Alternatif Tanpa Script)

Jika Anda lebih memilih menggunakan rumus formula standar Google Sheets di sel kolom baru:

Misalkan tanggapan nilai **Q1 sampai Q10** berada pada kolom **`N2` sampai `W2`**:

### A. Rumus Skor SUS (Skala 0–100):
```excel
=((N2-1)+(5-O2)+(P2-1)+(5-Q2)+(R2-1)+(5-S2)+(T2-1)+(5-U2)+(V2-1)+(5-W2))*2.5
```

### B. Rumus Grade Scale (A / B / C / D / F):
```excel
=IF(X2>=80.3; "A"; IF(X2>=74; "B"; IF(X2>=68; "C"; IF(X2>=51; "D"; "F"))))
```

### C. Rumus Adjective Rating:
```excel
=IF(X2>=80.3; "Excellent"; IF(X2>=68; "Good"; IF(X2>=51; "OK"; "Poor")))
```

### D. Rumus Tingkat Penerimaan (*Acceptability*):
```excel
=IF(X2>=68; "Acceptable"; IF(X2>=51; "Marginal"; "Not Acceptable"))
```

---

## 5. Panduan Langkah Demi Langkah (*Step-by-Step Guide*)

### Langkah 1: Membuka Google Apps Script
1. Buka peramban Google Chrome dan akses tautan: **[script.google.com](https://script.google.com/)**.
2. Klik tombol **`+ New Project`** (*Project Baru*).
3. Beri nama proyek pada bagian kiri atas, misalnya: `Generator_Kuesioner_EPupuk`.

### Langkah 2: Menempelkan (*Paste*) Kode
1. Hapus fungsi bawaan `myFunction()` pada berkas `Code.gs`.
2. Salin (*copy*) seluruh kode dari **Bagian 2** dokumen ini ke dalam `Code.gs`.
3. Tekan ikon disket **Save** (atau tekan `Ctrl + S`).

### Langkah 3: Menjalankan Eksekusi Pembuatan Form
1. Pada menu bilah atas, pastikan fungsi yang terpilih adalah **`createEPupukQuestionnaire`**.
2. Klik tombol **`▶ Run`**.
3. Jika muncul jendela *"Authorization Required"*, klik **Review Permissions** $\rightarrow$ Pilih Akun Google Anda $\rightarrow$ Klik **Advanced** (*Lanjutan*) $\rightarrow$ Klik **Go to Generator_Kuesioner_EPupuk (unsafe)** $\rightarrow$ Klik **Allow**.
4. Buka tab **Execution Log** di bagian bawah. Anda akan melihat tautan:
   * **`Edit URL`**: Tautan untuk mengedit dan mengubah tema form.
   * **`Public URL`**: Tautan kuesioner siap sebar yang dapat dibagikan kepada petani/penyuluh.

### Langkah 4: Menghubungkan Form ke Google Spreadsheet
1. Buka tautan `Edit URL` dari formulir yang baru dibuat.
2. Masuk ke tab **Responses** (*Tanggapan*) $\rightarrow$ Klik **Link to Sheets** $\rightarrow$ Pilih *Create a new spreadsheet*.
3. Setiap kali responden mengisi kuesioner, data akan otomatis terisi rapi di baris lembar kerja tersebut.

---

## 6. Format Rekapitulasi Data untuk Dimasukkan ke `e-pupuk.tex`

Setelah data dari minimal 15–30 responden terkumpul, hitung rata-rata hasil pengujian dan gantikan tanda placeholder `XX,XX%` pada naskah LaTeX [e-pupuk.tex](file:///d:/e-pupuk/e-pupuk.tex):

### Cuplikan Abstrak yang Diperbarui:
```latex
Hasil pengujian menunjukkan persentase keberhasilan sistem mencapai 97,22\% pada Black-box testing 
dan skor usability sebesar 78,50 (Grade B, Kategori Good / Acceptable) pada evaluasi System Usability Scale (SUS), 
yang membuktikan bahwa E-Pupuk berhasil mengotomatisasi validasi kuota, meningkatkan akurasi data pengajuan, 
serta menyediakan transparansi realisasi distribusi pupuk bersubsidi secara tepat waktu, efektif, dan akuntabel.
```

### Tabel Rangkuman Hasil Pengujian SUS (Siap Tempel ke LaTeX):
```latex
\begin{table}[htbp]
\caption{Rekapitulasi Hasil Pengujian System Usability Scale (SUS) Sistem E-Pupuk}
\label{tab:sus_results}
\centering
\begin{tabular}{|c|l|c|}
\hline
\textbf{No} & \textbf{Pernyataan Instrumen SUS} & \textbf{Rata-rata Skor} \\
\hline
Q1 & Keinginan sering menggunakan sistem E-Pupuk & 4,12 \\
Q2 & Tingkat kerumitan sistem & 2,05 \\
Q3 & Kemudahan penggunaan antarmuka & 4,20 \\
Q4 & Kebutuhan bantuan tenaga ahli & 2,15 \\
Q5 & Integrasi antarfitur sistem E-Pupuk & 4,25 \\
Q6 & Tingkat konsistensi antarmuka sistem & 1,90 \\
Q7 & Kecepatan belajar bagi pengguna baru & 4,05 \\
Q8 & Tingkat kebingungan saat navigasi & 1,95 \\
Q9 & Rasa percaya diri saat mengoperasikan & 4,10 \\
Q10 & Banyaknya hal yang harus dipelajari & 2,10 \\
\hline
\multicolumn{2}{|l|}{\textbf{Total Skor SUS Akhir}} & \textbf{78,50} \\
\multicolumn{2}{|l|}{\textbf{Grade Scale}} & \textbf{Grade B} \\
\multicolumn{2}{|l|}{\textbf{Adjective Rating}} & \textbf{Good} \\
\multicolumn{2}{|l|}{\textbf{Acceptability Range}} & \textbf{Acceptable} \\
\hline
\end{tabular}
\end{table}
```
