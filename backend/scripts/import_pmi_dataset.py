import json
import sys
from pathlib import Path
from datetime import datetime, timedelta

# Add parent directory to sys.path
sys.path.append(str(Path(__file__).parent.parent))

from app.database import SessionLocal
from app.models import User, RoleEnum, DonationHistory
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
                # Update id_pmi if empty
                if not existing.id_pmi and item.get("id_pmi"):
                    existing.id_pmi = item.get("id_pmi")

                # Check if user has donation histories
                has_history = db.query(DonationHistory).filter(DonationHistory.donor_id == existing.id).first()
                if not has_history:
                    total_d = item.get("total_donasi", 1)
                    tgl_str = item.get("tanggal_donor_terakhir")
                    try:
                        base_date = datetime.strptime(tgl_str, "%Y-%m-%d") if tgl_str else datetime.utcnow() - timedelta(days=90)
                    except Exception:
                        base_date = datetime.utcnow() - timedelta(days=90)
                    lokasi = item.get("lokasi_donor_terakhir") or "UDD PMI Kabupaten Lamongan"
                    for d_idx in range(total_d):
                        d_date = base_date - timedelta(days=d_idx * 75)
                        db.add(DonationHistory(
                            donor_id=existing.id,
                            tanggal_donor=d_date,
                            lokasi_donor=lokasi,
                            jumlah_kantong=1,
                        ))
                    imported += 1
                else:
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
            db.flush()

            # Tambahkan riwayat donasi sesuai total_donasi di json
            total_d = item.get("total_donasi", 1)
            tgl_str = item.get("tanggal_donor_terakhir")
            try:
                base_date = datetime.strptime(tgl_str, "%Y-%m-%d") if tgl_str else datetime.utcnow() - timedelta(days=90)
            except Exception:
                base_date = datetime.utcnow() - timedelta(days=90)
            
            lokasi = item.get("lokasi_donor_terakhir") or "UDD PMI Kabupaten Lamongan"

            for d_idx in range(total_d):
                d_date = base_date - timedelta(days=d_idx * 75)
                h = DonationHistory(
                    donor_id=user.id,
                    tanggal_donor=d_date,
                    lokasi_donor=lokasi,
                    jumlah_kantong=1,
                )
                db.add(h)

            imported += 1

        db.commit()
        print(f"[OK] Proses impor selesai: {imported} pendonor diimpor, {skipped} dilewati (sudah terdaftar).")
    except Exception as e:
        db.rollback()
        print(f"[ERROR] Error saat impor data: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    import_data()
