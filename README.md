# LogCoC - Sistema de Gestión y Autenticación

Este proyecto es una aplicación full-stack que combina un backend robusto en Python con una interfaz móvil moderna en Flutter. El sistema está diseñado bajo una arquitectura desacoplada, enfocada en la seguridad y la escalabilidad.

## 🏗 Arquitectura del Proyecto

El repositorio se divide en dos componentes principales:

### 1. Backend (`/backend`)
Construido con **FastAPI**, enfocado en alto rendimiento y validación de datos estricta.
*   **Framework:** FastAPI 0.110.0.
*   **Base de Datos:** MySQL / MariaDB (Compatible con Aiven Cloud DB).
*   **Migraciones:** Gestionadas con **Alembic** para el control de versiones de esquema SQL de forma automática.
*   **Seguridad:** Autenticación JWT (JSON Web Tokens) y hashing de contraseñas con PBKDF2.
*   **Estructura:**
    *   `main.py`: Punto de entrada de la API.
    *   `routes/`: Definición de endpoints (Auth, Products, Admin, Chatbot).
    *   `services/`: Lógica de negocio y procesamiento de datos (Auth, Products, Chatbot, Excel Extractor).
    *   `models/`: Modelos declarativos de SQLAlchemy y esquemas de datos Pydantic.
    *   `database/`: Gestión de conexiones y transacciones.
    *   `alembic/`: Archivos de control de migraciones.

### 2. Frontend (`/frontend`)
Aplicación web y móvil desarrollada en **Flutter** con un diseño enfocado en la experiencia de usuario (UX).
*   **Framework:** Flutter SDK.
*   **UI Style:** Glassmorphism moderno con soporte para Material 3.
*   **Gestión de Red:** HTTP Client con servicios desacoplados en `api_service.dart`.
*   **Persistencia:** Almacenamiento local de tokens mediante `shared_preferences`.

---

## 🚀 Configuración y Despliegue

### Requisitos Previos
*   Python 3.10+
*   Flutter SDK
*   MySQL o MariaDB Server (Local o en la nube como Aiven)

### Paso 1: Configuración del Backend
1. Instala las dependencias: `pip install -r requirements.txt`.
2. Configura las variables de entorno:
   *   Crea un archivo `.env` basado en `.env.example`.
   *   Define `JWT_SECRET`, `DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_PORT`, `DB_NAME` y `GROQ_API_KEY`.
3. Ejecuta las migraciones de Alembic para crear/actualizar las tablas automáticamente:
   *   `python -m alembic upgrade head`
4. Inicia el servidor: `python -m uvicorn main:app --host 0.0.0.0 --port 8000`.

### Paso 2: Configuración del Frontend
1. Navega a la carpeta: `cd frontend`.
2. Obtén las dependencias: `flutter pub get`.
3. Compila/ejecuta la aplicación web:
   *   **Para pruebas locales en PC (Desarrollo):**
       `flutter run -d web-server --web-port 5000 --web-hostname 0.0.0.0 --web-renderer html --no-dds`
   *   **Para producción / pruebas en iPhone (Release):**
       `flutter build web --release`
       Luego sirve la carpeta con: `python -m http.server 5000 --directory build/web`.
4. Abre `http://localhost:5000` (en tu PC) o `http://<IP_DE_TU_PC>:5000` (en tu iPhone).

---

## 🛠 Endpoints Principales (API)

| Método | Ruta | Descripción |
| :--- | :--- | :--- |
| `POST` | `/auth/register` | Registro de nuevos usuarios. |
| `POST` | `/auth/login` | Autenticación y obtención de Token JWT. |
| `GET` | `/auth/me` | Recupera información del perfil del usuario actual (rol/email). |
| `GET` | `/api/products/` | Catálogo de productos (soporta filtros y búsqueda). |
| `POST` | `/api/chatbot/ask` | Consultas al Asistente IA (Garantías, stock y precios con redondeo). |
| `POST` | `/api/products/import` | Importación masiva de productos desde archivos Excel/Facturas. |

---

## 📝 Notas del Desarrollador
*   **Seguridad:** Nunca subas el archivo `.env` al repositorio. Se ha incluido un `.gitignore` para evitar fugas de credenciales.
*   **Despliegue en la Nube:** Si deseas subir el proyecto a producción para usar la cámara y el chatbot de manera pública en móviles, consulta la guía de despliegue en [guia_despliegue_nube.txt](file:///C:/Users/Usuario/Desktop/LogCoC/guia_despliegue_nube.txt).

---
*Desarrollado con estándares de código limpio y arquitectura modular por Andrexo12.*
