from typing import List, Optional, Any
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.database import get_db
from datetime import datetime
from app.models import User, RoleEnum, DonorLocation, BloodRequest, HealthFacility, DonationResponse
from app.schemas import (
    UserResponse,
    DonorLocationResponse,
    DonorLocationCreate,
    BloodRequestResponse,
    BloodRequestCreate,
)
from app.auth import require_role, get_current_user_optional

router = APIRouter(prefix="/admin", tags=["Admin"])
requests_router = APIRouter(prefix="/requests", tags=["Requests"])


@router.get("/users", response_model=list[UserResponse])
def list_all_users(
    db: Session = Depends(get_db),
    _admin: User = Depends(require_role(RoleEnum.admin)),
):
    """Daftar seluruh pengguna, khusus admin."""
    return db.query(User).all()


@router.get("/stats")
def get_dashboard_stats(
    db: Session = Depends(get_db),
    _admin: User = Depends(require_role(RoleEnum.admin)),
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

