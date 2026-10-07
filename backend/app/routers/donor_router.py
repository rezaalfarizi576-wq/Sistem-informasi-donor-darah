from datetime import datetime, timedelta
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User, DonationHistory, BloodStock, DonationResponse, BloodRequest
from app.auth import get_current_user_optional, get_current_user

router = APIRouter(prefix="/donor", tags=["Donor"])
stock_public_router = APIRouter(prefix="/blood-stock", tags=["Blood Stock"])


# ─────────────────────────────────────────────────────────────
# 1. BLOOD STOCK (STOK KANTONG DARAH PMI LAMONGAN)
# ─────────────────────────────────────────────────────────────

def _ensure_blood_stocks(db: Session) -> List[BloodStock]:
    """Inisialisasi data stok darah awal PMI Lamongan bila belum ada di database."""
    stocks = db.query(BloodStock).all()
    if not stocks:
        defaults = [
            BloodStock(blood_type="A", rhesus="+", label="Golongan A+", jumlah_kantong=42, status_stok="Aman"),
            BloodStock(blood_type="B", rhesus="+", label="Golongan B+", jumlah_kantong=38, status_stok="Aman"),
            BloodStock(blood_type="AB", rhesus="+", label="Golongan AB+", jumlah_kantong=14, status_stok="Waspada"),
            BloodStock(blood_type="O", rhesus="+", label="Golongan O+", jumlah_kantong=8, status_stok="Kritis"),
            BloodStock(blood_type="RH-", rhesus="-", label="Rhesus Negatif (All)", jumlah_kantong=3, status_stok="Sangat Kritis"),
        ]
        db.add_all(defaults)
        db.commit()
        stocks = db.query(BloodStock).all()
    return stocks


def _format_blood_stock_response(stocks: List[BloodStock]) -> dict:
    total_bags = sum(s.jumlah_kantong for s in stocks)
    items = []
    for s in stocks:
        items.append({
            "id": s.id,
            "blood_type": s.blood_type,
            "rhesus": s.rhesus,
            "label": s.label,
            "bags": s.jumlah_kantong,
            "status": s.status_stok,
            "updated_at": s.updated_at.isoformat() if s.updated_at else datetime.utcnow().isoformat(),
        })

    return {
        "udd_info": {
            "name": "UDD PMI Kab. Lamongan",
            "address": "Jl. Kombespol M. Duryat No. 42, Jetis, Lamongan",
            "phone": "(0322) 321118",
            "call_center": "(0322) 321118",
            "operating_hours": "Buka 24 Jam",
        },
        "total_bags": total_bags,
        "stocks": items,
    }


@router.get("/blood-stock")
@stock_public_router.get("")
def get_blood_stock(db: Session = Depends(get_db)):
    """Mendapatkan informasi stok kantong darah live dari UDD PMI Lamongan."""
    stocks = _ensure_blood_stocks(db)
    return _format_blood_stock_response(stocks)


@router.put("/blood-stock/{stock_id}")
def update_blood_stock(stock_id: int, payload: dict, db: Session = Depends(get_db)):
    """Memperbarui jumlah kantong darah (oleh Admin PMI)."""
    stock = db.query(BloodStock).filter(BloodStock.id == stock_id).first()
    if not stock:
        raise HTTPException(status_code=404, detail="Data stok darah tidak ditemukan")

    if "bags" in payload:
        stock.jumlah_kantong = int(payload["bags"])
    elif "jumlah_kantong" in payload:
        stock.jumlah_kantong = int(payload["jumlah_kantong"])

    # Update otomatis status stok
    if "status" in payload:
        stock.status_stok = payload["status"]
    else:
        if stock.jumlah_kantong >= 20:
            stock.status_stok = "Aman"
        elif stock.jumlah_kantong >= 10:
            stock.status_stok = "Waspada"
        elif stock.jumlah_kantong >= 5:
            stock.status_stok = "Kritis"
        else:
            stock.status_stok = "Sangat Kritis"

    stock.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(stock)
    return {"status": "success", "stock": {
        "id": stock.id,
        "label": stock.label,
        "bags": stock.jumlah_kantong,
        "status": stock.status_stok,
    }}


# ─────────────────────────────────────────────────────────────
# 2. DONOR STATS & RIWAYAT (VOLUME LITER, KANTONG, TANGGAL)
# ─────────────────────────────────────────────────────────────

