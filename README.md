# LogCoC – Sistema de Gestión y Autenticación

## 🎯 Visión General del Proyecto
LogCoC es una aplicación **full‑stack** que combina un **backend** en **FastAPI** con una **interfaz** en **Flutter** (Web y móvil). El objetivo es ofrecer un sistema de gestión de productos con autenticación segura (JWT), roles de usuario y un chatbot integrado para consultas de garantías y stock.

---

## 📂 Estructura de Carpetas y Archivos Clave
| Ruta | Tipo | Descripción |
|---|---|---|
| `backend/` | Directorio | Código del servidor FastAPI. Contiene modelos, rutas, servicios, migraciones Alembic y pruebas. |
| `backend/main.py` | Archivo | Punto de entrada del API (`uvicorn main:app`). |
| `backend/models/` | Directorio | Definiciones ORM con **SQLAlchemy** y esquemas **Pydantic** (`user.py`, `product.py`, `admin.py`). |
| `backend/routes/` | Directorio | Endpoints API agrupados por funcionalidad (`auth.py`, `products.py`, `chatbot.py`, `import_products.py`, `admin.py`). |
| `backend/services/` | Directorio | Lógica de negocio separada de las rutas (autenticación, procesamiento de Excel, IA, etc.). |
| `backend/alembic/` | Directorio | Scripts de migración de base de datos. |
| `backend/database/` | Directorio | Configuración y gestión de la conexión a **MariaDB**. |
| `frontend/` | Directorio | Aplicación Flutter (Web/Móvil). |
| `frontend/lib/` | Directorio | Código Dart principal. Sub‑carpetas `core/` (API service, utils) y `ui/` (pantallas, widgets). |
| `frontend/pubspec.yaml` | Archivo | Declaración de dependencias Dart/Flutter, assets y fuentes. |
| `frontend/web/` | Directorio | Entrada para la versión web (`index.html`, `main.dart.js`). |
| `assets/` | Directorio | Recursos estáticos y documentación (logos, `docs/` con guías). |
| `assets/docs/PROJECT_STRUCTURE.md` | Archivo | Guía completa de la estructura del proyecto (actualizada automáticamente). |
| `requirements.txt` | Archivo | Lista de dependencias Python del backend. |
| `README.md` | Archivo | **Este documento** – referencia única para instalación y uso. |
| `GEMINI.md` | Archivo | Guía interna de Gemini (estado del proyecto, comandos útiles). |
| `docker-compose.yml` | Archivo | Configuración Docker para levantar la base de datos MariaDB.

---

## 🛠 Roles y Permisos
| Rol | Descripción | Permisos Principales |
|---|---|---|
| **admin** | Administrador del sistema. | Acceso a rutas `/api/admin/*`, gestión de usuarios y productos, exportación de datos. |
| **scanner** | Usuario con acceso limitado a visualización y escaneo de productos. | Lectura de productos, acceso a `/api/products/*`, uso del chatbot. |
| **guest** *(no autenticado)* | Visita la UI sin funcionalidades protegidas. | Solo puede ver la página de inicio y la versión pública del catálogo. |

---

## ⚙️ Dependencias y Requisitos
### Backend (Python)
- **Python ≥ 3.10**
- **FastAPI 0.110.0**
- **Uvicorn[standard] 0.27.1**
- **SQLAlchemy 2.0.28**
- **Alembic 1.13.1**
- **mysql‑connector‑python 8.3.0** (o **mysqlclient 2.2.4**) para MariaDB
- **PyJWT 2.8.0**, **passlib 1.7.4**, **python‑dotenv 1.0.1**
- **google‑generativeai ≥0.7.2**, **groq 1.2.0** (AI chatbot)
- **openpyxl 3.1.2** (importación Excel)
- **python‑multipart 0.0.9**
- **email‑validator 2.3.0**

Todos los paquetes están listados en `requirements.txt` y pueden instalarse con:
```bash
pip install -r requirements.txt
```

### Frontend (Flutter)
- **Flutter SDK ≥ 3.13** (compatible con iOS, Android y Web)
- **Dart >= 3.2**
- Herramientas de línea de comandos: `flutter`, `dart`
- Navegador moderno (Chrome/Edge/Safari) para la versión web.

### Requisitos del Sistema
| Sistema | CPU | RAM | Espacio en disco |
|---|---|---|---|
| macOS 12+ | 2 GHz (x86_64 o arm64) | 4 GB | 2 GB (para dependencias + Docker) |
| Windows 10/11 | 2 GHz (x86_64) | 4 GB | 2 GB |
| Linux (Ubuntu 22.04+) | 2 GHz | 4 GB | 2 GB |

---

