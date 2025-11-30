from fastapi import WebSocket
from typing import List, Dict
import json

class ConnectionManager:
    def __init__(self):
        # List of active connections
        self.active_connections: List[WebSocket] = []
        # Map client_id to WebSocket for direct messaging
        self.client_map: Dict[str, WebSocket] = {}

    async def connect(self, websocket: WebSocket, client_id: str = None):
        await websocket.accept()
        self.active_connections.append(websocket)
        if client_id:
            self.client_map[client_id] = websocket
            print(f"Client {client_id} connected.")

    def disconnect(self, websocket: WebSocket, client_id: str = None):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
        if client_id and client_id in self.client_map:
            del self.client_map[client_id]
        print(f"Client {client_id} disconnected.")

    async def send_personal_message(self, message: dict, websocket: WebSocket):
        await websocket.send_json(message)

    async def send_to_client(self, message: dict, client_id: str):
        if client_id in self.client_map:
            await self.client_map[client_id].send_json(message)

    async def broadcast(self, message: dict):
        for connection in self.active_connections:
            try:
                await connection.send_json(message)
            except Exception as e:
                print(f"Error broadcasting to client: {e}")
                # Optionally remove dead connection here

manager = ConnectionManager()
