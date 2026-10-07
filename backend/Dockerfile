# ============================================================
# E-Pupuk Backend — Dockerfile
# Python 3.12 + FastAPI + Uvicorn + SQLite
# ============================================================
FROM python:3.12-slim

# Metadata
LABEL maintainer="E-Pupuk Mojokerto"
LABEL description="Backend FastAPI untuk sistem e-Pupuk Kabupaten Mojokerto"

# Env defaults (dapat di-override via docker-compose)
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY . .

# Buat direktori uploads agar persistent
RUN mkdir -p uploads/ktp uploads/lahan uploads/survei

# Expose port
EXPOSE 8000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/api/health')" || exit 1

# Jalankan aplikasi
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

