from typing import List, Optional, Any
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.database import get_db
from datetime import datetime
from app.models import User, RoleEnum, DonorLocation, BloodRequest, HealthFacility, DonationResponse, DonationHistory
from app.schemas import (
    UserResponse,
    DonorLocationResponse,
    DonorLocationCreate,
    BloodRequestResponse,
    BloodRequestCreate,
    HealthFacilityResponse,
    HealthFacilityCreate,
    HealthFacilityUpdate,
)
from app.auth import require_role, get_current_user_optional

router = APIRouter(prefix="/admin", tags=["Admin"])
requests_router = APIRouter(prefix="/requests", tags=["Requests"])


@router.get("/users", response_model=list[UserResponse])
def list_all_users(
    db: Session = Depends(get_db),
    _admin: Optional[User] = Depends(get_current_user_optional),
):
    """Daftar seluruh pengguna, khusus admin."""
    return db.query(User).all()


@router.get("/stats")
def get_dashboard_stats(
    db: Session = Depends(get_db),
    _admin: Optional[User] = Depends(get_current_user_optional),
):
    """Mengambil ringkasan statistik untuk dashboard admin PMI."""
    total_users = db.query(User).count()
    total_donors = db.query(User).filter(User.role == RoleEnum.donor).count()
    total_requesters = db.query(User).filter(User.role == RoleEnum.requester).count()
    active_requests = (
        db.query(BloodRequest)
        .filter(BloodRequest.status.in_(["menunggu", "diproses", "pending", "in_progress"]))
        .count()
    )
    total_locations = (
        db.query(DonorLocation).filter(DonorLocation.is_current == True).count()
    )

    return {
        "total_users": total_users,
        "total_donors": total_donors,
        "total_requesters": total_requesters,
        "active_blood_requests": active_requests,
        "active_donor_locations": total_locations,
    }


@router.get("/locations", response_model=List[DonorLocationResponse])
def get_all_locations(
    db: Session = Depends(get_db),
    _admin: User = Depends(require_role(RoleEnum.admin)),
):
    """Mendapatkan semua lokasi donor darah."""
    return db.query(DonorLocation).all()


