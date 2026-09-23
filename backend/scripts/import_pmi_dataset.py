import json
import sys
from pathlib import Path

# Add parent directory to sys.path
sys.path.append(str(Path(__file__).parent.parent))

from app.database import SessionLocal
from app.models import User, RoleEnum
from app.auth import hash_password

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
            nik = item.get("nik")
            
            # Skip if no NIK
            if not nik:
                skipped += 1
                continue

            # Check if NIK already exists
            existing = db.query(User).filter(User.nik == nik).first()
            if existing:
                skipped += 1
                continue

            # Use dummy email with NIK (will be replaced during activation)
            dummy_email = f"{nik}@donordarah-lamongan.id"
            
            # Create temporary password hash (will be replaced during activation)
            temp_password_hash = hash_password("default_pmi_password")

            user = User(
                nik=nik,
                nama=item.get("nama", ""),
                email=dummy_email,
                no_hp=item.get("no_hp", ""),
                password_hash=temp_password_hash,
                role=RoleEnum.donor,
                blood_type=item.get("golongan_darah"),
                rhesus=item.get("rhesus"),
                sumber_data="pmi_pusat",
                is_activated=False,
                status_aktif=True,
                id_pmi=item.get("id_pmi"),
            )
            db.add(user)
            imported += 1

        db.commit()
        print(f"✓ Proses impor selesai: {imported} pendonor diimpor, {skipped} dilewati (sudah terdaftar).")
    except Exception as e:
        db.rollback()
        print(f"✗ Error saat impor data: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    import_data()
