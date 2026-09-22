from datetime import datetime
import enum
from sqlalchemy import (
    Column, BigInteger, SmallInteger, String, Boolean, DateTime, Float,
    ForeignKey, Numeric, UniqueConstraint, Enum as SQLEnum,
)
from sqlalchemy.orm import relationship, synonym
from app.database import Base

# Model ini disesuaikan dengan struktur tabel di database `donor_darah_lamongan`
# (phpMyAdmin): users, health_facilities, donor_locations, blood_requests,
# request_responses, donation_history.


class RoleEnum(str, enum.Enum):
    admin = "admin"
    donor = "donor"
    requester = "requester"


class User(Base):
    __tablename__ = "users"

    id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    nama = Column(String(100), nullable=False)
    email = Column(String(150), unique=True, index=True, nullable=False)
    no_hp = Column(String(20), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=True)
    role = Column(SQLEnum(RoleEnum), nullable=False, default=RoleEnum.donor)
    # Atribut Python tetap `blood_type`, kolom di database bernama `golongan_darah`
    blood_type = Column("golongan_darah", SQLEnum('A', 'B', 'AB', 'O', name='blood_types', create_constraint=False), nullable=True)
    rhesus = Column(SQLEnum('+', '-', name='rhesus_types', create_constraint=False), nullable=True)
    status_aktif = Column(Boolean, nullable=False, default=True)
    izin_lokasi = Column(Boolean, nullable=False, default=False)
    sumber_data = Column(String(20), nullable=False, default="mandiri")  # 'mandiri' atau 'pmi_pusat'
    id_pmi = Column(String(50), unique=True, nullable=True)
    is_activated = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Synonyms for backward compatibility
    name = synonym("nama")
    phone = synonym("no_hp")
    hashed_password = synonym("password_hash")
    is_active = synonym("status_aktif")

    # Relationships
    blood_requests = relationship("BloodRequest", back_populates="requester", cascade="all, delete-orphan")
    donation_responses = relationship("DonationResponse", back_populates="donor", cascade="all, delete-orphan")
    locations = relationship("DonorLocation", back_populates="user", cascade="all, delete-orphan")


class HealthFacility(Base):
    """Fasilitas kesehatan / UDD PMI (tabel `health_facilities`)."""
    __tablename__ = "health_facilities"

    id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    nama_faskes = Column(String(150), nullable=False)
    alamat = Column(String(255), nullable=False)
    latitude = Column(Numeric(10, 7), nullable=False)
    longitude = Column(Numeric(10, 7), nullable=False)
    telepon = Column(String(20), nullable=True)
    terverifikasi = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    blood_requests = relationship("BloodRequest", back_populates="facility")


class DonorLocation(Base):
    """Lokasi terakhir donor (tabel `donor_locations`), dipakai untuk pencarian radius."""
    __tablename__ = "donor_locations"

    id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    user_id = Column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    latitude = Column(Numeric(10, 7), nullable=False)
    longitude = Column(Numeric(10, 7), nullable=False)
    is_current = Column(Boolean, nullable=False, default=True)
    akurasi_meter = Column(Float, nullable=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Synonym for backward compatibility
    is_active = synonym("is_current")

    user = relationship("User", back_populates="locations")


class BloodRequest(Base):
    __tablename__ = "blood_requests"

    id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    requester_id = Column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    facility_id = Column(BigInteger, ForeignKey("health_facilities.id", ondelete="SET NULL"), nullable=True)
    blood_type = Column("golongan_darah", SQLEnum('A', 'B', 'AB', 'O', name='blood_types', create_constraint=False), nullable=False)
    rhesus = Column(SQLEnum('+', '-', name='rhesus_types', create_constraint=False), nullable=True)
    bags_needed = Column("jumlah_kantong", SmallInteger, nullable=False, default=1)
    urgency_level = Column("tingkat_urgensi", SQLEnum('kritis', 'tinggi', 'sedang', name='urgency_levels'), nullable=False, default='sedang')
    latitude_faskes = Column(Numeric(10, 7), nullable=False)
    longitude_faskes = Column(Numeric(10, 7), nullable=False)
    radius_km = Column(Numeric(4, 1), nullable=False, default=5.0)
    notes = Column("catatan", String(500), nullable=True)
    # Di database berupa ENUM: 'menunggu', 'diproses', 'terpenuhi', 'kedaluwarsa', ...
    # Dibuat String supaya nilai yang terpotong di screenshot tetap terbaca.
    status = Column(String(20), nullable=False, default='menunggu')
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    requester = relationship("User", back_populates="blood_requests")
    facility = relationship("HealthFacility", back_populates="blood_requests")
    responses = relationship("DonationResponse", back_populates="request", cascade="all, delete-orphan")

    @property
    def hospital_name(self):
        """Nama faskes, diambil dari relasi `facility` (tidak ada kolom sendiri)."""
        return self.facility.nama_faskes if self.facility else None


class DonationResponse(Base):
    """Respon donor terhadap permintaan darah (tabel `request_responses`)."""
    __tablename__ = "request_responses"
    __table_args__ = (UniqueConstraint("request_id", "donor_id", name="uq_request_donor"),)

    id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    request_id = Column(BigInteger, ForeignKey("blood_requests.id", ondelete="CASCADE"), nullable=False)
    donor_id = Column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    jarak_saat_notifikasi_km = Column(Numeric(5, 2), nullable=True)
    # Di database berupa ENUM: 'menunggu', 'diterima', 'ditolak', 'dibatalkan', ...
    status = Column(String(20), nullable=False, default='menunggu')
    waktu_respon = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    request = relationship("BloodRequest", back_populates="responses")
    donor = relationship("User", back_populates="donation_responses")


class DonationHistory(Base):
    """Riwayat donor yang sudah selesai (tabel `donation_history`)."""
    __tablename__ = "donation_history"

    id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    response_id = Column(BigInteger, ForeignKey("request_responses.id", ondelete="CASCADE"), unique=True, nullable=False)
    donor_id = Column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    request_id = Column(BigInteger, ForeignKey("blood_requests.id", ondelete="CASCADE"), nullable=False)
    tanggal_donor = Column(DateTime, nullable=False)
    lokasi_donor = Column(String(255), nullable=False)
    jumlah_kantong = Column(SmallInteger, nullable=False, default=1)
    created_at = Column(DateTime, default=datetime.utcnow)

    response = relationship("DonationResponse")
    donor = relationship("User")
    request = relationship("BloodRequest")