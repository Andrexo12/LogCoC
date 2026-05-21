# LogCoC - Guía del Proyecto para Gemini

Este archivo sirve como memoria técnica para que cualquier instancia de Gemini (o desarrollador) entienda rápidamente el estado y la arquitectura del proyecto.

## 🚀 Estado Actual
El proyecto es un sistema de gestión y autenticación con un Backend en **FastAPI** y un Frontend en **Flutter (Web/Mobile)**.

### Configuración de Infraestructura
- **Base de Datos**: Se utiliza MariaDB corriendo en Docker.
  - El archivo `docker-compose.yml` está configurado para levantar la DB y mapear el puerto 3306.
  - La tabla `users` incluye las columnas `email`, `password_hash` y `role`.
- **Backend**: FastAPI accesible en el puerto 8000.
  - Conexión configurada vía `.env` (usar `localhost` para ejecución local fuera de docker).
- **Frontend**: Flutter configurado para correr como Web Server en el puerto 5000.
  - Se recomienda usar el renderizador `--web-renderer html` para máxima compatibilidad con Safari/iOS.

## 🛠 Comandos Útiles

### Backend (Python)
```bash
cd backend
uvicorn main:app --host 0.0.0.0 --port 8000
```

### Frontend (Flutter Web)
```bash
cd frontend
# Para desarrollo
flutter run -d web-server --web-port 5000 --web-hostname 0.0.0.0 --web-renderer html
# Para producción/release (más rápido en móviles)
flutter build web --web-renderer html --release
python3 -m http.server 5000 --directory build/web
```

### Base de Datos (Docker)
```bash
docker compose up -d
```

## 📌 Notas de Arquitectura
- **Autenticación**: JWT. Los roles soportados son `admin` y `scanner`.
- **CORS**: Configurado en `backend/main.py` para permitir todas las conexiones en desarrollo.
- **API Service**: El archivo `frontend/lib/core/api_service.dart` contiene la `baseUrl` que debe apuntar a la URL pública del Codespace (puerto 8000).

## ⚠️ Recordatorios de Seguridad
- No commitear archivos `.env` ni `docker-compose.yml` si contienen credenciales reales.
- El archivo `.gitignore` ya excluye los datos de la DB local y logs.

---
*Mantenido por Gemini CLI en Codespaces.*
