import os
import sys
import json
import urllib.request
import urllib.error

# Pastikan path backend masuk ke sys.path
backend_dir = os.path.dirname(os.path.abspath(__file__))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

from app.core.geo import validate_and_normalize_polygon, calculate_geodesic_polygon_area
from app.core.database import SessionLocal
from app.models.models import Land, FieldSurvey, Application, User

BASE_URL = "http://127.0.0.1:8000"

def api_request(path: str, method: str = "GET", data: dict = None, token: str = None):
    url = f"{BASE_URL}{path}"
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    
    body = json.dumps(data).encode("utf-8") if data else None
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    
    try:
        with urllib.request.urlopen(req) as res:
            res_body = res.read().decode("utf-8")
            return res.status, json.loads(res_body) if res_body else {}
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8")
        try:
            return e.code, json.loads(err_body)
        except Exception:
            return e.code, {"detail": err_body}

def run_tests():
    print("==================================================")
    print("MENJALANKAN PENGUJIAN TAHAP 1: BACKEND & DATABASE")
    print("==================================================")

    # 1. Test Rumus Geospasial
    print("\n[TEST 1] Pengujian Rumus Geodesic Poligon:")
    # Koordinat petak sawah sampel di Trowulan, Mojokerto (~2.000 m²)
    sample_polygon = [
        [-7.545100, 112.385100],
        [-7.545100, 112.385550],
        [-7.545500, 112.385550],
        [-7.545500, 112.385100]
    ]
    is_valid, err, normalized = validate_and_normalize_polygon(sample_polygon)
    assert is_valid, f"Validasi gagal: {err}"
    assert len(normalized) == 4
    area_m2 = calculate_geodesic_polygon_area(normalized)
    print(f" -> Titik ternormalisasi: {len(normalized)} titik")
    print(f" -> Luas terhitung: {area_m2} m² ({(area_m2/10000):.4f} Ha)")
    assert 1800 <= area_m2 <= 2500, f"Perhitungan luas tidak wajar: {area_m2}"
    print(" -> [PASS] Rumus geodesik dan validasi poligon sukses!")

    # 2. Test Invalid Polygon
    print("\n[TEST 2] Pengujian Validasi Poligon Anomali:")
    invalid_polygon = [[-7.5, 112.5], [-7.6, 112.6]] # Hanya 2 titik
    is_valid, err, _ = validate_and_normalize_polygon(invalid_polygon)
    assert not is_valid
    print(f" -> Berhasil menolak 2 titik: '{err}'")
    print(" -> [PASS] Validasi anomali poligon sukses!")

    # 3. Test Admin Verifikasi & Penugasan ke PPL, lalu PPL Submit Survei dengan Poligon
    print("\n[TEST 3] Pengujian Alur Admin Penugasan & PPL Submit Survei Poligon:")
    # Login Admin
    status, login_admin = api_request("/api/auth/login", method="POST", data={"username": "admin", "password": "admin123"})
    assert status == 200, f"Login Admin gagal: {login_admin}"
    token_admin = login_admin["access_token"]

    # Cari pengajuan yang menunggu verifikasi berkas (misal #8)
    status, all_apps = api_request("/api/applications", method="GET", token=token_admin)
    assert status == 200, f"Ambil antrean applications gagal: {all_apps}"
    target_app = next((a for a in all_apps if a["status"] == "MENUNGGU_VERIFIKASI_BERKAS"), all_apps[0])
    task_id = target_app["id"]
    land_id = target_app["land_id"]
    print(f" -> Admin memilih Pengajuan #{task_id} (Land #{land_id})")

    # Admin verifikasi berkas
    status, verify_res = api_request(
        f"/api/admin/applications/{task_id}/verify-docs",
        method="POST",
        data={"action": "APPROVE", "catatan": "Berkas lengkap dan sesuai kriteria."},
        token=token_admin
    )
    assert status == 200, f"Verifikasi berkas gagal: {verify_res}"
    print(f" -> Admin berhasil verifikasi berkas #{task_id}: {verify_res['status']}")

    # Admin tugaskan ke PPL Ahmad (ID 4)
    status, assign_res = api_request(
        f"/api/admin/applications/{task_id}/assign-ppl",
        method="POST",
        data={"ppl_id": 4, "catatan": "Lakukan pemetaan poligon dan cek kondisi fisik sawah."},
        token=token_admin
    )
    assert status == 200, f"Penugasan PPL gagal: {assign_res}"
    print(f" -> Admin berhasil menugaskan Pengajuan #{task_id} ke PPL Ahmad: {assign_res['status']}")

    # Sekarang login sebagai PPL Ahmad
    status, login_res = api_request("/api/auth/login", method="POST", data={"username": "ppl_ahmad", "password": "ppl123"})
    assert status == 200, f"Login PPL gagal: {login_res}"
    token_ppl = login_res["access_token"]

    # Ambil task survei
    status, tasks = api_request("/api/ppl/assigned-tasks", method="GET", token=token_ppl)
    assert status == 200, f"Ambil task gagal: {tasks}"
    assigned_task = next((t for t in tasks if t["id"] == task_id), None)
    assert assigned_task is not None, f"Task #{task_id} tidak ditemukan di antrean PPL Ahmad"
    print(f" -> PPL Ahmad menemukan Task #{task_id} di antrean surveinya!")

    # Ambil data lahan awal sebelum survei langsung dari database
    db = SessionLocal()
    land_before = db.query(Land).filter(Land.id == land_id).first()
    luas_awal_petani = float(land_before.luas_m2)
    db.close()
    print(f" -> Luas awal lapor Petani pada Land #{land_id}: {luas_awal_petani} m²")

    # PPL submit survei dengan koordinat poligon
    survey_payload = {
        "kondisi_fisik_lahan": "BAIK",
        "keterangan_fisik_lahan": "Irigasi lancar, tanah lempung subur terverifikasi peta satelit.",
        "kondisi_tanaman": "SESUAI",
        "keterangan_tanaman": "Padi Ciherang umur 25 HST",
        "luas_lahan_aktual_m2": area_m2,
        "polygon_coords": sample_polygon,
        "catatan_ppl": "Pengukuran batas pematang sawah menggunakan citra satelit resolusi tinggi.",
        "rekomendasi": "SETUJU",
        "foto_survei_urls": ["/files/survei/sample_survey.jpg"]
    }

    status, survey_data = api_request(
        f"/api/ppl/applications/{task_id}/submit-survey",
        method="POST",
        data=survey_payload,
        token=token_ppl
    )
    assert status == 200, f"Submit survey gagal: {survey_data}"
    print(f" -> Response Survey: id={survey_data['id']}, rekomendasi={survey_data['rekomendasi']}")
    assert survey_data["polygon_coords"] is not None
    assert len(survey_data["polygon_coords"]) == 4
    print(" -> [PASS] Field survey menyimpan polygon_coords dengan benar!")

    # 4. Verifikasi Data Lahan di Database Pasca Survei
    print("\n[TEST 4] Verifikasi Integritas Entitas Land:")
    db = SessionLocal()
    land_after = db.query(Land).filter(Land.id == land_id).first()
    print(f" -> Status verifikasi lahan: {land_after.status_verifikasi}")
    print(f" -> Luas awal lapor petani: {land_after.luas_m2} m²")
    print(f" -> Luas hasil ukur PPL: {land_after.luas_verifikasi_m2} m²")
    print(f" -> Catatan verifikasi: {land_after.catatan_verifikasi}")

    assert land_after.status_verifikasi == "TERVERIFIKASI"
    assert float(land_after.luas_m2) == luas_awal_petani, "PERINGATAN: Luas awal petani tertimpa!"
    assert float(land_after.luas_verifikasi_m2) == area_m2
    assert land_after.polygon_coords is not None
    db.close()
    print(" -> [PASS] Pemisahan luas petani vs luas ukur PPL berhasil & data poligon tersimpan utuh!")

    # 5. Test Endpoint GET /api/lands (Admin View)
    print("\n[TEST 5] Pengujian API GET /api/lands (Admin View):")
    status, login_admin = api_request("/api/auth/login", method="POST", data={"username": "admin", "password": "admin123"})
    assert status == 200
    token_admin = login_admin["access_token"]
    status, lands_list = api_request("/api/lands", method="GET", token=token_admin)
    assert status == 200
    verified_land = next((l for l in lands_list if l["id"] == land_id), None)
    assert verified_land is not None
    assert verified_land["status_verifikasi"] == "TERVERIFIKASI"
    assert isinstance(verified_land["polygon_coords"], list)
    assert len(verified_land["polygon_coords"]) == 4
    print(f" -> Land #{land_id} polygon_coords ter-deserialize otomatis: {verified_land['polygon_coords']}")
    print(" -> [PASS] Deserialisasi polygon_coords pada API lands berfungsi!")

    # 6. Test Petani Tambah Lahan dengan Dokumen Sertifikat
    print("\n[TEST 6] Pengujian Petani Tambah Lahan:")
    status, login_petani = api_request("/api/auth/login", method="POST", data={"username": "petani_budi", "password": "petani123"})
    assert status == 200
    token_petani = login_petani["access_token"]

    new_land_payload = {
        "lokasi_deskripsi": "Sawah Blok C Sumbergirang",
        "alamat_lahan": "Desa Sumbergirang, Kec. Puri, Kab. Mojokerto",
        "latitude": -7.535000,
        "longitude": 112.445000,
        "luas_m2": 3500,
        "status_kepemilikan": "MILIK",
        "dokumen_sertifikat_url": "/files/sertifikat/sertifikat_budi_01.pdf"
    }

    status, created_land = api_request("/api/lands", method="POST", data=new_land_payload, token=token_petani)
    assert status == 200, f"Tambah lahan gagal: {created_land}"
    print(f" -> Berhasil tambah Lahan #{created_land['id']}: {created_land['lokasi_deskripsi']}")
    print(f" -> Dokumen sertifikat tersimpan: {created_land['dokumen_sertifikat_url']}")
    print(f" -> Status verifikasi default: {created_land['status_verifikasi']}")
    assert created_land["status_verifikasi"] == "BELUM_DIVERIFIKASI"
    assert created_land["dokumen_sertifikat_url"] == "/files/sertifikat/sertifikat_budi_01.pdf"
    print(" -> [PASS] Tambah lahan dengan sertifikat sukses!")

    print("\n==================================================")
    print("SELURUH PENGUJIAN TAHAP 1 BERHASIL (100% PASS)!")
    print("==================================================")

if __name__ == "__main__":
    run_tests()
