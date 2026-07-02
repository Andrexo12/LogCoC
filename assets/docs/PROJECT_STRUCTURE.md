# 📁 Proyecto LogCoC – Guía de Estructura Actualizada

Esta guía describe **cada carpeta y archivo** presente en la raíz del proyecto `LogCoC`. Sirve como referencia rápida para entender la arquitectura, responsabilidades y contenido de cada elemento.

---

## 📂 Directorios principales

| Carpeta | Descripción |
|---|---|
| `.agents` | Configuración local de *agents* personalizados de Antigravity. Contiene habilidades y reglas específicas del proyecto. |
| `.antigravitycli` | Metadatos y configuraciones del CLI de Antigravity para este workspace. |
| `.git` | Repositorio Git del proyecto. |
| `assets` | Recursos estáticos usados por la aplicación (imágenes, fuentes, iconos, etc.). |
| `backend` | **Backend** en Python (FastAPI). Contiene la lógica del servidor, rutas API, modelos y migraciones. |
| `frontend` | **Frontend** en Flutter (Web/Móvil). Código UI, servicios de red y recursos UI. |
| `frontend-sdk` *(si existe)* | SDK o componentes reutilizables para el frontend. |

---

## 📄 Archivos en la raíz del proyecto

| Archivo | Tipo | Descripción |
|---|---|---|
| `.gitignore` | Texto | Patrones que Git debe ignorar (p.ej., `__pycache__/`, `env/`, `*.env`). |
| `GEMINI.md` | Markdown | Guía interna de Gemini con estado del proyecto, comandos útiles y notas de arquitectura. |
| `Makefile` | Makefile | Automatiza tareas comunes (`run-backend`, `run-frontend`, `docker-up`, etc.). |
| `README.md` | Markdown | Visión general del proyecto, arquitectura, pasos de configuración y endpoints principales. |
| `docker-compose.yml` | YAML | Configuración de Docker para levantar la base de datos MariaDB y otros servicios. |
| `requirements.txt` | Texto | Lista de dependencias Python del backend. |
| `skills-lock.json` | JSON | Bloqueo de versiones de habilidades personalizadas de Antigravity. |
| `implementation_plan.md` | Markdown | Plan de implementación, hitos y tareas pendientes. |
| `run_app.ps1` | PowerShell | Script para iniciar simultáneamente backend y frontend en Windows. |
| `setup_test_users.py` | Python | Script para crear usuarios de prueba en la base de datos. |

---

## 🛠 Backend (`/backend`)

El backend está construido con **FastAPI** y utiliza **MariaDB** como base de datos. Principales componentes:

- `main.py`: Punto de entrada de la aplicación.
- `models/`: Definiciones ORM con SQLAlchemy y esquemas Pydantic.
- `routes/`: Endpoints API organizados por funcionalidades (`auth`, `products`, `chatbot`, `admin`, `import_products`).
- `services/`: Lógica de negocio separada de las rutas.
- `alembic/`: Migraciones de base de datos.
- `database/`: Configuración de conexión y sesión a la base de datos.
- `utils/`: Utilidades auxiliares.
- `tests/`: Tests unitarios e integración (pytest).

---

## 🎨 Frontend (`/frontend`)

Aplicación Flutter que funciona tanto en web como en móvil. Componentes clave:

- `lib/core/`: Servicios de red, modelos de datos y utilidades compartidas.
- `lib/ui/`: Widgets y pantallas (login, home, etc.).
- `lib/models/`: Clases Dart que representan datos.
- `pubspec.yaml`: Declaración de dependencias, assets y fuentes.
- `web/`: Entrada para la versión web (HTML, JS, CSS).
- `assets/`: Recursos estáticos (imágenes, íconos, fuentes) consumidos por la UI.
- `test/`: Tests de widgets y lógica.

---

## 📦 Assets (`/assets`)

Carpeta destinada a recursos estáticos que pueden ser utilizados tanto por el frontend como por documentación:

- `logos/`: Logotipos del proyecto.
- `docs/`: Documentación generada automáticamente (estructura del proyecto, detalle del backend y frontend).
- `README.md`: Archivo descriptivo de la carpeta assets (actualmente vacío, se puede rellenar con resumen de recursos).

---

## 📚 Cómo usar esta guía

1. **Navegación rápida** – Utiliza la tabla de contenidos para localizar cualquier carpeta o archivo.
2. **Actualizaciones** – Cuando añadas, elimines o renombres archivos, actualiza la sección correspondiente.
3. **Colaboración** – Comparte este documento con nuevos miembros del equipo como referencia única de la estructura.

---

*Esta guía es mantenida automáticamente por los *agents* de Antigravity. Cada vez que se modifican archivos, el agente puede actualizar este documento para reflejar la última estructura.*
