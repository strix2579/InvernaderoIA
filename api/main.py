import numpy as np
import joblib
import tensorflow as tf
from fastapi import FastAPI, HTTPException, Depends, WebSocket, WebSocketDisconnect, status, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from datetime import timedelta, datetime
import os
import json
from pydantic import BaseModel
from sqlalchemy.orm import Session
from typing import List, Optional

# Local imports
from .schemas import (
    SensorData, Token, User, UserInDB, Alert, UserCreate,
    PasswordReset, PasswordResetConfirm, SensorReadingResponse
)
from .security import (
    create_access_token,
    create_refresh_token,
    create_password_reset_token,
    verify_password_reset_token,
    get_current_user, 
    get_current_admin_user, 
    verify_password, 
    get_password_hash, 
    ACCESS_TOKEN_EXPIRE_MINUTES
)
from .websocket_manager import manager
from . import models, database

# ---- Configuración de la App y Modelos ----

# Crear tablas en la base de datos
models.Base.metadata.create_all(bind=database.engine)

app = FastAPI(
    title="InvernaderoAI Orchestrator",
    description="Backend central para gestión de invernadero con IA y WebSockets.",
    version="2.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---- Cargar modelo y scaler ----
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "..", "modelos", "Nymbria.keras")
SCALER_PATH = os.path.join(BASE_DIR, "..", "scripts", "scaler.pkl")

print("📦 Cargando modelo y scaler...")
try:
    model = tf.keras.models.load_model(MODEL_PATH)
    scaler = joblib.load(SCALER_PATH)
    print("✅ Modelo y scaler cargados correctamente.")
except Exception as e:
    print(f"❌ Error al cargar el modelo o el scaler: {e}")
    model = None
    scaler = None

clases = ['NORMAL', 'INCENDIO', 'FUGA_H2', 'FALLA_ELECTRICA', 'PLAGA']

# ---- Base de Datos Simulada (In-Memory) ----
fake_users_db = {
    "admin": {
        "username": "admin",
        "full_name": "Admin User",
        "email": "admin@example.com",
        "hashed_password": get_password_hash("Admin123"),
        "disabled": False,
        "role": "admin"
    },
    "strix__": {
        "username": "strix__",
        "full_name": "emmanuel esquivel sarmiento",
        "email": "emmaeskiv2579@gmail.com",
        "hashed_password": get_password_hash("Junior2579"),
        "disabled": False,
        "role": "admin"
    },
    "user": {
        "username": "user",
        "full_name": "Normal User",
        "email": "user@example.com",
        "hashed_password": get_password_hash("User1234"),
        "disabled": False,
        "role": "viewer"
    }
}

# ---- Modelos Pydantic Adicionales ----
class GoogleLoginRequest(BaseModel):
    id_token: str

# ---- Helper Functions ----

async def send_password_reset_email(email: str, token: str):
    """
    En producción: enviar email real con SendGrid, AWS SES, etc.
    Por ahora solo imprime el link
    """
    reset_link = f"http://localhost:5555/reset-password?token={token}"
    print(f"📧 Email de recuperación para {email}:")
    print(f"   Link: {reset_link}")
    print(f"   Token: {token}")
    # TODO: Implementar envío real de email

# ---- Auth Endpoints ----

@app.post("/auth/register", response_model=Token)
async def register(user: UserCreate):
    """Registro de nuevos usuarios con validación completa"""
    # Verificar si el usuario ya existe
    if user.username in fake_users_db:
        raise HTTPException(
            status_code=400, 
            detail="El nombre de usuario ya está registrado"
        )
    
    # Verificar si el email ya existe
    for existing_user in fake_users_db.values():
        if existing_user.get("email") == user.email:
            raise HTTPException(
                status_code=400,
                detail="El email ya está registrado"
            )
    
    # Crear usuario
    hashed_password = get_password_hash(user.password)
    user_in_db = {
        "username": user.username,
        "email": user.email,
        "full_name": user.full_name,
        "hashed_password": hashed_password,
        "disabled": False,
        "role": user.role
    }
    
    fake_users_db[user.username] = user_in_db
    
    # Crear tokens
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username, "role": user.role}, 
        expires_delta=access_token_expires
    )
    refresh_token = create_refresh_token(
        data={"sub": user.username, "role": user.role}
    )
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer"
    }

@app.post("/auth/login", response_model=Token)
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends()):
    """Login tradicional con username/email y contraseña"""
    # Buscar por username o email
    user_dict = fake_users_db.get(form_data.username)
    
    if not user_dict:
        # Intentar buscar por email
        for username, data in fake_users_db.items():
            if data.get("email") == form_data.username:
                user_dict = data
                break
    
    if not user_dict:
        raise HTTPException(
            status_code=400,
            detail="Usuario o contraseña incorrectos"
        )
    
    user = UserInDB(**user_dict)
    
    if not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=400,
            detail="Usuario o contraseña incorrectos"
        )
    
    if user.disabled:
        raise HTTPException(
            status_code=400,
            detail="Usuario desactivado"
        )
    
    # Crear tokens
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username, "role": user.role},
        expires_delta=access_token_expires
    )
    refresh_token = create_refresh_token(
        data={"sub": user.username, "role": user.role}
    )
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer"
    }

