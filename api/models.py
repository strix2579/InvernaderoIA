from sqlalchemy import Column, Integer, Float, String, DateTime, Boolean
from datetime import datetime
from .database import Base

class SensorReading(Base):
    __tablename__ = "sensor_readings"

    id = Column(Integer, primary_key=True, index=True)
    timestamp = Column(DateTime, default=datetime.utcnow)
    
    # Datos ambientales
    temperature = Column(Float)
    humidity = Column(Float)
    
    # Datos de suelo y agua
    soil_moisture_1 = Column(Float)
    soil_moisture_2 = Column(Float)
    water_level_1 = Column(Integer)
    water_level_2 = Column(Integer)
    
    # Datos de calidad de aire (sensores MQ)
    gas_mq2 = Column(Integer, nullable=True)
    gas_mq5 = Column(Integer, nullable=True)
    gas_mq135 = Column(Integer, nullable=True) # Asumiendo MQ135 o similar para AQI
    
    # Estado del sistema
    pump_state = Column(Boolean, default=False)
    fan_state = Column(Boolean, default=False)
    light_state = Column(Boolean, default=False)

class AlarmLog(Base):
    __tablename__ = "alarm_logs"

    id = Column(Integer, primary_key=True, index=True)
    timestamp = Column(DateTime, default=datetime.utcnow)
    type = Column(String) # "WATER_LEVEL", "GAS", "TEMP", etc.
    message = Column(String)
    active = Column(Boolean, default=True)
    resolved_at = Column(DateTime, nullable=True)

class SystemConfig(Base):
    __tablename__ = "system_configs"
    
    id = Column(Integer, primary_key=True, index=True)
    key = Column(String, unique=True, index=True) # ej: "min_temp", "irrigation_interval"
    value = Column(String)
    description = Column(String, nullable=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
