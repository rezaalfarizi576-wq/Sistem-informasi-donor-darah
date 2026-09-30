-- Database Setup Script for Donor Darah Lamongan
CREATE DATABASE IF NOT EXISTS donor_darah_lamongan
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE donor_darah_lamongan;

-- Table: users
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nik VARCHAR(20) UNIQUE NULL,
    nama VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NULL,
    role ENUM('admin', 'donor', 'requester') NOT NULL DEFAULT 'donor',
    no_hp VARCHAR(20),
    blood_type ENUM('A', 'B', 'AB', 'O'),
    rhesus ENUM('+', '-') DEFAULT '+',
    address TEXT,
    sumber_data VARCHAR(50) NOT NULL DEFAULT 'mandiri',
    is_activated BOOLEAN DEFAULT TRUE,
    status_aktif BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Table: donor_locations
CREATE TABLE IF NOT EXISTS donor_locations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    address TEXT NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    contact_number VARCHAR(20),
    operating_hours VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Table: blood_requests
CREATE TABLE IF NOT EXISTS blood_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    requester_id INT NOT NULL,
    patient_name VARCHAR(150) NOT NULL,
    hospital_name VARCHAR(150) NOT NULL,
    blood_type ENUM('A', 'B', 'AB', 'O') NOT NULL,
    rhesus ENUM('+', '-') DEFAULT '+',
    bags_needed INT NOT NULL DEFAULT 1,
    bags_collected INT NOT NULL DEFAULT 0,
    urgency_level ENUM('normal', 'urgent', 'critical') DEFAULT 'normal',
    status ENUM('pending', 'in_progress', 'completed', 'cancelled') DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (requester_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Table: donation_responses
CREATE TABLE IF NOT EXISTS donation_responses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    request_id INT NOT NULL,
    donor_id INT NOT NULL,
    status ENUM('accepted', 'heading_to_location', 'arrived', 'donated', 'cancelled') DEFAULT 'accepted',
    donor_latitude DECIMAL(10, 8),
    donor_longitude DECIMAL(11, 8),
    last_location_update TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (request_id) REFERENCES blood_requests(id) ON DELETE CASCADE,
    FOREIGN KEY (donor_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Insert Default Admin (Password: admin123, hash generated using bcrypt)
INSERT INTO users (nik, nama, email, password_hash, role, no_hp, status_aktif, sumber_data, is_activated)
VALUES (
    '3524000000000001',
    'Administrator PMI Lamongan',
    'admin@pmi-lamongan.id',
    '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW',
    'admin',
    '081234567890',
    TRUE,
    'mandiri',
    TRUE
) ON DUPLICATE KEY UPDATE nama=VALUES(nama);

-- Insert Sample Donor Location (PMI Lamongan)
INSERT INTO donor_locations (name, address, latitude, longitude, contact_number, operating_hours)
VALUES (
    'UDD PMI Kabupaten Lamongan',
    'Jl. Kombespol M. Duryat No. 42, Jetis, Kec. Lamongan, Kab. Lamongan, Jawa Timur',
    -7.119853,
    112.415278,
    '(0322) 321118',
    '24 Jam'
) ON DUPLICATE KEY UPDATE name=VALUES(name);
