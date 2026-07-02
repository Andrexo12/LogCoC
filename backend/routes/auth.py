from datetime import timedelta
from fastapi import APIRouter, HTTPException, Header, Depends, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from models.user import User, UserCreate, UserLogin
from services.auth_service import AuthService
from database.db import get_db

router = APIRouter(tags=["Authentication"])

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    payload = AuthService.decode_token(token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido o expirado"
        )
    email = payload.get("sub")
    user = db.query(User).filter(User.email == email).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado"
        )
    return user

def require_role(required_role: str):
    def dependency(current_user: User = Depends(get_current_user)):
        if current_user.role != required_role:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Permisos insuficientes"
            )
        return current_user
    return dependency

@router.post("/register")
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    hashed_pwd = AuthService.hash_password(user_data.password)
    new_user = User(
        email=user_data.email,
        password_hash=hashed_pwd,
        role=user_data.role
    )
    db.add(new_user)
    try:
        db.commit()
        db.refresh(new_user)
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=400, detail="El email ya existe")
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    
    return {"message": "Usuario registrado exitosamente en logW", "id": new_user.id}


@router.post("/login")
def login(credentials: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == credentials.email).first()
    
    if not user or not AuthService.verify_password(credentials.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Credenciales inválidas")
    
    token_data = {"sub": user.email, "role": user.role}
    token = AuthService.create_access_token(data=token_data)
    
    return {
        "access_token": token, 
        "token_type": "bearer",
        "user": {
            "email": user.email,
            "role": user.role
        }
    }


@router.post("/forgot-password")
def forgot_password(email: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == email).first()

    if not user:
        return {"message": "Si el email existe, se ha enviado un enlace de recuperación."}

    reset_token = AuthService.create_access_token(
        data={"sub": user.email, "action": "password_reset"},
        expires_delta=timedelta(minutes=15),
    )
    reset_link = f"https://logw-app.com/reset-password?token={reset_token}"
    return {"message": "Enlace generado", "debug_link": reset_link}

@router.get("/me")
def get_me(current_user: User = Depends(get_current_user)):
    return {
        "email": current_user.email,
        "role": current_user.role,
        "rol": current_user.role,
        "status": "verificado"
    }