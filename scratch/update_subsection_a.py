import re

target_block = r"""\subsection{Arsitektur Sistem dan Alur Pemrosesan Kasus}
Arsitektur sistem E-Pupuk dibangun mengadopsi pola \textit{decoupled multi-tier architecture} yang memisahkan antarmuka pengguna (\textit{frontend}), logika bisnis \textit{backend REST API}, modul inferensi kecerdasan artifisial, serta penyimpanan data terpusat \cite{b1}, \cite{b14}, \cite{b15}. Alur pemrosesan kasus pengajuan subsidi pupuk dan validasi laporan operasional berlangsung melalui rangkaian proses yang saling terhubung.

Proses diawali dengan pengguna mengunggah data permohonan melalui antarmuka web reaktif \cite{b14} atau aplikasi mobile berbasis formulir terstruktur dengan validasi skema data seketika menggunakan Pydantic \cite{b18}. Data mencakup nomor identitas kependudukan (NIK), keanggotaan kelompok tani (Poktan), komoditas tanaman, serta koordinat poligon batas lahan pertanian via Leaflet GIS \cite{b16}.

Selanjutnya, sistem memproses data masukan terhadap dataset terbuka pemerintah alokasi RDKK tingkat kecamatan. Mesin aturan (\textit{rule engine}) melakukan verifikasi batas kuota pupuk (Urea dan NPK) berdasarkan luas baku lahan yang diajukan untuk mendeteksi potensi anomali volume permohonan \cite{b17}.

Kasus permohonan yang lolos validasi awal diteruskan ke dasbor kerja Petugas Penyuluh Lapangan (PPL). Petugas melakukan survei faktual di lapangan, mencocokkan koordinat geospasial lahan, memeriksa kondisi riil vegetasi tanaman, dan memberikan rekomendasi persetujuan (\textit{approval}) atau penolakan dengan catatan revisi berjenjang.

Setelah rekomendasi PPL diberikan, permohonan divalidasi oleh Dinas Pertanian untuk kemudian diterbitkan bukti alokasi digital memuat \textit{dynamic QR Code token} berbasis enkripsi SHA-256 dan protokol stateless JWT \cite{b2}. Token ini mengunci identitas penerima dan kuota tebus guna mencegah klaim ganda di tingkat kios penyalur.

Terakhir, seluruh riwayat perubahan status kasus disimpan ke dalam basis data relasional PostgreSQL dengan pencatatan stempel waktu (\textit{timestamp}) dan jejak audit (\textit{audit trail}) yang transparan \cite{b13}."""

replacement_block = r"""\subsection{Arsitektur Sistem dan Alur Pemrosesan Kasus}
Arsitektur sistem E-Pupuk dibangun mengadopsi pola \textit{decoupled multi-tier architecture} yang memisahkan antarmuka pengguna (\textit{frontend}), logika bisnis \textit{backend REST API}, modul inferensi kecerdasan artifisial, serta penyimpanan data terpusat \cite{b1}, \cite{b14}, \cite{b15}. Alur pemrosesan kasus pengajuan subsidi pupuk dan validasi laporan operasional dirancang mengikuti siklus terstruktur yang terdiri atas lima tahapan:
\begin{enumerate}
    \item Pengguna mengunggah data permohonan melalui antarmuka web reaktif \cite{b14} atau aplikasi mobile berbasis formulir terstruktur dengan validasi skema data seketika menggunakan Pydantic \cite{b18}. Data mencakup nomor identitas kependudukan (NIK), keanggotaan kelompok tani (Poktan), komoditas tanaman, serta koordinat poligon batas lahan pertanian via Leaflet GIS \cite{b16}.
    \item Sistem memproses data masukan terhadap dataset terbuka pemerintah alokasi RDKK tingkat kecamatan. Mesin aturan (\textit{rule engine}) melakukan verifikasi batas kuota pupuk (Urea dan NPK) berdasarkan luas baku lahan yang diajukan untuk mendeteksi potensi anomali volume permohonan \cite{b17}.
    \item Kasus permohonan yang lolos validasi awal diteruskan ke dasbor kerja Petugas Penyuluh Lapangan (PPL). Petugas melakukan survei faktual di lapangan, mencocokkan koordinat geospasial lahan, memeriksa kondisi riil vegetasi tanaman, dan memberikan rekomendasi persetujuan (\textit{approval}) atau penolakan dengan catatan revisi berjenjang.
    \item Permohonan yang disetujui PPL divalidasi oleh Dinas Pertanian untuk kemudian diterbitkan bukti alokasi digital memuat \textit{dynamic QR Code token} berbasis enkripsi SHA-256 dan protokol stateless JWT \cite{b2}. Token ini mengunci identitas penerima dan kuota tebus guna mencegah klaim ganda di tingkat kios penyalur.
    \item Seluruh riwayat perubahan status kasus disimpan ke dalam basis data relasional PostgreSQL dengan pencatatan stempel waktu (\textit{timestamp}) dan jejak audit (\textit{audit trail}) yang transparan \cite{b13}.
\end{enumerate}"""

for fn in ['e-pupuk.tex', 'conference_101719.tex']:
    with open(fn, 'r', encoding='utf-8') as f:
        content = f.read()

    # Normalize CRLF
    is_crlf = '\r\n' in content
    t = target_block.replace('\r\n', '\n')
    r = replacement_block.replace('\r\n', '\n')
    if is_crlf:
        t = t.replace('\n', '\r\n')
        r = r.replace('\n', '\r\n')

    count = content.count(t)
    if count == 0:
        print(f'Warning: target block not found in {fn}')
    else:
        content = content.replace(t, r)
        with open(fn, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f'Successfully updated {count} occurrences in {fn}')
