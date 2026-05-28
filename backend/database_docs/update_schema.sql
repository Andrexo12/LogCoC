-- Actualización de esquema para LogCoC

-- Agregar rol a usuarios
ALTER TABLE users ADD COLUMN role VARCHAR(50) DEFAULT 'scanner';

-- Actualizar tabla de productos (si no existe, crearla, si existe agregar campos)
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    qr_id VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    price FLOAT NOT NULL,
    stock INT DEFAULT 0,
    category VARCHAR(100),
    product_type VARCHAR(100),
    image_url TEXT,
    is_ar_visible TINYINT(1) DEFAULT 1
);

-- Si la tabla ya existe, agregar los campos faltantes:
-- ALTER TABLE products ADD COLUMN product_type VARCHAR(100);
-- ALTER TABLE products ADD COLUMN image_url TEXT;
-- ALTER TABLE products ADD COLUMN is_ar_visible TINYINT(1) DEFAULT 1;

-- Tabla para configuración de visibilidad AR (Checkboxes del Admin)
CREATE TABLE IF NOT EXISTS ar_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    section_name VARCHAR(100) UNIQUE NOT NULL,
    is_enabled TINYINT(1) DEFAULT 1
);

-- Insertar secciones por defecto
INSERT IGNORE INTO ar_settings (section_name, is_enabled) VALUES 
('Precio', 1),
('Descripción', 1),
('Stock', 1),
('Chatbot', 1);

-- Tabla para entrenamiento de IA (Mejoras de respuestas)
CREATE TABLE IF NOT EXISTS ai_training (
    id INT AUTO_INCREMENT PRIMARY KEY,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    category VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
