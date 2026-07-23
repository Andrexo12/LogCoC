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

def require_admin(current_user: User = Depends(require_role("admin"))):
    return current_user

@router.post("/register")
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    from models.lookup import Role
    hashed_pwd = AuthService.hash_password(user_data.password)
    
    role = db.query(Role).filter_by(nombre=user_data.role).first()
    if not role:
        role = Role(nombre=user_data.role)
        db.add(role)
        db.commit()
        db.refresh(role)
        
    new_user = User(
        email=user_data.email,
        password_hash=hashed_pwd,
        first_name=user_data.first_name,
        last_name=user_data.last_name,
        role_id=role.id,
        status="pending"
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
        
    if user.status == "pending":
        raise HTTPException(status_code=403, detail="Tu cuenta está pendiente de aprobación por un administrador.")
    
    token_data = {"sub": user.email, "role": user.role}
    token = AuthService.create_access_token(data=token_data)
    
    return {
        "access_token": token, 
        "token_type": "bearer",
        "user": {
            "email": user.email,
            "role": user.role,
            "first_name": user.first_name,
            "last_name": user.last_name,
            "status": user.status
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
        "id": current_user.id,
        "email": current_user.email,
        "role": current_user.role,
        "first_name": current_user.first_name,
        "last_name": current_user.last_name,
        "rol": current_user.role,
        "status": current_user.status
    }

@router.get("/pending-users")
def get_pending_users(current_user: User = Depends(require_admin), db: Session = Depends(get_db)):
    users = db.query(User).filter(User.status == "pending").all()
    return [
        {
            "id": u.id,
            "email": u.email,
            "first_name": u.first_name,
            "last_name": u.last_name,
            "role": u.role,
            "created_at": u.created_at
        } for u in users
    ]

@router.post("/approve-user/{user_id}")
def approve_user(user_id: int, current_user: User = Depends(require_admin), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    user.status = "approved"
    db.commit()
    
    # Simulate sending email
    print(f"ENVIANDO CORREO a {user.email}: ¡Has sido aprobado como administrador en LogCoC!")
    
    return {"success": True, "message": "Usuario aprobado correctamente"}