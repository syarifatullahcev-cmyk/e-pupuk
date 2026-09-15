from typing import List, Optional
from decimal import Decimal
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload
from app.core.database import get_db
from app.core.dependencies import get_current_user, log_audit_action
from app.models.models import (
    User, Farmer, Land, Application, ApplicationStatus,
    Fertilizer, Notification, FieldSurvey
)
from app.schemas.schemas import (
    ApplicationCreate, ApplicationResponse, DashboardStatsPetani
)

router = APIRouter(prefix="/api/applications", tags=["Applications"])

@router.get("", response_model=List[ApplicationResponse])
def get_applications(
    status_filter: Optional[str] = None,
    farmer_id: Optional[int] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    query = db.query(Application).options(
        joinedload(Application.farmer),
        joinedload(Application.land),
        joinedload(Application.fertilizer),
        joinedload(Application.survey)
    )

    if current_user.role == "PETANI":
        farmer = db.query(Farmer).filter(Farmer.user_id == current_user.id).first()
        if not farmer:
            return []
        query = query.filter(Application.farmer_id == farmer.id)
    elif current_user.role == "PPL":
        query = query.filter(Application.assigned_ppl_id == current_user.id)
    elif farmer_id:
        query = query.filter(Application.farmer_id == farmer_id)

    if status_filter:
        query = query.filter(Application.status == status_filter)

    query = query.order_by(Application.created_at.desc())
    return query.all()

@router.get("/stats/petani", response_model=DashboardStatsPetani)
def get_petani_stats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != "PETANI":
        raise HTTPException(status_code=403, detail="Hanya petani yang dapat mengakses data ini")
        
    farmer = db.query(Farmer).filter(Farmer.user_id == current_user.id).first()
    if not farmer:
        return DashboardStatsPetani(
            total_pengajuan=0,
            aktif=0,
            disetujui=0,
            tersalurkan=0,
            total_lahan=0,
            kuota_tersedia_urea=Decimal("500"),
            kuota_tersedia_npk=Decimal("400")
        )

    apps = db.query(Application).filter(Application.farmer_id == farmer.id).all()
    lands_count = db.query(Land).filter(Land.farmer_id == farmer.id).count()

    total_pengajuan = len(apps)
    aktif = sum(1 for a in apps if a.status in [
        ApplicationStatus.DIAJUKAN,
        ApplicationStatus.MENUNGGU_VERIFIKASI_BERKAS,
        ApplicationStatus.PERLU_PERBAIKAN_BERKAS,
        ApplicationStatus.BERKAS_TERVERIFIKASI,
        ApplicationStatus.DITUGASKAN_KE_PPL,
        ApplicationStatus.SURVEI_LAPANGAN,
        ApplicationStatus.MENUNGGU_PERSETUJUAN_AKHIR
    ])
    disetujui = sum(1 for a in apps if a.status in [ApplicationStatus.DISETUJUI, ApplicationStatus.DIJADWALKAN_DISTRIBUSI])
    tersalurkan = sum(1 for a in apps if a.status == ApplicationStatus.TERSALURKAN)

    return DashboardStatsPetani(
        total_pengajuan=total_pengajuan,
        aktif=aktif,
        disetujui=disetujui,
        tersalurkan=tersalurkan,
        total_lahan=lands_count,
        kuota_tersedia_urea=Decimal("500"),
        kuota_tersedia_npk=Decimal("400")
    )

@router.get("/{id}", response_model=ApplicationResponse)
def get_application_detail(
    id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    app = db.query(Application).options(
        joinedload(Application.farmer),
        joinedload(Application.land),
        joinedload(Application.fertilizer),
        joinedload(Application.survey)
    ).filter(Application.id == id).first()

    if not app:
        raise HTTPException(status_code=404, detail="Pengajuan tidak ditemukan")

    if current_user.role == "PETANI":
        farmer = db.query(Farmer).filter(Farmer.user_id == current_user.id).first()
        if not farmer or app.farmer_id != farmer.id:
            raise HTTPException(status_code=403, detail="Akses pengajuan ditolak")

    return app

@router.post("", response_model=ApplicationResponse)
def create_application(
    data: ApplicationCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    farmer = db.query(Farmer).filter(Farmer.user_id == current_user.id).first()
    if not farmer:
        raise HTTPException(status_code=400, detail="Profil petani tidak ditemukan")

    land = db.query(Land).filter(Land.id == data.land_id, Land.farmer_id == farmer.id).first()
    if not land:
        raise HTTPException(status_code=400, detail="Lahan tidak valid atau bukan milik Anda")

    fertilizer = db.query(Fertilizer).filter(Fertilizer.id == data.fertilizer_id).first()
    if not fertilizer:
        raise HTTPException(status_code=400, detail="Jenis pupuk tidak valid")

    # Snapshot photos and coordinates
    new_app = Application(
        farmer_id=farmer.id,
        land_id=land.id,
        fertilizer_id=fertilizer.id,
        jumlah_diajukan=data.jumlah_diajukan,
        kuota_maksimal=Decimal("500.00"),
        status=ApplicationStatus.MENUNGGU_VERIFIKASI_BERKAS,
        foto_ktp_snapshot_url=farmer.foto_ktp_url,
        foto_lahan_snapshot_url=land.foto_lahan_url,
        alamat_lahan=data.alamat_lahan or land.alamat_lahan,
        latitude=data.latitude or land.latitude,
        longitude=data.longitude or land.longitude
    )
    db.add(new_app)
    db.commit()
    db.refresh(new_app)

    # Notification for farmer
    notif = Notification(
        user_id=current_user.id,
        judul="Pengajuan Subsidi Terkirim",
        pesan=f"Pengajuan subsidi pupuk {fertilizer.nama_pupuk} sebesar {data.jumlah_diajukan} kg telah berhasil diajukan dan sedang menunggu verifikasi berkas oleh Admin.",
        tipe="INFO"
    )
    db.add(notif)
    db.commit()

    log_audit_action(
        db,
        user_id=current_user.id,
        action="CREATE_APPLICATION",
        resource="applications",
        resource_id=new_app.id,
        details=f"Created application #{new_app.id} for {data.jumlah_diajukan} kg {fertilizer.nama_pupuk}"
    )

    return new_app

@router.put("/{id}/revise-docs", response_model=ApplicationResponse)
def revise_application_docs(
    id: int,
    foto_ktp_url: Optional[str] = None,
    foto_lahan_url: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    app = db.query(Application).filter(Application.id == id).first()
    if not app:
        raise HTTPException(status_code=404, detail="Pengajuan tidak ditemukan")

    farmer = db.query(Farmer).filter(Farmer.user_id == current_user.id).first()
    if not farmer or app.farmer_id != farmer.id:
        raise HTTPException(status_code=403, detail="Akses ditolak")

    if app.status != ApplicationStatus.PERLU_PERBAIKAN_BERKAS:
        raise HTTPException(status_code=400, detail="Pengajuan tidak dalam status perlu perbaikan berkas")

    if foto_ktp_url:
        app.foto_ktp_snapshot_url = foto_ktp_url
        farmer.foto_ktp_url = foto_ktp_url
    if foto_lahan_url:
        app.foto_lahan_snapshot_url = foto_lahan_url

    app.status = ApplicationStatus.MENUNGGU_VERIFIKASI_BERKAS
    db.commit()
    db.refresh(app)

    # Notification
    notif = Notification(
        user_id=current_user.id,
        judul="Berkas Perbaikan Terkirim",
        pesan=f"Perbaikan berkas untuk pengajuan #{app.id} telah dikirim ulang ke Admin.",
        tipe="SUCCESS"
    )
    db.add(notif)
    db.commit()

    return app

@router.put("/{id}/cancel")
def cancel_application(
    id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    app = db.query(Application).filter(Application.id == id).first()
    if not app:
        raise HTTPException(status_code=404, detail="Pengajuan tidak ditemukan")

    farmer = db.query(Farmer).filter(Farmer.user_id == current_user.id).first()
    if not farmer or app.farmer_id != farmer.id:
        raise HTTPException(status_code=403, detail="Akses ditolak")

    if app.status not in [ApplicationStatus.DIAJUKAN, ApplicationStatus.MENUNGGU_VERIFIKASI_BERKAS]:
        raise HTTPException(status_code=400, detail="Pengajuan tidak dapat dibatalkan pada tahap ini")

    app.status = ApplicationStatus.DITOLAK_BERKAS
    app.catatan_admin_berkas = "Dibatalkan oleh pemohon"
    db.commit()
    return {"message": "Pengajuan berhasil dibatalkan"}
