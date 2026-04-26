# LogCoC - Sistema de Gestión y Autenticación

Este proyecto es una aplicación full-stack que combina un backend robusto en Python con una interfaz móvil moderna en Flutter. El sistema está diseñado bajo una arquitectura desacoplada, enfocada en la seguridad y la escalabilidad.

## 🏗 Arquitectura del Proyecto

El repositorio se divide en dos componentes principales:

### 1. Backend (`/backend`)
Construido con **FastAPI**, enfocado en alto rendimiento y validación de datos estricta.
*   **Framework:** FastAPI 0.110.0.
*   **Base de Datos:** MariaDB / MySQL.
*   **Seguridad:** Autenticación JWT (JSON Web Tokens) y hashing de contraseñas con PBKDF2.
*   **Estructura:**
    *   `app/main.py`: Punto de entrada de la API.
    *   `app/routes/`: Definición de endpoints (Auth, User, etc.).
    *   `app/services/`: Lógica de negocio y procesamiento de datos.
    *   `app/models/`: Esquemas de datos con Pydantic.
    *   `app/database/`: Gestión de conexiones y transacciones.

### 2. Frontend (`/frontend`)
Aplicación móvil desarrollada en **Flutter** con un diseño enfocado en la experiencia de usuario (UX).
*   **Framework:** Flutter SDK (>=3.11.4).
*   **UI Style:** Glassmorphism moderno con soporte para Material 3.
*   **Gestión de Red:** HTTP Client con servicios desacoplados.
*   **Persistencia:** Almacenamiento local de tokens mediante `shared_preferences`.

---

## 🚀 Configuración y Despliegue

### Requisitos Previos
*   Python 3.10+
*   Flutter SDK
*   MariaDB o MySQL Server

### Paso 1: Configuración del Backend
1. Navega a la carpeta: `cd backend`.
2. Instala las dependencias: `pip install -r requirements.txt`.
3. Configura las variables de entorno:
   *   Crea un archivo `.env` basado en `.env.example`.
   *   Define `JWT_SECRET`, `DB_HOST`, `DB_USER`, `DB_PASSWORD` y `DB_NAME`.
4. Inicializa la base de datos:
   *   Ejecuta el script ubicado en `database_docs/database.sql`.
5. Inicia el servidor: `uvicorn app.main:app --reload`.

### Paso 2: Configuración del Frontend
1. Navega a la carpeta: `cd frontend`.
2. Obtén las dependencias: `flutter pub get`.
3. Configura la URL del API:
   *   Edita `lib/services/auth_service.dart` y ajusta `baseUrl` según tu entorno (IP local o localhost).
4. Ejecuta la aplicación: `flutter run`.

---

## 🛠 Endpoints Principales (API)

| Método | Ruta | Descripción |
| :--- | :--- | :--- |
| `POST` | `/auth/register` | Registro de nuevos usuarios. |
| `POST` | `/auth/login` | Autenticación y obtención de Token JWT. |
| `GET` | `/auth/me` | Recupera información del perfil del usuario actual. |
| `GET` | `/health` | Verificación de estado del servidor. |

---

## 📝 Notas del Desarrollador
*   **Seguridad:** Nunca subas el archivo `.env` al repositorio. Se ha incluido un `.gitignore` para evitar fugas de credenciales.
*   **Escalabilidad:** La estructura de carpetas `app/` en el backend permite añadir nuevos módulos (ventas, inventario, etc.) simplemente creando nuevas rutas y servicios.
*   **Frontend:** Los widgets reutilizables deben ubicarse en `lib/widgets` para mantener las pantallas (`screens`) limpias.

---
*Desarrollado con estándares de código limpio y arquitectura modular.*
