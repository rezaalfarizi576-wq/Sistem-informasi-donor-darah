import json
import sys
from pathlib import Path

# Add parent directory to sys.path
sys.path.append(str(Path(__file__).parent.parent))

from app.database import SessionLocal
from app.models import User, RoleEnum
from app.auth import get_password_hash
from scripts.pmi_schema import PMIDonorRecord

def import_data():
    dataset_file = Path(__file__).parent.parent / "dummy_pmi_donors.json"
    if not dataset_file.exists():
        print(f"File {dataset_file} tidak ditemukan!")
        return

    with open(dataset_file, "r", encoding="utf-8") as f:
        raw_donors = json.load(f)

    db = SessionLocal()
    imported = 0
    skipped = 0

    try:
        for item in raw_donors:
            record = PMIDonorRecord(**item)

            # Cek apakah NIK sudah ada
            existing = db.query(User).filter(User.nik == record.nik).first()
            if existing:
                skipped += 1
                continue

            # Default password dummy untuk akun yang belum diaktivasi
            temp_password_hash = get_password_hash("default_pmi_password")
            dummy_email = f"{record.nik}@donordarah-lamongan.id"

            user = User(
                nik=record.nik,
                nama=record.nama_lengkap,
                email=dummy_email,
                password_hash=temp_password_hash,
                role=RoleEnum.donor,
                no_hp=record.no_telepon,
                blood_type=record.golongan_darah,
                rhesus=record.rhesus,
                address=record.alamat,
                sumber_data="pmi_pusat",
                is_activated=False,
                status_aktif=True,
            )
            db.add(user)
            imported += 1

        db.commit()
        print(f"Proses impor selesai: {imported} pendonor diimpor, {skipped} dilewati (sudah terdaftar).")
    except Exception as e:
        db.rollback()
        print(f"Error saat impor data: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    import_data()
