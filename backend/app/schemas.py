from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, EmailStr, Field
from app.models import RoleEnum

# --- AUTH & USER SCHEMAS ---

class UserRegister(BaseModel):
    nama: str = Field(..., min_length=2, max_length=150)
    email: EmailStr
    no_hp: str = Field(..., min_length=8, max_length=20)
    password: str = Field(..., min_length=6)
    role: RoleEnum = Field(default=RoleEnum.requester)


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class ActivateAccount(BaseModel):
    nik: str = Field(..., min_length=16, max_length=16)
    email: EmailStr
    phone: str = Field(..., min_length=8, max_length=20)
    password: str = Field(..., min_length=6)


class UserResponse(BaseModel):
    id: int
    nama: str
    email: EmailStr
    no_hp: Optional[str] = None
    role: RoleEnum
    sumber_data: Optional[str] = "mandiri"
    is_activated: bool = True
    status_aktif: bool = True
    izin_lokasi: bool = False
    id_pmi: Optional[str] = None
    blood_type: Optional[str] = None
    rhesus: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: Optional[UserResponse] = None


class TokenData(BaseModel):
    user_id: Optional[int] = None
    role: Optional[str] = None


# Backward compatibility schemas
class UserBase(BaseModel):
    nama: str = Field(..., min_length=2, max_length=150)
    email: EmailStr
    no_hp: Optional[str] = None
    role: RoleEnum = RoleEnum.donor
    blood_type: Optional[str] = None
    rhesus: Optional[str] = None
    address: Optional[str] = None

    class Config:
        from_attributes = True


class UserCreate(BaseModel):
    nama: str = Field(..., min_length=2, max_length=150)
    email: EmailStr
    no_hp: Optional[str] = None
    password: str = Field(..., min_length=6)
    role: RoleEnum = RoleEnum.donor
    nik: Optional[str] = None
    blood_type: Optional[str] = None
    rhesus: Optional[str] = None
    address: Optional[str] = None


class AccountActivationRequest(BaseModel):
    email: EmailStr
    no_hp: str
    password: str = Field(..., min_length=6)
    nik: Optional[str] = None


# --- HEALTH FACILITY SCHEMAS (tabel health_facilities) ---

class HealthFacilityBase(BaseModel):
    nama_faskes: str = Field(..., max_length=150)
    alamat: str = Field(..., max_length=255)
    latitude: float
    longitude: float
    telepon: Optional[str] = Field(None, max_length=20)
    terverifikasi: bool = False


class HealthFacilityCreate(HealthFacilityBase):
    pass


class HealthFacilityResponse(HealthFacilityBase):
    id: int
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# --- DONOR LOCATION SCHEMAS (tabel donor_locations: lokasi donor) ---

class DonorLocationBase(BaseModel):
    latitude: float
    longitude: float
    akurasi_meter: Optional[float] = None
    is_current: bool = True


class DonorLocationCreate(DonorLocationBase):
    pass


class DonorLocationResponse(DonorLocationBase):
    id: int
    user_id: int
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# --- BLOOD REQUEST SCHEMAS (tabel blood_requests) ---

class BloodRequestBase(BaseModel):
    facility_id: Optional[int] = None
    blood_type: str = Field(..., pattern="^(A|B|AB|O)$")
    rhesus: Optional[str] = Field("+", pattern="^(\\+|\\-)$")
    bags_needed: int = Field(1, ge=1)
    urgency_level: str = Field("sedang", pattern="^(sedang|tinggi|kritis)$")
    latitude_faskes: float
    longitude_faskes: float
    radius_km: float = Field(5.0, gt=0)
    notes: Optional[str] = Field(None, max_length=500)


class BloodRequestCreate(BloodRequestBase):
    pass


class BloodRequestResponse(BloodRequestBase):
    id: int
    requester_id: int
    hospital_name: Optional[str] = None
    status: str
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# --- DONATION RESPONSE SCHEMAS (tabel request_responses) ---

class DonationResponseCreate(BaseModel):
    request_id: int


class DonationResponseUpdateStatus(BaseModel):
    status: str = Field(..., pattern="^(menunggu|diterima|ditolak|dibatalkan)$")


class LocationUpdate(BaseModel):
    latitude: float
    longitude: float
    akurasi_meter: Optional[float] = None