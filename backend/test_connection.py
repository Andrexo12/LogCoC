import requests
import json

BASE_URL = "http://127.0.0.1:8000"

def test_flow():
    print("--- Probando Conexión con logW API ---")
    
    # 1. Probar Health Check
    try:
        health = requests.get(f"{BASE_URL}/health")
        print(f"Health Check: {health.status_code} - {health.json()}")
    except Exception as e:
        print(f"Error: No se pudo conectar al servidor. ¿Está uvicorn corriendo? {e}")
        return

    # 2. Intentar registro
    user_data = {
        "email": "test@example.com",
        "password": "password123"
    }
    print(f"\nIntentando registrar usuario: {user_data['email']}...")
    res_reg = requests.post(f"{BASE_URL}/auth/register", json=user_data)
    print(f"Registro: {res_reg.status_code} - {res_reg.json()}")

    # 3. Intentar Login
    print(f"\nIntentando login con {user_data['email']}...")
    res_login = requests.post(f"{BASE_URL}/auth/login", json=user_data)
    if res_login.status_code == 200:
        token = res_login.json().get("access_token")
        print(f"Login Exitoso! Token recibido: {token[:20]}...")
    else:
        print(f"Login Fallido: {res_login.status_code} - {res_login.json()}")

if __name__ == "__main__":
    test_flow()