@app.post("/auth/refresh", response_model=Token)
async def refresh_access_token(refresh_token: str):
    """Renovar access token usando refresh token"""
    from jose import jwt, JWTError
    from .security import SECRET_KEY, ALGORITHM
    
    try:
        payload = jwt.decode(refresh_token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        role: str = payload.get("role")
        token_type: str = payload.get("type")
        
        if token_type != "refresh":
            raise HTTPException(status_code=401, detail="Token inválido")
        
        # Crear nuevo access token
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": username, "role": role},
            expires_delta=access_token_expires
        )
        
        return {
            "access_token": access_token,
            "refresh_token": refresh_token,  # Mantener el mismo refresh token
            "token_type": "bearer"
        }
    except JWTError:
        raise HTTPException(status_code=401, detail="Token inválido o expirado")

@app.post("/auth/password-reset")
async def request_password_reset(reset_request: PasswordReset, background_tasks: BackgroundTasks):
    """Solicitar recuperación de contraseña"""
    # Verificar si el email existe
    user_found = False
    for user_data in fake_users_db.values():
        if user_data.get("email") == reset_request.email:
            user_found = True
            break
    
    # Por seguridad, siempre retornar éxito (no revelar si el email existe)
    if user_found:
        token = create_password_reset_token(reset_request.email)
        background_tasks.add_task(send_password_reset_email, reset_request.email, token)
    
    return {
        "message": "Si el email existe, recibirás un link de recuperación"
    }

@app.post("/auth/password-reset/confirm")
async def confirm_password_reset(reset_confirm: PasswordResetConfirm):
    """Confirmar recuperación de contraseña con token"""
    email = verify_password_reset_token(reset_confirm.token)
    
    if not email:
        raise HTTPException(
            status_code=400,
            detail="Token inválido o expirado"
        )
    
    # Actualizar contraseña
    for username, user_data in fake_users_db.items():
        if user_data.get("email") == email:
            user_data["hashed_password"] = get_password_hash(reset_confirm.new_password)
            return {"message": "Contraseña actualizada exitosamente"}
    
    raise HTTPException(status_code=404, detail="Usuario no encontrado")

@app.post("/auth/google", response_model=Token)
async def google_login(login_data: GoogleLoginRequest):
    """Google OAuth 2.0 Login"""
    # En producción: validar id_token con Google API
    id_token = login_data.id_token
    username = f"google_{id_token[:12]}"
    
    if username not in fake_users_db:
        fake_users_db[username] = {
            "username": username,
            "full_name": "Google User",
            "email": f"{username}@gmail.com",
            "hashed_password": get_password_hash("Google123"),
            "disabled": False,
            "role": "viewer"
        }
    
    access_token = create_access_token(
        data={"sub": username, "role": "viewer"}, 
        expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    refresh_token = create_refresh_token(
        data={"sub": username, "role": "viewer"}
    )
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer"
    }

@app.get("/auth/me", response_model=User)
async def read_users_me(current_user: User = Depends(get_current_user)):
    """Obtener información del usuario actual"""
    return current_user

# ---- Control Endpoint ----

class ControlCommandRequest(BaseModel):
    device_id: str
    action: str
    value: float = None
    timestamp: str = None

@app.post("/api/control")
async def control_device(command: ControlCommandRequest, current_user: User = Depends(get_current_user)):
    """
    Recibe comandos de control desde el frontend y los reenvía via WebSocket al ESP32.
    """
    print(f"📡 Comando recibido: {command}")
    
    # Mapear al formato que espera el ESP32
    # Frontend envía: device_id='pump1', action='ON'
    # ESP32 espera: { "type": "COMMAND", "payload": { "actuator": "pump1", "action": "ON" } }
    
    message = {
        "type": "COMMAND",
        "payload": {
            "actuator": command.device_id,
            "action": command.action,
            "value": command.value
        }
    }
    
    await manager.broadcast(message)
    return {"status": "command_sent", "command": command}

# ---- WebSocket Endpoint ----

