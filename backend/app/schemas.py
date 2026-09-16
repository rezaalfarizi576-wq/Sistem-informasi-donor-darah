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
    email: EmailStr
    no_hp: str
    password_baru: str = Field(..., min_length=6)


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserResponse(BaseModel):
    id: int
    nama: str
    email: EmailStr
    no_hp: Optional[str] = None
    role: RoleEnum
    sumber_data: Optional[str] = "mandiri"
    is_activated: bool = True
    status_aktif: bool = True
    nik: Optional[str] = None
    blood_type: Optional[str] = None
    rhesus: Optional[str] = None
    address: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


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


# --- DONOR LOCATION SCHEMAS ---

class DonorLocationBase(BaseModel):
    name: str
    address: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    contact_number: Optional[str] = None
    operating_hours: Optional[str] = None
    is_active: bool = True


class DonorLocationCreate(DonorLocationBase):
    pass


class DonorLocationResponse(DonorLocationBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# --- BLOOD REQUEST SCHEMAS ---

class BloodRequestBase(BaseModel):
    patient_name: str
    hospital_name: str
    blood_type: str = Field(..., pattern="^(A|B|AB|O)$")
    rhesus: str = Field("+", pattern="^(\\+|\\-)$")
    bags_needed: int = Field(1, ge=1)
    urgency_level: str = Field("normal", pattern="^(normal|urgent|critical)$")
    notes: Optional[str] = None


class BloodRequestCreate(BloodRequestBase):
    pass


class BloodRequestResponse(BloodRequestBase):
    id: int
    requester_id: int
    bags_collected: int
    status: str
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# --- DONATION RESPONSE SCHEMAS ---

class DonationResponseCreate(BaseModel):
    request_id: int


class DonationResponseUpdateStatus(BaseModel):
    status: str = Field(..., pattern="^(accepted|heading_to_location|arrived|donated|cancelled)$")


class LocationUpdate(BaseModel):
    latitude: float
    longitude: float
