-- EmpowerPlant Database Schema
-- This script initializes the database with all necessary tables

SET sql_mode = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION';

-- Create database if it doesn't exist
CREATE DATABASE IF NOT EXISTS empowerplant CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE empowerplant;

-- Users table
CREATE TABLE users (
    id CHAR(36) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    roles JSON NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_is_active (is_active)
);

-- Sensors table
CREATE TABLE sensors (
    id CHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    sensor_type ENUM('soil_moisture', 'temperature', 'humidity', 'light', 'ph', 'conductivity', 'water_flow', 'pressure') NOT NULL,
    location VARCHAR(255) NOT NULL,
    status ENUM('active', 'inactive', 'error', 'maintenance') DEFAULT 'active',
    battery_level DECIMAL(5,2) NULL,
    last_reading_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_sensor_type (sensor_type),
    INDEX idx_status (status),
    INDEX idx_location (location)
);

-- Sensor readings table (partitioned by date for performance)
CREATE TABLE sensor_readings (
    id CHAR(36) PRIMARY KEY,
    sensor_id CHAR(36) NOT NULL,
    value DECIMAL(10,4) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    quality_score DECIMAL(3,2) NULL,
    metadata JSON NULL,
    FOREIGN KEY (sensor_id) REFERENCES sensors(id) ON DELETE CASCADE,
    INDEX idx_sensor_timestamp (sensor_id, timestamp),
    INDEX idx_timestamp (timestamp)
) PARTITION BY RANGE (UNIX_TIMESTAMP(timestamp)) (
    PARTITION p_2024 VALUES LESS THAN (UNIX_TIMESTAMP('2025-01-01')),
    PARTITION p_2025 VALUES LESS THAN (UNIX_TIMESTAMP('2026-01-01')),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- Plants table
CREATE TABLE plants (
    id CHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    variety VARCHAR(255) NOT NULL,
    planting_date DATE NOT NULL,
    location VARCHAR(255) NOT NULL,
    growth_stage ENUM('seed', 'germination', 'seedling', 'vegetative', 'flowering', 'fruiting', 'mature', 'harvest') DEFAULT 'seed',
    health_status ENUM('excellent', 'good', 'fair', 'poor', 'critical') DEFAULT 'good',
    image_url TEXT NULL,
    notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_growth_stage (growth_stage),
    INDEX idx_health_status (health_status),
    INDEX idx_location (location),
    INDEX idx_planting_date (planting_date)
);

-- Weather data table
CREATE TABLE weather_data (
    id CHAR(36) PRIMARY KEY,
    location VARCHAR(255) NOT NULL,
    temperature DECIMAL(5,2) NOT NULL,
    humidity DECIMAL(5,2) NOT NULL,
    rainfall DECIMAL(8,2) DEFAULT 0,
    wind_speed DECIMAL(5,2) DEFAULT 0,
    wind_direction DECIMAL(5,2) DEFAULT 0,
    solar_radiation DECIMAL(8,2) NULL,
    uv_index DECIMAL(4,2) NULL,
    timestamp TIMESTAMP NOT NULL,
    source VARCHAR(100) DEFAULT 'external_api',
    INDEX idx_location_timestamp (location, timestamp),
    INDEX idx_timestamp (timestamp)
);

-- Irrigation zones table
CREATE TABLE irrigation_zones (
    id CHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    area DECIMAL(10,2) NOT NULL COMMENT 'Area in square meters',
    crop_type VARCHAR(100) NOT NULL,
    soil_type VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    last_irrigation TIMESTAMP NULL,
    next_scheduled TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_is_active (is_active),
    INDEX idx_next_scheduled (next_scheduled)
);

-- Irrigation events table
CREATE TABLE irrigation_events (
    id CHAR(36) PRIMARY KEY,
    zone_id CHAR(36) NOT NULL,
    duration_minutes INT NOT NULL,
    water_amount_liters DECIMAL(10,2) NOT NULL,
    trigger_type ENUM('manual', 'scheduled', 'sensor_based', 'weather_based') NOT NULL,
    started_at TIMESTAMP NOT NULL,
    completed_at TIMESTAMP NULL,
    is_successful BOOLEAN DEFAULT TRUE,
    failure_reason TEXT NULL,
    FOREIGN KEY (zone_id) REFERENCES irrigation_zones(id) ON DELETE CASCADE,
    INDEX idx_zone_started (zone_id, started_at),
    INDEX idx_started_at (started_at),
    INDEX idx_trigger_type (trigger_type)
);

-- Alerts table
CREATE TABLE alerts (
    id CHAR(36) PRIMARY KEY,
    alert_type ENUM('sensor_failure', 'low_moisture', 'extreme_temperature', 'system_error', 'maintenance_required', 'weather_alert') NOT NULL,
    severity ENUM('low', 'medium', 'high', 'critical') NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    source VARCHAR(100) NOT NULL,
    affected_resources JSON NULL,
    acknowledged BOOLEAN DEFAULT FALSE,
    acknowledged_by CHAR(36) NULL,
    acknowledged_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (acknowledged_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_alert_type (alert_type),
    INDEX idx_severity (severity),
    INDEX idx_acknowledged (acknowledged),
    INDEX idx_created_at (created_at)
);

-- System logs table
CREATE TABLE system_logs (
    id CHAR(36) PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL,
    level ENUM('DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL') NOT NULL,
    message TEXT NOT NULL,
    context JSON NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_service_level (service_name, level),
    INDEX idx_timestamp (timestamp),
    INDEX idx_level (level)
) PARTITION BY RANGE (UNIX_TIMESTAMP(timestamp)) (
    PARTITION p_logs_2024 VALUES LESS THAN (UNIX_TIMESTAMP('2025-01-01')),
    PARTITION p_logs_2025 VALUES LESS THAN (UNIX_TIMESTAMP('2026-01-01')),
    PARTITION p_logs_future VALUES LESS THAN MAXVALUE
);

-- Equipment table
CREATE TABLE equipment (
    id CHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(100) NOT NULL,
    model VARCHAR(100) NULL,
    manufacturer VARCHAR(100) NULL,
    purchase_date DATE NULL,
    warranty_expiration DATE NULL,
    status ENUM('operational', 'maintenance', 'broken', 'retired') DEFAULT 'operational',
    location VARCHAR(255) NOT NULL,
    notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_type (type),
    INDEX idx_status (status),
    INDEX idx_warranty_expiration (warranty_expiration)
);

-- Maintenance logs table
CREATE TABLE maintenance_logs (
    id CHAR(36) PRIMARY KEY,
    equipment_id CHAR(36) NOT NULL,
    maintenance_type ENUM('scheduled', 'repair', 'replacement', 'calibration') NOT NULL,
    description TEXT NOT NULL,
    performed_by CHAR(36) NULL,
    performed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cost DECIMAL(10,2) NULL,
    next_maintenance_due DATE NULL,
    FOREIGN KEY (equipment_id) REFERENCES equipment(id) ON DELETE CASCADE,
    FOREIGN KEY (performed_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_equipment_performed (equipment_id, performed_at),
    INDEX idx_maintenance_type (maintenance_type),
    INDEX idx_next_maintenance_due (next_maintenance_due)
);

-- User sessions table (for tracking active sessions)
CREATE TABLE user_sessions (
    id CHAR(36) PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    token_hash VARCHAR(255) NOT NULL,
    ip_address VARCHAR(45) NULL,
    user_agent TEXT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_token_hash (token_hash),
    INDEX idx_expires_at (expires_at)
);

-- Create initial admin user
INSERT INTO users (
    id, 
    email, 
    password_hash, 
    first_name, 
    last_name, 
    roles,
    is_active
) VALUES (
    'admin-user-uuid-here-000000000000',
    'admin@empowerplant.com',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdiVGBGJxHE/2.6', -- password: admin123
    'System',
    'Administrator',
    '["admin", "farmer"]',
    TRUE
);

-- Create sample irrigation zones
INSERT INTO irrigation_zones (
    id,
    name,
    area,
    crop_type,
    soil_type,
    is_active
) VALUES 
    (UUID(), 'Zone A - Vegetables', 100.5, 'Mixed Vegetables', 'Loamy', TRUE),
    (UUID(), 'Zone B - Herbs', 50.0, 'Herbs', 'Sandy Loam', TRUE),
    (UUID(), 'Zone C - Fruits', 200.0, 'Berry Bushes', 'Clay Loam', TRUE);

-- Create sample sensors
INSERT INTO sensors (
    id,
    name,
    sensor_type,
    location,
    status
) VALUES 
    (UUID(), 'Soil Moisture Sensor 1', 'soil_moisture', 'Zone A', 'active'),
    (UUID(), 'Temperature Sensor 1', 'temperature', 'Zone A', 'active'),
    (UUID(), 'pH Sensor 1', 'ph', 'Zone A', 'active'),
    (UUID(), 'Soil Moisture Sensor 2', 'soil_moisture', 'Zone B', 'active'),
    (UUID(), 'Light Sensor 1', 'light', 'Zone B', 'active'),
    (UUID(), 'Water Flow Sensor 1', 'water_flow', 'Main Line', 'active');

-- Create sample plants
INSERT INTO plants (
    id,
    name,
    variety,
    planting_date,
    location,
    growth_stage,
    health_status
) VALUES 
    (UUID(), 'Tomato Plant 1', 'Cherry Tomato', '2024-01-15', 'Zone A', 'vegetative', 'good'),
    (UUID(), 'Basil Plant 1', 'Sweet Basil', '2024-02-01', 'Zone B', 'mature', 'excellent'),
    (UUID(), 'Strawberry Plant 1', 'June Bearer', '2023-09-15', 'Zone C', 'fruiting', 'good'),
    (UUID(), 'Lettuce 1', 'Buttercrunch', '2024-02-15', 'Zone A', 'seedling', 'fair');

-- Create indexes for better performance
CREATE INDEX idx_sensor_readings_sensor_timestamp ON sensor_readings(sensor_id, timestamp DESC);
CREATE INDEX idx_irrigation_events_zone_started ON irrigation_events(zone_id, started_at DESC);
CREATE INDEX idx_alerts_unacknowledged ON alerts(acknowledged, created_at DESC) WHERE acknowledged = FALSE;
