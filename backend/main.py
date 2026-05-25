import logging
import os
from fastapi import FastAPI, Request, HTTPException, Header
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from mysql.connector import Error as MySQLError
from routes.auth import router as auth_router
from routes.products import router as product_router
from routes.chatbot import router as chatbot_router
from routes.admin import router as admin_router
from routes.import_products import router as import_router

# Configuración de logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="logW API",
    description="API for logW application",
    version="1.0.0"
)

# ... (omitted handlers)

# Middleware CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # En producción, especificar dominios reales
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Incluir rutas
app.include_router(auth_router, prefix="/auth", tags=["Authentication"])
app.include_router(import_router, prefix="/api", tags=["Products Import"])
app.include_router(product_router, prefix="/api", tags=["Products"])
app.include_router(chatbot_router, prefix="/api", tags=["Chatbot"])
app.include_router(admin_router, prefix="/api", tags=["Admin"])

@app.get("/", tags=["General"])
async def home():
    logger.info("Home endpoint accessed")
    return {"status": "logW API is running", "version": "1.0.0"}

@app.get("/health", tags=["General"])
async def health_check():
    logger.info("Health check performed")
    return {"status": "healthy"}

@app.get("/dashboard")
def dashboard(authorization: str = Header(None)):
    if not authorization:
        raise HTTPException(status_code=401, detail="No tienes permiso, falta el token")
    return {
        "mensaje": "¡Bienvenido al panel de Innova Center!",
        "ventas_hoy": 150.50,
        "usuario_activo": "admin@logw.com"
    }
