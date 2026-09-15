from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.models import User, Farmer, Land
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

    for key, val in data.dict(exclude_unset=True).items():
        setattr(land, key, val)
        
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
