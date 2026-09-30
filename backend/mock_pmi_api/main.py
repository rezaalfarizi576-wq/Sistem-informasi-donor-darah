import json
from pathlib import Path
from typing import Optional, List
from fastapi import FastAPI, HTTPException, Header
from pydantic import BaseModel

app = FastAPI(
    title="Mock API PMI Pusat",
    description="Simulasi API Layanan Data Pendonor PMI Pusat untuk verifikasi NIK dan riwayat donor",
    version="1.0.0"
)

DATA_PATH = Path(__file__).parent.parent / "dummy_pmi_donors.json"

def load_dummy_donors() -> List[dict]:
    if not DATA_PATH.exists():
        return []
    with open(DATA_PATH, "r", encoding="utf-8") as f:
        return json.load(f)

class DonorPMIResponse(BaseModel):
    nik: str
    nama_lengkap: str
    jenis_kelamin: str
    golongan_darah: str
    rhesus: str
    no_telepon: str
    alamat: str
    kecamatan: str
    total_donor: int
    terakhir_donor: str
    status_kelayakan: str

@app.get("/")
def root():
    return {
        "service": "Mock API PMI Pusat",
        "status": "ready"
    }

@app.get("/api/v1/donors", response_model=List[DonorPMIResponse])
def get_all_pmi_donors(
    x_api_key: Optional[str] = Header(None, description="API Key PMI")
):
    """
    Simulasi endpoint mengambil seluruh dataset pendonor PMI Lamongan.
    """
    return load_dummy_donors()

@app.get("/api/v1/donors/verify/{nik}", response_model=DonorPMIResponse)
def verify_donor_nik(
    nik: str,
    x_api_key: Optional[str] = Header(None, description="API Key PMI")
):
    """
    Verifikasi keanggotaan pendonor PMI berdasarkan NIK.
    """
    donors = load_dummy_donors()
    for donor in donors:
        if donor.get("nik") == nik:
            return donor
    raise HTTPException(status_code=404, detail="Data NIK pendonor tidak ditemukan dalam database PMI.")
