import datetime
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload
from app.core.database import get_db
from app.core.dependencies import get_current_user, log_audit_action
from app.models.models import (
    User, Farmer, Application, ApplicationStatus, Distribution,
    QRScan, Notification
)
from app.schemas.schemas import (
    DistributionResponse, QRScanRequest, QRScanResponse, NotificationResponse
)

router = APIRouter(tags=["Distributions & QR Scanner"])

@router.get("/api/distributions/my", response_model=List[DistributionResponse])
def get_my_distributions(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    farmer = db.query(Farmer).filter(Farmer.user_id == current_user.id).first()
    if not farmer:
        return []

    dists = db.query(Distribution).join(Application).filter(
        Application.farmer_id == farmer.id
    ).options(
        joinedload(Distribution.application).joinedload(Application.fertilizer),
        joinedload(Distribution.application).joinedload(Application.land)
    ).all()

    return dists

@router.post("/api/distributions/scan-qr", response_model=QRScanResponse)
def scan_and_redeem_qr(
    data: QRScanRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    dist = db.query(Distribution).filter(Distribution.qr_code_hash == data.qr_token.strip()).first()
    if not dist:
        return QRScanResponse(
            success=False,
            status="INVALID",
            message="Kode QR tidak ditemukan atau tidak valid."
        )

    if dist.status_penyaluran == "SELESAI":
        return QRScanResponse(
            success=False,
            status="ALREADY_CLAIMED",
            message=f"Pupuk ini telah disalurkan pada {dist.tanggal_penyaluran.strftime('%d-%m-%Y %H:%M') if dist.tanggal_penyaluran else '-'}.",
            distribution=dist
        )

    # Mark as collected
    dist.status_penyaluran = "SELESAI"
    dist.tanggal_penyaluran = datetime.datetime.now()

    # Update application status
    if dist.application:
        dist.application.status = ApplicationStatus.TERSALURKAN

    # Record scan
    scan = QRScan(
        distribution_id=dist.id,
        scanner_user_id=current_user.id,
        latitude=data.latitude,
        longitude=data.longitude,
        validation_status="VALID"
    )
    db.add(scan)

    # Notify farmer
    if dist.application and dist.application.farmer:
        db.add(Notification(
            user_id=dist.application.farmer.user_id,
            judul="Pupuk Bersubsidi Telah Diterima",
            pesan=f"Pupuk bersubsidi sejumlah {dist.jumlah_disalurkan} kg telah berhasil disalurkan kepada Anda. Terima kasih!",
            tipe="SUCCESS"
        ))

    db.commit()
    db.refresh(dist)

    log_audit_action(
        db,
        user_id=current_user.id,
        action="REDEEM_QR_DISTRIBUTION",
        resource="distributions",
        resource_id=dist.id,
        details=f"Redeemed {dist.jumlah_disalurkan} kg via QR scan"
    )

    return QRScanResponse(
        success=True,
        status="VALID",
        message="Validasi berhasil! Penyaluran pupuk bersubsidi sukses dicatat.",
        distribution=dist
    )

@router.get("/api/notifications", response_model=List[NotificationResponse])
def get_user_notifications(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return db.query(Notification).filter(
        Notification.user_id == current_user.id
    ).order_by(Notification.created_at.desc()).limit(20).all()

@router.put("/api/notifications/{id}/read")
def mark_notification_read(
    id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    notif = db.query(Notification).filter(
        Notification.id == id,
        Notification.user_id == current_user.id
    ).first()
    if notif:
        notif.is_read = True
        db.commit()
    return {"message": "Notifikasi ditandai dibaca"}
