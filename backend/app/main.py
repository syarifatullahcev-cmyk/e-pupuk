import time
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy import text
from app.core.config import settings
from app.core.database import engine, Base
from app.routers import (
    auth,
    farmers,
    lands,
    applications,
    admin,
    ppl,
    distributions,
    files
)

logger = logging.getLogger("uvicorn.error")

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup: tunggu MySQL siap lalu buat semua tabel."""
    max_retries = 10
    for attempt in range(1, max_retries + 1):
        try:
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            logger.info("✅ Koneksi database berhasil.")
            break
        except Exception as e:
            logger.warning(f"⏳ Menunggu database... ({attempt}/{max_retries}): {e}")
            time.sleep(3)
    else:
        logger.error("❌ Gagal terhubung ke database setelah beberapa percobaan.")

    # Import semua model agar Base.metadata mengenali tabel
    import app.models.models  # noqa: F401
    Base.metadata.create_all(bind=engine)
    logger.info("✅ Tabel database siap.")
    yield

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="Sistem Verifikasi & Distribusi Pupuk Bersubsidi Kabupaten Mojokerto",
    version="1.0.0",
    lifespan=lifespan
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(auth.router, prefix=settings.API_V1_STR)
app.include_router(farmers.router)
app.include_router(lands.router)
app.include_router(applications.router)
app.include_router(admin.router)
app.include_router(ppl.router)
app.include_router(distributions.router)
app.include_router(files.router)

@app.get("/")
def root():
    return {
        "app": settings.PROJECT_NAME,
        "status": "online",
        "docs_url": "/docs"
    }

@app.get("/api/health")
def health_check():
    return {"status": "ok", "service": "epupuk-backend"}

