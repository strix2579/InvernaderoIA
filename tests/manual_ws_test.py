"""
Script de prueba manual para el WebSocket IoT
Simula un cliente ESP32 conectándose a la API
"""
import asyncio
import websockets
import json
import random

SERVER_URL = "ws://localhost:8000/ws/iot/test_client_manual"

async def simulate_esp32():
    async with websockets.connect(SERVER_URL) as websocket:
        print("✅ Conectado al servidor WebSocket")
        
        # Enviar heartbeat inicial
        await websocket.send(json.dumps({"type": "heartbeat"}))
        response = await websocket.recv()
        print(f"📡 Heartbeat ACK: {response}")
        
        # Simular envío de datos de sensores
        for i in range(5):
            sensor_data = {
                "type": "sensor_update",
                "payload": {
                    "temp": 25.0 + random.uniform(-2, 2),
                    "hum": 60.0 + random.uniform(-5, 5),
                    "soil1": 70.0 + random.uniform(-3, 3),
                    "soil2": 70.0 + random.uniform(-3, 3),
                    "mq2": 100.0 + random.uniform(-10, 10),
                    "mq5": 100.0 + random.uniform(-10, 10),
                    "mq8": 100.0 + random.uniform(-10, 10),
                    "aqi": 50.0 + random.uniform(-5, 5)
                }
            }
            
            print(f"\n📤 Enviando datos de sensores #{i+1}...")
            await websocket.send(json.dumps(sensor_data))
            
            # Recibir respuesta
            response = await websocket.recv()
            data = json.loads(response)
            print(f"📥 Predicción recibida: {data['payload']['clase_predicha']}")
            
            # Verificar si hay comandos adicionales
            try:
                command = await asyncio.wait_for(websocket.recv(), timeout=1.0)
                cmd_data = json.loads(command)
                if cmd_data["type"] == "command":
                    print(f"🎛️  Comando recibido: {cmd_data['payload']}")
                    # Enviar ACK
                    await websocket.send(json.dumps({
                        "type": "ack",
                        "message_id": "command_received"
                    }))
            except asyncio.TimeoutError:
                pass
            
            await asyncio.sleep(2)
        
        print("\n✅ Prueba completada")

if __name__ == "__main__":
    print("🚀 Iniciando simulación de cliente ESP32...")
    print("⚠️  Asegúrate de que la API esté corriendo en http://localhost:8000")
    asyncio.run(simulate_esp32())
