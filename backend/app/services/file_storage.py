import os
import uuid
import aiofiles
from pathlib import Path
from fastapi import UploadFile, HTTPException, status
from PIL import Image
from app.core.config import settings

CATEGORY_DIR_MAP = {
    "ktp": settings.KTP_DIR,
    "lahan": settings.LAHAN_DIR,
    "survei": settings.SURVEI_DIR,
}

async def save_upload_file(file: UploadFile, category: str) -> str:
    if category not in CATEGORY_DIR_MAP:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Kategori upload '{category}' tidak valid."
        )
        
    target_dir = CATEGORY_DIR_MAP[category]
    target_dir.mkdir(parents=True, exist_ok=True)
    
    # Validate content type
    if file.content_type not in settings.ALLOWED_MIME_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Format file '{file.content_type}' tidak diizinkan. Gunakan JPG, PNG, atau WEBP."
        )
        
    # Read and validate size
    content = await file.read()
    if len(content) > settings.MAX_FILE_SIZE_BYTES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Ukuran file melebihi batas maksimum 5MB ({len(content) / (1024*1024):.2f}MB)."
        )
        
    # Generate unique filename
    ext = Path(file.filename or "upload.jpg").suffix.lower()
    if not ext or ext not in [".jpg", ".jpeg", ".png", ".webp"]:
        ext = ".jpg"
        
    unique_name = f"{category}_{uuid.uuid4().hex[:12]}{ext}"
    file_path = target_dir / unique_name
    
    async with aiofiles.open(file_path, "wb") as out_file:
        await out_file.write(content)
        
    # Relative path URL served by FastAPI file router
    return f"/files/{category}/{unique_name}"

def delete_file(relative_url: str):
    try:
        parts = relative_url.strip("/").split("/")
        if len(parts) >= 3 and parts[0] == "files":
            cat = parts[1]
            fname = parts[2]
            if cat in CATEGORY_DIR_MAP:
                fpath = CATEGORY_DIR_MAP[cat] / fname
                if fpath.exists():
                    fpath.unlink()
    except Exception:
        pass