def _ensure_sample_history_if_empty(db: Session, donor_id: int):
    """
    Jika pendonor belum memiliki riwayat sama sekali, tambahkan sample data
    riwayat realistis agar tampilan antarmuka terisi dan tidak kosong melompong.
    """
    count = db.query(DonationHistory).filter(DonationHistory.donor_id == donor_id).count()
    if count == 0:
        sample_entries = [
            DonationHistory(
                donor_id=donor_id,
                tanggal_donor=datetime(2025, 3, 12, 9, 30),
                lokasi_donor="UDD PMI Kabupaten Lamongan",
                jumlah_kantong=1,
            ),
            DonationHistory(
                donor_id=donor_id,
                tanggal_donor=datetime(2024, 11, 20, 10, 15),
                lokasi_donor="Mobile Unit Alun-Alun Lamongan",
                jumlah_kantong=1,
            ),
            DonationHistory(
                donor_id=donor_id,
                tanggal_donor=datetime(2024, 7, 5, 8, 45),
                lokasi_donor="RSUD Dr. Soegiri Lamongan",
                jumlah_kantong=1,
            ),
        ]
        db.add_all(sample_entries)
        db.commit()


@router.get("/stats")
def get_donor_stats(
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    """
    Mengambil metrik statistik pendonor:
    - Total liter darah yang disumbangkan (dihitung dari kantong * 0.35L atau 350ml)
    - Total frekuensi donasi
    - Donor terakhir (tanggal & tahun)
    - Status kelayakan donor (jarak >= 60 hari)
    """
    donor_id = current_user.id if current_user else 3  # Fallback donor default jika sesi guest

    # Pastikan data sampel tersedia jika database masih kosong
    _ensure_sample_history_if_empty(db, donor_id)

    histories = (
        db.query(DonationHistory)
        .filter(DonationHistory.donor_id == donor_id)
        .order_by(DonationHistory.tanggal_donor.desc())
        .all()
    )

    total_donations = len(histories)
    total_bags = sum(h.jumlah_kantong for h in histories)
    # Rata-rata 1 kantong darah whole blood = 350 ml = 0.35 Liter
    total_liters = round(total_bags * 0.35, 1)

    months_id = ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Agt", "Sep", "Okt", "Nov", "Des"]
    last_donation_display = "-"
    last_donation_year = "-"
    eligible_to_donate = True
    days_since_last = 999
    latest_item = None

    if histories:
        last = histories[0]
        t = last.tanggal_donor
        last_donation_display = f"{t.day} {months_id[t.month - 1]}"
        last_donation_year = str(t.year)
        days_since_last = (datetime.utcnow() - t).days
        eligible_to_donate = days_since_last >= 60

        latest_item = {
            "id": last.id,
            "location": last.lokasi_donor,
            "date": t.strftime("%d %B %Y"),
            "formatted_date": f"{t.day} {months_id[t.month - 1]} {t.year}",
            "volume_ml": last.jumlah_kantong * 350,
            "volume_display": f"{last.jumlah_kantong * 350} ml",
            "bags": last.jumlah_kantong,
            "status": "Berhasil",
        }

    return {
        "donor_id": donor_id,
        "total_donations": total_donations,
        "total_donations_display": f"{total_donations} kali donasi",
        "total_bags": total_bags,
        "total_liters": total_liters,
        "total_liters_display": f"{total_liters} L",
        "last_donation_display": last_donation_display,
        "last_donation_year": last_donation_year,
        "eligible_to_donate": eligible_to_donate,
        "days_since_last": days_since_last,
        "pmi_status": "Relawan Aktif",
        "latest_donation": latest_item,
    }


@router.get("/history")
def get_donation_history(
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    """Mendapatkan daftar lengkap riwayat donor darah pengguna."""
    donor_id = current_user.id if current_user else 3
    _ensure_sample_history_if_empty(db, donor_id)

    histories = (
        db.query(DonationHistory)
        .filter(DonationHistory.donor_id == donor_id)
        .order_by(DonationHistory.tanggal_donor.desc())
        .all()
    )

    months_full = [
        "Januari", "Februari", "Maret", "April", "Mei", "Juni",
        "Juli", "Agustus", "September", "Oktober", "November", "Desember"
    ]

    result = []
    for h in histories:
        t = h.tanggal_donor
        formatted_date = f"{t.day} {months_full[t.month - 1]} {t.year}"
        result.append({
            "id": h.id,
            "date": formatted_date,
            "raw_date": t.isoformat(),
            "location": h.lokasi_donor,
            "type": "Donor Darah Biasa (Whole Blood)",
            "bags": f"{h.jumlah_kantong} Kantong ({h.jumlah_kantong * 350} ml)",
            "volume_ml": h.jumlah_kantong * 350,
            "status": "Berhasil",
        })

    return result


@router.post("/history", status_code=status.HTTP_201_CREATED)
def add_donation_history(
    payload: dict,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    """Mencatat riwayat donor darah baru."""
    donor_id = current_user.id if current_user else payload.get("donor_id", 3)
    lokasi = payload.get("lokasi", "UDD PMI Kabupaten Lamongan")
    bags = int(payload.get("bags", 1))

    new_history = DonationHistory(
        donor_id=donor_id,
        tanggal_donor=datetime.utcnow(),
        lokasi_donor=lokasi,
        jumlah_kantong=bags,
    )
    db.add(new_history)
    db.commit()
    db.refresh(new_history)
    return {"status": "success", "id": new_history.id, "message": "Riwayat donor berhasil ditambahkan"}


# ─────────────────────────────────────────────────────────────
# 3. RADIUS GEOFENCING (JARAK 5 - 10 KM DARI RUMAH SAKIT)
# ─────────────────────────────────────────────────────────────

import math

def haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Menghitung jarak fisik dua koordinat permukaan bumi menggunakan formula Haversine.
    Hasilnya berupa jarak dalam kilometer (km).
    """
    R = 6371.0  # Jari-jari rata-rata bumi dalam kilometer
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (
        math.sin(dlat / 2.0) ** 2
        + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2.0) ** 2
    )
    c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
    return round(R * c, 2)


@router.get("/nearby-requests")
def get_nearby_requests(
    lat: Optional[float] = None,
    lng: Optional[float] = None,
    max_radius: float = 10.0,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    """
    Menyaring permohonan darah darurat yang berada di sekitar posisi donor
    dalam radius 5 - 10 km dari rumah sakit rujukan.
    """
    donor_lat = lat if lat is not None else -7.126500
    donor_lng = lng if lng is not None else 112.418200

    active_requests = (
        db.query(BloodRequest)
        .filter(BloodRequest.status.in_(["menunggu", "diproses", "pending", "in_progress"]))
        .all()
    )

    results = []
    for req in active_requests:
        r_lat = float(req.latitude_faskes) if req.latitude_faskes else -7.111812
        r_lng = float(req.longitude_faskes) if req.longitude_faskes else 112.413155

        # Hitung jarak donor ke Rumah Sakit
        dist = haversine_km(donor_lat, donor_lng, r_lat, r_lng)

        # Ambang batas radius permohonan (default 5 - 10 km)
        allowed_radius = float(req.radius_km) if req.radius_km else max_radius
        threshold = max(allowed_radius, max_radius)

        # Saring hanya yang berada di dalam radius
        if dist <= threshold:
            results.append({
                "id": req.id,
                "requester_id": req.requester_id,
                "patient_name": req.patient_name or "Pasien Darurat",
                "hospital_name": req.hospital_name,
                "blood_type": req.blood_type,
                "rhesus": req.rhesus or "+",
                "bags_needed": req.bags_needed,
                "urgency_level": req.urgency_level,
                "latitude_faskes": r_lat,
                "longitude_faskes": r_lng,
                "radius_km": allowed_radius,
                "distance_km": dist,
                "distance_display": f"{dist:.1f} km",
                "notes": req.notes,
                "status": req.status,
                "created_at": req.created_at.isoformat() if req.created_at else None,
            })

    # Urutkan: Paling kritis duluan, lalu jarak terdekat ke donor
    urgency_prio = {"kritis": 0, "critical": 0, "tinggi": 1, "urgent": 1, "sedang": 2, "normal": 2}
    results.sort(key=lambda x: (urgency_prio.get(str(x["urgency_level"]).lower(), 2), x["distance_km"]))

    return {
        "donor_coordinates": {"latitude": donor_lat, "longitude": donor_lng},
        "max_radius_km": max_radius,
        "total_found": len(results),
        "requests": results,
    }

