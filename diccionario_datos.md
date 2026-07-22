# Diccionario de Datos (LogCoC)

Este documento detalla la estructura, tipos de datos y propósito de cada tabla y campo en la base de datos del proyecto LogCoC.

---

### Tabla: `users` (Usuarios)
**Propósito:** Gestión de cuentas de usuario, autenticación y permisos de acceso.
- **`id`** *(INT)*: Identificador único del usuario. (Primary Key, Auto-incremental)
- **`email`** *(VARCHAR 255)*: Correo electrónico usado para iniciar sesión. (Unique, Not Null)
- **`password_hash`** *(VARCHAR 255)*: Contraseña encriptada por seguridad. (Not Null)
- **`role`** *(VARCHAR 50)*: Rol o nivel de permiso del usuario. Valores comunes: `admin`, `scanner`. (Default: 'scanner')
- **`created_at`** *(TIMESTAMP)*: Fecha y hora exacta de registro. (Default: CURRENT_TIMESTAMP)

---

### Tabla: `products` (Productos)
**Propósito:** Almacena el catálogo de productos disponibles y sus metadatos para la Realidad Aumentada.
- **`id`** *(INT)*: Identificador único del producto. (Primary Key, Auto-incremental)
- **`qr_id`** *(VARCHAR 100)*: Código identificador impreso o asociado al código QR físico. (Unique, Not Null)
- **`name`** *(VARCHAR 200)*: Nombre comercial del producto. (Not Null)
- **`description`** *(TEXT)*: Descripción detallada o especificaciones. (Opcional)
- **`price`** *(FLOAT)*: Precio unitario. (Not Null)
- **`stock`** *(INT)*: Cantidad física en bodega/tienda. (Default: 0)
- **`category`** *(VARCHAR 100)*: Categoría general del producto (ej. 'Apple', 'Samsung'). (Opcional)
- **`product_type`** *(VARCHAR 100)*: Sub-categoría o tipo de línea (ej. 'Línea Blanca', 'Electrodomésticos'). (Opcional)
- **`model`** *(VARCHAR 100)*: Modelo exacto del fabricante. (Opcional)
- **`image_url`** *(TEXT)*: URL hacia la foto oficial del producto. (Opcional)
- **`is_ar_visible`** *(TINYINT)*: Define si el producto se renderiza en la vista de Realidad Aumentada `1` = Sí, `0` = No. (Default: 1)

---

### Tabla: `product_views` (Estadísticas: Vistas)
**Propósito:** Sistema de analíticas para saber qué productos son más escaneados.
- **`id`** *(INT)*: Identificador del registro. (Primary Key, Auto-incremental)
- **`product_id`** *(INT)*: ID del producto que fue visualizado. (Foreign Key hacia `products.id`, ON DELETE CASCADE)
- **`timestamp`** *(DATETIME)*: Fecha y hora en que ocurrió el escaneo. (Default: CURRENT_TIMESTAMP)

---

### Tabla: `sales` (Estadísticas: Ventas)
**Propósito:** Sistema de registro rápido de transacciones.
- **`id`** *(INT)*: Identificador de la transacción. (Primary Key, Auto-incremental)
- **`product_id`** *(INT)*: ID del producto vendido. (Foreign Key hacia `products.id`, ON DELETE CASCADE)
- **`quantity`** *(INT)*: Número de unidades de la venta. (Default: 1, Not Null)
- **`timestamp`** *(DATETIME)*: Fecha y hora de la venta. (Default: CURRENT_TIMESTAMP)

---

### Tabla: `chatbot_logs` (Registros de IA)
**Propósito:** Guardar el historial de interacción del usuario con el agente de Inteligencia Artificial para medir su precisión.
- **`id`** *(INT)*: Identificador del log. (Primary Key, Auto-incremental)
- **`intent`** *(VARCHAR 100)*: Intención detectada o categoría de la pregunta (ej. 'precio', 'garantia'). (Not Null)
- **`query_text`** *(TEXT)*: Lo que el usuario escribió o dijo textualmente al chatbot. (Opcional)
- **`timestamp`** *(DATETIME)*: Fecha y hora de la consulta. (Default: CURRENT_TIMESTAMP)

---

### Tabla: `ar_settings` (Configuraciones Móviles)
**Propósito:** Permite apagar o encender "capas" de información en la interfaz de la cámara de la App móvil desde el panel de administrador.
- **`id`** *(INT)*: Identificador de configuración. (Primary Key, Auto-incremental)
- **`section_name`** *(VARCHAR 100)*: Nombre de la interfaz. Valores actuales: 'Precio', 'Descripción', 'Stock', 'Chatbot'. (Unique, Not Null)
- **`is_enabled`** *(TINYINT)*: `1` = Se muestra en la pantalla, `0` = Se oculta. (Default: 1)

---

### Tabla: `ai_training` (Base de Conocimiento)
**Propósito:** Preguntas y respuestas guardadas por los administradores para darle contexto al chatbot sobre temas específicos del negocio.
- **`id`** *(INT)*: Identificador de la regla. (Primary Key, Auto-incremental)
- **`question`** *(TEXT)*: Pregunta frecuente o palabra clave esperada. (Not Null)
- **`answer`** *(TEXT)*: Respuesta exacta que debe dar la IA a esa pregunta. (Not Null)
- **`category`** *(VARCHAR 100)*: Temática de la regla. (Opcional)
- **`created_at`** *(TIMESTAMP)*: Fecha en que se configuró esta regla. (Default: CURRENT_TIMESTAMP)
