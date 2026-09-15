from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.core.config import settings
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

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="Sistem Verifikasi & Distribusi Pupuk Bersubsidi Kabupaten Mojokerto",
    version="1.0.0"
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
