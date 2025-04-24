from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
import uuid
from typing import List, Optional
from geopy.distance import geodesic
import logging
import datetime
from database import get_db, init_db
from models import User, Alert, UserPreferences, EmergencyContact, CommunityResource
from schemas import (
    UserCreate, User as UserSchema,
    AlertCreate, Alert as AlertSchema,
    UserPreferencesCreate, UserPreferences as UserPreferencesSchema,
    EmergencyContactCreate, EmergencyContact as EmergencyContactSchema,
    CommunityResourceCreate, CommunityResource as CommunityResourceSchema,
    Token
)
from auth import (
    get_current_user, create_tokens,
    verify_password, get_password_hash
)

# Configure logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = FastAPI(title="Community Alert API")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize database
@app.on_event("startup")
async def startup():
    init_db()

# Auth routes
@app.post("/api/auth/register", response_model=Token)
async def register(user: UserCreate, db: Session = Depends(get_db)):
    try:
        logger.debug(f"Registration attempt with data: {user.dict()}")
    except Exception as e:
        logger.error(f"Error parsing registration data: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Invalid request data: {str(e)}"
        )
    
    # Check if user already exists
    db_user = db.query(User).filter(User.email == user.email).first()
    if db_user:
        logger.warning(f"Registration failed - Email already exists: {user.email}")
        raise HTTPException(status_code=400, detail="Email already registered")
    
    try:
        # Create new user
        user_id = str(uuid.uuid4())
        logger.debug(f"Creating new user with ID: {user_id}")
        
        db_user = User(
            id=user_id,
            email=user.email,
            password=get_password_hash(user.password),
            full_name=user.full_name,
            phone_number=user.phone_number
        )
        db.add(db_user)
        
        # Create default preferences
        logger.debug("Creating default user preferences")
        db_preferences = UserPreferences(
            user_id=user_id,
            alert_radius=5.0,
            sound_enabled=True,
            vibration_enabled=True,
            critical_alerts_enabled=True,
            community_alerts_enabled=True
        )
        db.add(db_preferences)
        
        db.commit()
        logger.info(f"User successfully registered: {user.email}")
        return create_tokens(user_id)
    except Exception as e:
        logger.error(f"Error during registration: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An error occurred during registration"
        )

@app.post("/api/auth/login", response_model=Token)
async def login(email: str, password: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == email).first()
    if not user or not verify_password(password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Update last login
    user.last_login = datetime.datetime.utcnow()
    db.commit()
    
    return create_tokens(user.id)

# Alert routes
@app.get("/api/alerts", response_model=List[AlertSchema])
async def get_alerts(
    latitude: Optional[float] = None,
    longitude: Optional[float] = None,
    radius: Optional[float] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        query = db.query(Alert).filter(Alert.is_active == True)
        
        if latitude and longitude and radius:
            alerts = query.all()
            try:
                return [
                    alert for alert in alerts
                    if geodesic((latitude, longitude), (alert.latitude, alert.longitude)).km <= radius
                ]
            except ValueError as e:
                logger.error(f"Error calculating distance: {str(e)}")
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid coordinates provided"
                )
        
        return query.all()
    except Exception as e:
        logger.error(f"Error fetching alerts: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An error occurred while fetching alerts"
        )

@app.post("/api/alerts", response_model=AlertSchema)
async def create_alert(
    alert: AlertCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    db_alert = Alert(
        id=str(uuid.uuid4()),
        title=alert.title,
        description=alert.description,
        category=alert.category,
        priority=alert.priority,
        latitude=alert.location.latitude,
        longitude=alert.location.longitude,
        radius=alert.radius,
        source=alert.source,
        user_id=current_user.id
    )
    db.add(db_alert)
    db.commit()
    db.refresh(db_alert)
    return db_alert

# User routes
@app.get("/api/users/{user_id}", response_model=UserSchema)
async def get_user(
    user_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to access this user")
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@app.get("/api/users/{user_id}/preferences", response_model=UserPreferencesSchema)
async def get_user_preferences(
    user_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to access these preferences")
    
    preferences = db.query(UserPreferences).filter(UserPreferences.user_id == user_id).first()
    if not preferences:
        raise HTTPException(status_code=404, detail="Preferences not found")
    return preferences

@app.put("/api/users/{user_id}/preferences", response_model=UserPreferencesSchema)
async def update_user_preferences(
    user_id: str,
    preferences: UserPreferencesCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to update these preferences")
    
    db_preferences = db.query(UserPreferences).filter(UserPreferences.user_id == user_id).first()
    if not db_preferences:
        raise HTTPException(status_code=404, detail="Preferences not found")
    
    for key, value in preferences.dict().items():
        setattr(db_preferences, key, value)
    
    db.commit()
    db.refresh(db_preferences)
    return db_preferences

# Community Resources routes
@app.get("/api/resources/nearby", response_model=List[CommunityResourceSchema])
async def get_nearby_resources(
    latitude: float,
    longitude: float,
    radius: float,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    resources = db.query(CommunityResource).all()
    return [
        resource for resource in resources
        if geodesic((latitude, longitude), (resource.latitude, resource.longitude)).km <= radius
    ] 