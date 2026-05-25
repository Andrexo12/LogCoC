import os
import io
import time
import requests
import openpyxl

BASE_URL = "http://127.0.0.1:8000"

def test_api():
    print("====================================================")
    print("🚀 INICIANDO PRUEBAS DE INTEGRACIÓN DE LOGCOC API")
    print("====================================================\n")

    # 1. Health check
    print("🩺 1. Probando Health Check...")
    try:
        res = requests.get(f"{BASE_URL}/health")
        print(f"   Status: {res.status_code}, Resp: {res.json()}")
        assert res.status_code == 200
        assert res.json()["status"] == "healthy"
    except Exception as e:
        print(f"❌ Falló conexión al Backend en {BASE_URL}. Asegúrate de que uvicorn esté corriendo. Error: {e}")
        return

    # Generar credenciales únicas
    unique_email = f"test_{int(time.time())}@logw.com"
    password = "password123"

    # 2. Registrar usuario admin
    print("\n📝 2. Probando Registro de Admin...")
    reg_data = {
        "email": unique_email,
        "password": password,
        "role": "admin"
    }
    res = requests.post(f"{BASE_URL}/auth/register", json=reg_data)
    print(f"   Status: {res.status_code}, Resp: {res.json()}")
    assert res.status_code == 200

    # 3. Login
    print("\n🔑 3. Probando Login...")
    login_data = {
        "email": unique_email,
        "password": password
    }
    res = requests.post(f"{BASE_URL}/auth/login", json=login_data)
    print(f"   Status: {res.status_code}")
    assert res.status_code == 200
    token = res.json()["access_token"]
    print(f"   Token obtenido: {token[:20]}...")
    headers = {"Authorization": f"Bearer {token}"}

    # 4. Crear producto
    print("\n📦 4. Creando nuevo producto...")
    new_product = {
        "qr_id": f"qr-{int(time.time())}",
        "name": "Xiaomi Redmi Note 13",
        "description": "Xiaomi Redmi Note 13 8GB RAM 256GB ROM",
        "price": 199.99,
        "stock": 15,
        "category": "Xiaomi",
        "product_type": "Electrodomésticos",
        "is_ar_visible": 1
    }
    res = requests.post(f"{BASE_URL}/api/products/", json=new_product, headers=headers)
    print(f"   Status: {res.status_code}, Resp: {res.json()}")
    assert res.status_code == 200
    prod_id = res.json()["id"]
    qr_id = res.json()["qr_id"]
    
    # Validar redondeo calculado en el backend
    # Original: 199.99 -> Redondeado superior al 0.50: 200.00
    assert res.json()["rounded_price"] == 200.0

    # 5. Obtener producto por QR (Público)
    print("\n🔍 5. Obteniendo producto por QR...")
    res = requests.get(f"{BASE_URL}/api/products/{qr_id}")
    print(f"   Status: {res.status_code}, Resp: {res.json()}")
    assert res.status_code == 200
    assert res.json()["name"] == "Xiaomi Redmi Note 13"
    assert res.json()["rounded_price"] == 200.0

    # 6. Actualizar producto
    print("\n✏️ 6. Modificando precio y stock...")
    update_data = {
        "name": "Xiaomi Redmi Note 13 Pro",
        "price": 249.20,  # Redondeo esperado: 249.50
        "stock": 8
    }
    res = requests.put(f"{BASE_URL}/api/products/{prod_id}", json=update_data, headers=headers)
    print(f"   Status: {res.status_code}, Resp: {res.json()}")
    assert res.status_code == 200
    assert res.json()["rounded_price"] == 249.50

    # 7. Listar todos los productos
    print("\n📋 7. Obteniendo listado total con filtros...")
    res = requests.get(f"{BASE_URL}/api/products/?search=Xiaomi")
    print(f"   Status: {res.status_code}, total encontrados: {len(res.json())}")
    assert res.status_code == 200
    assert len(res.json()) > 0

    # 8. Cargar entrenamiento de contexto activo
    print("\n🧠 8. Agregando contexto promocional a la IA...")
    promo_context = {
        "question": "Xiaomi Promo Especial",
        "answer": "Descuento del 10% adicional si pagan en efectivo.",
        "category": "general_context"
    }
    res = requests.post(f"{BASE_URL}/api/admin/ai-training", json=promo_context, headers=headers)
    print(f"   Status: {res.status_code}, Resp: {res.json()}")
    assert res.status_code == 200

    # 9. Consultar chatbot (Asesor IA)
    print("\n🤖 9. Consultando Chatbot con contexto de producto escaneado...")
    chat_payload = {
        "message": "Hola, ¿cuánto cuesta el Xiaomi y qué promociones tienen?",
        "qr_id": qr_id
    }
    res = requests.post(f"{BASE_URL}/api/chatbot/ask", json=chat_payload)
    print(f"   Status: {res.status_code}, Resp: {res.json().get('reply', 'Sin respuesta')[:100]}...")
    assert res.status_code == 200

    # 10. Probar importador masivo (Excel)
    print("\n📊 10. Probando Importador Masivo (.xlsx) en-memoria...")
    # Crear planilla excel en memoria
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "Productos"
    ws.append(["Nombre", "Especificaciones", "Precio", "Cantidad"])
    ws.append(["Samsung Galaxy S24", "Samsung S24 128GB", "799.10", "5"])
    ws.append(["Apple iPhone 15", "iPhone 15 256GB", "899.99", "12"])

    excel_file = io.BytesIO()
    wb.save(excel_file)
    excel_file.seek(0)

    files = {
        "file": ("inventario.xlsx", excel_file, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
    }
    res = requests.post(f"{BASE_URL}/api/products/import", files=files, headers=headers)
    print(f"   Status: {res.status_code}, Resp: {res.json()}")
    assert res.status_code == 200
    assert res.json()["imported_count"] == 2

    print("\n====================================================")
    print("✨ ¡TODAS LAS PRUEBAS DE LA API FINALIZARON CON ÉXITO!")
    print("====================================================")

if __name__ == "__main__":
    test_api()
