from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User
from app.schemas import UserRegister, UserLogin, UserResponse, Token, ActivateAccount
from app.auth import hash_password, verify_password, create_access_token, get_current_user

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(payload: UserRegister, db: Session = Depends(get_db)):
    """FR-01: Registrasi mandiri, khusus peminta darah (requester)."""

    existing = (
        db.query(User)
        .filter((User.email == payload.email) | (User.no_hp == payload.no_hp))
        .first()
    )
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email atau nomor HP sudah terdaftar",
        )

    new_user = User(
        nama=payload.nama,
        email=payload.email,
        no_hp=payload.no_hp,
        password_hash=hash_password(payload.password),
        role=payload.role,  # selalu 'requester', divalidasi di schema
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
    """

    user = (
        db.query(User)
        .filter(User.email == payload.email, User.no_hp == payload.no_hp)
        .first()
    )
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Data tidak ditemukan. Pastikan email & no HP sesuai data terdaftar di PMI",
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

    user.password_hash = hash_password(payload.password_baru)
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
