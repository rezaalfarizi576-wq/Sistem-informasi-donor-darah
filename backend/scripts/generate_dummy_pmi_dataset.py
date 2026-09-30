import json
import random
from pathlib import Path
from datetime import datetime, timedelta

KECAMATAN_LAMONGAN = [
    "Lamongan", "Babat", "Paciran", "Brondong", "Tikung",
    "Deket", "Sukodadi", "Pucuk", "Karanggeneng", "Sekaran"
]

FIRST_NAMES = ["Ahmad", "Budi", "Citra", "Dian", "Eka", "Fajar", "Gilang", "Hendra", "Indah", "Joko"]
LAST_NAMES = ["Pratama", "Santoso", "Saputra", "Lestari", "Kusuma", "Hidayat", "Wijaya", "Utami"]

BLOOD_TYPES = ["A", "B", "AB", "O"]
RHESUS_TYPES = ["+", "+", "+", "+", "-"] # Kebanyakan rhesus positif

def generate_nik(index: int) -> str:
    # 3524 = Kode Kabupaten Lamongan di Kemendagri
    return f"3524{random.randint(10, 27):02d}{random.randint(1, 28):02d}{random.randint(1, 12):02d}{random.randint(80, 99):02d}{index:04d}"

def generate_dataset(count: int = 25):
    donors = []
    today = datetime.today()

    for i in range(1, count + 1):
        first = random.choice(FIRST_NAMES)
        last = random.choice(LAST_NAMES)
        gender = "L" if first in ["Ahmad", "Budi", "Dian", "Fajar", "Gilang", "Hendra", "Joko"] else "P"
        kecamatan = random.choice(KECAMATAN_LAMONGAN)
        days_ago = random.randint(30, 360)
        last_donation = (today - timedelta(days=days_ago)).strftime("%Y-%m-%d")

        donor = {
            "nik": generate_nik(i),
            "nama_lengkap": f"{first} {last}",
            "jenis_kelamin": gender,
            "golongan_darah": random.choice(BLOOD_TYPES),
            "rhesus": random.choice(RHESUS_TYPES),
            "no_telepon": f"0812{random.randint(10000000, 99999999)}",
            "alamat": f"Desa {kecamatan}, Kec. {kecamatan}, Lamongan",
            "kecamatan": kecamatan,
            "total_donor": random.randint(1, 20),
            "terakhir_donor": last_donation,
            "status_kelayakan": "layak" if days_ago > 60 else "tidak_layak"
        }
        donors.append(donor)
    return donors

def main():
    output_path = Path(__file__).parent.parent / "dummy_pmi_donors.json"
    donors = generate_dataset(30)
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(donors, f, indent=2, ensure_ascii=False)
    print(f"Berhasil menghasilkan {len(donors)} data dummy pendonor ke {output_path}")

if __name__ == "__main__":
    main()
