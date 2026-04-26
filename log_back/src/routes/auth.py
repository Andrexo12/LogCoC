from datetime import timedelta
from contextlib import contextmanager

from fastapi import APIRouter, HTTPException, Header
from mysql.connector import Error as MySQLError

from src.models.user import UserCreate, UserLogin
from src.services.auth_service import AuthService
from src.database.db import Database

router = APIRouter(prefix="/auth", tags=["Authentication"])


@contextmanager
def get_db():
    db = Database()
    conn = db.connect()
    if not conn:
        raise HTTPException(status_code=500, detail="Error de conexión a la base de datos")
    cursor = conn.cursor(dictionary=True)
    try:
        yield conn, cursor
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        cursor.close()
        db.close()


@router.post("/register")
def register(user_data: UserCreate):
    hashed_pwd = AuthService.hash_password(user_data.password)
    with get_db() as (conn, cursor):
        try:
            cursor.execute(
                "INSERT INTO users (email, password_hash) VALUES (%s, %s)",
                (user_data.email, hashed_pwd),
            )
        except MySQLError as err:
            if getattr(err, "errno", None) == 1062:
                raise HTTPException(status_code=400, detail="El email ya existe")
            raise HTTPException(status_code=500, detail=str(err))
    return {"message": "Usuario registrado exitosamente en logW"}


@router.post("/login")
def login(credentials: UserLogin):
    with get_db() as (_, cursor):
        cursor.execute(
            "SELECT email, password_hash FROM users WHERE email = %s",
            (credentials.email,),
        )
        user = cursor.fetchone()
    if not user or not AuthService.verify_password(credentials.password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="Credenciales inválidas")
    token = AuthService.create_access_token(data={"sub": user["email"]})
    return {"access_token": token, "token_type": "bearer"}


@router.post("/forgot-password")
def forgot_password(email: str):
    with get_db() as (_, cursor):
        cursor.execute("SELECT email FROM users WHERE email = %s", (email,))
        user = cursor.fetchone()

    if not user:
        return {"message": "Si el email existe, se ha enviado un enlace de recuperación."}

    reset_token = AuthService.create_access_token(
        data={"sub": user["email"], "action": "password_reset"},
        expires_delta=timedelta(minutes=15),
    )
    reset_link = f"https://logw-app.com/reset-password?token={reset_token}"
    return {"message": "Enlace generado", "debug_link": reset_link}

@router.get("/me")
def get_current_user(token: str = Header(None)):
    # Aquí es donde validaremos el JWT que recibimos del iPhone
    if not token:
        raise HTTPException(status_code=401, detail="No estas autorizado, falta el token")
    
    # Lógica para decodificar el token y devolver los datos del usuario
    # (Esto lo podemos programar en un "Dependency Injection" luego)
    return {"email": "usuario@logw.com", "rol": "admin", "status": "verificado"}