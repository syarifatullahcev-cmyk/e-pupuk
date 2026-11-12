import re

# Read the base tex
with open('e-pupuk.tex', 'r', encoding='utf-8') as f:
    text = f.read()

methodology_block = r"""\section{Methodology}
\label{sec:methodology}

\subsection{Arsitektur Sistem dan Alur Pemrosesan Kasus}
Arsitektur sistem E-Pupuk dibangun mengadopsi pola \textit{decoupled multi-tier architecture} yang memisahkan antarmuka pengguna (\textit{frontend}), logika bisnis \textit{backend REST API}, modul inferensi kecerdasan artifisial, serta penyimpanan data terpusat \cite{b1}, \cite{b14}, \cite{b15}. Alur pemrosesan kasus pengajuan subsidi pupuk dan validasi laporan operasional dirancang mengikuti siklus terstruktur yang terdiri atas lima tahapan utama:
\begin{enumerate}
    \item \textbf{Inisiasi dan Input Berkas Kasus:} Pengguna mengunggah data permohonan melalui antarmuka web reaktif \cite{b14} atau aplikasi mobile berbasis formulir terstruktur dengan validasi skema data seketika menggunakan Pydantic \cite{b18}. Data mencakup nomor identitas kependudukan (NIK), keanggotaan kelompok tani (Poktan), komoditas tanaman, serta koordinat poligon batas lahan pertanian via Leaflet GIS \cite{b16}.
    \item \textbf{Sinkronisasi dan Validasi Rule-based Kuota e-RDKK:} Sistem memproses data masukan terhadap dataset terbuka pemerintah alokasi RDKK tingkat kecamatan. Mesin aturan (\textit{rule engine}) melakukan verifikasi batas kuota pupuk (Urea dan NPK) berdasarkan luas baku lahan yang diajukan untuk mendeteksi potensi anomali volume permohonan \cite{b17}.
    \item \textbf{Disposisi dan Verifikasi Lapangan (PPL):} Kasus permohonan yang lolos validasi awal diteruskan ke dasbor kerja Petugas Penyuluh Lapangan (PPL). Petugas melakukan survei faktual di lapangan, mencocokkan koordinat geospasial lahan, memeriksa kondisi riil vegetasi tanaman, dan memberikan rekomendasi persetujuan (\textit{approval}) atau penolakan dengan catatan revisi berjenjang.
    \item \textbf{Otorisasi Eksekutif dan Penerbitan Token Kriptografis:} Permohonan yang disetujui PPL divalidasi oleh Dinas Pertanian untuk kemudian diterbitkan bukti alokasi digital memuat \textit{dynamic QR Code token} berbasis enkripsi SHA-256 dan protokol stateless JWT \cite{b2}. Token ini mengunci identitas penerima dan kuota tebus guna mencegah klaim ganda di tingkat kios penyalur.
    \item \textbf{Pencatatan Transaksi dan Audit Trail:} Seluruh riwayat perubahan status kasus disimpan ke dalam basis data relasional PostgreSQL dengan pencatatan stempel waktu (\textit{timestamp}) dan jejak audit (\textit{audit trail}) yang transparan \cite{b13}.
\end{enumerate}

\subsection{Rancangan User Flow Pelaporan Siswa}
Modul pelaporan dalam sistem E-Pupuk mengakomodasi peran siswa magang, mahasiswa peneliti vokasi pertanian (siswa pelapor lapangan), serta petani dalam menyampaikan laporan kendala operasional, laporan penyaluran pupuk, maupun pengaduan anomali data di wilayah kerja Kabupaten Mojokerto. Rancangan \textit{user flow} pelaporan dirancang responsif dan intuitif sesuai sepuluh prinsip heuristik usabilitas Nielsen \cite{b12}:
\begin{enumerate}
    \item \textbf{Tahap Autentikasi dan Pemilihan Modul:} Pengguna melakukan proses masuk (\textit{login}) dengan pengamanan RBAC dan token JWT \cite{b2}. Pada menu pelaporan, sistem menyajikan opsi kategori: (a) Pelaporan Lapangan / Survei Mandiri Siswa, (b) Pengaduan Kendala Kuota Petani, dan (c) Pelaporan Ketidaksesuaian Distribusi Kios.
    \item \textbf{Pengisian Formulir dan Bukti Geospasial:} Antarmuka menyajikan alur langkah (\textit{stepper wizard}) untuk memandu pengisian kronologi kasus, deskripsi narasi laporan, unggah foto bukti lapangan faktual, serta penandaan titik koordinat GPS interaktif \cite{b16}.
    \item \textbf{Pra-validasi dan Deteksi Anomali Seketika:} Sebelum laporan dikirim, sistem secara otomatis menjalankan sanitasi masukan teks, validasi format gambar, dan pemeriksaan duplikasi berkas laporan aktif guna menjamin integritas data pengaduan.
    \item \textbf{Konfirmasi Pengiriman dan Pelacakan Tiket:} Setelah laporan terkirim, sistem menghasilkan nomor tiket laporan unik (\textit{Report Tracking ID}). Siswa atau pelapor dapat memantau status tindak lanjut penanganan kasus (Diterima, Sedang Diverifikasi, Ditindaklanjuti, Selesai) secara transparan melalui lini masa (\textit{timeline}) status interaktif.
\end{enumerate}

\subsection{AI Pipeline}
Untuk mempercepat penanganan volume laporan dan mendeteksi anomali pada kasus pengajuan subsidi, E-Pupuk mengintegrasikan saluran pipa kecerdasan artifisial (\textit{AI Pipeline}) terotomatisasi yang terdiri dari tiga tahapan pemrosesan data:
\begin{enumerate}
    \item \textbf{Text Processing dan Klasifikasi Kategori Laporan (NLP Stage):} Deskripsi teks pengaduan atau catatan survei lapangan diproses melalui tahapan \textit{case folding}, pembersihan karakter, dan tokenisasi. Representasi vektor teks diekstraksi memanfaatkan model \textit{bidirectional encoder} berbasis arsitektur Transformer \cite{b3}, \cite{b4} dan RoBERTa \cite{b9}. Model kemudian mengklasifikasikan tiket laporan ke dalam departemen penanganan yang relevan secara otomatis menggunakan algoritma pembelajaran mesin terawasi \cite{b8}, \cite{b17}.
    \item \textbf{Computer Vision dan Validasi Bukti Fisik (CV Stage):} Citra dokumentasi lapangan atau foto surat tanda kepemilikan lahan dianalisis menggunakan jaringan saraf tiruan konvolusional (Convolutional Neural Networks / ResNet) \cite{b6}, \cite{b7}. Tahap ini memverifikasi kejelasan visual bukti dokumentasi lahan pertanian serta mendeteksi potensi kecurangan atau gambar berulang (\textit{duplicate image submission}).
    \item \textbf{Knowledge Retrieval dan Generasi Solusi Penanganan (RAG Stage):} Untuk membantu petugas dinas merumuskan respons penanganan laporan kasus secara cepat dan sesuai regulasi, diimplementasikan kerangka kerja \textit{Retrieval-Augmented Generation} (RAG) \cite{b11}. Mesin pencarian semantik (\textit{dense retrieval}) berbasis representasi kalimat \cite{b10} menelusuri basis pengetahuan regulasi perundang-undangan pupuk bersubsidi, kemudian model generatif merangkum draf rekomendasi solusi tindak lanjut bagi pengambil kebijakan \cite{b5}.
\end{enumerate}
"""

