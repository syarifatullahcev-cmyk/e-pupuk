import datetime
import json
from pathlib import Path
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session, joinedload
from app.core.database import get_db
from app.core.dependencies import get_current_user, log_audit_action
from app.core.config import settings
from app.core.geo import calculate_distance_meters
from app.models.models import (
    User, Farmer, Application, ApplicationStatus, Distribution,
    QRScan, Notification
)
from app.schemas.schemas import (
    DistributionResponse, QRScanRequest, QRScanResponse, NotificationResponse
)

router = APIRouter(tags=["Distributions & QR Scanner"])
GEOFENCE_RADIUS_METERS = 100


def _point_in_polygon(latitude: float, longitude: float, raw_polygon: str) -> bool:
    try:
        polygon = json.loads(raw_polygon)
    except (TypeError, json.JSONDecodeError):
        return False
    if not isinstance(polygon, list) or len(polygon) < 3:
        return False

    inside = False
    previous = polygon[-1]
    for current in polygon:
        try:
            current_lat, current_lon = float(current[0]), float(current[1])
            previous_lat, previous_lon = float(previous[0]), float(previous[1])
        except (TypeError, ValueError, IndexError):
            return False
        crosses = (current_lat > latitude) != (previous_lat > latitude)
        if crosses:
            intersection_lon = (
                (previous_lon - current_lon)
                * (latitude - current_lat)
                / (previous_lat - current_lat)
                + current_lon
            )
            if longitude < intersection_lon:
                inside = not inside
        previous = current
    return inside


def _location_matches_land(
    latitude: float,
    longitude: float,
    land: object,
) -> bool:
    polygon = getattr(land, "polygon_coords", None)
    if polygon and _point_in_polygon(latitude, longitude, polygon):
        return True

    land_latitude = getattr(land, "latitude", None)
    land_longitude = getattr(land, "longitude", None)
    if land_latitude is None or land_longitude is None:
        return False
    return calculate_distance_meters(
        latitude,
        longitude,
        float(land_latitude),
        float(land_longitude),
    ) <= GEOFENCE_RADIUS_METERS

