-- Initial schema for EmpowerPlant irrigation system
-- Migration: 20250725_001_initial_irrigation_schema

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    email VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_users_email (email)
);

-- Plants table
CREATE TABLE IF NOT EXISTS plants (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id CHAR(36) NOT NULL,
    name VARCHAR(255) NOT NULL,
    plant_type VARCHAR(100) NOT NULL,
    location VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_plants_user_id (user_id),
    INDEX idx_plants_type (plant_type)
);

-- Sensors table
CREATE TABLE IF NOT EXISTS sensors (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    name VARCHAR(255) NOT NULL,
    sensor_type ENUM('temperature', 'humidity', 'soil_moisture', 'ph', 'light', 'water_level', 'flow_rate', 'voltage', 'pressure') NOT NULL,
    location VARCHAR(255) NOT NULL,
    status ENUM('active', 'inactive', 'error', 'warning') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_sensors_type (sensor_type),
    INDEX idx_sensors_status (status)
);

-- Sensor readings table
CREATE TABLE IF NOT EXISTS sensor_readings (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    sensor_id CHAR(36) NOT NULL,
    value DECIMAL(10,3) NOT NULL,
    unit VARCHAR(10) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (sensor_id) REFERENCES sensors(id) ON DELETE CASCADE,
    INDEX idx_readings_sensor_timestamp (sensor_id, timestamp),
    INDEX idx_readings_timestamp (timestamp)
);

-- Irrigation system status table
CREATE TABLE IF NOT EXISTS irrigation_status (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    pump_active BOOLEAN DEFAULT FALSE,
    pump_pwm_level TINYINT UNSIGNED DEFAULT 0,
    solenoid_active BOOLEAN DEFAULT FALSE,
    water_level_ok BOOLEAN DEFAULT TRUE,
    flow_rate DECIMAL(6,2) DEFAULT 0.00,
    voltage DECIMAL(4,1) DEFAULT 0.0,
    system_uptime BIGINT UNSIGNED DEFAULT 0,
    last_command VARCHAR(50),
    error_message TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_irrigation_timestamp (timestamp)
);

-- Irrigation commands log
CREATE TABLE IF NOT EXISTS irrigation_commands (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id CHAR(36),
    command VARCHAR(50) NOT NULL,
    parameters JSON,
    result VARCHAR(255),
    success BOOLEAN DEFAULT FALSE,
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_commands_user_executed (user_id, executed_at),
    INDEX idx_commands_executed (executed_at)
);

-- Irrigation diagnostics table
CREATE TABLE IF NOT EXISTS irrigation_diagnostics (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    pump_current DECIMAL(4,1),
    pump_temperature DECIMAL(5,2),
    pump_runtime_hours DECIMAL(8,2),
    pump_cycles BIGINT UNSIGNED,
    solenoid_resistance DECIMAL(5,1),
    solenoid_activations BIGINT UNSIGNED,
    solenoid_response_time INT UNSIGNED,
    supply_voltage DECIMAL(4,1),
    current_draw DECIMAL(4,1),
    power_consumption DECIMAL(6,2),
    efficiency DECIMAL(5,2),
    thermal_status VARCHAR(20),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_diagnostics_timestamp (timestamp)
);

-- System alerts table
CREATE TABLE IF NOT EXISTS system_alerts (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    alert_type ENUM('error', 'warning', 'info') NOT NULL,
    component VARCHAR(50) NOT NULL,
    message TEXT NOT NULL,
    severity ENUM('low', 'medium', 'high', 'critical') DEFAULT 'medium',
    resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_alerts_type_created (alert_type, created_at),
    INDEX idx_alerts_severity (severity),
    INDEX idx_alerts_resolved (resolved)
);

-- Cameras table
CREATE TABLE IF NOT EXISTS cameras (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    name VARCHAR(255) NOT NULL,
    location VARCHAR(255) NOT NULL,
    status ENUM('active', 'inactive', 'error') DEFAULT 'inactive',
    stream_url VARCHAR(512),
    network_ssid VARCHAR(128),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_cameras_status (status)
);

-- User sessions for JWT token management
CREATE TABLE IF NOT EXISTS user_sessions (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id CHAR(36) NOT NULL,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_sessions_user (user_id),
    INDEX idx_sessions_expires (expires_at),
    INDEX idx_sessions_token_hash (token_hash)
);

-- Insert default admin user (password: admin123)
INSERT IGNORE INTO users (id, email, name, password_hash) VALUES 
('admin-user-id', 'admin@empowerplant.com', 'Admin User', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewDDDgwrPrkJcLGi');

-- Insert default sensors
INSERT IGNORE INTO sensors (id, name, sensor_type, location) VALUES 
('water-level-sensor', 'Water Level Sensor', 'water_level', 'Water Barrel'),
('flow-rate-sensor', 'Flow Rate Sensor', 'flow_rate', 'Main Line'),
('voltage-sensor', 'Voltage Monitor', 'voltage', 'Power Supply'),
('soil-moisture-a', 'Soil Moisture Zone A', 'soil_moisture', 'Zone A'),
('pressure-sensor', 'Water Pressure Sensor', 'pressure', 'Main Line');
