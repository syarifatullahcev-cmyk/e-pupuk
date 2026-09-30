from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.security import verify_password, create_access_token, get_password_hash
from app.core.dependencies import get_current_user, log_audit_action
from app.models.models import User, Farmer, UserRole, Notification
from app.schemas.schemas import LoginRequest, RegisterRequest, Token, UserResponse

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

@router.post("/register", status_code=status.HTTP_201_CREATED)
def register_petani(request: RegisterRequest, db: Session = Depends(get_db)):
    # 1. Validasi NIK 16 digit angka
    cleaned_nik = request.nik.strip()
    if len(cleaned_nik) != 16 or not cleaned_nik.isdigit():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="NIK wajib berisi 16 digit angka."
        )

    # 2. Validasi panjang password
    if len(request.password) < 6:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Kata sandi minimal berisi 6 karakter."
        )

    # 3. Cek apakah username sudah digunakan
    cleaned_username = request.username.strip()
    existing_user = db.query(User).filter(User.username == cleaned_username).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username sudah digunakan. Silakan gunakan username lain."
        )

    # 4. Cek apakah NIK sudah terdaftar
    existing_farmer = db.query(Farmer).filter(Farmer.nik == cleaned_nik).first()
    if existing_farmer:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="NIK ini sudah terdaftar dalam sistem E-Pupuk."
        )

    # 5. Siapkan email unik
    user_email = request.email or f"{cleaned_username.lower()}@petani.epupuk.id"
    existing_email = db.query(User).filter(User.email == user_email).first()
    if existing_email:
        user_email = f"{cleaned_username.lower()}_{cleaned_nik[-4:]}@petani.epupuk.id"

    # 6. Buat record User (Role: PETANI)
    new_user = User(
        username=cleaned_username,
        email=user_email,
        password_hash=get_password_hash(request.password),
        role=UserRole.PETANI,
        is_active=True
    )
    db.add(new_user)
    db.flush()

    # 7. Buat profil Farmer
    new_farmer = Farmer(
        user_id=new_user.id,
        nama=request.nama.strip(),
        nik=cleaned_nik,
        kontak=request.kontak.strip() if request.kontak else None,
        alamat=request.alamat.strip() if request.alamat else "Kabupaten Mojokerto",
        farmer_group_id=request.farmer_group_id
    )
    db.add(new_farmer)

    # 8. Notifikasi sambutan
    welcome_notif = Notification(
        user_id=new_user.id,
        judul="Selamat Datang di E-Pupuk!",
        pesan=f"Halo {request.nama.strip()}, akun petani Anda berhasil didaftarkan. Silakan login dan lengkapi data lahan Anda untuk mengajukan kuota pupuk bersubsidi.",
        tipe="SUCCESS"
    )
    db.add(welcome_notif)

    # 9. Audit log
    log_audit_action(
        db,
        user_id=new_user.id,
        action="REGISTER",
        resource="users",
        resource_id=new_user.id,
        details=f"Petani {request.nama.strip()} (NIK: {cleaned_nik}) registered new account"
    )

    db.commit()
    db.refresh(new_user)
    db.refresh(new_farmer)

    return {
        "message": "Pendaftaran akun petani berhasil! Silakan masuk.",
        "user_id": new_user.id,
        "username": new_user.username,
        "nama": new_farmer.nama
    }
