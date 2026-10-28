import sys
import os
import datetime
from decimal import Decimal
from pathlib import Path
import json

BASE_DIR = Path(__file__).resolve().parent
if str(BASE_DIR) not in sys.path:
    sys.path.insert(0, str(BASE_DIR))

from app.core.database import SessionLocal, engine
from app.core.security import get_password_hash
from app.models.models import (
    Base, User, FarmerGroup, Farmer, Commodity, Fertilizer,
    FertilizerBatch, Land, Application, ApplicationStatus,
    FieldSurvey
)

def seed_mojokerto_ppl():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        print("Mempersiapkan data PPL dan Petani Kabupaten Mojokerto...")

        # 1. Pastikan User PPL Ahmad ada
        ahmad = db.query(User).filter(User.username == "ppl_ahmad").first()
        if not ahmad:
            ahmad = User(
                username="ppl_ahmad",
                email="ahmad.ppl@mojokertokab.go.id",
                password_hash=get_password_hash("ppl123"),
                role="PPL",
                is_active=True
            )
            db.add(ahmad)
            db.commit()
            db.refresh(ahmad)

        # 2. Kelompok Tani
        poktan1 = db.query(FarmerGroup).filter(FarmerGroup.nama_kelompok == "Poktan Sumber Makmur").first()
        if not poktan1:
            poktan1 = FarmerGroup(nama_kelompok="Poktan Sumber Makmur", wilayah="Wilbin BPP Mojosari, Kab. Mojokerto")
            db.add(poktan1)

        poktan2 = db.query(FarmerGroup).filter(FarmerGroup.nama_kelompok == "Poktan Tani Sejahtera").first()
        if not poktan2:
            poktan2 = FarmerGroup(nama_kelompok="Poktan Tani Sejahtera", wilayah="Desa Sukamaju, Kec. Mojosari")
            db.add(poktan2)

        poktan3 = db.query(FarmerGroup).filter(FarmerGroup.nama_kelompok == "Poktan Sri Rejeki").first()
        if not poktan3:
            poktan3 = FarmerGroup(nama_kelompok="Poktan Sri Rejeki", wilayah="Desa Sumberrejo, Kec. Mojosari")
            db.add(poktan3)
        db.commit()

        # 3. Komoditas
        com_padi = db.query(Commodity).filter(Commodity.nama_komoditas == "Padi Inpari 32").first()
        if not com_padi:
            com_padi = Commodity(nama_komoditas="Padi Inpari 32", standar_kebutuhan_kg_per_ha=Decimal("300.00"))
            db.add(com_padi)

        com_jagung = db.query(Commodity).filter(Commodity.nama_komoditas == "Jagung Hibrida").first()
        if not com_jagung:
            com_jagung = Commodity(nama_komoditas="Jagung Hibrida", standar_kebutuhan_kg_per_ha=Decimal("250.00"))
            db.add(com_jagung)

        com_kedelai = db.query(Commodity).filter(Commodity.nama_komoditas == "Kedelai Anjasmoro").first()
        if not com_kedelai:
            com_kedelai = Commodity(nama_komoditas="Kedelai Anjasmoro", standar_kebutuhan_kg_per_ha=Decimal("200.00"))
            db.add(com_kedelai)
        db.commit()

        # 4. Pupuk
        fert_urea = db.query(Fertilizer).filter(Fertilizer.nama_pupuk == "Urea Bersubsidi").first()
        if not fert_urea:
            fert_urea = Fertilizer(nama_pupuk="Urea Bersubsidi", satuan="kg")
            db.add(fert_urea)

        fert_npk = db.query(Fertilizer).filter(Fertilizer.nama_pupuk == "NPK Phonska Bersubsidi").first()
        if not fert_npk:
            fert_npk = Fertilizer(nama_pupuk="NPK Phonska Bersubsidi", satuan="kg")
            db.add(fert_npk)
        db.commit()

        # 5. Petani 1: Siti Aminah
        user_siti = db.query(User).filter(User.username == "petani_siti").first()
        if not user_siti:
            user_siti = User(username="petani_siti", email="siti.aminah@gmail.com", password_hash=get_password_hash("petani123"), role="PETANI")
            db.add(user_siti)
            db.commit()
            db.refresh(user_siti)

        farmer_siti = db.query(Farmer).filter(Farmer.nik == "3516082104850002").first()
        if not farmer_siti:
            farmer_siti = db.query(Farmer).filter(Farmer.user_id == user_siti.id).first()
        if not farmer_siti:
            farmer_siti = Farmer(
                user_id=user_siti.id,
                nama="Siti Aminah",
                nik="3516082104850002",
                kontak="0812-3456-7890",
                alamat="Dsn. Sumberarum RT 02 RW 01, Ds. Tanjungrejo, Kec. Mojosari",
                farmer_group_id=poktan1.id
            )
            db.add(farmer_siti)
        else:
            farmer_siti.nama = "Siti Aminah"
            farmer_siti.nik = "3516082104850002"
            farmer_siti.kontak = "0812-3456-7890"
            farmer_siti.alamat = "Dsn. Sumberarum RT 02 RW 01, Ds. Tanjungrejo, Kec. Mojosari"
            farmer_siti.farmer_group_id = poktan1.id
        db.commit()
        db.refresh(farmer_siti)

        # Lahan Siti 1: Sawah Blok Timur Kebondalem (PLN-001)
        siti_polygon = [
            [-7.526012, 112.533812],
            [-7.526012, 112.534618],
            [-7.526812, 112.534618],
            [-7.526812, 112.533812]
        ]
        land_siti_1 = db.query(Land).filter(Land.farmer_id == farmer_siti.id, Land.lokasi_deskripsi == "Sawah Blok Timur Kebondalem").first()
        if not land_siti_1:
            land_siti_1 = Land(
                farmer_id=farmer_siti.id,
                lokasi_deskripsi="Sawah Blok Timur Kebondalem",
                alamat_lahan="Dsn. Sumberarum RT 02 RW 01, Ds. Tanjungrejo, Kec. Mojosari",
                latitude=Decimal("-7.526412"),
                longitude=Decimal("112.534218"),
                luas_m2=Decimal("8000.00"),
                commodity_id=com_padi.id,
                status_kepemilikan="MILIK",
                polygon_coords=json.dumps(siti_polygon),
                luas_verifikasi_m2=Decimal("7850.00"),
                status_verifikasi="TERVERIFIKASI",
                catatan_verifikasi="Batas fisik pematang sawah telah diverifikasi citra Sentinel-2 & GPS PPL."
            )
            db.add(land_siti_1)
        else:
            land_siti_1.latitude = Decimal("-7.526412")
            land_siti_1.longitude = Decimal("112.534218")
            land_siti_1.luas_m2 = Decimal("8000.00")
            land_siti_1.commodity_id = com_padi.id
            land_siti_1.polygon_coords = json.dumps(siti_polygon)
            land_siti_1.luas_verifikasi_m2 = Decimal("7850.00")

        # Lahan Siti 2: Tegal Sawah Blok Selatan (PLN-002)
        land_siti_2 = db.query(Land).filter(Land.farmer_id == farmer_siti.id, Land.lokasi_deskripsi == "Tegal Sawah Blok Selatan").first()
        if not land_siti_2:
            land_siti_2 = Land(
                farmer_id=farmer_siti.id,
                lokasi_deskripsi="Tegal Sawah Blok Selatan",
                alamat_lahan="Dsn. Sumberarum RT 03 RW 01, Ds. Tanjungrejo, Kec. Mojosari",
                latitude=Decimal("-7.528500"),
                longitude=Decimal("112.536200"),
                luas_m2=Decimal("6000.00"),
                commodity_id=com_jagung.id,
                status_kepemilikan="GARAP",
                polygon_coords=None,
                status_verifikasi="BELUM_DIVERIFIKASI"
            )
            db.add(land_siti_2)
        db.commit()
        db.refresh(land_siti_1)
        db.refresh(land_siti_2)

        # Petani 2: Joko Santoso
        user_joko = db.query(User).filter(User.username == "petani_joko").first()
        if not user_joko:
            user_joko = User(username="petani_joko", email="joko.santoso@gmail.com", password_hash=get_password_hash("petani123"), role="PETANI")
            db.add(user_joko)
            db.commit()
            db.refresh(user_joko)

        farmer_joko = db.query(Farmer).filter(Farmer.nik == "3516081208800019").first()
        if not farmer_joko:
            farmer_joko = db.query(Farmer).filter(Farmer.user_id == user_joko.id).first()
        if not farmer_joko:
            farmer_joko = Farmer(
                user_id=user_joko.id,
                nama="Joko Santoso",
                nik="3516081208800019",
                kontak="0812-9876-5432",
                alamat="Desa Sukamaju, Kec. Mojosari",
                farmer_group_id=poktan2.id
            )
            db.add(farmer_joko)
        else:
            farmer_joko.nama = "Joko Santoso"
            farmer_joko.nik = "3516081208800019"
            farmer_joko.kontak = "0812-9876-5432"
            farmer_joko.alamat = "Desa Sukamaju, Kec. Mojosari"
            farmer_joko.farmer_group_id = poktan2.id
        db.commit()
        db.refresh(farmer_joko)

        land_joko = db.query(Land).filter(Land.farmer_id == farmer_joko.id).first()
        if not land_joko:
            land_joko = Land(
                farmer_id=farmer_joko.id,
                lokasi_deskripsi="Sawah Sukamaju Blok Tengah",
                alamat_lahan="Desa Sukamaju, Kec. Mojosari",
                latitude=Decimal("-7.521500"),
                longitude=Decimal("112.539000"),
                luas_m2=Decimal("12000.00"),
                commodity_id=com_jagung.id,
                status_kepemilikan="MILIK",
                status_verifikasi="BELUM_DIVERIFIKASI"
            )
            db.add(land_joko)
            db.commit()
            db.refresh(land_joko)

        # Petani 3: Dewi Lestari
        user_dewi = db.query(User).filter(User.username == "petani_dewi").first()
        if not user_dewi:
            user_dewi = User(username="petani_dewi", email="dewi.lestari@gmail.com", password_hash=get_password_hash("petani123"), role="PETANI")
            db.add(user_dewi)
            db.commit()
            db.refresh(user_dewi)

        farmer_dewi = db.query(Farmer).filter(Farmer.nik == "3516085509910041").first()
        if not farmer_dewi:
            farmer_dewi = db.query(Farmer).filter(Farmer.user_id == user_dewi.id).first()
        if not farmer_dewi:
            farmer_dewi = Farmer(
                user_id=user_dewi.id,
                nama="Dewi Lestari",
                nik="3516085509910041",
                kontak="0857-1122-3344",
                alamat="Desa Sumberrejo, Kec. Mojosari",
                farmer_group_id=poktan3.id
            )
            db.add(farmer_dewi)
        else:
            farmer_dewi.nama = "Dewi Lestari"
            farmer_dewi.nik = "3516085509910041"
            farmer_dewi.kontak = "0857-1122-3344"
            farmer_dewi.alamat = "Desa Sumberrejo, Kec. Mojosari"
            farmer_dewi.farmer_group_id = poktan3.id
        db.commit()
        db.refresh(farmer_dewi)

        land_dewi = db.query(Land).filter(Land.farmer_id == farmer_dewi.id).first()
        if not land_dewi:
            land_dewi = Land(
                farmer_id=farmer_dewi.id,
                lokasi_deskripsi="Tegal Sumberrejo Blok Utara",
                alamat_lahan="Desa Sumberrejo, Kec. Mojosari",
                latitude=Decimal("-7.518000"),
                longitude=Decimal("112.542000"),
                luas_m2=Decimal("6000.00"),
                commodity_id=com_kedelai.id,
                status_kepemilikan="MILIK",
                status_verifikasi="PERLU_SURVEI_ULANG"
            )
            db.add(land_dewi)
            db.commit()
            db.refresh(land_dewi)

        # 6. Buat / Perbarui Aplikasi & Penugasan PPL Ahmad
        # Task 1: Siti Aminah (SRV-2025-014)
        app_siti = db.query(Application).filter(Application.farmer_id == farmer_siti.id, Application.land_id == land_siti_1.id).first()
        if not app_siti:
            app_siti = Application(
                farmer_id=farmer_siti.id,
                land_id=land_siti_1.id,
                fertilizer_id=fert_urea.id,
                jumlah_diajukan=Decimal("240.00"),
                kuota_maksimal=Decimal("240.00"),
                status=ApplicationStatus.DITUGASKAN_KE_PPL,
                alamat_lahan=land_siti_1.alamat_lahan,
                latitude=land_siti_1.latitude,
                longitude=land_siti_1.longitude,
                assigned_ppl_id=ahmad.id,
                catatan_penugasan="SRV-2025-014 - Jadwal 14 Feb 2025 • Pagi. Verifikasi tapak batas sawah dan geotagging."
            )
            db.add(app_siti)
        else:
            app_siti.status = ApplicationStatus.DITUGASKAN_KE_PPL
            app_siti.assigned_ppl_id = ahmad.id
            app_siti.catatan_penugasan = "SRV-2025-014 - Jadwal 14 Feb 2025 • Pagi. Verifikasi tapak batas sawah dan geotagging."

        # Task 2: Joko Santoso (SRV-2025-018)
        app_joko = db.query(Application).filter(Application.farmer_id == farmer_joko.id).first()
        if not app_joko:
            app_joko = Application(
                farmer_id=farmer_joko.id,
                land_id=land_joko.id,
                fertilizer_id=fert_npk.id,
                jumlah_diajukan=Decimal("300.00"),
                kuota_maksimal=Decimal("300.00"),
                status=ApplicationStatus.SURVEI_LAPANGAN,
                alamat_lahan=land_joko.alamat_lahan,
                latitude=land_joko.latitude,
                longitude=land_joko.longitude,
                assigned_ppl_id=ahmad.id,
                catatan_penugasan="SRV-2025-018 - Jadwal 15 Feb 2025 • Siang. Dalam proses survei lapangan (Progress: 60%)."
            )
            db.add(app_joko)
        else:
            app_joko.status = ApplicationStatus.SURVEI_LAPANGAN
            app_joko.assigned_ppl_id = ahmad.id
            app_joko.catatan_penugasan = "SRV-2025-018 - Jadwal 15 Feb 2025 • Siang. Dalam proses survei lapangan (Progress: 60%)."

        # Task 3: Dewi Lestari (SRV-2025-021)
        app_dewi = db.query(Application).filter(Application.farmer_id == farmer_dewi.id).first()
        if not app_dewi:
            app_dewi = Application(
                farmer_id=farmer_dewi.id,
                land_id=land_dewi.id,
                fertilizer_id=fert_urea.id,
                jumlah_diajukan=Decimal("120.00"),
                kuota_maksimal=Decimal("120.00"),
                status=ApplicationStatus.SURVEI_LAPANGAN,
                alamat_lahan=land_dewi.alamat_lahan,
                latitude=land_dewi.latitude,
                longitude=land_dewi.longitude,
                assigned_ppl_id=ahmad.id,
                catatan_penugasan="SRV-2025-021 - Jadwal 17 Feb 2025. Koreksi poligon lahan terindikasi tumpang tindih."
            )
            db.add(app_dewi)
        else:
            app_dewi.status = ApplicationStatus.SURVEI_LAPANGAN
            app_dewi.assigned_ppl_id = ahmad.id
            app_dewi.catatan_penugasan = "SRV-2025-021 - Jadwal 17 Feb 2025. Koreksi poligon lahan terindikasi tumpang tindih."

        db.commit()
        print("[SUCCESS] Data PPL Ahmad, Petani Siti Aminah, Joko Santoso, Dewi Lestari dan penugasan survei berhasil diperbarui!")
    finally:
        db.close()

if __name__ == "__main__":
    seed_mojokerto_ppl()
