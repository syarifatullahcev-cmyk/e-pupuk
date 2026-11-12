import datetime
import json
import tempfile
import unittest
from contextlib import asynccontextmanager
from decimal import Decimal
from pathlib import Path

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.config import settings
from app.core.database import Base, get_db
from app.core.security import get_password_hash
from app.main import app
from app.models.models import (
    Application,
    ApplicationStatus,
    Commodity,
    Distribution,
    Farmer,
    Fertilizer,
    FertilizerBatch,
    FieldSurvey,
    Land,
    User,
    UserRole,
)
from app.services import file_storage


@asynccontextmanager
async def _test_lifespan(_app):
    yield


class SubsidyWorkflowE2ETest(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory(prefix="epupuk-e2e-")
        self.root = Path(self.temp_dir.name)
        self.engine = create_engine(
            f"sqlite:///{self.root / 'workflow-test.sqlite3'}",
            connect_args={"check_same_thread": False},
        )
        self.session_factory = sessionmaker(
            autocommit=False,
            autoflush=False,
            bind=self.engine,
        )
        Base.metadata.create_all(bind=self.engine)

        self.original_lifespan = app.router.lifespan_context
        self.original_pupuk_dir = settings.PUPUK_DIR
        self.original_survei_dir = settings.SURVEI_DIR
        self.original_pupuk_mapping = file_storage.CATEGORY_DIR_MAP["pupuk"]
        self.original_survei_mapping = file_storage.CATEGORY_DIR_MAP["survei"]
        app.router.lifespan_context = _test_lifespan
        settings.PUPUK_DIR = self.root / "uploads" / "pupuk"
        settings.SURVEI_DIR = self.root / "uploads" / "survei"
        file_storage.CATEGORY_DIR_MAP["pupuk"] = settings.PUPUK_DIR
        file_storage.CATEGORY_DIR_MAP["survei"] = settings.SURVEI_DIR
        app.dependency_overrides[get_db] = self._override_get_db

        self._seed_test_data()
        self.client = TestClient(app)

    def tearDown(self):
        if hasattr(self, "client"):
            self.client.close()
        app.dependency_overrides.clear()
        app.router.lifespan_context = self.original_lifespan
        settings.PUPUK_DIR = self.original_pupuk_dir
        settings.SURVEI_DIR = self.original_survei_dir
        file_storage.CATEGORY_DIR_MAP["pupuk"] = self.original_pupuk_mapping
        file_storage.CATEGORY_DIR_MAP["survei"] = self.original_survei_mapping
        self.engine.dispose()
        self.temp_dir.cleanup()

    def _override_get_db(self):
        db = self.session_factory()
        try:
            yield db
        finally:
            db.close()

    def _seed_test_data(self):
        with self.session_factory() as db:
            self.farmer_user = User(
                username="e2e_farmer",
                email="e2e_farmer@example.test",
                password_hash=get_password_hash("test-password"),
                role=UserRole.PETANI,
                is_active=True,
            )
            self.admin_user = User(
                username="e2e_admin",
                email="e2e_admin@example.test",
                password_hash=get_password_hash("test-password"),
                role=UserRole.ADMIN,
                is_active=True,
            )
            self.ppl_user = User(
                username="e2e_ppl",
                email="e2e_ppl@example.test",
                password_hash=get_password_hash("test-password"),
                role=UserRole.PPL,
                is_active=True,
            )
            db.add_all([self.farmer_user, self.admin_user, self.ppl_user])
            db.flush()

            farmer = Farmer(
                user_id=self.farmer_user.id,
                nama="Petani Uji E2E",
                nik="0000000000000000",
                kontak="080000000000",
                alamat="Alamat Uji",
                foto_ktp_url="/files/ktp/dummy-test.jpg",
            )
            db.add(farmer)
            db.flush()
            self.farmer_id = farmer.id

            commodity = Commodity(
                nama_komoditas="Komoditas Uji",
                standar_kebutuhan_kg_per_ha=Decimal("100"),
            )
            fertilizer = Fertilizer(nama_pupuk="Urea Uji", satuan="kg")
            db.add_all([commodity, fertilizer])
            db.flush()
            self.fertilizer_id = fertilizer.id

            self.land = Land(
                farmer_id=farmer.id,
                lokasi_deskripsi="Petak uji E2E",
                alamat_lahan="Alamat petak uji",
                latitude=Decimal("-7.5266000"),
                longitude=Decimal("112.5344000"),
                luas_m2=Decimal("10000"),
                commodity_id=commodity.id,
                status_kepemilikan="MILIK",
                foto_lahan_url="/files/lahan/dummy-test.jpg",
                status_verifikasi="BELUM_DIVERIFIKASI",
            )
            db.add(self.land)
            db.flush()
            self.land_id = self.land.id

            db.add(
                FertilizerBatch(
                    batch_code="E2E-TEST-BATCH",
                    fertilizer_id=fertilizer.id,
                    production_date=datetime.date.today(),
                    expired_date=datetime.date.today()
                    + datetime.timedelta(days=365),
                    stok_kg=Decimal("125"),
                )
            )
            db.commit()
            self.farmer_user_id = self.farmer_user.id
            self.admin_user_id = self.admin_user.id
            self.ppl_user_id = self.ppl_user.id

    def _login(self, username):
        response = self.client.post(
            "/api/auth/login",
            json={"username": username, "password": "test-password"},
        )
        self.assertEqual(response.status_code, 200, response.text)
        return {"Authorization": f"Bearer {response.json()['access_token']}"}

    def test_application_to_final_redemption_persists_consistently(self):
        farmer_headers = self._login("e2e_farmer")
        admin_headers = self._login("e2e_admin")
        ppl_headers = self._login("e2e_ppl")

        created = self.client.post(
            "/api/applications",
            headers=farmer_headers,
            json={
                "land_id": self.land_id,
                "fertilizer_id": self.fertilizer_id,
                "jumlah_diajukan": 100,
            },
        )
        self.assertEqual(created.status_code, 200, created.text)
        application_id = created.json()["id"]
        self.assertEqual(
            created.json()["status"],
            ApplicationStatus.MENUNGGU_VERIFIKASI_BERKAS,
        )

        verified = self.client.post(
            f"/api/admin/applications/{application_id}/verify-docs",
            headers=admin_headers,
            json={"action": "APPROVE", "catatan": "Berkas uji lengkap."},
        )
        self.assertEqual(verified.status_code, 200, verified.text)
        self.assertEqual(verified.json()["status"], ApplicationStatus.BERKAS_TERVERIFIKASI)

        assigned = self.client.post(
            f"/api/admin/applications/{application_id}/assign-ppl",
            headers=admin_headers,
            json={"ppl_id": self.ppl_user_id, "catatan": "Penugasan uji."},
        )
        self.assertEqual(assigned.status_code, 200, assigned.text)
        self.assertEqual(assigned.json()["status"], ApplicationStatus.DITUGASKAN_KE_PPL)

        tasks = self.client.get("/api/ppl/assigned-tasks", headers=ppl_headers)
        self.assertEqual(tasks.status_code, 200, tasks.text)
        self.assertEqual([task["id"] for task in tasks.json()], [application_id])
        self.assertEqual(tasks.json()[0]["status"], ApplicationStatus.DITUGASKAN_KE_PPL)

        started = self.client.post(
            f"/api/ppl/applications/{application_id}/start-survey",
            headers=ppl_headers,
        )
        self.assertEqual(started.status_code, 200, started.text)
        self.assertEqual(started.json()["status"], ApplicationStatus.SURVEI_LAPANGAN)

        png_bytes = bytes.fromhex(
            "89504e470d0a1a0a0000000d494844520000000100000001"
            "08060000001f15c4890000000b49444154789c636000020000"
            "050001a5f645400000000049454e44ae426082"
        )
        survey_photo_urls = []
        for filename in ("lahan.png", "patok.png"):
            photo = self.client.post(
                "/api/files/upload",
                headers=ppl_headers,
                data={"category": "survei"},
                files={"file": (filename, png_bytes, "image/png")},
            )
            self.assertEqual(photo.status_code, 200, photo.text)
            self.assertTrue((settings.SURVEI_DIR / photo.json()["filename"]).is_file())
            survey_photo_urls.append(photo.json()["url"])

        polygon = [
            [-7.526210, 112.534015],
            [-7.526180, 112.534820],
            [-7.527010, 112.534850],
            [-7.527020, 112.534025],
        ]
        missing_photos = self.client.post(
            f"/api/ppl/applications/{application_id}/submit-survey",
            headers=ppl_headers,
            json={
                "kondisi_fisik_lahan": "BAIK",
                "kondisi_tanaman": "SESUAI",
                "rekomendasi": "SETUJU",
                "polygon_coords": polygon,
            },
        )
        self.assertEqual(missing_photos.status_code, 422, missing_photos.text)

        invalid_survey = self.client.post(
            f"/api/ppl/applications/{application_id}/submit-survey",
            headers=ppl_headers,
            json={
                "kondisi_fisik_lahan": "BAIK",
                "kondisi_tanaman": "SESUAI",
                "rekomendasi": "SETUJU",
                "polygon_coords": polygon[:2],
                "foto_survei_urls": survey_photo_urls,
            },
        )
        self.assertEqual(invalid_survey.status_code, 400, invalid_survey.text)

        submitted = self.client.post(
            f"/api/ppl/applications/{application_id}/submit-survey",
            headers=ppl_headers,
            json={
                "kondisi_fisik_lahan": "BAIK",
                "keterangan_fisik_lahan": "Batas uji terukur.",
                "kondisi_tanaman": "SESUAI",
                "keterangan_tanaman": "Tanaman uji.",
                "luas_lahan_aktual_m2": 1,
                "catatan_ppl": "Survei integrasi uji.",
                "rekomendasi": "SETUJU",
                "polygon_coords": polygon,
                "foto_survei_urls": survey_photo_urls,
            },
        )
        self.assertEqual(submitted.status_code, 200, submitted.text)
        self.assertGreater(float(submitted.json()["luas_lahan_aktual_m2"]), 0)

        with self.session_factory() as db:
            saved_land = db.get(Land, self.land_id)
            self.assertEqual(saved_land.luas_m2, Decimal("10000.00"))
            self.assertGreater(saved_land.luas_verifikasi_m2, 0)
            saved_polygon = json.loads(saved_land.polygon_coords)
            self.assertEqual(len(saved_polygon), 4)
            saved_survey = (
                db.query(FieldSurvey)
                .filter(FieldSurvey.application_id == application_id)
                .one()
            )
            self.assertEqual(saved_survey.foto_survei_urls, survey_photo_urls)
            self.assertEqual(
                db.get(Application, application_id).status,
                ApplicationStatus.MENUNGGU_PERSETUJUAN_AKHIR,
            )

        approved = self.client.post(
            f"/api/admin/applications/{application_id}/final-approve",
            headers=admin_headers,
            json={"action": "APPROVE", "jumlah_disetujui": 100},
        )
        self.assertEqual(approved.status_code, 200, approved.text)
        self.assertEqual(approved.json()["status"], ApplicationStatus.DIJADWALKAN_DISTRIBUSI)

        farmer_distributions = self.client.get(
            "/api/distributions/my",
            headers=farmer_headers,
        )
        self.assertEqual(farmer_distributions.status_code, 200, farmer_distributions.text)
        distributions = farmer_distributions.json()
        self.assertEqual(len(distributions), 4)
        self.assertTrue(
            all(item["status_penyaluran"] == "MENUNGGU_PENGAMBILAN" for item in distributions)
        )

        upload = self.client.post(
            "/api/files/upload",
            headers=farmer_headers,
            data={"category": "pupuk"},
            files={
                "file": (
                    "pupuk.png",
                    bytes.fromhex(
                        "89504e470d0a1a0a0000000d494844520000000100000001"
                        "08060000001f15c4890000000b49444154789c636000020000"
                        "050001a5f645400000000049454e44ae426082"
                    ),
                    "image/png",
                )
            },
        )
        self.assertEqual(upload.status_code, 200, upload.text)
        photo_url = upload.json()["url"]

        for distribution in distributions:
            redeemed = self.client.post(
                "/api/distributions/scan-qr",
                headers=farmer_headers,
                json={
                    "qr_token": distribution["qr_code_hash"],
                    "latitude": -7.5266,
                    "longitude": 112.5344,
                    "foto_pupuk_url": photo_url,
                },
            )
            self.assertEqual(redeemed.status_code, 200, redeemed.text)
            self.assertTrue(redeemed.json()["success"], redeemed.text)
            self.assertEqual(redeemed.json()["status"], "VALID")

        duplicate = self.client.post(
            "/api/distributions/scan-qr",
            headers=farmer_headers,
            json={
                "qr_token": distributions[0]["qr_code_hash"],
                "latitude": -7.5266,
                "longitude": 112.5344,
                "foto_pupuk_url": photo_url,
            },
        )
        self.assertEqual(duplicate.status_code, 200, duplicate.text)
        self.assertEqual(duplicate.json()["status"], "ALREADY_CLAIMED")

        for headers in (farmer_headers, ppl_headers, admin_headers):
            final_application = self.client.get(
                f"/api/applications/{application_id}",
                headers=headers,
            )
            self.assertEqual(final_application.status_code, 200, final_application.text)
            self.assertEqual(
                final_application.json()["status"],
                ApplicationStatus.TERSALURKAN,
            )

        with self.session_factory() as db:
            saved_application = db.get(Application, application_id)
            saved_distributions = (
                db.query(Distribution)
                .filter(Distribution.application_id == application_id)
                .all()
            )
            self.assertEqual(saved_application.status, ApplicationStatus.TERSALURKAN)
            self.assertEqual(len(saved_distributions), 4)
            self.assertTrue(
                all(item.status_penyaluran == "SELESAI" for item in saved_distributions)
            )


if __name__ == "__main__":
    unittest.main()
