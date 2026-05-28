CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'scanner',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

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

CREATE TABLE IF NOT EXISTS ar_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    section_name VARCHAR(100) UNIQUE NOT NULL,
    is_enabled TINYINT(1) DEFAULT 1
);

INSERT IGNORE INTO ar_settings (section_name, is_enabled) VALUES 
('Precio', 1),
('Descripción', 1),
('Stock', 1),
('Chatbot', 1);

CREATE TABLE IF NOT EXISTS ai_training (
    id INT AUTO_INCREMENT PRIMARY KEY,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    category VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT IGNORE INTO products (qr_id, name, description, price, stock, category, product_type, is_ar_visible) VALUES 
('prod-001', 'Xiaomi Redmi Note 13', 'Xiaomi Redmi Note 13 8GB RAM 256GB ROM', 199.99, 15, 'Xiaomi', 'Electrodomésticos', 1),
('prod-002', 'Apple iPhone 15 Pro', 'Apple iPhone 15 Pro Max 256GB Titanio', 999.50, 8, 'Apple', 'Electrodomésticos', 1),
('prod-003', 'Samsung Galaxy S24 Ultra', 'Samsung Galaxy S24 Ultra 12GB RAM 512GB', 1299.99, 5, 'Samsung', 'Electrodomésticos', 1);