import assert from 'node:assert/strict';
import test from 'node:test';
import {
  buildAdminReport,
  escapeReportHtml,
  getAdminReportRegions,
  toCsvCell,
} from '../src/utils/adminReports.js';

const data = {
  farmers: [{
    id: 1,
    nama: 'Petani Satu',
    nik: '1234567890123456',
    kontak: '081234567890',
    alamat: 'Desa Contoh',
    tanggal_registrasi: '2026-11-01',
    farmer_group: { nama_kelompok: 'Poktan Contoh', wilayah: 'Puri' },
  }],
  lands: [{
    id: 2,
    farmer_id: 1,
    alamat_lahan: 'Sawah Contoh',
    luas_m2: 1000,
    tanggal_registrasi: '2026-11-01',
  }],
  applications: [{
    id: 3,
    tanggal_pengajuan: '2026-11-02',
    final_approved_at: '2026-11-04',
    status: 'TERSALURKAN',
    jumlah_diajukan: 25,
    jumlah_disetujui: 25,
    farmer: { nama: 'Petani Satu', nik: '1234567890123456', farmer_group: { wilayah: 'Puri' } },
    fertilizer: { nama_pupuk: 'Urea' },
    survey: { tanggal_survei: '2026-11-03', rekomendasi: 'SETUJU' },
  }],
  distributions: [{
    id: 4,
    application_id: 3,
    created_at: '2026-11-05',
    jumlah_disalurkan: 25,
    status_penyaluran: 'SELESAI',
    application: {
      farmer: { nama: 'Petani Satu', farmer_group: { wilayah: 'Puri' } },
      fertilizer: { nama_pupuk: 'Urea' },
    },
  }],
};

test('builds a report for each Admin report category', () => {
  for (const key of ['farmers', 'lands', 'applications', 'surveys', 'approvals', 'distributions']) {
    const report = buildAdminReport(key, data);
    assert.ok(report.title);
    assert.ok(report.headers.length > 0);
    assert.equal(report.rows.length, 1, key);
  }
});

test('applies date and wilayah filters to report rows', () => {
  const report = buildAdminReport('farmers', data, {
    startDate: '2026-11-01',
    endDate: '2026-11-01',
    region: 'Puri',
  });
  assert.equal(report.rows.length, 1);
  assert.equal(buildAdminReport('farmers', data, { startDate: '2026-11-02' }).rows.length, 0);
  assert.equal(buildAdminReport('farmers', data, { region: 'Trowulan' }).rows.length, 0);
});

test('lists distinct report regions and rejects unknown report types', () => {
  assert.deepEqual(getAdminReportRegions([
    ...data.farmers,
    { farmer_group: { wilayah: 'Puri' } },
    { farmer_group: { wilayah: 'Trowulan' } },
  ]), ['Puri', 'Trowulan']);
  assert.throws(() => buildAdminReport('unknown', data), /Jenis laporan tidak dikenal/);
});

test('escapes CSV cells and printable HTML values', () => {
  assert.equal(toCsvCell('A, "B"'), '"A, ""B"""');
  assert.equal(escapeReportHtml(`<script>&"'</script>`), '&lt;script&gt;&amp;&quot;&#39;&lt;/script&gt;');
});
