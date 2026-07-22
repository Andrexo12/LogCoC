# Modelo Relacional de Datos (LogCoC) - Español

A continuación se muestra una representación visual (Diagrama de Entidad-Relación) del modelo de datos de tu aplicación, traducido conceptualmente al español para facilitar su lectura.

```mermaid
erDiagram
    usuarios {
        int id PK
        string correo UK
        string contrasena_hash
        string rol
        datetime fecha_creacion
    }

    productos {
        int id PK
        string id_qr UK
        string nombre
        text descripcion
        float precio
        int inventario
        string categoria
        string tipo_producto
        string modelo
        text url_imagen
        int visible_en_ra
    }

    vistas_producto {
        int id PK
        int id_producto FK
        datetime fecha_hora
    }

    ventas {
        int id PK
        int id_producto FK
        int cantidad
        datetime fecha_hora
    }

    registros_chatbot {
        int id PK
        string intencion
        text texto_consulta
        datetime fecha_hora
    }

    configuracion_ra {
        int id PK
        string nombre_seccion UK
        int esta_habilitado
    }

    entrenamiento_ia {
        int id PK
        text pregunta
        text respuesta
        string categoria
        datetime fecha_creacion
    }

    productos ||--o{ vistas_producto : "es visto en"
    productos ||--o{ ventas : "tiene"
```

## Ubicación en el Código (Nombres Originales)
Recuerda que en el código de tu proyecto, estas tablas y campos están en inglés. Si deseas inspeccionar o modificar este modelo, puedes encontrarlo en las siguientes ubicaciones de tu proyecto:

- **Esquema SQL Inicial:** backend/database_docs/database.sql
- **Modelos de SQLAlchemy (Python):** Se encuentran en el directorio `backend/models/`:
  - user.py (Tabla `users`)
  - product.py (Tabla `products`)
  - statistics.py (Tablas `product_views`, `sales`, `chatbot_logs`)
  - admin.py (Tablas `ar_settings`, `ai_training`)
