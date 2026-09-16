from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User, RoleEnum, DonorLocation, BloodRequest
from app.schemas import (
    UserResponse,
    DonorLocationResponse,
    DonorLocationCreate,
    BloodRequestResponse,
)
from app.auth import require_role

router = APIRouter(prefix="/admin", tags=["Admin"])


@router.get("/users", response_model=list[UserResponse])
def list_all_users(
    db: Session = Depends(get_db),
    # Hanya role admin yang boleh mengakses endpoint ini (RBAC).
    _admin: User = Depends(require_role(RoleEnum.admin)),
):
    """Contoh endpoint ber-RBAC: daftar seluruh pengguna, khusus admin."""
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
        .filter(BloodRequest.status.in_(["pending", "in_progress"]))
        .count()
    )
    total_locations = (
        db.query(DonorLocation).filter(DonorLocation.is_active == True).count()
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


@router.get("/requests", response_model=List[BloodRequestResponse])
def get_all_blood_requests(
    status_filter: Optional[str] = Query(None, alias="status"),
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
    _admin: User = Depends(require_role(RoleEnum.admin)),
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
