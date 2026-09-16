from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

from app.config import settings

engine = create_engine(
    settings.database_url,
    pool_pre_ping=True,  # menghindari koneksi mati saat idle lama
    pool_recycle=3600,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db():
    """Dependency FastAPI: buka session per-request, tutup otomatis setelahnya."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
