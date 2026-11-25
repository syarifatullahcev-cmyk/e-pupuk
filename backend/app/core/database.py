import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.pool import NullPool
from app.core.config import settings

is_serverless = bool(os.getenv("VERCEL") or os.getenv("AWS_LAMBDA_FUNCTION_NAME"))

if settings.DATABASE_URL.startswith("sqlite"):
    engine = create_engine(
        settings.DATABASE_URL,
        connect_args={"check_same_thread": False},
        echo=False
    )
else:
    connect_args = {}
    db_url_lower = settings.DATABASE_URL.lower()
    if (
        "tidbcloud" in db_url_lower
        or "ssl" in db_url_lower
        or os.getenv("MYSQL_SSL", "").lower() in ("true", "1")
        or str(settings.MYSQL_PORT) in ("4000",)
    ):
        connect_args["ssl"] = {}

    if is_serverless:
        engine = create_engine(
            settings.DATABASE_URL,
            connect_args=connect_args,
            poolclass=NullPool,
            echo=False
        )
    else:
        engine = create_engine(
            settings.DATABASE_URL,
            connect_args=connect_args,
            pool_pre_ping=True,
            pool_recycle=3600,
            pool_size=10,
            max_overflow=20,
            echo=False
        )

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