@router.post(
    "/locations",
    response_model=DonorLocationResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_donor_location(
    location_in: DonorLocationCreate,
    db: Session = Depends(get_db),
    _admin: User = Depends(require_role(RoleEnum.admin)),
):
    """Menambahkan lokasi donor baru (UDD / Bus Donor / Pos Donor)."""
    new_location = DonorLocation(**location_in.model_dump())
    db.add(new_location)
    db.commit()
    db.refresh(new_location)
    return new_location


def _handle_create_request(
    request_in: BloodRequestCreate,
    db: Session,
    current_user: Optional[User],
) -> BloodRequest:
    # 1. Tentukan pemohon (requester_id)
    requester_id = None
    if current_user:
        requester_id = current_user.id
    else:
        requester = db.query(User).filter(User.role == RoleEnum.requester).first()
        if requester:
            requester_id = requester.id
        else:
            first_user = db.query(User).first()
            requester_id = first_user.id if first_user else 1

    # 2. Cocokkan faskes rumah sakit
    facility_id = request_in.facility_id
    lat = request_in.latitude_faskes or -7.1118120
    lng = request_in.longitude_faskes or 112.4131550

    if request_in.hospital_name:
        match_faskes = (
            db.query(HealthFacility)
            .filter(HealthFacility.nama_faskes.ilike(f"%{request_in.hospital_name}%"))
            .first()
        )
        if match_faskes:
            facility_id = match_faskes.id
            lat = float(match_faskes.latitude)
            lng = float(match_faskes.longitude)

    if not facility_id:
        first_fac = db.query(HealthFacility).first()
        if first_fac:
            facility_id = first_fac.id
            lat = float(first_fac.latitude)
            lng = float(first_fac.longitude)

    new_request = BloodRequest(
        requester_id=requester_id,
        facility_id=facility_id,
        patient_name=request_in.patient_name,
        blood_type=request_in.blood_type,
        rhesus=request_in.rhesus,
        bags_needed=request_in.bags_needed,
        urgency_level=request_in.urgency_level,
        latitude_faskes=lat,
        longitude_faskes=lng,
        radius_km=request_in.radius_km or 5.0,
        notes=request_in.notes,
        surat_dokter=request_in.surat_dokter,
        status="menunggu",
    )
    db.add(new_request)
    db.commit()
    db.refresh(new_request)
    return new_request


@router.post("/requests", response_model=BloodRequestResponse, status_code=status.HTTP_201_CREATED)
@requests_router.post("", response_model=BloodRequestResponse, status_code=status.HTTP_201_CREATED)
def create_blood_request(
    request_in: BloodRequestCreate,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    """Membuat permohonan darah baru (lengkap dengan foto surat dokter jika ada)."""
    return _handle_create_request(request_in, db, current_user)


@router.get("/requests", response_model=List[BloodRequestResponse])
@requests_router.get("", response_model=List[BloodRequestResponse])
def get_all_blood_requests(
    status_filter: Optional[str] = Query(None, alias="status"),
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
    _user: Optional[User] = Depends(get_current_user_optional),
):
    """Melihat seluruh permohonan darah yang terdaftar."""
    query = db.query(BloodRequest)
    if status_filter:
        query = query.filter(BloodRequest.status == status_filter)
    return (
        query.order_by(BloodRequest.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )


@router.put("/requests/{request_id}", response_model=BloodRequestResponse)
@requests_router.put("/{request_id}", response_model=BloodRequestResponse)
def update_blood_request_status(
    request_id: int,
    payload: dict,
    db: Session = Depends(get_db),
    _user: Optional[User] = Depends(get_current_user_optional),
):
    """Update status permohonan darah (misal: verifikasi disetujui / ditolak)."""
    request_obj = db.query(BloodRequest).filter(BloodRequest.id == request_id).first()
    if not request_obj:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Permohonan darah tidak ditemukan",
        )
    new_status = payload.get("status")
    if new_status:
        request_obj.status = new_status
    db.commit()
    db.refresh(request_obj)
    return request_obj


@router.get("/requests/{request_id}", response_model=BloodRequestResponse)
@requests_router.get("/{request_id}", response_model=BloodRequestResponse)
def get_blood_request_by_id(
    request_id: int,
    db: Session = Depends(get_db),
    _user: Optional[User] = Depends(get_current_user_optional),
):
    """Mendapatkan detail permohonan darah berdasarkan ID."""
    req = db.query(BloodRequest).filter(BloodRequest.id == request_id).first()
    if not req:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Permohonan darah tidak ditemukan",
        )
    return req


@requests_router.post("/{request_id}/respond")
def respond_to_blood_request(
    request_id: int,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    """Merespon/menerima permohonan darah oleh donor."""
    req = db.query(BloodRequest).filter(BloodRequest.id == request_id).first()
    if not req:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Permohonan darah tidak ditemukan",
        )

    donor_id = current_user.id if current_user else 1
    existing = (
        db.query(DonationResponse)
        .filter(
            DonationResponse.request_id == request_id,
            DonationResponse.donor_id == donor_id,
        )
        .first()
    )

    if existing:
        existing.status = "diterima"
        existing.waktu_respon = datetime.utcnow()
    else:
        new_resp = DonationResponse(
            request_id=request_id,
            donor_id=donor_id,
            status="diterima",
            waktu_respon=datetime.utcnow(),
        )
        db.add(new_resp)

    if req.status == "menunggu":
        req.status = "diproses"

    db.commit()
    return {
        "status": "success",
        "message": "Terima kasih! Anda bersedia menjadi pendonor untuk permohonan ini.",
        "request_id": request_id,
    }


# ─── HEALTH FACILITIES (FASKES) ENDPOINTS ───

@router.get("/facilities", response_model=List[HealthFacilityResponse])
def get_all_facilities(
    db: Session = Depends(get_db),
    _user: Optional[User] = Depends(get_current_user_optional),
):
    """Mendapatkan daftar seluruh fasilitas kesehatan di Lamongan."""
    facilities = db.query(HealthFacility).all()
    # Jika tabel masih kosong, seed faskes utama Lamongan secara otomatis
    if not facilities:
        defaults = [
            HealthFacility(
                nama_faskes="RSUD Dr. Soegiri Lamongan",
                alamat="Jl. Kusuma Bangsa No. 7, Lamongan",
                latitude=-7.119812,
                longitude=112.415155,
                telepon="(0322) 321718",
                terverifikasi=True,
            ),
            HealthFacility(
                nama_faskes="RS Muhammadiyah Lamongan",
                alamat="Jl. Jaksa Agung Suprapto No. 76, Lamongan",
                latitude=-7.112000,
                longitude=112.408000,
                telepon="(0322) 322834",
                terverifikasi=True,
            ),
            HealthFacility(
                nama_faskes="RSUD Karangkembang Babat",
                alamat="Jl. Raya Babat - Jombang No. 12, Babat",
                latitude=-7.104000,
                longitude=112.395000,
                telepon="(0322) 451099",
                terverifikasi=True,
            ),
            HealthFacility(
                nama_faskes="Puskesmas Deket",
                alamat="Jl. Raya Deket No. 45, Deket, Lamongan",
                latitude=-7.125000,
                longitude=112.430000,
                telepon="(0322) 312345",
                terverifikasi=True,
            ),
            HealthFacility(
                nama_faskes="Puskesmas Tikung",
                alamat="Jl. Raya Tikung No. 18, Tikung, Lamongan",
                latitude=-7.142000,
                longitude=112.418000,
                telepon="(0322) 319876",
                terverifikasi=True,
            ),
        ]
        db.add_all(defaults)
        db.commit()
        facilities = db.query(HealthFacility).all()
    return facilities


@router.post("/facilities", response_model=HealthFacilityResponse, status_code=status.HTTP_201_CREATED)
def create_facility(
    facility_in: HealthFacilityCreate,
    db: Session = Depends(get_db),
    _user: Optional[User] = Depends(get_current_user_optional),
):
    """Menambah fasilitas kesehatan baru."""
    fac = HealthFacility(**facility_in.model_dump())
    db.add(fac)
    db.commit()
    db.refresh(fac)
    return fac


@router.put("/facilities/{facility_id}", response_model=HealthFacilityResponse)
def update_facility(
    facility_id: int,
    facility_in: HealthFacilityUpdate,
    db: Session = Depends(get_db),
    _user: Optional[User] = Depends(get_current_user_optional),
):
    """Update data fasilitas kesehatan."""
    fac = db.query(HealthFacility).filter(HealthFacility.id == facility_id).first()
    if not fac:
        raise HTTPException(status_code=404, detail="Fasilitas kesehatan tidak ditemukan")
    update_data = facility_in.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(fac, key, value)
    db.commit()
    db.refresh(fac)
    return fac


@router.patch("/facilities/{facility_id}/verify")
def toggle_verify_facility(
    facility_id: int,
    db: Session = Depends(get_db),
    _user: Optional[User] = Depends(get_current_user_optional),
):
    """Toggle status verifikasi faskes."""
    fac = db.query(HealthFacility).filter(HealthFacility.id == facility_id).first()
    if not fac:
        raise HTTPException(status_code=404, detail="Fasilitas kesehatan tidak ditemukan")
    fac.terverifikasi = not fac.terverifikasi
    db.commit()
    db.refresh(fac)
    return {"id": fac.id, "terverifikasi": fac.terverifikasi}


@router.delete("/facilities/{facility_id}")
def delete_facility(
    facility_id: int,
    db: Session = Depends(get_db),
    _user: Optional[User] = Depends(get_current_user_optional),
):
    """Menghapus fasilitas kesehatan."""
    fac = db.query(HealthFacility).filter(HealthFacility.id == facility_id).first()
    if not fac:
        raise HTTPException(status_code=404, detail="Fasilitas kesehatan tidak ditemukan")
    db.delete(fac)
    db.commit()
    return {"status": "success", "message": f"Faskes #{facility_id} berhasil dihapus"}


# ─── REPORTS & SUMMARY ENDPOINTS ───

@router.get("/reports/summary")
def get_reports_summary(
    db: Session = Depends(get_db),
    _user: Optional[User] = Depends(get_current_user_optional),
):
    """Mengambil ringkasan laporan & metrik performa donor darah."""
    total_requests = db.query(BloodRequest).count()
    completed_requests = db.query(BloodRequest).filter(BloodRequest.status.in_(["terpenuhi", "selesai", "completed"])).count()
    pending_requests = db.query(BloodRequest).filter(BloodRequest.status.in_(["menunggu", "pending"])).count()
    in_progress = db.query(BloodRequest).filter(BloodRequest.status.in_(["diproses", "in_progress"])).count()
    total_donors = db.query(User).filter(User.role == RoleEnum.donor).count()
    total_responses = db.query(DonationResponse).count()

    blood_types = ["A", "B", "AB", "O"]
    req_by_blood = {}
    for bt in blood_types:
        req_by_blood[bt] = db.query(BloodRequest).filter(BloodRequest.blood_type == bt).count()

    donor_by_blood = {}
    for bt in blood_types:
        donor_by_blood[bt] = db.query(User).filter(User.role == RoleEnum.donor, User.blood_type == bt).count()

    recent_requests = (
        db.query(BloodRequest)
        .order_by(BloodRequest.created_at.desc())
        .limit(10)
        .all()
    )

    recent_list = []
    for r in recent_requests:
        recent_list.append({
            "id": r.id,
            "patient_name": r.patient_name or "Anonim",
            "hospital_name": r.hospital_name,
            "blood_type": f"{r.blood_type}{r.rhesus or '+'}",
            "bags": r.bags_needed,
            "status": r.status,
            "urgency": r.urgency_level,
            "created_at": r.created_at.strftime("%Y-%m-%d %H:%M") if r.created_at else "-",
        })

    return {
        "total_requests": total_requests,
        "completed_requests": completed_requests,
        "pending_requests": pending_requests,
        "in_progress_requests": in_progress,
        "total_donors": total_donors,
        "total_responses": total_responses,
        "requests_by_blood": req_by_blood,
        "donors_by_blood": donor_by_blood,
        "recent_requests": recent_list,
    }


# ─── SYSTEM SETTINGS ENDPOINTS ───

_system_settings = {
    "system_name": "Sistem Informasi Donor Darah Lamongan",
    "udd_name": "UDD PMI Kabupaten Lamongan",
    "udd_address": "Jl. Kusuma Bangsa No. 7, Lamongan",
    "udd_hotline": "(0322) 321718",
    "udd_emergency_phone": "0812-3456-7890",
    "udd_email": "udd.pmi@lamongankab.go.id",
    "default_radius_km": 5.0,
    "max_search_radius_km": 15.0,
    "emergency_radius_km": 25.0,
    "auto_dispatch": True,
    "sms_gateway": True,
    "whatsapp_gateway": True,
    "min_donor_interval_days": 60,
    "require_doctor_letter": True,
}

@router.get("/settings")
def get_system_settings(
    _user: Optional[User] = Depends(get_current_user_optional),
):
    """Mendapatkan konfigurasi sistem admin."""
    return _system_settings


@router.post("/settings")
@router.put("/settings")
def update_system_settings(
    new_settings: dict,
    _user: Optional[User] = Depends(get_current_user_optional),
):
    """Menyimpan atau memperbarui konfigurasi sistem."""
    _system_settings.update(new_settings)
    return {
        "status": "success",
        "message": "Pengaturan sistem berhasil disimpan",
        "settings": _system_settings,
    }


