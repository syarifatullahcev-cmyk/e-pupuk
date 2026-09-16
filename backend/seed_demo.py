import sys
import os
sys.path.append(os.path.dirname(__file__))
from app.core.database import SessionLocal
from app.models.models import User, Farmer
from app.core.security import get_password_hash
from app.core.database import SessionLocal, engine, Base

print("Creating database tables...")
Base.metadata.create_all(bind=engine)
db = SessionLocal()
users = [
    User(username='admin', email='admin@mojokerto.go.id', password_hash=get_password_hash('admin123'), role='ADMIN', is_active=True),
    User(username='ppl_ahmad', email='ahmad@mojokerto.go.id', password_hash=get_password_hash('ppl123'), role='PPL', is_active=True),
    User(username='petani_budi', email='budi@petani.com', password_hash=get_password_hash('petani123'), role='PETANI', is_active=True),
    User(username='petani_siti', email='siti@petani.com', password_hash=get_password_hash('petani123'), role='PETANI', is_active=True)
]
for u in users:
    existing = db.query(User).filter(User.username == u.username).first()
    if existing:
        existing.password_hash = u.password_hash
    else:
        db.add(u)
db.commit()
# Create farmers
budi_user = db.query(User).filter(User.username == 'petani_budi').first()
if not db.query(Farmer).filter(Farmer.user_id == budi_user.id).first():
    db.add(Farmer(user_id=budi_user.id, nama='Budi Santoso', nik='3516000000000001', alamat='Mojosari', kontak='081234567890'))
siti_user = db.query(User).filter(User.username == 'petani_siti').first()
if not db.query(Farmer).filter(Farmer.user_id == siti_user.id).first():
    db.add(Farmer(user_id=siti_user.id, nama='Siti Aminah', nik='3516000000000002', alamat='Trowulan', kontak='081234567891'))
db.commit()
print('Demo accounts seeded!')
