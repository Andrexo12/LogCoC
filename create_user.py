import sys
import os

# Añadir el path del backend para poder importar AuthService
sys.path.append(os.path.join(os.getcwd(), 'backend'))

from services.auth_service import AuthService
from database.db_legacy import Database

def create_test_user():
    email = "test@test.com"
    password = "123456"
    hashed_pwd = AuthService.hash_password(password)
    
    db = Database()
    conn = db.connect()
    if not conn:
        print("Error: No se pudo conectar a la base de datos")
        return
    
    cursor = conn.cursor()
    try:
        # Verificar si ya existe
        cursor.execute("SELECT id FROM users WHERE email = %s", (email,))
        if cursor.fetchone():
            print(f"El usuario {email} ya existe. Actualizando contraseña...")
            cursor.execute("UPDATE users SET password_hash = %s WHERE email = %s", (hashed_pwd, email))
        else:
            print(f"Creando usuario {email}...")
            cursor.execute("INSERT INTO users (email, password_hash) VALUES (%s, %s)", (email, hashed_pwd))
        
        conn.commit()
        print("¡Usuario listo para usar!")
    except Exception as e:
        print(f"Error: {e}")
        conn.rollback()
    finally:
        cursor.close()
        db.close()

if __name__ == "__main__":
    create_test_user()
