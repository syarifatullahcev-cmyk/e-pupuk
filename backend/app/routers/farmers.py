from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.dependencies import get_current_user, require_role, log_audit_action
from app.models.models import (
    Application,
    ApplicationStatus,
    Farmer,
    FarmerGroup,
    Commodity,
    Fertilizer,
    Notification,
    User,
)
from app.schemas.schemas import (
    FarmerResponse, FarmerUpdate, FarmerGroupResponse,
    CommodityResponse, FertilizerResponse
)

router = APIRouter(tags=["Farmers & Reference Data"])

@router.get("/api/farmers", response_model=List[FarmerResponse])
def get_farmers(
    search: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    query = db.query(Farmer)
    if search:
        query = query.filter(Farmer.nama.ilike(f"%{search}%") | Farmer.nik.ilike(f"%{search}%"))
    farmers = query.all()
    
    # Mask NIK if not admin
    if current_user.role != "ADMIN":
        for f in farmers:
            if f.nik and len(f.nik) > 4:
                f.nik = f.nik[:4] + "*" * (len(f.nik) - 8) + f.nik[-4:]
                
    return farmers

@router.get("/api/farmers/me", response_model=FarmerResponse)
def get_my_farmer_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    farmer = db.query(Farmer).filter(Farmer.user_id == current_user.id).first()
    if not farmer:
        raise HTTPException(status_code=404, detail="Profil petani tidak ditemukan")
    return farmer

@router.get("/api/farmers/{id}", response_model=FarmerResponse)
def get_farmer_detail(
    id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    farmer = db.query(Farmer).filter(Farmer.id == id).first()
    if not farmer:
        raise HTTPException(status_code=404, detail="Petani tidak ditemukan")
        
    if current_user.role != "ADMIN" and current_user.id != farmer.user_id:
        if farmer.nik and len(farmer.nik) > 4:
            farmer.nik = farmer.nik[:4] + "*" * (len(farmer.nik) - 8) + farmer.nik[-4:]
            
    return farmer

@router.put("/api/farmers/{id}", response_model=FarmerResponse)
def update_farmer(
    id: int,
    data: FarmerUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    farmer = db.query(Farmer).filter(Farmer.id == id).first()
    if not farmer:
        raise HTTPException(status_code=404, detail="Petani tidak ditemukan")
        
    if current_user.role != "ADMIN" and current_user.id != farmer.user_id:
        raise HTTPException(status_code=403, detail="Anda tidak memiliki izin mengubah data petani ini")
        
    updates = data.dict(exclude_unset=True)
    ktp_changed = (
        "foto_ktp_url" in updates
        and updates["foto_ktp_url"] != farmer.foto_ktp_url
    )
    for key, value in updates.items():
        setattr(farmer, key, value)

    if ktp_changed and current_user.role == "PETANI":
        pending_applications = db.query(Application).filter(
            Application.farmer_id == farmer.id,
            Application.status.in_([
                ApplicationStatus.MENUNGGU_VERIFIKASI_BERKAS,
                ApplicationStatus.PERLU_PERBAIKAN_BERKAS,
            ]),
        ).all()
        for application in pending_applications:
            application.foto_ktp_snapshot_url = farmer.foto_ktp_url
            application.status = ApplicationStatus.MENUNGGU_VERIFIKASI_BERKAS
            application.admin_verifier_id = None
            application.admin_verified_at = None
            application.catatan_admin_berkas = (
                "Foto KTP diperbarui oleh petani; perlu diverifikasi ulang."
            )

        if pending_applications:
            db.add(Notification(
                user_id=current_user.id,
                judul="Foto KTP Diperbarui",
                pesan=(
                    "Foto KTP terbaru tersimpan. Pengajuan yang masih menunggu "
                    "verifikasi berkas telah dikirim ulang untuk ditinjau Admin."
                ),
                tipe="INFO",
            ))

        log_audit_action(
            db,
            user_id=current_user.id,
            action="UPDATE_KTP_PHOTO",
            resource="farmers",
            resource_id=farmer.id,
            details="Petani memperbarui foto KTP.",
        )

    db.commit()
    db.refresh(farmer)
    return farmer

# --- Reference data ---
@router.get("/api/farmer-groups", response_model=List[FarmerGroupResponse])
def get_farmer_groups(db: Session = Depends(get_db)):
    return db.query(FarmerGroup).all()

@router.get("/api/commodities", response_model=List[CommodityResponse])
def get_commodities(db: Session = Depends(get_db)):
    return db.query(Commodity).all()

@router.get("/api/fertilizers", response_model=List[FertilizerResponse])
def get_fertilizers(db: Session = Depends(get_db)):
    return db.query(Fertilizer).all()