references_block = r"""\begin{thebibliography}{00}
\bibitem{b1} M. S. L. Tiangolo, ``FastAPI: Modern, High-Performance Web Framework for Python,'' 2023. [Online]. Available: https://fastapi.tiangolo.com/
\bibitem{b2} M. B. Jones, J. Bradley, and N. Sakimura, ``JSON Web Token (JWT),'' \textit{RFC 7519, Internet Engineering Task Force (IETF)}, 2015. [Online]. Available: https://datatracker.ietf.org/doc/html/rfc7519
\bibitem{b3} A. Vaswani, N. Shazeer, N. Parmar, J. Uszkoreit, L. Jones, A. N. Gomez, L. Kaiser, and I. Polosukhin, ``Attention Is All You Need,'' in \textit{Advances in Neural Information Processing Systems (NeurIPS)}, vol. 30, 2017. [Online]. Available: https://arxiv.org/abs/1706.03762
\bibitem{b4} J. Devlin, M. W. Chang, K. Lee, and K. Toutanova, ``BERT: Pre-training of Deep Bidirectional Transformers for Language Understanding,'' in \textit{Proc. NAACL-HLT}, 2019, pp. 4171--4186. [Online]. Available: https://arxiv.org/abs/1810.04805
\bibitem{b5} A. Radford, J. Wu, R. Child, D. Luan, D. Amodei, and I. Sutskever, ``Language Models are Unsupervised Multitask Learners,'' OpenAI Technical Report, 2019. [Online]. Available: https://cdn.openai.com/better-language-models/language\_models\_are\_unsupervised\_multitask\_learners.pdf
\bibitem{b6} Y. Kim, ``Convolutional Neural Networks for Sentence Classification,'' in \textit{Proc. EMNLP}, 2014, pp. 1746--1751. [Online]. Available: https://arxiv.org/abs/1408.5882
\bibitem{b7} K. He, X. Zhang, S. Ren, and J. Sun, ``Deep Residual Learning for Image Recognition,'' in \textit{Proc. IEEE CVPR}, 2016, pp. 770--778. [Online]. Available: https://arxiv.org/abs/1512.03385
\bibitem{b8} A. Joulin, E. Grave, P. Bojanowski, and T. Mikolov, ``Bag of Tricks for Efficient Text Classification,'' in \textit{Proc. EACL}, 2017, pp. 427--431. [Online]. Available: https://arxiv.org/abs/1607.01759
\bibitem{b9} Y. Liu, M. Ott, N. Goyal, J. Du, M. Joshi, D. Chen, O. Levy, M. Lewis, L. Zettlemoyer, and V. Stoyanov, ``RoBERTa: A Robustly Optimized BERT Pretraining Approach,'' arXiv preprint arXiv:1907.11692, 2019. [Online]. Available: https://arxiv.org/abs/1907.11692
\bibitem{b10} N. Reimers and I. Gurevych, ``Sentence-BERT: Sentence Embeddings using Siamese BERT-Networks,'' in \textit{Proc. EMNLP-IJCNLP}, 2019, pp. 3982--3992. [Online]. Available: https://arxiv.org/abs/1908.10084
\bibitem{b11} P. Lewis, E. Perez, A. Piktus, F. Petroni, V. Karpukhin, N. Goyal, H. Kuttler, M. Lewis, W. Yih, T. Rockt\"{a}schel, S. Riedel, and D. Kiela, ``Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks,'' in \textit{Advances in Neural Information Processing Systems (NeurIPS)}, vol. 33, 2020, pp. 9459--9474. [Online]. Available: https://arxiv.org/abs/2005.11401
\bibitem{b12} J. Nielsen, ``10 Usability Heuristics for User Interface Design,'' Nielsen Norman Group, 2020. [Online]. Available: https://www.nngroup.com/articles/ten-usability-heuristics/
\bibitem{b13} PostgreSQL Global Development Group, ``PostgreSQL 16 Documentation,'' 2023. [Online]. Available: https://www.postgresql.org/docs/current/index.html
\bibitem{b14} Meta Open Source, ``React: The Library for Web and Native User Interfaces,'' 2023. [Online]. Available: https://react.dev/
\bibitem{b15} Docker Inc., ``Docker Documentation: Accelerated Container Application Development,'' 2023. [Online]. Available: https://docs.docker.com/
\bibitem{b16} V. Agafonkin, ``Leaflet: An Open-Source JavaScript Library for Mobile-Friendly Interactive Maps,'' 2023. [Online]. Available: https://leafletjs.com/
\bibitem{b17} F. Pedregosa et al., ``Scikit-learn: Machine Learning in Python,'' \textit{Journal of Machine Learning Research}, vol. 12, pp. 2825--2830, 2011. [Online]. Available: https://scikit-learn.org/stable/
\bibitem{b18} S. Colvin et al., ``Pydantic: Data Validation using Python Type Hints,'' 2023. [Online]. Available: https://docs.pydantic.dev/
\end{thebibliography}"""

# Update both occurrences in file:
# In paper article part: before \begin{thebibliography} we insert methodology_block, and replace \begin{thebibliography}...\end{thebibliography} with references_block.
# Also update the code listing inside Bab II!

def update_content(content):
    # Pattern to match:
    # \begin{thebibliography}{00} ... \end{thebibliography}
    # We replace:
    # 1. First occurrence
    # 2. Second occurrence (inside lstlisting)
    bib_regex = re.compile(r'\\begin\{thebibliography\}\{00\}.*?\\end\{thebibliography\}', re.DOTALL)
    
    parts = []
    last_end = 0
    for match in bib_regex.finditer(content):
        # Text between last_end and match.start()
        prefix = content[last_end:match.start()]
        # Append methodology_block right before the bibliography
        parts.append(prefix + "\n" + methodology_block + "\n\n" + references_block)
        last_end = match.end()
    parts.append(content[last_end:])
    return "".join(parts)

for fn in ['e-pupuk.tex', 'conference_101719.tex']:
    with open(fn, 'r', encoding='utf-8') as f:
        c = f.read()
    new_c = update_content(c)
    with open(fn, 'w', encoding='utf-8') as f:
        f.write(new_c)
    print(f'Successfully updated {fn}')
