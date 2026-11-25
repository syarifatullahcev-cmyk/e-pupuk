import sys
from pathlib import Path

# Tambahkan direktori backend ke sys.path agar package 'app' dapat di-import
backend_dir = Path(__file__).resolve().parent.parent
if str(backend_dir) not in sys.path:
    sys.path.insert(0, str(backend_dir))

from app.main import app

# Export app untuk runtime Vercel Serverless
__all__ = ["app"]
