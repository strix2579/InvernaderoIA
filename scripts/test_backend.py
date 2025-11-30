import asyncio
import websockets
import requests
import json

API_URL = "http://127.0.0.1:8000"
WS_URL = "ws://127.0.0.1:8000/ws/connect"

async def test_backend():
    print("--- Testing Auth ---")
    # 1. Login
    try:
        response = requests.post(f"{API_URL}/auth/login", data={"username": "admin", "password": "admin123"})
        if response.status_code == 200:
            token = response.json()["access_token"]
            print(f"✅ Login successful. Token: {token[:10]}...")
        else:
            print(f"❌ Login failed: {response.text}")
            return
    except Exception as e:
        print(f"❌ Could not connect to API: {e}")
        return

    print("\n--- Testing WebSocket ---")
    # 2. Connect to WebSocket
    try:
        async with websockets.connect(WS_URL) as websocket:
            print("✅ Connected to WebSocket")
            
            # 3. Send Telemetry
            telemetry = {
                "type": "TELEMETRY",
                "payload": {
                    "timestamp": "2023-10-27T10:00:00Z",
                    "temp": 25.5,
                    "hum": 60.0,
                    "soil_moisture": [45.0, 50.0],
                    "gas": {
                        "mq2": 120,
                        "mq5": 110,
                        "mq8": 130,
                        "aqi": 45
                    }
                }
            }
            await websocket.send(json.dumps(telemetry))
            print("📤 Sent telemetry")
            
            # 4. Receive Response (Broadcast)
            response = await websocket.recv()
            print(f"📥 Received: {response}")
            
    except Exception as e:
        print(f"❌ WebSocket error: {e}")

if __name__ == "__main__":
    asyncio.run(test_backend())
