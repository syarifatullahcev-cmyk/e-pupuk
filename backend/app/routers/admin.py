import datetime
from decimal import Decimal
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.core.database import get_db
from app.core.dependencies import get_current_user, require_role, log_audit_action
from app.models.models import (
    User, Farmer, Land, Application, ApplicationStatus,
    Distribution, Notification, AuditLog, FieldSurvey
)
from app.schemas.schemas import (
    DashboardStatsAdmin, ApplicationResponse,
    ApplicationAdminVerifyRequest, ApplicationAssignPPLRequest,
    ApplicationFinalApproveRequest, UserResponse, AuditLogResponse
)

router = APIRouter(prefix="/api/admin", tags=["Admin Management"])

@router.get("/stats", response_model=DashboardStatsAdmin)
def get_admin_stats(
    current_user: User = Depends(require_role("ADMIN")),
    db: Session = Depends(get_db)
):
    total_pengajuan = db.query(Application).count()
    menunggu_verifikasi_berkas = db.query(Application).filter(
        Application.status.in_([ApplicationStatus.DIAJUKAN, ApplicationStatus.MENUNGGU_VERIFIKASI_BERKAS])
    ).count()
    perlu_survei_ppl = db.query(Application).filter(
        Application.status.in_([ApplicationStatus.BERKAS_TERVERIFIKASI, ApplicationStatus.DITUGASKAN_KE_PPL, ApplicationStatus.SURVEI_LAPANGAN])
    ).count()
    menunggu_persetujuan_akhir = db.query(Application).filter(
        Application.status == ApplicationStatus.MENUNGGU_PERSETUJUAN_AKHIR
    ).count()
    disetujui = db.query(Application).filter(
        Application.status.in_([ApplicationStatus.DISETUJUI, ApplicationStatus.DIJADWALKAN_DISTRIBUSI, ApplicationStatus.TERSALURKAN])
    ).count()
    ditolak = db.query(Application).filter(
        Application.status.in_([ApplicationStatus.DITOLAK_BERKAS, ApplicationStatus.DITOLAK_LAPANGAN])
    ).count()

    total_petani = db.query(Farmer).count()
    total_lahan_m2_res = db.query(func.sum(Land.luas_m2)).scalar() or Decimal("0")

    return DashboardStatsAdmin(
        total_pengajuan=total_pengajuan,
        menunggu_verifikasi_berkas=menunggu_verifikasi_berkas,
        perlu_survei_ppl=perlu_survei_ppl,
        menunggu_persetujuan_akhir=menunggu_persetujuan_akhir,
        disetujui=disetujui,
        ditolak=ditolak,
        total_petani=total_petani,
        total_lahan_m2=total_lahan_m2_res,
        kuota_urea_kg=Decimal("150000.00"),
        kuota_npk_kg=Decimal("120000.00")
    )

@router.get("/ppl-officers")
def get_ppl_officers(
    current_user: User = Depends(require_role("ADMIN")),
    db: Session = Depends(get_db)
):
    ppl_users = db.query(User).filter(User.role == "PPL", User.is_active == True).all()
    result = []
    for u in ppl_users:
        active_surveys = db.query(Application).filter(
            Application.assigned_ppl_id == u.id,
            Application.status.in_([ApplicationStatus.DITUGASKAN_KE_PPL, ApplicationStatus.SURVEI_LAPANGAN])
        ).count()
        result.append({
            "id": u.id,
            "username": u.username,
            "email": u.email,
            "active_tasks": active_surveys,
            "wilayah": "Mojokerto & Sekitarnya"
        })
    return result

@router.post("/applications/{id}/verify-docs")
def verify_application_docs(
    id: int,
    data: ApplicationAdminVerifyRequest,
    current_user: User = Depends(require_role("ADMIN")),
    db: Session = Depends(get_db)
):
    app = db.query(Application).filter(Application.id == id).first()
    if not app:
        raise HTTPException(status_code=404, detail="Pengajuan tidak ditemukan")

    app.admin_verifier_id = current_user.id
    app.admin_verified_at = datetime.datetime.now()
    app.catatan_admin_berkas = data.catatan

    farmer_user_id = app.farmer.user_id if app.farmer else None

    if data.action == "APPROVE":
        app.status = ApplicationStatus.BERKAS_TERVERIFIKASI
        if farmer_user_id:
            db.add(Notification(
                user_id=farmer_user_id,
                judul="Berkas Terverifikasi",
                pesan=f"Berkas pengajuan #{app.id} telah lolos verifikasi admin. Menunggu penugasan survei PPL.",
                tipe="SUCCESS"
            ))
    elif data.action == "PERBAIKAN":
        app.status = ApplicationStatus.PERLU_PERBAIKAN_BERKAS
        if farmer_user_id:
            db.add(Notification(
                user_id=farmer_user_id,
                judul="Perlu Perbaikan Berkas",
                pesan=f"Berkas pengajuan #{app.id} perlu diperbaiki: {data.catatan or 'Periksa kembali foto dokumen'}",
                tipe="WARNING"
            ))
    elif data.action == "TOLAK":
        app.status = ApplicationStatus.DITOLAK_BERKAS
        if farmer_user_id:
            db.add(Notification(
                user_id=farmer_user_id,
                judul="Pengajuan Ditolak (Berkas)",
                pesan=f"Pengajuan #{app.id} ditolak pada verifikasi berkas. Alasan: {data.catatan}",
                tipe="DANGER"
            ))
    else:
        raise HTTPException(status_code=400, detail="Aksi tidak valid (APPROVE / PERBAIKAN / TOLAK)")

    db.commit()
    db.refresh(app)

    log_audit_action(
        db,
        user_id=current_user.id,
        action=f"VERIFY_DOCS_{data.action}",
        resource="applications",
        resource_id=app.id,
        details=f"Admin {current_user.username} verified docs: {data.action}. Note: {data.catatan}"
    )

    return {"message": "Status verifikasi berkas berhasil diperbarui", "status": app.status}

