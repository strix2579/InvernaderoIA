import asyncio
import websockets

async def test_connection():
    uri = "ws://192.168.100.2:8080/ws/connect?client_id=test_script"
    print(f"Intentando conectar a {uri} ...")
    try:
        async with websockets.connect(uri) as websocket:
            print("✅ ¡ÉXITO! La conexión WebSocket funciona correctamente por la IP.")
            await websocket.close()
    except Exception as e:
        print(f"❌ ERROR: No se pudo conectar. Causa: {e}")
        print("--> Si ves este error, el Firewall de Windows está bloqueando la conexión.")

if __name__ == "__main__":
    asyncio.run(test_connection())
