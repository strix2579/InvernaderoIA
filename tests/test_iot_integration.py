"""
Test de integración para WebSocket IoT
Simula un cliente ESP32 conectándose a la API
"""
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

import asyncio
import json
import pytest
from fastapi.testclient import TestClient
from api.main import app

def test_websocket_connection():
    """Test básico de conexión WebSocket"""
    client = TestClient(app)
    with client.websocket_connect("/ws/iot/test_client") as websocket:
        # Enviar heartbeat
        websocket.send_json({"type": "heartbeat"})
        data = websocket.receive_json()
        assert data["type"] == "heartbeat_ack"

def test_sensor_update_and_prediction():
    """Test de envío de datos de sensores y recepción de predicción"""
    client = TestClient(app)
    with client.websocket_connect("/ws/iot/test_client") as websocket:
        # Enviar datos de sensores (condiciones normales)
        sensor_data = {
            "type": "sensor_update",
            "payload": {
                "temp": 25.5,
                "hum": 60.0,
                "soil1": 70.2,
                "soil2": 72.5,
                "mq2": 120.0,
                "mq5": 110.0,
                "mq8": 130.0,
                "aqi": 45.0
            }
        }
        websocket.send_json(sensor_data)
        
        # Recibir respuesta de predicción
        response = websocket.receive_json()
        assert response["type"] == "prediction_result"
        assert "predicciones" in response["payload"]
        assert "clase_predicha" in response["payload"]

def test_fire_detection_triggers_command():
    """Test de detección de incendio y envío de comando"""
    client = TestClient(app)
    with client.websocket_connect("/ws/iot/test_client") as websocket:
        # Enviar datos que simulan incendio (alta temperatura, gases)
        sensor_data = {
            "type": "sensor_update",
            "payload": {
                "temp": 45.0,  # Temperatura alta
                "hum": 30.0,
                "soil1": 40.0,
                "soil2": 40.0,
                "mq2": 800.0,  # Humo detectado
                "mq5": 700.0,
                "mq8": 600.0,
                "aqi": 350.0
            }
        }
        websocket.send_json(sensor_data)
        
        # Recibir predicción
        response1 = websocket.receive_json()
        assert response1["type"] == "prediction_result"
        
        # Si se detecta incendio, debería recibir comando
        if response1["payload"]["clase_predicha"] == "INCENDIO":
            response2 = websocket.receive_json()
            assert response2["type"] == "command"
            assert response2["payload"]["actuator"] == "water_pump"
            assert response2["payload"]["action"] == "ON"

def test_ack_message():
    """Test de envío de ACK"""
    client = TestClient(app)
    with client.websocket_connect("/ws/iot/test_client") as websocket:
        # Enviar ACK
        websocket.send_json({
            "type": "ack",
            "message_id": "test_message_123"
        })
        # El servidor solo registra el ACK, no envía respuesta

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
