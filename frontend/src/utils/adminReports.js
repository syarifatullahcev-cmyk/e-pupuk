export const ADMIN_REPORT_TYPES = [
  { key: 'farmers', title: 'Data Petani Terdaftar' },
  { key: 'lands', title: 'Register Bidang Lahan' },
  { key: 'applications', title: 'Pengajuan & Verifikasi Berkas' },
  { key: 'surveys', title: 'Hasil Survei Lapangan PPL' },
  { key: 'approvals', title: 'Surat Keputusan Persetujuan' },
  { key: 'distributions', title: 'Distribusi Pupuk Bersubsidi' },
];

const REPORTS = {
  farmers: {
    title: 'Data Petani Terdaftar',
    headers: ['ID Petani', 'Nama', 'NIK', 'Kontak', 'Alamat', 'Kelompok Tani', 'Wilayah', 'Tanggal Registrasi'],
    date: (farmer) => farmer.tanggal_registrasi,
    sources: ({ farmers }) => farmers,
    rows: ({ farmers }) => farmers.map((farmer) => [
      farmer.id,
      farmer.nama,
      farmer.nik,
      farmer.kontak,
      farmer.alamat,
      farmer.farmer_group?.nama_kelompok,
      farmer.farmer_group?.wilayah,
      farmer.tanggal_registrasi,
    ]),
    region: (farmer) => farmer.farmer_group?.wilayah,
  },
  lands: {
    title: 'Register Bidang Lahan',
    headers: ['ID Lahan', 'Nama Petani', 'Alamat Lahan', 'Luas (m²)', 'Kepemilikan', 'Komoditas', 'Status Verifikasi', 'Wilayah', 'Tanggal Registrasi'],
    date: (land) => land.tanggal_registrasi,
    sources: ({ lands }) => lands,
    rows: ({ farmers, lands }) => {
      const farmersById = new Map(farmers.map((farmer) => [farmer.id, farmer]));
      return lands.map((land) => {
        const farmer = farmersById.get(land.farmer_id);
        return [
          land.id,
          farmer?.nama,
          land.alamat_lahan,
          land.luas_m2,
          land.status_kepemilikan,
          land.commodity?.nama_komoditas,
          land.status_verifikasi,
          farmer?.farmer_group?.wilayah,
          land.tanggal_registrasi,
        ];
      });
    },
    region: (land, { farmers }) => farmers.find((farmer) => farmer.id === land.farmer_id)?.farmer_group?.wilayah,
  },
  applications: {
    title: 'Pengajuan & Verifikasi Berkas',
    headers: ['ID Pengajuan', 'Nama Petani', 'NIK', 'Alamat Lahan', 'Pupuk', 'Jumlah Diajukan (kg)', 'Status', 'Catatan Admin', 'Tanggal Pengajuan'],
    date: (app) => app.tanggal_pengajuan,
    sources: ({ applications }) => applications,
    rows: ({ applications }) => applications.map((app) => [
      app.id,
      app.farmer?.nama,
      app.farmer?.nik,
      app.alamat_lahan || app.land?.alamat_lahan,
      app.fertilizer?.nama_pupuk,
      app.jumlah_diajukan,
      app.status,
      app.catatan_admin_berkas,
      app.tanggal_pengajuan,
    ]),
    region: (app) => app.farmer?.farmer_group?.wilayah,
  },
  surveys: {
    title: 'Hasil Survei Lapangan PPL',
    headers: ['ID Pengajuan', 'Nama Petani', 'Kondisi Lahan', 'Keterangan Lahan', 'Kondisi Tanaman', 'Keterangan Tanaman', 'Luas Terukur (m²)', 'Rekomendasi', 'Catatan PPL', 'Tanggal Survei'],
    date: (app) => app.survey?.tanggal_survei,
    sources: ({ applications }) => applications.filter((app) => app.survey),
    rows: ({ applications }) => applications
      .filter((app) => app.survey)
      .map((app) => [
        app.id,
        app.farmer?.nama,
        app.survey.kondisi_fisik_lahan,
        app.survey.keterangan_fisik_lahan,
        app.survey.kondisi_tanaman,
        app.survey.keterangan_tanaman,
        app.survey.luas_lahan_aktual_m2,
        app.survey.rekomendasi,
        app.survey.catatan_ppl,
        app.survey.tanggal_survei,
      ]),
    region: (app) => app.farmer?.farmer_group?.wilayah,
  },
  approvals: {
    title: 'Surat Keputusan Persetujuan',
    headers: ['ID Pengajuan', 'Nama Petani', 'NIK', 'Pupuk', 'Jumlah Diajukan (kg)', 'Jumlah Disetujui (kg)', 'Status', 'Catatan Keputusan', 'Tanggal Persetujuan'],
    date: (app) => app.final_approved_at,
    sources: ({ applications }) => applications.filter((app) =>
      app.final_approved_at || ['DISETUJUI', 'DIJADWALKAN_DISTRIBUSI', 'TERSALURKAN'].includes(app.status)),
    rows: ({ applications }) => applications
      .filter((app) => app.final_approved_at || ['DISETUJUI', 'DIJADWALKAN_DISTRIBUSI', 'TERSALURKAN'].includes(app.status))
      .map((app) => [
        app.id,
        app.farmer?.nama,
        app.farmer?.nik,
        app.fertilizer?.nama_pupuk,
        app.jumlah_diajukan,
        app.jumlah_disetujui,
        app.status,
        app.catatan_final_admin,
        app.final_approved_at,
      ]),
    region: (app) => app.farmer?.farmer_group?.wilayah,
  },
  distributions: {
    title: 'Distribusi Pupuk Bersubsidi',
    headers: ['ID Distribusi', 'ID Pengajuan', 'Nama Petani', 'Pupuk', 'Jumlah Disalurkan (kg)', 'Status Penyaluran', 'Tanggal Penyaluran'],
    date: (distribution) => distribution.tanggal_penyaluran || distribution.created_at,
    sources: ({ distributions }) => distributions,
    rows: ({ distributions }) => distributions.map((distribution) => [
      distribution.id,
      distribution.application_id,
      distribution.application?.farmer?.nama,
      distribution.application?.fertilizer?.nama_pupuk,
      distribution.jumlah_disalurkan,
      distribution.status_penyaluran,
      distribution.tanggal_penyaluran,
    ]),
    region: (distribution) => distribution.application?.farmer?.farmer_group?.wilayah,
  },
};

