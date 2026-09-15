from pathlib import Path
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form, Request
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.config import settings
from app.core.dependencies import get_current_user, log_audit_action
from app.services.file_storage import save_upload_file
from app.models.models import User

router = APIRouter(tags=["Files"])

@router.post("/api/files/upload")
async def upload_file_endpoint(
    file: UploadFile = File(...),
    category: str = Form(...), # "ktp", "lahan", "survei"
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    url = await save_upload_file(file, category)
    log_audit_action(
        db,
        user_id=current_user.id,
        action="UPLOAD_FILE",
        resource=category,
        details=f"Uploaded {file.filename} -> {url}"
    )
    return {"url": url, "filename": Path(url).name, "category": category}

@router.get("/files/ktp/{filename}")
def get_ktp_file(
    filename: str,
    request: Request,
    db: Session = Depends(get_db),
    # Optional token query param for direct <img> tags
    token: str = None
):
    file_path = settings.KTP_DIR / filename
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="File KTP tidak ditemukan")

    # Audit log access
    client_ip = request.client.host if request.client else "unknown"
    log_audit_action(
        db,
        user_id=None,
        action="ACCESS_KTP",
        resource="ktp_file",
        details=f"File {filename} accessed",
        ip_address=client_ip
    )
    
    return FileResponse(
        path=str(file_path),
        media_type="image/jpeg",
        filename=filename
    )

@router.get("/files/lahan/{filename}")
def get_lahan_file(filename: str):
    file_path = settings.LAHAN_DIR / filename
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="File foto lahan tidak ditemukan")
    return FileResponse(path=str(file_path), filename=filename)

@router.get("/files/survei/{filename}")
def get_survei_file(filename: str):
    file_path = settings.SURVEI_DIR / filename
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="File survei tidak ditemukan")
    return FileResponse(path=str(file_path), filename=filename)