@router.post("/applications/{id}/assign-ppl")
def assign_ppl(
    id: int,
    data: ApplicationAssignPPLRequest,
    current_user: User = Depends(require_role("ADMIN")),
    db: Session = Depends(get_db)
):
    app = db.query(Application).filter(Application.id == id).first()
    if not app:
        raise HTTPException(status_code=404, detail="Pengajuan tidak ditemukan")

    ppl = db.query(User).filter(User.id == data.ppl_id, User.role == "PPL").first()
    if not ppl:
        raise HTTPException(status_code=400, detail="Petugas PPL tidak valid")

    app.assigned_ppl_id = ppl.id
    app.assigned_at = datetime.datetime.now()
    app.catatan_penugasan = data.catatan
    app.status = ApplicationStatus.DITUGASKAN_KE_PPL

    # Notify PPL
    db.add(Notification(
        user_id=ppl.id,
        judul="Tugas Survei Lapangan Baru",
        pesan=f"Anda ditugaskan melakukan survei fisik lahan untuk pengajuan #{app.id} (Petani: {app.farmer.nama if app.farmer else 'Petani'}). Catatan: {data.catatan or '-'}",
        tipe="INFO"
    ))

    # Notify Farmer
    if app.farmer and app.farmer.user_id:
        db.add(Notification(
            user_id=app.farmer.user_id,
            judul="PPL Telah Ditugaskan",
            pesan=f"Petugas PPL ({ppl.username}) telah ditugaskan untuk melakukan verifikasi fisik lahan Anda.",
            tipe="INFO"
        ))

    db.commit()
    db.refresh(app)

    log_audit_action(
        db,
        user_id=current_user.id,
        action="ASSIGN_PPL",
        resource="applications",
        resource_id=app.id,
        details=f"Assigned to PPL {ppl.username} (ID: {ppl.id})"
    )

    return {"message": "PPL berhasil ditugaskan", "status": app.status}

@router.post("/applications/{id}/final-approve")
def final_approve_application(
    id: int,
    data: ApplicationFinalApproveRequest,
    current_user: User = Depends(require_role("ADMIN")),
    db: Session = Depends(get_db)
):
    app = db.query(Application).filter(Application.id == id).first()
    if not app:
        raise HTTPException(status_code=404, detail="Pengajuan tidak ditemukan")

    app.final_approver_id = current_user.id
    app.final_approved_at = datetime.datetime.now()
    app.catatan_final_admin = data.catatan

    farmer_user_id = app.farmer.user_id if app.farmer else None

    if data.action == "APPROVE":
        app.status = ApplicationStatus.DISETUJUI
        app.jumlah_disetujui = data.jumlah_disetujui or app.jumlah_diajukan

        # Keep distribution allocation separate from the physical bag QR.
        existing_dist = db.query(Distribution).filter(Distribution.application_id == app.id).first()
        if not existing_dist:
            dist = Distribution(
                application_id=app.id,
                jumlah_disalurkan=app.jumlah_disetujui,
                status_penyaluran="MENUNGGU_PENGAMBILAN"
            )
            db.add(dist)
            app.status = ApplicationStatus.DIJADWALKAN_DISTRIBUSI

        if farmer_user_id:
            db.add(Notification(
                user_id=farmer_user_id,
                judul="Pengajuan Subsidi Disetujui!",
                pesan=f"Selamat! Pengajuan subsidi pupuk #{app.id} telah disetujui untuk kuota {app.jumlah_disetujui} kg. Pembukaan pupuk menggunakan QR pada karung pupuk.",
                tipe="SUCCESS"
            ))

    elif data.action == "REJECT":
        app.status = ApplicationStatus.DITOLAK_LAPANGAN
        if farmer_user_id:
            db.add(Notification(
                user_id=farmer_user_id,
                judul="Pengajuan Subsidi Ditolak",
                pesan=f"Pengajuan subsidi pupuk #{app.id} ditolak pada keputusan akhir. Alasan: {data.catatan}",
                tipe="DANGER"
            ))
    else:
        raise HTTPException(status_code=400, detail="Aksi tidak valid (APPROVE / REJECT)")

    db.commit()
    db.refresh(app)

    log_audit_action(
        db,
        user_id=current_user.id,
        action=f"FINAL_APPROVE_{data.action}",
        resource="applications",
        resource_id=app.id,
        details=f"Admin {current_user.username} decided: {data.action} ({app.jumlah_disetujui} kg)"
    )

    return {"message": "Keputusan akhir berhasil disimpan", "status": app.status}

@router.get("/audit-logs", response_model=List[AuditLogResponse])
def get_audit_logs(
    limit: int = 50,
    current_user: User = Depends(require_role("ADMIN")),
    db: Session = Depends(get_db)
):
    return db.query(AuditLog).order_by(AuditLog.created_at.desc()).limit(limit).all()