function isWithinDateRange(value, startDate, endDate) {
  if (!startDate && !endDate) return true;
  if (!value) return false;
  const date = String(value).slice(0, 10);
  return (!startDate || date >= startDate) && (!endDate || date <= endDate);
}

export function getAdminReportRegions(farmers) {
  return [...new Set(
    farmers
      .map((farmer) => farmer.farmer_group?.wilayah?.trim())
      .filter(Boolean),
  )].sort((a, b) => a.localeCompare(b, 'id'));
}

export function buildAdminReport(reportKey, data, filters = {}) {
  const report = REPORTS[reportKey];
  if (!report) throw new Error(`Jenis laporan tidak dikenal: ${reportKey}`);

  const sources = report.sources(data);
  const rows = report.rows(data);
  const filteredRows = sources.reduce((result, source, index) => {
    if (filters.region && report.region(source, data) !== filters.region) return result;
    if (!isWithinDateRange(report.date(source), filters.startDate, filters.endDate)) return result;
    result.push(rows[index]);
    return result;
  }, []);

  return {
    title: report.title,
    headers: report.headers,
    rows: filteredRows,
  };
}

export function toCsvCell(value) {
  const text = value == null ? '' : String(value);
  return `"${text.replaceAll('"', '""')}"`;
}

export function escapeReportHtml(value) {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}
