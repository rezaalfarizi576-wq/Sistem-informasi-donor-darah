from datetime import datetime
import enum
from sqlalchemy import Column, Integer, String, Text, Boolean, DateTime, ForeignKey, Numeric, Enum as SQLEnum
from sqlalchemy.orm import relationship, synonym
from app.database import Base


class RoleEnum(str, enum.Enum):
    admin = "admin"
    donor = "donor"
    requester = "requester"


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    nik = Column(String(20), unique=True, index=True, nullable=True)
    nama = Column(String(150), nullable=False)
    email = Column(String(150), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=True)
    role = Column(SQLEnum(RoleEnum), nullable=False, default=RoleEnum.donor)
    no_hp = Column(String(20), nullable=True)
    blood_type = Column(SQLEnum('A', 'B', 'AB', 'O', name='blood_types'), nullable=True)
    rhesus = Column(SQLEnum('+', '-', name='rhesus_types'), nullable=True, default='+')
    address = Column(Text, nullable=True)
    sumber_data = Column(String(50), nullable=False, default="mandiri")
    is_activated = Column(Boolean, default=True)
    status_aktif = Column(Boolean, default=True)
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


class DonorLocation(Base):
    __tablename__ = "donor_locations"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String(150), nullable=False)
    address = Column(Text, nullable=False)
    latitude = Column(Numeric(10, 8), nullable=True)
    longitude = Column(Numeric(11, 8), nullable=True)
    contact_number = Column(String(20), nullable=True)
    operating_hours = Column(String(100), nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class BloodRequest(Base):
    __tablename__ = "blood_requests"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    requester_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    patient_name = Column(String(150), nullable=False)
    hospital_name = Column(String(150), nullable=False)
    blood_type = Column(SQLEnum('A', 'B', 'AB', 'O', name='blood_types'), nullable=False)
    rhesus = Column(SQLEnum('+', '-', name='rhesus_types'), default='+')
    bags_needed = Column(Integer, nullable=False, default=1)
    bags_collected = Column(Integer, nullable=False, default=0)
    urgency_level = Column(SQLEnum('normal', 'urgent', 'critical', name='urgency_levels'), default='normal')
    status = Column(SQLEnum('pending', 'in_progress', 'completed', 'cancelled', name='request_status'), default='pending')
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    requester = relationship("User", back_populates="blood_requests")
    responses = relationship("DonationResponse", back_populates="request", cascade="all, delete-orphan")


class DonationResponse(Base):
    __tablename__ = "donation_responses"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    request_id = Column(Integer, ForeignKey("blood_requests.id", ondelete="CASCADE"), nullable=False)
    donor_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    status = Column(SQLEnum('accepted', 'heading_to_location', 'arrived', 'donated', 'cancelled', name='response_status'), default='accepted')
    donor_latitude = Column(Numeric(10, 8), nullable=True)
    donor_longitude = Column(Numeric(11, 8), nullable=True)
    last_location_update = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    request = relationship("BloodRequest", back_populates="responses")
    donor = relationship("User", back_populates="donation_responses")
