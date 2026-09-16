import sys
import os
sys.path.append(os.path.dirname(__file__))
from app.core.database import SessionLocal
from app.models.models import User
from app.core.security import get_password_hash

db = SessionLocal()
if db.query(User).count() == 0:
    admin = User(username='admin', email='admin@example.com', password_hash=get_password_hash('password'), role='ADMIN', is_active=True)
    ppl = User(username='ppl', email='ppl@example.com', password_hash=get_password_hash('password'), role='PPL', is_active=True)
    petani = User(username='petani', email='petani@example.com', password_hash=get_password_hash('password'), role='PETANI', is_active=True)
    db.add_all([admin, ppl, petani])
    db.commit()
    print('Users seeded successfully.')
else:
    print('Users already exist.')
