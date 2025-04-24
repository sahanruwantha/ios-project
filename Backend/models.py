from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime
import enum

Base = declarative_base()

class AlertCategory(str, enum.Enum):
    WEATHER = "Weather"
    TRAFFIC = "Traffic"
    CRIME = "Crime"
    COMMUNITY = "Community"
    PUBLIC_SAFETY = "Public Safety"
    INFRASTRUCTURE = "Infrastructure"

class AlertPriority(str, enum.Enum):
    IMMEDIATE = "Immediate"
    IMPORTANT = "Important"
    INFORMATIONAL = "Informational"

class AlertVerificationStatus(str, enum.Enum):
    VERIFIED = "Verified"
    PENDING = "Pending"
    UNVERIFIED = "Unverified"

class ResourceType(str, enum.Enum):
    SHELTER = "Shelter"
    HOSPITAL = "Hospital"
    POLICE_STATION = "Police Station"
    FIRE_STATION = "Fire Station"
    COMMUNITY_CENTER = "Community Center"

class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True)
    email = Column(String, unique=True, nullable=False)
    password = Column(String, nullable=False)
    full_name = Column(String, nullable=False)
    phone_number = Column(String, nullable=False)
    avatar_url = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    last_login = Column(DateTime, nullable=True)

class UserPreferences(Base):
    __tablename__ = "user_preferences"

    user_id = Column(String, ForeignKey("users.id"), primary_key=True)
    alert_radius = Column(Float, default=5.0)  # in kilometers
    sound_enabled = Column(Boolean, default=True)
    vibration_enabled = Column(Boolean, default=True)
    critical_alerts_enabled = Column(Boolean, default=True)
    community_alerts_enabled = Column(Boolean, default=True)

class EmergencyContact(Base):
    __tablename__ = "emergency_contacts"

    id = Column(String, primary_key=True)
    user_id = Column(String, ForeignKey("users.id"))
    name = Column(String, nullable=False)
    phone_number = Column(String, nullable=False)
    relationship = Column(String, nullable=False)

class Alert(Base):
    __tablename__ = "alerts"

    id = Column(String, primary_key=True)
    title = Column(String, nullable=False)
    description = Column(String, nullable=False)
    category = Column(Enum(AlertCategory), nullable=False)
    priority = Column(Enum(AlertPriority), nullable=False)
    verification_status = Column(Enum(AlertVerificationStatus), default=AlertVerificationStatus.PENDING)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    radius = Column(Float, nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow)
    source = Column(String, nullable=False)
    is_active = Column(Boolean, default=True)
    user_id = Column(String, ForeignKey("users.id"))

    @property
    def location(self):
        from schemas import Location
        return Location(latitude=self.latitude, longitude=self.longitude)

class CommunityResource(Base):
    __tablename__ = "community_resources"

    id = Column(String, primary_key=True)
    name = Column(String, nullable=False)
    type = Column(Enum(ResourceType), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    description = Column(String, nullable=True)
    contact_info = Column(String, nullable=True) 