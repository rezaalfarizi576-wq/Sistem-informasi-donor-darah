from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from typing import Dict, List

from app.config import settings
from app.database import engine, Base
from app.routers import auth_router, admin_router

# Inisialisasi model tabel (apabila belum dibuat oleh script SQL)
# Catatan: Gunakan setup_database.sql via phpMyAdmin untuk setup awal schema.
try:
    Base.metadata.create_all(bind=engine)
except Exception as e:
    import logging
    logging.warning(f"Tabel sudah ada atau error saat create_all (abaikan jika schema sudah dibuat via SQL): {e}")

# Inisialisasi FastAPI App
app = FastAPI(
    title=settings.APP_NAME,
    description="Backend API Sistem Donor Darah Lamongan",
    version="1.0.0",
    debug=settings.DEBUG
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register Routers
app.include_router(auth_router.router)
app.include_router(admin_router.router)

# WebSocket Connection Manager for Realtime Live Tracking
class ConnectionManager:
    def __init__(self):
        # Menyimpan websocket connections per request_id
        self.active_connections: Dict[str, List[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, request_id: str):
        await websocket.accept()
        if request_id not in self.active_connections:
            self.active_connections[request_id] = []
        self.active_connections[request_id].append(websocket)

    def disconnect(self, websocket: WebSocket, request_id: str):
        if request_id in self.active_connections:
            if websocket in self.active_connections[request_id]:
                self.active_connections[request_id].remove(websocket)
            if not self.active_connections[request_id]:
                del self.active_connections[request_id]

    async def broadcast_location(self, request_id: str, message: dict):
        if request_id in self.active_connections:
            for connection in self.active_connections[request_id]:
                await connection.send_json(message)

manager = ConnectionManager()

@app.websocket("/ws/tracking/{request_id}")
async def websocket_tracking_endpoint(websocket: WebSocket, request_id: str):
    """
    WebSocket endpoint untuk real-time location tracking donor ke requester.
    """
    await manager.connect(websocket, request_id)
    try:
        while True:
            data = await websocket.receive_json()
            # Broadcast update koordinat lokasi ke semua subscriber request_id ini
            await manager.broadcast_location(request_id, data)
    except WebSocketDisconnect:
        manager.disconnect(websocket, request_id)

@app.get("/", tags=["Health"])
def health_check():
    """
    Endpoint pemeriksaan status server.
    """
    return {
        "status": "online",
        "service": settings.APP_NAME,
        "environment": settings.APP_ENV
    }
