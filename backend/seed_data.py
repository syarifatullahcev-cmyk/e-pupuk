import argparse
import sys
import datetime
from pathlib import Path
from decimal import Decimal

# Ensure backend root is in sys.path
BASE_DIR = Path(__file__).resolve().parent
if str(BASE_DIR) not in sys.path:
    sys.path.insert(0, str(BASE_DIR))

from app.core.database import SessionLocal, engine
from app.core.security import get_password_hash
from app.models.models import (
    Base, User, FarmerGroup, Farmer, Commodity, Fertilizer,
    FertilizerBatch, Land, Application, ApplicationStatus,
    FieldSurvey, Distribution, Notification
)

def _is_demo_database(database_url):
    database_name = Path(database_url.database or "").stem
    if database_name.lower() != "epupuk_demo":
        return False
    if database_url.drivername.startswith("sqlite"):
        return True
    return database_url.host in {"localhost", "127.0.0.1", "::1", "db"}


def seed(demo_only=False):
    if not demo_only:
        raise RuntimeError(
            "Demo seeding is disabled by default. Pass --demo-only to continue."
        )
    if not _is_demo_database(engine.url):
        raise RuntimeError(
            "Refusing to seed: configure a local database named epupuk_demo."
        )

    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        # Check if already seeded
        if db.query(User).first():
            print("Database already contains user records. Skipping seed.")
            return

        print("Seeding initial data for E-Pupuk...")

        # 1. Users
        users = [
            User(username="admin", email="admin@example.com", password_hash=get_password_hash("admin123"), role="ADMIN"),
            User(username="petani_budi", email="petani1@example.com", password_hash=get_password_hash("petani123"), role="PETANI"),
            User(username="petani_siti", email="petani2@example.com", password_hash=get_password_hash("petani123"), role="PETANI"),
            User(username="ppl_ahmad", email="ppl@example.com", password_hash=get_password_hash("ppl123"), role="PPL"),
        ]
        db.add_all(users)
        db.commit()

        # 2. Farmer Groups
        groups = [
            FarmerGroup(nama_kelompok="POKTAN CONTOH 1", wilayah="WILAYAH DEMO 1"),
            FarmerGroup(nama_kelompok="POKTAN CONTOH 2", wilayah="WILAYAH DEMO 2"),
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
                user_id=users[1].id,
                nama="PETANI CONTOH 1",
                nik="0000000000000001",
                kontak="00000000001",
                alamat="ALAMAT CONTOH 1 - BUKAN ALAMAT NYATA",
                foto_ktp_url="/files/ktp/sample_ktp_budi.jpg",
                farmer_group_id=groups[0].id
            ),
            Farmer(
                user_id=users[2].id,
                nama="PETANI CONTOH 2",
                nik="0000000000000002",
                kontak="00000000002",
                alamat="ALAMAT CONTOH 2 - BUKAN ALAMAT NYATA",
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
                lokasi_deskripsi="LOKASI DEMO 1 - BUKAN LAHAN NYATA",
                alamat_lahan="ALAMAT LAHAN DEMO 1 - BUKAN ALAMAT NYATA",
                latitude=None,
                longitude=None,
                luas_m2=Decimal("12000.00"),
                commodity_id=commodities[0].id,
                status_kepemilikan="MILIK",
                foto_lahan_url="/files/lahan/sample_sawah_mojosari.jpg"
            ),
            Land(
                farmer_id=farmers[1].id,
                lokasi_deskripsi="LOKASI DEMO 2 - BUKAN LAHAN NYATA",
                alamat_lahan="ALAMAT LAHAN DEMO 2 - BUKAN ALAMAT NYATA",
                latitude=None,
                longitude=None,
                luas_m2=Decimal("8500.00"),
                commodity_id=commodities[1].id,
                status_kepemilikan="GARAP",
                foto_lahan_url="/files/lahan/sample_jagung_trowulan.jpg"
            ),
        ]
        db.add_all(lands)
        db.commit()

        # 8. Applications representing the lifecycle stages
        # App 1: MENUNGGU_VERIFIKASI_BERKAS (Petani Contoh 1)
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

        # App 2: DITUGASKAN_KE_PPL (Petani Contoh 2)
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

        # App 3: MENUNGGU_PERSETUJUAN_AKHIR (Petani Contoh 1) - survey complete
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

        # App 4: DIJADWALKAN_DISTRIBUSI (Petani Contoh 2) - with QR ready
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
                pesan="Anda memiliki tugas survei fisik lapangan untuk pengajuan demo #2.",
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

def main():
    parser = argparse.ArgumentParser(
        description="Seed fictional data into an isolated local demo database."
    )
    parser.add_argument(
        "--demo-only",
        action="store_true",
        help="Confirm that this is an isolated demo database named epupuk_demo.",
    )
    args = parser.parse_args()
    try:
        seed(demo_only=args.demo_only)
    except RuntimeError as error:
        parser.error(str(error))


if __name__ == "__main__":
    main()
