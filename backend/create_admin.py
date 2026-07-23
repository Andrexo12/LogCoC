import os
import sys

# Ensure backend directory is in path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from database.db import SessionLocal
from models.user import User
from models.lookup import Role
from services.auth_service import AuthService

def create_admin():
    db = SessionLocal()
    try:
        # Check if user already exists
        existing_user = db.query(User).filter(User.email == "test@test.com").first()
        if existing_user:
            print("User test@test.com already exists. Updating password and role...")
            user = existing_user
        else:
            print("Creating new user test@test.com...")
            user = User(email="test@test.com")
            
        # Get admin role
        admin_role = db.query(Role).filter(Role.nombre == "admin").first()
        if not admin_role:
            print("Admin role not found. Creating it...")
            admin_role = Role(nombre="admin")
            db.add(admin_role)
            db.flush()
            
        user.role_id = admin_role.id
        user.password_hash = AuthService.hash_password("123456")
        
        if not existing_user:
            db.add(user)
            
        db.commit()
        print("Successfully created/updated test@test.com as admin.")
        
    except Exception as e:
        db.rollback()
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    create_admin()
