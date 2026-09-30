from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr, Field, field_validator

from app.models import RoleEnum, GolonganDarahEnum, RhesusEnum, SumberDataEnum


class UserRegister(BaseModel):
    """
    Registrasi mandiri HANYA untuk role requester (keluarga pasien).
    Akun donor TIDAK dibuat lewat endpoint ini — data donor diimpor dari
    PMI Pusat (lihat scripts/import_pmi_dataset.py) lalu diaktivasi lewat
    endpoint /auth/activate.
    """

    nama: str = Field(min_length=2, max_length=100)
    email: EmailStr
    no_hp: str = Field(min_length=8, max_length=20)
    password: str = Field(min_length=8, max_length=72)
    role: RoleEnum = RoleEnum.requester

    @field_validator("role")
    @classmethod
    def role_hanya_requester(cls, v: RoleEnum) -> RoleEnum:
        if v != RoleEnum.requester:
            raise ValueError(
                "Registrasi mandiri hanya untuk peminta darah (requester). "
                "Akun donor diimpor dari data PMI Pusat, aktivasi lewat /auth/activate. "
                "Akun admin dibuat manual oleh pengelola sistem."
            )
        return v


class ActivateAccount(BaseModel):
    """
    Aktivasi akun donor hasil impor PMI Pusat: donor men-set password
    pertama kalinya. Verifikasi identitas sederhana (email + no_hp harus
    cocok persis dengan data PMI) -- untuk produksi sebaiknya ditambah
    verifikasi OTP SMS, di luar scope simulasi ini.
    """

    email: EmailStr
    no_hp: str = Field(min_length=8, max_length=20)
    password_baru: str = Field(min_length=8, max_length=72)


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    id: int
    nama: str
    email: EmailStr
    no_hp: str
    role: RoleEnum
    golongan_darah: Optional[GolonganDarahEnum] = None
    rhesus: Optional[RhesusEnum] = None
    status_aktif: bool
    izin_lokasi: bool
    sumber_data: SumberDataEnum
    is_activated: bool
    created_at: datetime

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class TokenPayload(BaseModel):
    user_id: int
    role: RoleEnum