import datetime
from decimal import Decimal
from app.core.database import SessionLocal, engine
from app.core.security import get_password_hash
from app.models.models import (
    Base, User, FarmerGroup, Farmer, Commodity, Fertilizer,
    FertilizerBatch, Land, Application, ApplicationStatus,
    FieldSurvey, Distribution, Notification
)

def seed():
    db = SessionLocal()
    try:
        # Check if already seeded
        if db.query(User).first():
            print("Database already contains user records. Skipping seed.")
            return

        print("Seeding initial data for E-Pupuk...")

        # 1. Users
        users = [
            User(username="admin", email="admin.pupuk@mojokertokab.go.id", password_hash=get_password_hash("admin123"), role="ADMIN"),
            User(username="petani_budi", email="budi.santoso@gmail.com", password_hash=get_password_hash("petani123"), role="PETANI"),
            User(username="petani_siti", email="siti.aminah@gmail.com", password_hash=get_password_hash("petani123"), role="PETANI"),
            User(username="ppl_ahmad", email="ahmad.ppl@mojokertokab.go.id", password_hash=get_password_hash("ppl123"), role="PPL"),
            User(username="pimpinan", email="kadis.pertanian@mojokertokab.go.id", password_hash=get_password_hash("pimpinan123"), role="PIMPINAN"),
        ]
        db.add_all(users)
        db.commit()

        # 2. Farmer Groups
        groups = [
            FarmerGroup(nama_kelompok="Poktan Sumber Makmur", wilayah="Kecamatan Mojosari, Kab. Mojokerto"),
            FarmerGroup(nama_kelompok="Poktan Tani Jaya", wilayah="Kecamatan Trowulan, Kab. Mojokerto"),
        ]
        db.add_all(groups)
        db.commit()

        # 3. Commodities
        commodities = [
            Commodity(nama_komoditas="Padi Ciherang", standar_kebutuhan_kg_per_ha=Decimal("300.00")),
            Commodity(nama_komoditas="Jagung Hibrida", standar_kebutuhan_kg_per_ha=Decimal("250.00")),
            Commodity(nama_komoditas="Cabai Rawit", standar_kebutuhan_kg_per_ha=Decimal("200.00")),
        ]
        db.add_all(commodities)
        db.commit()

        # 4. Fertilizers
        fertilizers = [
            Fertilizer(nama_pupuk="Urea Bersubsidi", satuan="kg"),
            Fertilizer(nama_pupuk="NPK Phonska Bersubsidi", satuan="kg"),
        ]
        db.add_all(fertilizers)
        db.commit()

        # 5. Fertilizer Batches
        batches = [
            FertilizerBatch(
                batch_code="BATCH-UREA-2026-01",
                fertilizer_id=fertilizers[0].id,
                production_date=datetime.date(2026, 1, 15),
                expired_date=datetime.date(2028, 1, 15),
                stok_kg=Decimal("50000.00")
            ),
            FertilizerBatch(
                batch_code="BATCH-NPK-2026-01",
                fertilizer_id=fertilizers[1].id,
                production_date=datetime.date(2026, 2, 1),
                expired_date=datetime.date(2028, 2, 1),
                stok_kg=Decimal("45000.00")
            ),
        ]
        db.add_all(batches)
        db.commit()

        # 6. Farmers
        farmers = [
            Farmer(
                user_id=users[1].id, # budi
                nama="Budi Santoso",
                nik="3516011208800001",
                kontak="081234567890",
                alamat="Dsn. Sumberarum RT 02 RW 01, Ds. Kebondalem, Kec. Mojosari",
                foto_ktp_url="/files/ktp/sample_ktp_budi.jpg",
                farmer_group_id=groups[0].id
            ),
            Farmer(
                user_id=users[2].id, # siti
                nama="Siti Aminah",
                nik="3516025505850002",
                kontak="085712345678",
                alamat="Dsn. Kemasan RT 03 RW 02, Ds. Sentonorejo, Kec. Trowulan",
                foto_ktp_url="/files/ktp/sample_ktp_siti.jpg",
                farmer_group_id=groups[1].id
            ),
        ]
        db.add_all(farmers)
        db.commit()

        # 7. Lands
        lands = [
            Land(
                farmer_id=farmers[0].id,
                lokasi_deskripsi="Sawah Blok Timur Kebondalem",
                alamat_lahan="Jl. Raya Pertanian No. 12, Kebondalem, Mojosari",
                latitude=Decimal("-7.5312340"),
                longitude=Decimal("112.5512340"),
                luas_m2=Decimal("12000.00"),
                commodity_id=commodities[0].id,
                status_kepemilikan="MILIK",
                foto_lahan_url="/files/lahan/sample_sawah_mojosari.jpg"
            ),
            Land(
                farmer_id=farmers[1].id,
                lokasi_deskripsi="Tegal Jagung Sentonorejo",
                alamat_lahan="Jl. Candi Gentong No. 45, Trowulan",
                latitude=Decimal("-7.5589120"),
                longitude=Decimal("112.3812340"),
                luas_m2=Decimal("8500.00"),
                commodity_id=commodities[1].id,
                status_kepemilikan="GARAP",
                foto_lahan_url="/files/lahan/sample_jagung_trowulan.jpg"
            ),
        ]
        db.add_all(lands)
        db.commit()

        # 8. Applications representing the lifecycle stages
        # App 1: MENUNGGU_VERIFIKASI_BERKAS (Budi)
        app1 = Application(
            farmer_id=farmers[0].id,
            land_id=lands[0].id,
            fertilizer_id=fertilizers[0].id,
            jumlah_diajukan=Decimal("250.00"),
            kuota_maksimal=Decimal("500.00"),
            status=ApplicationStatus.MENUNGGU_VERIFIKASI_BERKAS,
            foto_ktp_snapshot_url=farmers[0].foto_ktp_url,
            foto_lahan_snapshot_url=lands[0].foto_lahan_url,
            alamat_lahan=lands[0].alamat_lahan,
            latitude=lands[0].latitude,
            longitude=lands[0].longitude
        )

        # App 2: DITUGASKAN_KE_PPL (Siti)
        app2 = Application(
            farmer_id=farmers[1].id,
            land_id=lands[1].id,
            fertilizer_id=fertilizers[1].id,
            jumlah_diajukan=Decimal("200.00"),
            kuota_maksimal=Decimal("400.00"),
            status=ApplicationStatus.DITUGASKAN_KE_PPL,
            foto_ktp_snapshot_url=farmers[1].foto_ktp_url,
            foto_lahan_snapshot_url=lands[1].foto_lahan_url,
            alamat_lahan=lands[1].alamat_lahan,
            latitude=lands[1].latitude,
            longitude=lands[1].longitude,
            admin_verifier_id=users[0].id,
            admin_verified_at=datetime.datetime.now() - datetime.timedelta(days=1),
            catatan_admin_berkas="Dokumen KTP dan foto lahan valid dan cocok.",
            assigned_ppl_id=users[3].id, # ahmad ppl
            assigned_at=datetime.datetime.now() - datetime.timedelta(hours=12),
            catatan_penugasan="Segera tinjau batas lahan dan jenis tanaman jagung."
        )

        # App 3: MENUNGGU_PERSETUJUAN_AKHIR (Budi) - survey complete
        app3 = Application(
            farmer_id=farmers[0].id,
            land_id=lands[0].id,
            fertilizer_id=fertilizers[1].id,
            jumlah_diajukan=Decimal("150.00"),
            kuota_maksimal=Decimal("500.00"),
            status=ApplicationStatus.MENUNGGU_PERSETUJUAN_AKHIR,
            foto_ktp_snapshot_url=farmers[0].foto_ktp_url,
            foto_lahan_snapshot_url=lands[0].foto_lahan_url,
            alamat_lahan=lands[0].alamat_lahan,
            latitude=lands[0].latitude,
            longitude=lands[0].longitude,
            admin_verifier_id=users[0].id,
            admin_verified_at=datetime.datetime.now() - datetime.timedelta(days=3),
            catatan_admin_berkas="Berkas lengkap dan sesuai.",
            assigned_ppl_id=users[3].id,
            assigned_at=datetime.datetime.now() - datetime.timedelta(days=2),
            catatan_penugasan="Cek fisik lahan padi."
        )

        # App 4: DIJADWALKAN_DISTRIBUSI (Siti) - with QR ready
        app4 = Application(
            farmer_id=farmers[1].id,
            land_id=lands[1].id,
            fertilizer_id=fertilizers[0].id,
            jumlah_diajukan=Decimal("100.00"),
            kuota_maksimal=Decimal("400.00"),
            status=ApplicationStatus.DIJADWALKAN_DISTRIBUSI,
            foto_ktp_snapshot_url=farmers[1].foto_ktp_url,
            foto_lahan_snapshot_url=lands[1].foto_lahan_url,
            alamat_lahan=lands[1].alamat_lahan,
            latitude=lands[1].latitude,
            longitude=lands[1].longitude,
            admin_verifier_id=users[0].id,
            admin_verified_at=datetime.datetime.now() - datetime.timedelta(days=7),
            assigned_ppl_id=users[3].id,
            assigned_at=datetime.datetime.now() - datetime.timedelta(days=6),
            final_approver_id=users[0].id,
            final_approved_at=datetime.datetime.now() - datetime.timedelta(days=4),
            jumlah_disetujui=Decimal("100.00"),
            catatan_final_admin="Disetujui penuh sesuai kuota dan rekomendasi survei."
        )

        db.add_all([app1, app2, app3, app4])
        db.commit()

        # Survey for App 3
        survey3 = FieldSurvey(
            application_id=app3.id,
            ppl_id=users[3].id,
            kondisi_fisik_lahan="BAIK",
            keterangan_fisik_lahan="Saluran irigasi aktif, tanah gembur siap tanam.",
            kondisi_tanaman="SESUAI",
            keterangan_tanaman="Tanaman padi umur 14 HST, pertumbuhan serempak.",
            luas_lahan_aktual_m2=Decimal("12000.00"),
            foto_survei_urls=["/files/survei/sample_survei_lahan1.jpg"],
            catatan_ppl="Lahan memenuhi syarat penuh untuk subsidi pupuk NPK.",
            rekomendasi="SETUJU"
        )
        db.add(survey3)

        # Distribution for App 4
        dist4 = Distribution(
            application_id=app4.id,
            batch_id=batches[0].id,
            jumlah_disalurkan=Decimal("100.00"),
            status_penyaluran="MENUNGGU_PENGAMBILAN",
            qr_code_hash="EPUPUK-4-SITI-QR2026"
        )
        db.add(dist4)

        # Initial Notifications
        notifs = [
            Notification(
                user_id=users[1].id, # budi
                judul="Pengajuan Berhasil Dikirim",
                pesan="Pengajuan subsidi Urea #1 sedang menunggu verifikasi berkas oleh Admin.",
                tipe="INFO"
            ),
            Notification(
                user_id=users[2].id, # siti
                judul="PPL Ditugaskan Survei",
                pesan="Petugas PPL telah ditugaskan untuk melakukan verifikasi fisik lahan Anda untuk pengajuan #2.",
                tipe="INFO"
            ),
            Notification(
                user_id=users[3].id, # ppl ahmad
                judul="Tugas Survei Baru",
                pesan="Anda memiliki tugas survei fisik lapangan untuk pengajuan #2 di Trowulan.",
                tipe="WARNING"
            ),
            Notification(
                user_id=users[0].id, # admin
                judul="Hasil Survei Siap Ditinjau",
                pesan="Pengajuan #3 telah disurvei oleh PPL dan menunggu persetujuan akhir dari Anda.",
                tipe="INFO"
            )
        ]
        db.add_all(notifs)
        db.commit()

        print("Seeding completed successfully!")
    finally:
        db.close()

if __name__ == "__main__":
    seed()
