import logging
import os
from fastapi import FastAPI, Request, HTTPException, Header
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from mysql.connector import Error as MySQLError
from src.routes.auth import router as auth_router

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="logW API",
    description="API for logW application",
    version="1.0.0"
)

# --- MANEJADORES DE ERRORES ---
@app.exception_handler(MySQLError)
async def database_exception_handler(request: Request, exc: MySQLError):
    return JSONResponse(status_code=503, content={"error": "Error de Base de Datos"})

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    return JSONResponse(status_code=400, content={"error": "Formato de datos incorrecto"})
# ------------------------------

# Middleware CORS: restringir orígenes en producción usando variables de entorno
allowed_origins = os.getenv("ALLOWED_ORIGINS", "*").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Incluir rutas de autenticación
app.include_router(auth_router, prefix="/auth", tags=["Authentication"])

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
