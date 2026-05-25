import sys
import os

# Añadir el path del backend para poder importar AuthService
sys.path.append(os.path.join(os.getcwd(), 'backend'))

from services.auth_service import AuthService
from database.db import SessionLocal
from models.user import User

def setup_users():
    users_to_create = [
        {"email": "test@frontend.com", "password": "123456", "role": "admin"},
        {"email": "user@test.com", "password": "user_password", "role": "scanner"}
    ]
    
    db = SessionLocal()
    try:
        for u_data in users_to_create:
            email = u_data["email"]
            password = u_data["password"]
            role = u_data["role"]
            hashed_pwd = AuthService.hash_password(password)
            
            user = db.query(User).filter(User.email == email).first()
            if user:
                print(f"Actualizando usuario {email}...")
                user.password_hash = hashed_pwd
                user.role = role
            else:
                print(f"Creando usuario {email}...")
                user = User(email=email, password_hash=hashed_pwd, role=role)
                db.add(user)
        
        db.commit()
        print("¡Usuarios configurados correctamente!")
    except Exception as e:
        db.rollback()
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    setup_users()
