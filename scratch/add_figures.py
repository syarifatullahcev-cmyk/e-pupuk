import re

fig_a = r"""\begin{figure}[htbp]
    \centering
    \setlength{\fboxsep}{10pt}
    \fbox{
        \begin{minipage}[c][5.2cm][c]{0.88\columnwidth}
            \centering
            \textbf{[Space Kosong Gambar]}\\[0.25cm]
            \footnotesize \textbf{Arsitektur Sistem E-Pupuk}\\
            \textit{(Space disediakan untuk gambar diagram arsitektur sistem E-Pupuk)}
        \end{minipage}
    }
    \caption{Arsitektur Sistem E-Pupuk}
    \label{fig:arsitektur_epupuk}
\end{figure}
"""

fig_b = r"""\begin{figure}[htbp]
    \centering
    \setlength{\fboxsep}{10pt}
    \fbox{
        \begin{minipage}[c][5.2cm][c]{0.88\columnwidth}
            \centering
            \textbf{[Space Kosong Gambar]}\\[0.25cm]
            \footnotesize \textbf{Diagram Alur Pengguna (\textit{User Flow})}\\
            \textit{(Space disediakan untuk gambar diagram alur pengguna pelaporan)}
        \end{minipage}
    }
    \caption{Diagram Alur Pengguna (\textit{User Flow}) Pelaporan Sistem E-Pupuk}
    \label{fig:user_flow_pelaporan}
\end{figure}
"""

sub_b = r'\subsection{Rancangan User Flow Pelaporan Siswa}'
sub_c = r'\subsection{AI Pipeline}'

for fn in ['e-pupuk.tex', 'conference_101719.tex']:
    with open(fn, 'r', encoding='utf-8') as f:
        content = f.read()

    # We want to insert fig_a before every sub_b, and fig_b before every sub_c
    # Check if fig_a is already in content
    if '[Space Kosong Gambar]' in content:
        print(f'{fn} already contains figure placeholder, skipping insert.')
        continue

    # Split by sub_b
    parts_b = content.split(sub_b)
    # Join by (fig_a + '\n' + sub_b)
    content = (fig_a + '\n' + sub_b).join(parts_b)

    # Split by sub_c
    parts_c = content.split(sub_c)
    content = (fig_b + '\n' + sub_c).join(parts_c)

    with open(fn, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f'Successfully added empty space figures to {fn}')
