from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.security import verify_password, create_access_token
from app.core.dependencies import get_current_user, log_audit_action
from app.models.models import User, Farmer
from app.schemas.schemas import LoginRequest, Token, UserResponse

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/login", response_model=Token)
def login(request: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == request.username).first()
    if not user or not verify_password(request.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Username atau kata sandi tidak valid."
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Akun ini telah dinonaktifkan."
        )

    # If role is PETANI, retrieve farmer profile id and name
    farmer_id = None
    display_name = user.username
    if user.role == "PETANI":
        farmer = db.query(Farmer).filter(Farmer.user_id == user.id).first()
        if farmer:
            farmer_id = farmer.id
            display_name = farmer.nama

    token = create_access_token(data={
        "user_id": user.id,
        "username": user.username,
        "role": user.role
    })

    log_audit_action(db, user_id=user.id, action="LOGIN", resource="auth", details=f"User {user.username} logged in")

    return Token(
        access_token=token,
        token_type="bearer",
        role=user.role,
        user_id=user.id,
        username=user.username,
        nama=display_name,
        farmer_id=farmer_id
    )

@router.get("/me")
def get_current_profile(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    farmer_id = None
    farmer_data = None
    if current_user.role == "PETANI":
        farmer = db.query(Farmer).filter(Farmer.user_id == current_user.id).first()
        if farmer:
            farmer_id = farmer.id
            farmer_data = {
                "id": farmer.id,
                "nama": farmer.nama,
                "nik": farmer.nik,
                "alamat": farmer.alamat,
                "kontak": farmer.kontak,
                "foto_ktp_url": farmer.foto_ktp_url
            }
            
    return {
        "id": current_user.id,
        "username": current_user.username,
        "email": current_user.email,
        "role": current_user.role,
        "farmer_id": farmer_id,
        "farmer": farmer_data
    }

@router.post("/logout")
def logout(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    log_audit_action(db, user_id=current_user.id, action="LOGOUT", resource="auth")
    return {"message": "Berhasil keluar dari sistem"}
