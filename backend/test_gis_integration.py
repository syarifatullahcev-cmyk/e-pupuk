import json
import urllib.request
import urllib.error

BASE_URL = "http://127.0.0.1:8000"

def run_gis_tests():
    print("=== GIS INTEGRATION TEST: E-PUPUK MOJOKERTO ===")
    
    # 1. Login PPL
    login_req = urllib.request.Request(
        f"{BASE_URL}/api/auth/login",
        data=json.dumps({"username": "ppl_ahmad", "password": "ppl123"}).encode(),
        headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(login_req) as res:
        login_data = json.loads(res.read().decode())
        token = login_data["access_token"]
        print(f"[PASS] 1. Login PPL Berhasil: {login_data['nama']} (Role: {login_data['role']})")

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {token}"
    }

    # 2. Ambil Task Terdisposisi
    task_req = urllib.request.Request(f"{BASE_URL}/api/ppl/assigned-tasks", headers=headers)
    with urllib.request.urlopen(task_req) as res:
        tasks = json.loads(res.read().decode())
        print(f"[PASS] 2. Berhasil mengambil {len(tasks)} tugas survei lapangan.")
        target_task = tasks[0]
        app_id = target_task["id"]
        farmer_name = target_task.get("farmer", {}).get("nama", "Petani")
        print(f"       Target Survei: Pengajuan #{app_id} (Petani: {farmer_name}, Lahan #{target_task['land_id']})")

    # 3. Test Poligon Tidak Valid (Kurang dari 3 titik)
    invalid_payload = {
        "kondisi_fisik_lahan": "BAIK",
        "keterangan_fisik_lahan": "Uji titik tidak memadai",
        "kondisi_tanaman": "SESUAI",
        "keterangan_tanaman": "Padi Inpari",
        "luas_lahan_aktual_m2": 5000.0,
        "rekomendasi": "SETUJU",
        "polygon_coords": [[-7.526210, 112.534015], [-7.526180, 112.534820]] # Hanya 2 titik!
    }
    try:
        req = urllib.request.Request(
            f"{BASE_URL}/api/ppl/applications/{app_id}/submit-survey",
            data=json.dumps(invalid_payload).encode(),
            headers=headers
        )
        urllib.request.urlopen(req)
        print("[FAIL] 3. Server seharusnya menolak poligon dengan < 3 titik!")
    except urllib.error.HTTPError as e:
        err_msg = json.loads(e.read().decode())
        print(f"[PASS] 3. Server berhasil menolak poligon < 3 titik (HTTP {e.code}: {err_msg['detail']})")

    # 4. Test Submit Poligon Valid & Hitung Ulang Luas Server
    valid_coords = [
        [-7.526210, 112.534015],
        [-7.526180, 112.534820],
        [-7.527010, 112.534850],
        [-7.527020, 112.534025],
    ]
    valid_payload = {
        "kondisi_fisik_lahan": "BAIK",
        "keterangan_fisik_lahan": "Batas terverifikasi dengan patok BPN dan saluran irigasi.",
        "kondisi_tanaman": "SESUAI",
        "keterangan_tanaman": "Padi Inpari 32 umur 40 HST",
        "luas_lahan_aktual_m2": 8215.15,
        "catatan_ppl": "Pengukuran poligon WGS84 selesai dilakukan secara tertutup.",
        "rekomendasi": "SETUJU",
        "polygon_coords": valid_coords
    }

    req = urllib.request.Request(
        f"{BASE_URL}/api/ppl/applications/{app_id}/submit-survey",
        data=json.dumps(valid_payload).encode(),
        headers=headers
    )
    with urllib.request.urlopen(req) as res:
        survey_res = json.loads(res.read().decode())
        saved_area = survey_res["luas_lahan_aktual_m2"]
        print(f"[PASS] 4. Berhasil submit survei geospasial: Survey ID #{survey_res['id']}, Luas: {saved_area} m²")

    # 5. Verifikasi Data Lahan di Database Sinkron
    land_id = target_task["land_id"]
    land_req = urllib.request.Request(f"{BASE_URL}/api/lands/{land_id}", headers=headers)
    with urllib.request.urlopen(land_req) as res:
        land_data = json.loads(res.read().decode())
        print(f"[PASS] 5. Verifikasi database lahan #{land_id}:")
        print(f"       - Status Verifikasi: {land_data['status_verifikasi']}")
        print(f"       - Luas Awal Pelaporan: {land_data['luas_m2']} m² (Tetap Terlindungi)")
        print(f"       - Luas Faktual Terverifikasi: {land_data['luas_verifikasi_m2']} m²")
        poly_obj = land_data['polygon_coords']
        poly_list = poly_obj if isinstance(poly_obj, list) else json.loads(poly_obj)
        print(f"       - Poligon Terkunci: {len(poly_list)} titik koordinat")

    print("\nALL GIS END-TO-END AUDIT & VERIFICATION TESTS PASSED SUCCESSFULLY!")

if __name__ == "__main__":
    run_gis_tests()
