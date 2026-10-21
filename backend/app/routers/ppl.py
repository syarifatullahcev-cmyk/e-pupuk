from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload
from app.core.database import get_db
from app.core.dependencies import get_current_user, require_role, log_audit_action
from app.models.models import (
    User, Application, ApplicationStatus, FieldSurvey, Notification
)
from app.schemas.schemas import (
    ApplicationResponse, FieldSurveyCreate, FieldSurveyResponse
)

router = APIRouter(prefix="/api/ppl", tags=["PPL Field Survey"])

@router.get("/assigned-tasks", response_model=List[ApplicationResponse])
def get_assigned_tasks(
    current_user: User = Depends(require_role("PPL", "ADMIN")),
    db: Session = Depends(get_db)
):
    query = db.query(Application).options(
        joinedload(Application.farmer),
        joinedload(Application.land),
        joinedload(Application.fertilizer),
        joinedload(Application.survey)
    )
    if current_user.role == "PPL":
        query = query.filter(Application.assigned_ppl_id == current_user.id)
        
    query = query.filter(
        Application.status.in_([
            ApplicationStatus.DITUGASKAN_KE_PPL,
            ApplicationStatus.SURVEI_LAPANGAN,
            ApplicationStatus.MENUNGGU_PERSETUJUAN_AKHIR
        ])
    )
    return query.order_by(Application.created_at.desc()).all()

@router.post("/applications/{id}/start-survey")
def start_survey(
    id: int,
    current_user: User = Depends(require_role("PPL", "ADMIN")),
    db: Session = Depends(get_db)
):
    app = db.query(Application).filter(Application.id == id).first()
    if not app:
        raise HTTPException(status_code=404, detail="Pengajuan tidak ditemukan")

    if current_user.role == "PPL" and app.assigned_ppl_id != current_user.id:
        raise HTTPException(status_code=403, detail="Tugas ini bukan untuk Anda")

    app.status = ApplicationStatus.SURVEI_LAPANGAN
    db.commit()
    db.refresh(app)
    return {"message": "Status survei lapangan dimulai", "status": app.status}

import json
from decimal import Decimal
from app.core.geo import validate_and_normalize_polygon, calculate_geodesic_polygon_area

@router.post("/applications/{id}/submit-survey", response_model=FieldSurveyResponse)
def submit_survey(
    id: int,
    data: FieldSurveyCreate,
    current_user: User = Depends(require_role("PPL", "ADMIN")),
    db: Session = Depends(get_db)
):
    app = db.query(Application).filter(Application.id == id).first()
    if not app:
        raise HTTPException(status_code=404, detail="Pengajuan tidak ditemukan")

    if current_user.role == "PPL" and app.assigned_ppl_id != current_user.id:
        raise HTTPException(status_code=403, detail="Tugas ini bukan untuk Anda")

    # 1. Validasi Geospasial Poligon jika disediakan
    polygon_json_str = None
    actual_area_m2 = data.luas_lahan_aktual_m2

    if data.polygon_coords:
        is_valid, err_msg, normalized_coords = validate_and_normalize_polygon(data.polygon_coords)
        if not is_valid:
            raise HTTPException(status_code=400, detail=f"Data poligon batas lahan tidak valid: {err_msg}")

        polygon_json_str = json.dumps(normalized_coords)
        server_area_m2 = calculate_geodesic_polygon_area(normalized_coords)

        # Jika luas aktual dari klien kosong atau 0, gunakan hasil kalkulasi server
        if actual_area_m2 is None or float(actual_area_m2) <= 0:
            actual_area_m2 = Decimal(str(server_area_m2))
        else:
            # Bandingkan luas kiriman klien dengan perhitungan geodetik server
            client_area = float(actual_area_m2)
            if abs(client_area - server_area_m2) > (0.1 * server_area_m2):
                # Gunakan hasil perhitungan geodetik server yang terpercaya
                actual_area_m2 = Decimal(str(server_area_m2))

    # 2. Upsert field survey
    survey = db.query(FieldSurvey).filter(FieldSurvey.application_id == app.id).first()
    if not survey:
        survey = FieldSurvey(
            application_id=app.id,
            ppl_id=current_user.id,
            kondisi_fisik_lahan=data.kondisi_fisik_lahan,
            keterangan_fisik_lahan=data.keterangan_fisik_lahan,
            kondisi_tanaman=data.kondisi_tanaman,
            keterangan_tanaman=data.keterangan_tanaman,
            luas_lahan_aktual_m2=actual_area_m2,
            polygon_coords=polygon_json_str,
            foto_survei_urls=data.foto_survei_urls,
            catatan_ppl=data.catatan_ppl,
            rekomendasi=data.rekomendasi
        )
        db.add(survey)
    else:
        survey.kondisi_fisik_lahan = data.kondisi_fisik_lahan
        survey.keterangan_fisik_lahan = data.keterangan_fisik_lahan
        survey.kondisi_tanaman = data.kondisi_tanaman
        survey.keterangan_tanaman = data.keterangan_tanaman
        survey.luas_lahan_aktual_m2 = actual_area_m2
        if polygon_json_str is not None:
            survey.polygon_coords = polygon_json_str
        survey.foto_survei_urls = data.foto_survei_urls
        survey.catatan_ppl = data.catatan_ppl
        survey.rekomendasi = data.rekomendasi

    # 3. Sinkronisasi ke entitas lahan petani (Land)
    if app.land:
        if polygon_json_str is not None:
            app.land.polygon_coords = polygon_json_str
        if actual_area_m2 is not None:
            app.land.luas_verifikasi_m2 = actual_area_m2
        app.land.status_verifikasi = "TERVERIFIKASI" if data.rekomendasi == "SETUJU" else "DITOLAK"
        app.land.catatan_verifikasi = data.catatan_ppl
        # PENTING: Luas awal pelaporan petani (app.land.luas_m2) tetap dipertahankan

    # 4. Advance application status to MENUNGGU_PERSETUJUAN_AKHIR
    app.status = ApplicationStatus.MENUNGGU_PERSETUJUAN_AKHIR

    # 5. Notifikasi Admin dan Petani
    admins = db.query(User).filter(User.role == "ADMIN").all()
    for adm in admins:
        db.add(Notification(
            user_id=adm.id,
            judul="Hasil Survei Lapangan Diserahkan",
            pesan=f"PPL {current_user.username} telah menyelesaikan survei lapangan untuk pengajuan #{app.id}. Rekomendasi: {data.rekomendasi}. Menunggu persetujuan akhir Anda.",
            tipe="INFO"
        ))

    if app.farmer and app.farmer.user_id:
        db.add(Notification(
            user_id=app.farmer.user_id,
            judul="Survei Lapangan Telah Selesai",
            pesan=f"Petugas PPL telah menyelesaikan verifikasi fisik lahan Anda. Pengajuan sedang menunggu persetujuan akhir dari Admin Dinas Pertanian.",
            tipe="INFO"
        ))

    db.commit()
    db.refresh(survey)

    log_audit_action(
        db,
        user_id=current_user.id,
        action="SUBMIT_FIELD_SURVEY",
        resource="field_surveys",
        resource_id=survey.id,
        details=f"Survey submitted for app #{app.id}: {data.rekomendasi}"
    )

    resp = FieldSurveyResponse.model_validate(survey)
    resp.ppl_nama = current_user.username
    return resp
