import random
import time
from typing import Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User
from app.schemas import (
    UserRegister,
    UserLogin,
    UserResponse,
    Token,
    ActivateAccount,
    ForgotPasswordRequest,
    ForgotPasswordReset,
)
from app.auth import hash_password, verify_password, create_access_token, get_current_user

router = APIRouter(prefix="/auth", tags=["Auth"])

# In-memory storage for OTP codes: {user_id: {"otp": str, "expires_at": float, "identifier": str}}
_otp_storage: Dict[int, Dict[str, Any]] = {}


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(payload: UserRegister, db: Session = Depends(get_db)):
    """FR-01: Registrasi mandiri (requester atau pendonor mandiri)."""

    clean_nik = payload.nik.strip() if payload.nik and payload.nik.strip() else None
    if clean_nik:
        existing_nik = db.query(User).filter(User.nik == clean_nik).first()
        if existing_nik:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="NIK sudah terdaftar di sistem",
            )

    existing = (
        db.query(User)
        .filter((User.email == payload.email) | (User.no_hp == payload.no_hp))
        .first()
    )
    if existing:
        detail = "Email sudah terdaftar di sistem" if existing.email == payload.email else "Nomor HP sudah terdaftar di sistem"
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=detail,
        )

    new_user = User(
        nama=payload.nama,
        email=payload.email,
        no_hp=payload.no_hp,
        nik=clean_nik,
        password_hash=hash_password(payload.password),
        role=payload.role,
        blood_type=payload.blood_type if payload.blood_type else None,
        rhesus=payload.rhesus if payload.rhesus else None,
        sumber_data="mandiri",
        is_activated=True,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user


@router.post("/activate", response_model=UserResponse)
def activate_account(payload: ActivateAccount, db: Session = Depends(get_db)):
    """
    Aktivasi akun donor hasil impor PMI Pusat: donor men-set password
    pertama kalinya sebelum bisa login dan dipakai untuk menerima
    notifikasi permintaan darah.
    
    Validasi via NIK (16 digit), kemudian update email, phone, dan password baru.
    """

    user = (
        db.query(User)
        .filter(User.nik == payload.nik)
        .first()
    )
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="NIK tidak ditemukan di data terdaftar PMI Lamongan",
        )
    if user.sumber_data != "pmi_pusat":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Akun ini bukan hasil impor PMI Pusat, gunakan /auth/register",
        )
    if user.is_activated:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Akun sudah pernah diaktivasi, silakan login",
        )

    # Check if email already in use by another user
    existing_email = db.query(User).filter(User.email == payload.email, User.id != user.id).first()
    if existing_email:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email sudah terdaftar di sistem",
        )
    
    # Check if phone already in use by another user
    existing_phone = db.query(User).filter(User.no_hp == payload.phone, User.id != user.id).first()
    if existing_phone:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Nomor HP sudah terdaftar di sistem",
        )

    user.email = payload.email
    user.no_hp = payload.phone
    user.password_hash = hash_password(payload.password)
    user.is_activated = True
    db.commit()
    db.refresh(user)
    return user


@router.post("/login", response_model=Token)
async def login(request: Request, db: Session = Depends(get_db)):
    """
    FR-01: Autentikasi pengguna, mengembalikan JWT access token.
    Mendukung format Form URL-Encoded (Swagger UI / OAuth2 / Flutter) dan JSON Body.
    """
    content_type = request.headers.get("content-type", "")
    email = None
    password = None

    if "application/x-www-form-urlencoded" in content_type or "multipart/form-data" in content_type:
        form = await request.form()
        email = form.get("username") or form.get("email")
        password = form.get("password")
    else:
        try:
            body = await request.json()
            email = body.get("email") or body.get("username")
            password = body.get("password")
        except Exception:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Format data login tidak valid",
            )

    if not email or not password:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Email/username dan password wajib diisi",
        )

    user = db.query(User).filter(User.email == email).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email atau password salah",
        )

    if not user.is_activated or user.password_hash is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Akun belum diaktivasi. Silakan aktivasi dulu lewat /auth/activate",
        )

    if not verify_password(password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email atau password salah",
        )

    if not user.status_aktif:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Akun tidak aktif, hubungi admin",
        )

    token = create_access_token(user_id=user.id, role=user.role.value)
    return Token(
        access_token=token,
        token_type="bearer",
        user=UserResponse.model_validate(user),
    )


@router.get("/me", response_model=UserResponse)
def read_current_user(current_user: User = Depends(get_current_user)):
    """Ambil data profil pengguna yang sedang login (validasi token)."""
    return current_user