@router.get("/api/distributions/my", response_model=List[DistributionResponse])
def get_my_distributions(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != "PETANI":
        raise HTTPException(status_code=403, detail="Hanya petani yang dapat melihat QR miliknya")
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
    if current_user.role != "PETANI":
        raise HTTPException(status_code=403, detail="Hanya petani yang dapat memindai QR pupuk")

    photo_path = data.foto_pupuk_url.removeprefix("/files/pupuk/")
    if (
        not data.foto_pupuk_url.startswith("/files/pupuk/")
        or not photo_path
        or Path(photo_path).name != photo_path
        or not (settings.PUPUK_DIR / photo_path).is_file()
    ):
        raise HTTPException(status_code=400, detail="Foto pupuk wajib diunggah sebelum pemindaian")

    farmer = db.query(Farmer).filter(Farmer.user_id == current_user.id).first()
    if not farmer:
        raise HTTPException(status_code=403, detail="Profil petani tidak ditemukan")

    dist = (
        db.query(Distribution)
        .options(
            joinedload(Distribution.application).joinedload(Application.land),
            joinedload(Distribution.application).joinedload(Application.farmer),
            joinedload(Distribution.batch),
        )
        .filter(Distribution.qr_code_hash == data.qr_token.strip())
        .with_for_update()
        .first()
    )
    if not dist:
        return QRScanResponse(
            success=False,
            status="INVALID",
            message="Kode QR tidak ditemukan atau tidak valid."
        )

    if not dist.application or dist.application.farmer_id != farmer.id:
        raise HTTPException(status_code=403, detail="QR ini bukan milik pengajuan Anda")

    if dist.status_penyaluran == "SELESAI":
        return QRScanResponse(
            success=False,
            status="ALREADY_CLAIMED",
            message=f"Pupuk ini telah disalurkan pada {dist.tanggal_penyaluran.strftime('%d-%m-%Y %H:%M') if dist.tanggal_penyaluran else '-'}.",
            distribution=dist
        )

    if dist.status_penyaluran != "MENUNGGU_PENGAMBILAN":
        raise HTTPException(status_code=400, detail="QR ini tidak aktif untuk pembukaan pupuk")

    if dist.batch and dist.batch.expired_date < datetime.date.today():
        return QRScanResponse(
            success=False,
            status="EXPIRED",
            message="Masa berlaku pupuk pada karung ini telah habis.",
            distribution=dist,
        )

    land = dist.application.land
    latitude = float(data.latitude)
    longitude = float(data.longitude)
    location_matches = land is not None and _location_matches_land(
        latitude,
        longitude,
        land,
    )
    if not location_matches:
        db.add(QRScan(
            distribution_id=dist.id,
            scanner_user_id=current_user.id,
            latitude=data.latitude,
            longitude=data.longitude,
            foto_pupuk_url=data.foto_pupuk_url,
            validation_status="INVALID",
        ))
        db.commit()
        return QRScanResponse(
            success=False,
            status="INVALID",
            message="Lokasi GPS tidak sesuai dengan lahan terdaftar.",
            distribution=dist,
        )

    dist.status_penyaluran = "SELESAI"
    dist.tanggal_penyaluran = datetime.datetime.now()
    db.flush()

    unfinished_bags = db.query(Distribution).filter(
        Distribution.application_id == dist.application_id,
        Distribution.status_penyaluran == "MENUNGGU_PENGAMBILAN",
    ).count()
    if unfinished_bags == 0:
        dist.application.status = ApplicationStatus.TERSALURKAN

    scan = QRScan(
        distribution_id=dist.id,
        scanner_user_id=current_user.id,
        latitude=data.latitude,
        longitude=data.longitude,
        foto_pupuk_url=data.foto_pupuk_url,
        validation_status="VALID"
    )
    db.add(scan)

    if dist.application and dist.application.farmer:
        db.add(Notification(
            user_id=dist.application.farmer.user_id,
            judul="Pembukaan Pupuk di Lahan Berhasil",
            pesan=f"Pembukaan karung {dist.jumlah_disalurkan} kg berhasil divalidasi di lahan terdaftar.",
            tipe="SUCCESS"
        ))

    db.commit()
    db.refresh(dist)

    log_audit_action(
        db,
        user_id=current_user.id,
        action="OPEN_FERTILIZER_VALIDATION",
        resource="distributions",
        resource_id=dist.id,
        details=f"Validated fertilizer opening: {dist.jumlah_disalurkan} kg at lat {data.latitude}, lng {data.longitude}"
    )

    return QRScanResponse(
        success=True,
        status="VALID",
        message="Validasi berhasil! Pembukaan dan penggunaan pupuk di lahan sukses dicatat.",
        distribution=dist
    )

@router.get("/api/distributions/scans/my")
def get_my_scans(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != "PETANI":
        raise HTTPException(status_code=403, detail="Hanya petani yang dapat melihat riwayat pemindaian")
    farmer = db.query(Farmer).filter(Farmer.user_id == current_user.id).first()
    if not farmer:
        return []

    scans = (
        db.query(QRScan)
        .join(Distribution, QRScan.distribution_id == Distribution.id)
        .join(Application, Distribution.application_id == Application.id)
        .filter(Application.farmer_id == farmer.id)
        .order_by(QRScan.scan_timestamp.desc())
        .all()
    )

    results = []
    for s in scans:
        dist = s.distribution
        app = dist.application if dist else None
        results.append({
            "id": s.id,
            "distribution_id": s.distribution_id,
            "tanggal": s.scan_timestamp.strftime("%d %B %Y") if s.scan_timestamp else "-",
            "waktu": s.scan_timestamp.strftime("%H:%M WIB") if s.scan_timestamp else "-",
            "scan_timestamp": s.scan_timestamp.isoformat() if s.scan_timestamp else None,
            "jenis_pupuk": (app.fertilizer.nama_pupuk + " Bersubsidi") if (app and app.fertilizer) else "Pupuk Bersubsidi",
            "jumlah_pupuk": f"{dist.jumlah_disalurkan} kg" if dist else "0 kg",
            "jumlah_kg": float(dist.jumlah_disalurkan) if dist else 0,
            "nama_lahan": (app.land.lokasi_deskripsi or app.land.alamat_lahan) if (app and app.land) else "Lahan Pertanian Terdaftar",
            "alamat_lahan": app.land.alamat_lahan if (app and app.land) else "-",
            "latitude": float(s.latitude) if s.latitude is not None else None,
            "longitude": float(s.longitude) if s.longitude is not None else None,
            "foto_pupuk_url": s.foto_pupuk_url,
            "status_pembukaan": "Pembukaan Berhasil",
            "status_validasi": s.validation_status or "VALID",
            "verifikasi_lokasi": "Lokasi sesuai dengan lahan terdaftar"
        })
    return results

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
    if not notif:
        raise HTTPException(status_code=404, detail="Notifikasi tidak ditemukan")
    notif.is_read = True
    db.commit()
    return {"message": "Notifikasi ditandai dibaca"}
