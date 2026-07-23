# 📂 Detalle del Backend de LogCoC

Este documento describe **todos los archivos y carpetas** dentro del directorio `backend/`. Cada elemento incluye una breve explicación de su propósito.

---

## 📁 Raíz del backend

| Archivo / Carpeta | Tipo | Descripción |
|---|---|---|
| `.env` | Texto | Variables de entorno (credenciales, claves JWT, configuración de DB). **No se debe commitear**. |
| `.env.example` | Texto | Plantilla de `.env` con ejemplos de variables requeridas. |
| `.gitignore` | Texto | Archivos y carpetas que Git debe ignorar dentro del backend. |
| `Dockerfile` | Dockerfile | Imagen Docker para construir el servicio FastAPI. |
| `alembic/` | Directorio | Scripts de migración de base de datos (usando Alembic). Contiene sub‑carpeta `versions/` con cada revisión. |
| `alembic.ini` | Config | Configuración de Alembic (ruta a DB, script location). |
| `app/` | Directorio | Código fuente principal del proyecto (útil cuando se usa `app.main`). |
| `backend.log` / `backend_log.txt` | Texto | Log de ejecución del servidor. |
| `database/` | Directorio | Configuración y utilidad de conexión a MariaDB. |
| `database_docs/` | Directorio | Documentación interna de la capa de datos y script inicial SQL. |
| `main.py` | Python | **Punto de entrada** del API (`uvicorn main:app`). |
| `models/` | Directorio | Definiciones ORM con SQLAlchemy y esquemas Pydantic (usuarios, productos, etc.). |
| `routes/` | Directorio | Módulos de rutas API (`auth.py`, `products.py`, `chatbot.py`, …). Cada archivo expone endpoints FastAPI. |
| `services/` | Directorio | Lógica de negocio separada de las rutas (autenticación, procesamiento de Excel, IA, etc.). |
| `static/` | Directorio | Archivos estáticos servidos por FastAPI. |

---

## 📂 Sub‑directorios importantes

- **`alembic/versions/`** – Cada archivo de versión contiene instrucciones SQL para migrar el esquema.
- **`models/`** – Agrupa los modelos ORM (`user.py`, `product.py`, etc.) y los esquemas de validación.
- **`routes/`** – Agrupa los *routers* FastAPI (`auth.py`, `products.py`, `chatbot.py`). Cada router se incluye en `main.py`.
- **`services/`** – Implementa la lógica de negocio real (por ejemplo, `auth_service.py`, `product_service.py`).
- **`tests/`** – Conjunto de pruebas automáticas que se ejecutan con `pytest`.

---

## 🛠 Uso rápido

1. **Instalar dependencias**: `pip install -r requirements.txt`
2. **Configurar variables de entorno** usando `.env.example` como guía.
3. **Aplicar migraciones**: `alembic upgrade head`
4. **Ejecutar**: `uvicorn main:app --reload --host 0.0.0.0 --port 8000`

---

*Mantén este documento actualizado cuando añadas, elimines o renombres archivos en el backend.*
