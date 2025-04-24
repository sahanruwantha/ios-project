from pydantic import BaseModel, EmailStr
from typing import List, Optional
from datetime import datetime
from models import AlertCategory, AlertPriority, AlertVerificationStatus, ResourceType

class Location(BaseModel):
    latitude: float
    longitude: float

class UserBase(BaseModel):
    email: EmailStr
    full_name: str
    phone_number: str

class UserCreate(UserBase):
    password: str

class User(UserBase):
    id: str
    avatar_url: Optional[str] = None
    created_at: datetime
    last_login: Optional[datetime] = None

    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str
    expires_in: int
    user_id: str

class AlertBase(BaseModel):
    title: str
    description: str
    category: AlertCategory
    priority: AlertPriority
    location: Location
    radius: float
    source: str

class AlertCreate(AlertBase):
    pass

class Alert(AlertBase):
    id: str
    verification_status: AlertVerificationStatus
    timestamp: datetime
    is_active: bool
    user_id: str

    class Config:
        from_attributes = True

class NotificationSettings(BaseModel):
    sound_enabled: bool
    vibration_enabled: bool
    critical_alerts_enabled: bool
    community_alerts_enabled: bool

class EmergencyContactBase(BaseModel):
    name: str
    phone_number: str
    relationship: str

class EmergencyContactCreate(EmergencyContactBase):
    pass

class EmergencyContact(EmergencyContactBase):
    id: str
    user_id: str

    class Config:
        from_attributes = True

class UserPreferencesBase(BaseModel):
    alert_radius: float
    notification_settings: NotificationSettings

class UserPreferencesCreate(UserPreferencesBase):
    pass

class UserPreferences(UserPreferencesBase):
    user_id: str

    class Config:
        from_attributes = True

class CommunityResourceBase(BaseModel):
    name: str
    type: ResourceType
    location: Location
    description: Optional[str] = None
    contact_info: Optional[str] = None

class CommunityResourceCreate(CommunityResourceBase):
    pass

class CommunityResource(CommunityResourceBase):
    id: str

    class Config:
        from_attributes = True 