@app.websocket("/ws/connect")
async def websocket_endpoint(websocket: WebSocket, client_id: str = "unknown"):
    await manager.connect(websocket, client_id)
    try:
        while True:
            data = await websocket.receive_text()
            try:
                msg_json = json.loads(data)
                
                if msg_json.get("type") == "TELEMETRY":
                    payload = msg_json.get("payload")
                    
                    # Guardar en Base de Datos
                    try:
                        db = database.SessionLocal()
                        soil_data = payload.get("soil_moisture", [0, 0])
                        water_data = payload.get("water_level", [0, 0])
                        gas_data = payload.get("gas", {})
                        
                        reading = models.SensorReading(
                            temperature=payload.get("temp", 0),
                            humidity=payload.get("hum", 0),
                            soil_moisture_1=soil_data[0] if len(soil_data) > 0 else 0,
                            soil_moisture_2=soil_data[1] if len(soil_data) > 1 else 0,
                            water_level_1=water_data[0] if len(water_data) > 0 else 0,
                            water_level_2=water_data[1] if len(water_data) > 1 else 0,
                            gas_mq2=gas_data.get("mq2", 0),
                            gas_mq5=gas_data.get("mq5", 0),
                            gas_mq135=gas_data.get("aqi", 0)
                        )
                        db.add(reading)
                        db.commit()
                        db.close()
                    except Exception as e:
                        print(f"⚠️ Error guardando en DB: {e}")

                    if model and scaler and payload:
                        try:
                            soil1 = payload.get("soil_moisture", [0, 0])[0]
                            soil2 = payload.get("soil_moisture", [0, 0])[1] if len(payload.get("soil_moisture", [])) > 1 else 0
                            gas_data = payload.get("gas", {})
                            
                            datos_array = np.array([[
                                payload.get("temp", 0),
                                payload.get("hum", 0),
                                soil1,
                                soil2,
                                gas_data.get("mq2", 0),
                                gas_data.get("mq5", 0),
                                gas_data.get("mq8", 0),
                                gas_data.get("aqi", 0)
                            ]])
                            
                            datos_scaled = scaler.transform(datos_array)
                            pred_proba = model.predict(datos_scaled, verbose=0)[0]
                            pred_dict = {clase: float(prob) for clase, prob in zip(clases, pred_proba)}
                            clase_predicha = max(pred_dict, key=pred_dict.get)
                            
                            await manager.broadcast({
                                "type": "STATE_UPDATE",
                                "payload": {
                                    "sensors": payload,
                                    "prediction": {
                                        "class": clase_predicha,
                                        "probabilities": pred_dict
                                    }
                                }
                            })
                            
                            if clase_predicha == "INCENDIO" and pred_dict[clase_predicha] > 0.8:
                                await manager.broadcast({
                                    "type": "ALERT",
                                    "payload": {
                                        "type": "FIRE",
                                        "severity": "CRITICAL",
                                        "message": "¡Incendio detectado!",
                                        "confidence": pred_dict[clase_predicha]
                                    }
                                })
                                
                        except Exception as e:
                            print(f"Error en predicción: {e}")
                
                elif msg_json.get("type") == "COMMAND":
                    await manager.broadcast({
                        "type": "COMMAND",
                        "payload": msg_json.get("payload")
                    })
                    
            except json.JSONDecodeError:
                pass
                
    except WebSocketDisconnect:
        manager.disconnect(websocket, client_id)

# ---- AI Prediction Endpoint (Legacy/REST) ----

@app.post("/predict/")
async def predict(data: SensorData, current_user: User = Depends(get_current_user)):
    """Recibe datos de los sensores y devuelve la predicción"""
    if not model or not scaler:
        raise HTTPException(status_code=503, detail="Modelo no disponible.")

    try:
        soil1 = data.soil_moisture[0] if len(data.soil_moisture) > 0 else 0
        soil2 = data.soil_moisture[1] if len(data.soil_moisture) > 1 else 0
        
        datos_array = np.array([[
            data.temp, 
            data.hum, 
            soil1, 
            soil2, 
            data.gas.mq2, 
            data.gas.mq5, 
            data.gas.mq8, 
            data.gas.aqi
        ]])

        datos_scaled = scaler.transform(datos_array)
        pred_proba = model.predict(datos_scaled, verbose=0)[0]

        pred_dict = {clase: float(prob) for clase, prob in zip(clases, pred_proba)}
        clase_mas_probable = max(pred_dict, key=pred_dict.get)

        return {"predicciones": pred_dict, "clase_predicha": clase_mas_probable}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error predicción: {str(e)}")

@app.get("/api/history")
def get_history(
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    limit: int = 100, 
    offset: int = 0, 
    current_user: User = Depends(get_current_user)
):
    """Obtener historial de lecturas de sensores"""
    db = database.SessionLocal()
    try:
        query = db.query(models.SensorReading)
        
        if start_date:
            try:
                start_dt = datetime.fromisoformat(start_date.replace('Z', '+00:00'))
                query = query.filter(models.SensorReading.timestamp >= start_dt)
            except ValueError:
                pass # Ignorar formato inválido
                
        if end_date:
            try:
                end_dt = datetime.fromisoformat(end_date.replace('Z', '+00:00'))
                query = query.filter(models.SensorReading.timestamp <= end_dt)
            except ValueError:
                pass

        readings = query.order_by(models.SensorReading.timestamp.desc())\
            .offset(offset)\
            .limit(limit)\
            .all()
            
        return {"data": readings}
    finally:
        db.close()

@app.get("/")
def root():
    return {"message": "InvernaderoAI API v2.0 Running"}

@app.get("/system/status")
def system_status():
    return {
        "status": "online",
        "model_loaded": model is not None,
        "scaler_loaded": scaler is not None
    }