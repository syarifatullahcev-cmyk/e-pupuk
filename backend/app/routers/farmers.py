from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.dependencies import get_current_user, require_role, log_audit_action
from app.models.models import User, Farmer, FarmerGroup, Commodity, Fertilizer
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
        
    for key, value in data.dict(exclude_unset=True).items():
        setattr(farmer, key, value)
        
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
