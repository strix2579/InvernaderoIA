from pydantic import BaseModel, Field, EmailStr, validator
from typing import List, Optional, Dict
from datetime import datetime
import uuid
import re

# ---- Auth Models ----
class Token(BaseModel):
    access_token: str
    token_type: str
    refresh_token: Optional[str] = None

class TokenData(BaseModel):
    username: Optional[str] = None
    role: Optional[str] = None

class User(BaseModel):
    username: str
    email: Optional[EmailStr] = None
    full_name: Optional[str] = None
    disabled: Optional[bool] = None
    role: str = "viewer" # admin, viewer

class UserInDB(User):
    hashed_password: str

class UserCreate(BaseModel):
    username: str
    email: EmailStr
    full_name: Optional[str] = None
    password: str
    role: str = "viewer"
    
    @validator('password')
    def validate_password(cls, v):
        if len(v) < 8:
            raise ValueError('La contraseña debe tener al menos 8 caracteres')
        if not re.search(r'[A-Z]', v):
            raise ValueError('La contraseña debe contener al menos una mayúscula')
        if not re.search(r'[a-z]', v):
            raise ValueError('La contraseña debe contener al menos una minúscula')
        if not re.search(r'[0-9]', v):
            raise ValueError('La contraseña debe contener al menos un número')
        return v
    
    @validator('username')
    def validate_username(cls, v):
        if len(v) < 3:
            raise ValueError('El usuario debe tener al menos 3 caracteres')
        if not re.match(r'^[a-zA-Z0-9_]+$', v):
            raise ValueError('El usuario solo puede contener letras, números y guiones bajos')
        return v

class PasswordReset(BaseModel):
    email: EmailStr

class PasswordResetConfirm(BaseModel):
    token: str
    new_password: str
    
    @validator('new_password')
    def validate_password(cls, v):
        if len(v) < 8:
            raise ValueError('La contraseña debe tener al menos 8 caracteres')
        if not re.search(r'[A-Z]', v):
            raise ValueError('La contraseña debe contener al menos una mayúscula')
        if not re.search(r'[a-z]', v):
            raise ValueError('La contraseña debe contener al menos una minúscula')
        if not re.search(r'[0-9]', v):
            raise ValueError('La contraseña debe contener al menos un número')
        return v

# ---- Sensor & Actuator Models ----

class GasReadings(BaseModel):
    mq2: float = Field(..., description="Lectura bruta MQ-2 (0-1023)")
    mq5: float = Field(..., description="Lectura bruta MQ-5 (0-1023)")
    mq8: float = Field(..., description="Lectura bruta MQ-8 (0-1023)")
    aqi: float = Field(..., description="AQI calculado (0-500)")

class SensorData(BaseModel):
    timestamp: Optional[datetime] = Field(default_factory=datetime.utcnow)
    temp: float = Field(..., description="Temperatura (°C)")
    hum: float = Field(..., description="Humedad relativa (%)")
    soil_moisture: List[float] = Field(..., description="Lista de humedad del suelo (%)")
    gas: GasReadings

class SensorReadingResponse(BaseModel):
    id: int
    timestamp: datetime
    temperature: float
    humidity: float
    soil_moisture_1: float
    soil_moisture_2: float
    water_level_1: float
    water_level_2: float
    gas_mq2: float
    gas_mq5: float
    gas_mq135: float

    class Config:
        orm_mode = True

class DeviceState(BaseModel):
    on: bool
    value: Optional[int] = None # 0-100 for speed/intensity
    color: Optional[str] = None # Hex code for lights

class ActuatorState(BaseModel):
    fan: DeviceState
    pump: DeviceState
    lights: DeviceState
    heater: DeviceState

# ---- Alert / AI Models ----
class Alert(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    type: str # FIRE, LEAK, DISEASE, NORMAL
    confidence: float
    severity: str # INFO, WARNING, CRITICAL
    action_taken: Optional[str] = None