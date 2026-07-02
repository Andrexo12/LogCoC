# 📂 Detalle del Frontend de LogCoC

Este documento enumera **todos los archivos y carpetas** dentro del directorio `frontend/`. Cada elemento incluye una breve explicación de su propósito y cómo encaja en la arquitectura Flutter.

---

## 📁 Raíz del frontend

| Archivo / Carpeta | Tipo | Descripción |
|---|---|---|
| `.dart_tool/` | Directorio | Herramientas y caché usadas por Dart/Flutter (no se versiona). |
| `.flutter-plugins` | Texto | Lista de plugins de Flutter instalados. |
| `.flutter-plugins-dependencies` | Texto | Dependencias de los plugins listados. |
| `.gitignore` | Texto | Patrones que Git debe ignorar (build/, .dart_tool/, .packages, etc.). |
| `.idea/` | Directorio | Configuración del IDE (Android Studio/IntelliJ). |
| `.metadata` | Texto | Metadatos del proyecto Flutter (versión SDK, etc.). |
| `README.md` | Markdown | Descripción breve del frontend y pasos de ejecución. |
| `analysis_options.yaml` | YAML | Reglas de análisis estático (lint) para Dart. |
| `android/` | Directorio | Código nativo Android (Gradle, manifest, etc.). |
| `ios/` | Directorio | Código nativo iOS (Xcode project, pods, etc.). |
| `lib/` | Directorio | **Código fuente principal** de la aplicación Flutter (Dart). |
| `pubspec.yaml` | YAML | Declaración de dependencias Dart/Flutter, assets, fonts. |
| `pubspec.lock` | Lockfile | Versiones exactas de paquetes instalados. |
| `build/` | Directorio | Salida de compilación (generada por `flutter build`). |
| `frontend.iml` | XML | Configuración del módulo IntelliJ. |
| `frontend_log.txt` | Texto | Log de ejecución del `flutter run`.
| `spa_server.py` | Python | Servidor sencillo para servir la aplicación web en modo *Single Page Application* durante desarrollo.
| `test/` | Directorio | Tests unitarios y de widget para la aplicación Flutter. |
| `web/` | Directorio | Código y assets para la versión web (index.html, icons, etc.). |

---

## 📂 Sub‑directorios importantes dentro `lib/`

| Sub‑carpeta | Propósito |
|---|---|
| `lib/core/` | Servicios de red, modelos de datos, utilidades compartidas (p.ej., `api_service.dart`). |
| `lib/ui/` | Widgets y pantallas de la UI (p.ej., `login_page.dart`, `home_screen.dart`). |
| `lib/models/` | Definiciones de clases Dart que representan datos (User, Product, etc.). |
| `lib/widgets/` | Componentes reutilizables (botones, tarjetas, dialogs). |
| `lib/helpers/` | Funciones auxiliares y extensiones (validaciones, formateo). |

---

## 📂 Recursos estáticos

- **`frontend/assets/`** (si existe) – Imágenes, íconos y fuentes usadas por la UI.
- **`frontend/web/`** – Archivos HTML/CSS/JS que sirven como punto de entrada para la versión web. Incluye `index.html`, `favicon.png`, `manifest.json`.

---

## 🛠 Uso rápido

1. **Instalar dependencias**: `flutter pub get`
2. **Ejecutar en web**: `flutter run -d web-server --web-port 5000 --web-hostname 0.0.0.0 --web-renderer html`
3. **Construir para producción**: `flutter build web --release`
4. **Ejecutar pruebas**: `flutter test`

---

*Actualiza este documento cuando añadas nuevos paquetes, widgets o cambies la estructura del proyecto.*