def _find_user_by_identifier(db: Session, identifier: str) -> User | None:
    """Helper untuk mencari pengguna berdasarkan email, no_hp, atau NIK (dengan variasi nomor telepon)."""
    clean_id = identifier.strip()
    if not clean_id:
        return None

    # Cari langsung via email / no_hp / nik
    user = (
        db.query(User)
        .filter(
            (User.email == clean_id)
            | (User.no_hp == clean_id)
            | (User.nik == clean_id)
        )
        .first()
    )
    if user:
        return user

    # Cek variasi nomor telepon (08xx vs 628xx vs +628xx)
    variants = []
    if clean_id.startswith("08"):
        variants.append("628" + clean_id[2:])
        variants.append("+628" + clean_id[2:])
    elif clean_id.startswith("628"):
        variants.append("08" + clean_id[3:])
        variants.append("+628" + clean_id[3:])
    elif clean_id.startswith("+628"):
        variants.append("08" + clean_id[4:])
        variants.append("628" + clean_id[4:])

    for v in variants:
        found = db.query(User).filter(User.no_hp == v).first()
        if found:
            return found

    return None


@router.post("/forgot-password/request-otp")
def request_password_reset_otp(payload: ForgotPasswordRequest, db: Session = Depends(get_db)):
    """
    Generate 4 digit OTP untuk reset password.
    Mendukung pencarian via No HP, Email, atau NIK.
    Mengembalikan OTP dalam response agar frontend dapat menampilkan banner notifikasi langsung
    dan menyiapkan tautan WhatsApp.
    """
    user = _find_user_by_identifier(db, payload.identifier)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Akun dengan Email, Nomor HP, atau NIK tersebut tidak ditemukan",
        )

    if not user.status_aktif:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Akun ini berstatus non-aktif. Silakan hubungi admin UTD PMI Lamongan.",
        )

    # Generate 4-digit numeric OTP
    otp_code = f"{random.randint(1000, 9999)}"
    # 5 menit masa berlaku (300 detik)
    expires_at = time.time() + 300

    _otp_storage[user.id] = {
        "otp": otp_code,
        "expires_at": expires_at,
        "identifier": payload.identifier.strip(),
    }

    # Masking no_hp untuk privacy preview
    phone_preview = user.no_hp or ""
    if len(phone_preview) >= 8:
        phone_preview = phone_preview[:4] + "****" + phone_preview[-3:]

    # Masking email
    email_preview = user.email
    if "@" in email_preview:
        parts = email_preview.split("@")
        name_part = parts[0]
        if len(name_part) > 2:
            masked_name = name_part[0] + "***" + name_part[-1]
        else:
            masked_name = name_part + "***"
        email_preview = f"{masked_name}@{parts[1]}"

    return {
        "success": True,
        "message": f"Kode OTP telah digenerate untuk {user.nama}",
        "otp_code": otp_code,
        "user_name": user.nama,
        "phone": user.no_hp,
        "phone_preview": phone_preview,
        "email": user.email,
        "email_preview": email_preview,
        "user_id": user.id,
        "expires_in_seconds": 300,
    }


@router.post("/forgot-password/reset")
def reset_password_with_otp(payload: ForgotPasswordReset, db: Session = Depends(get_db)):
    """
    Validasi OTP 4-digit dan perbarui password pengguna.
    """
    user = _find_user_by_identifier(db, payload.identifier)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Akun tidak ditemukan",
        )

    cached_otp = _otp_storage.get(user.id)
    if not cached_otp:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Kode OTP belum diminta atau sudah kedaluwarsa. Silakan minta kode OTP baru.",
        )

    now = time.time()
    if now > cached_otp["expires_at"]:
        _otp_storage.pop(user.id, None)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Kode OTP sudah kedaluwarsa (lebih dari 5 menit). Silakan minta kode OTP baru.",
        )

    if cached_otp["otp"] != payload.otp_code.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Kode OTP tidak sesuai. Silakan periksa kode 4 digit Anda.",
        )

    # Update password
    user.password_hash = hash_password(payload.new_password)
    # Jika akun sebelumnya belum aktif / dari PMI pusat, sekalian aktifkan
    user.is_activated = True
    db.commit()

    # Hapus OTP yang sudah digunakan
    _otp_storage.pop(user.id, None)

    return {
        "success": True,
        "message": "Password berhasil diperbarui. Silakan masuk menggunakan password baru Anda.",
    }

