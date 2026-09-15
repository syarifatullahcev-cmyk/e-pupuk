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

    # Upsert field survey
    survey = db.query(FieldSurvey).filter(FieldSurvey.application_id == app.id).first()
    if not survey:
        survey = FieldSurvey(
            application_id=app.id,
            ppl_id=current_user.id,
            kondisi_fisik_lahan=data.kondisi_fisik_lahan,
            keterangan_fisik_lahan=data.keterangan_fisik_lahan,
            kondisi_tanaman=data.kondisi_tanaman,
            keterangan_tanaman=data.keterangan_tanaman,
            luas_lahan_aktual_m2=data.luas_lahan_aktual_m2,
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
        survey.luas_lahan_aktual_m2 = data.luas_lahan_aktual_m2
        survey.foto_survei_urls = data.foto_survei_urls
        survey.catatan_ppl = data.catatan_ppl
        survey.rekomendasi = data.rekomendasi

    # Advance application status to MENUNGGU_PERSETUJUAN_AKHIR
    app.status = ApplicationStatus.MENUNGGU_PERSETUJUAN_AKHIR

    # Notify Admin and Farmer
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

    resp = FieldSurveyResponse.from_orm(survey)
    resp.ppl_nama = current_user.username
    return resp
