import os
from pathlib import Path
from dotenv import load_dotenv

# Root paths
BACKEND_DIR = Path(__file__).resolve().parent.parent.parent
UPLOAD_DIR = BACKEND_DIR / "uploads"

# Load .env file if present
load_dotenv(BACKEND_DIR / ".env")
load_dotenv(BACKEND_DIR.parent / ".env")

class Settings:
    PROJECT_NAME: str = "E-Pupuk Kabupaten Mojokerto"
    API_V1_STR: str = "/api"
    SECRET_KEY: str = os.getenv("SECRET_KEY", "epupuk-mojokerto-super-secret-key-2026-secure-jwt")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 # 24 hours
    
    # Database
    MYSQL_USER: str = os.getenv("MYSQL_USER", "root")
    MYSQL_PASSWORD: str = os.getenv("MYSQL_PASSWORD", "")
    MYSQL_HOST: str = os.getenv("MYSQL_HOST", "127.0.0.1")
    MYSQL_PORT: str = os.getenv("MYSQL_PORT", "3306")
    MYSQL_DB: str = os.getenv("MYSQL_DB", "epupuk")
    
    @property
    def DATABASE_URL(self) -> str:
        if self.MYSQL_PASSWORD:
            return f"mysql+pymysql://{self.MYSQL_USER}:{self.MYSQL_PASSWORD}@{self.MYSQL_HOST}:{self.MYSQL_PORT}/{self.MYSQL_DB}?charset=utf8mb4"
        return f"mysql+pymysql://{self.MYSQL_USER}@{self.MYSQL_HOST}:{self.MYSQL_PORT}/{self.MYSQL_DB}?charset=utf8mb4"

    # File uploads
    UPLOAD_PATH: Path = UPLOAD_DIR
    KTP_DIR: Path = UPLOAD_DIR / "ktp"
    LAHAN_DIR: Path = UPLOAD_DIR / "lahan"
    SURVEI_DIR: Path = UPLOAD_DIR / "survei"
    MAX_FILE_SIZE_BYTES: int = 5 * 1024 * 1024 # 5MB
    ALLOWED_MIME_TYPES: list = ["image/jpeg", "image/png", "image/webp"]

settings = Settings()