## 🚀 Paso a Paso para Descargar, Configurar y Probar el Proyecto
### 1. Clonar el repositorio
```bash
# macOS / Linux / Windows (Git Bash)
git clone https://github.com/Andrexo12/LogCoC.git
cd LogCoC
```
### 2. Levantar la base de datos con Docker (opcional pero recomendado)
```bash
docker compose up -d   # levanta MariaDB en el puerto 3306
```
> **Nota:** Si ya tienes una instancia de MariaDB, crea una base de datos y configura las variables en `.env`.
### 3. Configurar el Backend
1. Copia el archivo de ejemplo y rellena tus variables:
   ```bash
   cp .env.example .env
   # edita .env con tu editor favorito
   ```
2. Instala las dependencias Python:
   ```bash
   python -m venv venv   # opcional, entorno virtual
   source venv/bin/activate   # macOS/Linux
   .\\venv\\Scripts\\activate   # Windows PowerShell
   pip install -r requirements.txt
   ```
3. Ejecuta las migraciones Alembic para crear/actualizar el esquema:
   ```bash
   alembic upgrade head
   ```
4. Inicia el servidor FastAPI:
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```
   El API quedará disponible en `http://localhost:8000`.
### 4. Configurar el Frontend (Flutter)
1. Instala Flutter siguiendo la guía oficial: https://flutter.dev/docs/get-started/install
2. Navega al directorio del frontend y descarga dependencias:
   ```bash
   cd frontend
   flutter pub get
   ```
3. **Ejecutar en modo desarrollo (Web)**
   ```bash
   flutter run -d web-server --web-port 5000 --web-hostname 0.0.0.0 --web-renderer html
   ```
   Abre `http://localhost:5000` en tu navegador.
4. **Compilar para producción**
   ```bash
   flutter build web --release
   # opcional: servir la carpeta construida
   python -m http.server 5000 --directory build/web
   ```
5. **Ejecutar en dispositivos móviles** (iOS/Android) – conecta tu dispositivo o usa un emulador y ejecuta:
   ```bash
   flutter run
   ```
### 5. Verificar la Instalación
- **Backend**: abre `http://localhost:8000/docs` para ver la documentación Swagger UI.
- **Frontend**: abre `http://localhost:5000` y verifica que puedas iniciar sesión, navegar el catálogo y usar el chatbot.
- **Roles**: crea usuarios de prueba con el script `setup_test_users.py` o mediante la ruta `/auth/register`.

---

## 🧩 Funcionalidades Principales del Proyecto
| Módulo | Funcionalidad | Endpoint(s) relevantes |
|---|---|---|
| **Autenticación** | Registro, login, generación y verificación de JWT. | `/auth/register`, `/auth/login`, `/auth/me` |
| **Gestión de Productos** | CRUD de productos, búsqueda, filtros, importación masiva desde Excel. | `/api/products/`, `/api/products/import` |
| **Chatbot** | Respuestas automáticas sobre garantías, stock y precios (IA). | `/api/chatbot/ask` |
| **Admin** | Operaciones de administración (usuarios, métricas). | `/api/admin/*` |
| **Importación** | Procesamiento de archivos Excel/Facturas y población de la BD. | `/api/products/import` |
| **Roles** | Control de acceso basado en JWT y rol (`admin`, `scanner`). | Middleware `Depends(get_current_user)` en rutas protegidas |

---

## 📦 Gestión de Dependencias
- **Python**: todas las dependencias están en `requirements.txt`. Usa `pip freeze > requirements.txt` para actualizar.
- **Flutter**: dependencias declaradas en `pubspec.yaml`. Ejecuta `flutter pub upgrade` para actualizar.

---

## 📚 Documentación Automática
- La carpeta `assets/docs/` contiene documentos generados por los agents de Antigravity que describen en detalle la estructura del proyecto y cada módulo. Puedes consultarlos para una visión más profunda.

---

## 🛡 Buenas Prácticas
- Nunca comitees el archivo `.env` con credenciales reales.
- Usa entornos virtuales para Python y control de versiones de paquetes.
- Ejecuta pruebas unitarias (`pytest`) antes de desplegar cambios.
- Mantén actualizado `requirements.txt` y `pubspec.lock`.

---

## 📞 Soporte y Contribución
- **Issues**: abre un issue en GitHub para reportar bugs o solicitar funcionalidades.
- **Pull Requests**: sigue el flujo `git checkout -b feature/xyz`, desarrolla, y abre un PR.
- **Comunicación**: revisa `GEMINI.md` para información interna del proyecto y contactos.

---

*Esta guía se mantiene automáticamente por los *agents* de Antigravity; cualquier cambio estructural debe reflejarse aquí para mantener la documentación sincronizada.*
