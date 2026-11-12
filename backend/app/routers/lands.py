from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.dependencies import get_current_user, log_audit_action
from app.models.models import (
    Application,
    ApplicationStatus,
    Farmer,
    Land,
    Notification,
    User,
)
from app.schemas.schemas import LandCreate, LandUpdate, LandResponse

router = APIRouter(prefix="/api/lands", tags=["Lands"])

@router.get("", response_model=List[LandResponse])
def get_lands(
    farmer_id: Optional[int] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    query = db.query(Land)
    if current_user.role == "PETANI":
        farmer = db.query(Farmer).filter(Farmer.user_id == current_user.id).first()
        if not farmer:
            return []
        query = query.filter(Land.farmer_id == farmer.id)
    elif farmer_id:
        query = query.filter(Land.farmer_id == farmer_id)
        
    return query.all()

@router.get("/{id}", response_model=LandResponse)
def get_land(
    id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    land = db.query(Land).filter(Land.id == id).first()
    if not land:
        raise HTTPException(status_code=404, detail="Data lahan tidak ditemukan")
    return land

@router.post("", response_model=LandResponse)
def create_land(
    data: LandCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    target_farmer_id = data.farmer_id
    if current_user.role == "PETANI":
        farmer = db.query(Farmer).filter(Farmer.user_id == current_user.id).first()
        if not farmer:
            raise HTTPException(status_code=400, detail="Profil petani Anda belum terdaftar")
        target_farmer_id = farmer.id
    elif not target_farmer_id:
        raise HTTPException(status_code=400, detail="ID Petani wajib diisi")

    land_dict = data.dict(exclude={"farmer_id"})
    if "polygon_coords" in land_dict and land_dict["polygon_coords"] is not None:
        if not isinstance(land_dict["polygon_coords"], str):
            import json
            land_dict["polygon_coords"] = json.dumps(land_dict["polygon_coords"])

    new_land = Land(
        farmer_id=target_farmer_id,
        **land_dict
    )
    db.add(new_land)
    db.commit()
    db.refresh(new_land)
    return new_land

@router.put("/{id}", response_model=LandResponse)
def update_land(
    id: int,
    data: LandUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    land = db.query(Land).filter(Land.id == id).first()
    if not land:
        raise HTTPException(status_code=404, detail="Data lahan tidak ditemukan")
        
    if current_user.role == "PETANI":
        farmer = db.query(Farmer).filter(Farmer.user_id == current_user.id).first()
        if not farmer or land.farmer_id != farmer.id:
            raise HTTPException(status_code=403, detail="Anda tidak memiliki akses untuk mengubah lahan ini")

    import json
    updates = data.dict(exclude_unset=True)
    if current_user.role == "PETANI":
        restricted_fields = {
            "polygon_coords",
            "luas_verifikasi_m2",
            "status_verifikasi",
            "catatan_verifikasi",
        }
        attempted_restricted_fields = restricted_fields.intersection(updates)
        if attempted_restricted_fields:
            raise HTTPException(
                status_code=403,
                detail="Data hasil verifikasi hanya dapat diubah oleh petugas berwenang.",
            )

    land_documents_changed = any(
        key in updates and updates[key] != getattr(land, key)
        for key in ("foto_lahan_url", "dokumen_sertifikat_url")
    )
    for key, val in updates.items():
        if key == "polygon_coords" and val is not None and not isinstance(val, str):
            val = json.dumps(val)
        setattr(land, key, val)

    if land_documents_changed and current_user.role == "PETANI":
        pending_applications = db.query(Application).filter(
            Application.land_id == land.id,
            Application.status.in_([
                ApplicationStatus.MENUNGGU_VERIFIKASI_BERKAS,
                ApplicationStatus.PERLU_PERBAIKAN_BERKAS,
            ]),
        ).all()
        for application in pending_applications:
            application.foto_lahan_snapshot_url = land.foto_lahan_url
            application.status = ApplicationStatus.MENUNGGU_VERIFIKASI_BERKAS
            application.admin_verifier_id = None
            application.admin_verified_at = None
            application.catatan_admin_berkas = (
                "Dokumen lahan diperbarui oleh petani; perlu diverifikasi ulang."
            )

        if pending_applications:
            db.add(Notification(
                user_id=current_user.id,
                judul="Dokumen Lahan Diperbarui",
                pesan=(
                    f"Dokumen lahan {land.lokasi_deskripsi or land.id} tersimpan. "
                    "Pengajuan yang masih menunggu verifikasi berkas telah dikirim "
                    "ulang untuk ditinjau Admin."
                ),
                tipe="INFO",
            ))

        log_audit_action(
            db,
            user_id=current_user.id,
            action="UPDATE_LAND_DOCUMENTS",
            resource="lands",
            resource_id=land.id,
            details=f"Petani memperbarui dokumen lahan #{land.id}.",
        )

    db.commit()
    db.refresh(land)
    return land

@router.delete("/{id}")
def delete_land(
    id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    land = db.query(Land).filter(Land.id == id).first()
    if not land:
        raise HTTPException(status_code=404, detail="Data lahan tidak ditemukan")
        
    if current_user.role == "PETANI":
        farmer = db.query(Farmer).filter(Farmer.user_id == current_user.id).first()
        if not farmer or land.farmer_id != farmer.id:
            raise HTTPException(status_code=403, detail="Anda tidak memiliki akses menghapus lahan ini")
            
    db.delete(land)
    db.commit()
    return {"message": "Lahan berhasil dihapus"}
