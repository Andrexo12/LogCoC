CREATE TABLE IF NOT EXISTS roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL
);

INSERT IGNORE INTO roles (nombre) VALUES ('scanner'), ('admin');

CREATE TABLE IF NOT EXISTS usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    correo VARCHAR(255) UNIQUE NOT NULL,
    hash_contrasena VARCHAR(255) NOT NULL,
    nombre VARCHAR(100),
    apellido VARCHAR(100),
    id_rol INT,
    estado VARCHAR(50) DEFAULT 'approved',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_rol) REFERENCES roles(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS categorias (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS tipos_producto (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS productos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_qr VARCHAR(100) UNIQUE NOT NULL,
    nombre VARCHAR(200) NOT NULL,
    descripcion TEXT,
    precio FLOAT NOT NULL,
    stock INT DEFAULT 0,
    id_categoria INT,
    id_tipo_producto INT,
    modelo VARCHAR(100),
    url_imagen TEXT,
    es_visible_ra TINYINT(1) DEFAULT 1,
    FOREIGN KEY (id_categoria) REFERENCES categorias(id) ON DELETE SET NULL,
    FOREIGN KEY (id_tipo_producto) REFERENCES tipos_producto(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS configuracion_ra (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre_seccion VARCHAR(100) UNIQUE NOT NULL,
    esta_habilitado TINYINT(1) DEFAULT 1
);

INSERT IGNORE INTO configuracion_ra (nombre_seccion, esta_habilitado) VALUES 
('Precio', 1),
('Descripción', 1),
('Stock', 1),
('Chatbot', 1);

CREATE TABLE IF NOT EXISTS categorias_ia (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS entrenamiento_ia (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pregunta TEXT NOT NULL,
    respuesta TEXT NOT NULL,
    id_categoria_ia INT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_categoria_ia) REFERENCES categorias_ia(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS vistas_producto (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_producto INT NOT NULL,
    fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_producto) REFERENCES productos(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS ventas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_producto INT NOT NULL,
    cantidad INT NOT NULL DEFAULT 1,
    fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_producto) REFERENCES productos(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS registros_chatbot (
    id INT AUTO_INCREMENT PRIMARY KEY,
    intencion VARCHAR(100) NOT NULL,
    texto_consulta TEXT,
    fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS contexto_chatbot (
    id INT AUTO_INCREMENT PRIMARY KEY,
    texto_contexto TEXT NOT NULL,
    creado_por INT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (creado_por) REFERENCES usuarios(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS auditoria (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT,
    accion VARCHAR(255) NOT NULL,
    objetivo VARCHAR(255) NOT NULL,
    cambios TEXT,
    fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id) ON DELETE SET NULL
);

INSERT IGNORE INTO categorias (id, nombre) VALUES 
(1, 'Xiaomi'), 
(2, 'Apple'), 
(3, 'Samsung');

INSERT IGNORE INTO tipos_producto (id, nombre) VALUES 
(1, 'Electrodomésticos');

INSERT IGNORE INTO productos (id_qr, nombre, descripcion, precio, stock, id_categoria, id_tipo_producto, es_visible_ra) VALUES 
('prod-001', 'Xiaomi Redmi Note 13', 'Xiaomi Redmi Note 13 8GB RAM 256GB ROM', 199.99, 15, 1, 1, 1),
('prod-002', 'Apple iPhone 15 Pro', 'Apple iPhone 15 Pro Max 256GB Titanio', 999.50, 8, 2, 1, 1),
('prod-003', 'Samsung Galaxy S24 Ultra', 'Samsung Galaxy S24 Ultra 12GB RAM 512GB', 1299.99, 5, 3, 1, 1);
