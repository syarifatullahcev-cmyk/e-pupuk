import json
import urllib.request
import urllib.error

BASE_URL = "http://127.0.0.1:8000/api"

def make_request(url, method="GET", headers=None, data=None):
    if headers is None:
        headers = {}
    body = None
    if data is not None:
        body = json.dumps(data).encode("utf-8")
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as response:
            res_body = response.read().decode("utf-8")
            return response.status, json.loads(res_body) if res_body else {}
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8")
        try:
            return e.code, json.loads(err_body)
        except Exception:
            return e.code, {"error": err_body}

def run_tests():
    print("=== TEST 1: HEALTH CHECK ===")
    status, res = make_request("http://127.0.0.1:8000/api/health")
    print(f"Status: {status}, Body: {res}")
    assert status == 200

    print("\n=== TEST 2: LOGIN PPL ===")
    status, auth_data = make_request(f"{BASE_URL}/auth/login", method="POST", data={"username": "ppl_ahmad", "password": "ppl123"})
    print(f"Status: {status}")
    assert status == 200, f"Login failed: {auth_data}"
    token = auth_data["access_token"]
    print(f"Logged in user: {auth_data.get('nama')}, Role: {auth_data.get('role')}")
    headers = {"Authorization": f"Bearer {token}"}

    print("\n=== TEST 3: GET FARMERS ===")
    status, farmers = make_request(f"{BASE_URL}/farmers", headers=headers)
    print(f"Status: {status}, Total farmers: {len(farmers)}")
    assert status == 200
    for f in farmers[:3]:
        poktan_nama = f.get('farmer_group', {}).get('nama_kelompok') if f.get('farmer_group') else '-'
        print(f" - [{f['id']}] {f['nama']} (NIK: {f.get('nik')}) - Poktan: {poktan_nama}")

    print("\n=== TEST 4: GET ASSIGNED TASKS PPL ===")
    status, tasks = make_request(f"{BASE_URL}/ppl/assigned-tasks", headers=headers)
    print(f"Status: {status}")
    assert status == 200
    print(f"Total Assigned Tasks for ppl_ahmad: {len(tasks)}")
    for t in tasks:
        farmer_nama = t.get('farmer', {}).get('nama') if t.get('farmer') else '-'
        print(f" - Task #{t['id']} | Status: {t['status']} | Petani: {farmer_nama} | Pupuk: {t.get('fertilizer', {}).get('nama_pupuk')} ({t.get('jumlah_diajukan')} kg)")

    if tasks:
        app_id = tasks[0]["id"]
        print(f"\n=== TEST 5: SUBMIT FIELD SURVEY WITH GIS POLYGON (App #{app_id}) ===")
        polygon = [
            [-7.526210, 112.534015],
            [-7.526180, 112.534820],
            [-7.527010, 112.534850],
            [-7.527020, 112.534025]
        ]
        survey_payload = {
            "kondisi_fisik_lahan": "BAIK",
            "keterangan_fisik_lahan": "Tapak sawah terpetakan rapi dengan patok BPN dan saluran irigasi.",
            "kondisi_tanaman": "SESUAI",
            "keterangan_tanaman": "Padi Inpari 32 vegetatif awal subur.",
            "luas_lahan_aktual_m2": 7850.0,
            "polygon_coords": polygon,
            "foto_survei_urls": ["/files/survei/lahan_sample1.jpg", "/files/survei/patok_sample1.jpg"],
            "catatan_ppl": "Patok batas sudut telah diverifikasi bersama pemilik petak berbatasan.",
            "rekomendasi": "SETUJU"
        }
        status, res = make_request(f"{BASE_URL}/ppl/applications/{app_id}/submit-survey", method="POST", headers=headers, data=survey_payload)
        print(f"Status: {status}")
        if status == 200:
            print(f"Survey ID #{res['id']} submitted successfully!")
            print(f" - Luas lahan aktual m2: {res.get('luas_lahan_aktual_m2')}")
            print(f" - Rekomendasi: {res.get('rekomendasi')}")
        else:
            print(f"Error: {res}")

    print("\nALL API ENDPOINT INTEGRATION TESTS COMPLETED SUCCESSFULLY!")

if __name__ == "__main__":
    run_tests()
