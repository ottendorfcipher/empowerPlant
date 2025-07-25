-- empowerPlant Database Initialization Script
-- This script creates all necessary tables, indexes, constraints, and sample data

-- Use the empowerplant database
USE empowerplant;

-- Create users table
CREATE TABLE users (
    id VARCHAR(36) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role ENUM('admin', 'user', 'manager') DEFAULT 'user',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_active (is_active)
);

-- Create user_sessions table
CREATE TABLE user_sessions (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_token (session_token),
    INDEX idx_user_id (user_id),
    INDEX idx_expires (expires_at)
);

-- Create plants table
CREATE TABLE plants (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    species VARCHAR(255) NOT NULL,
    location VARCHAR(255) NOT NULL,
    user_id VARCHAR(36) NOT NULL,
    planted_date DATE,
    notes TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_species (species),
    INDEX idx_location (location),
    INDEX idx_active (is_active)
);

-- Create sensors table
CREATE TABLE sensors (
    id VARCHAR(36) PRIMARY KEY,
    plant_id VARCHAR(36) NOT NULL,
    sensor_type ENUM('soil_moisture', 'temperature', 'humidity', 'light', 'ph') NOT NULL,
    model VARCHAR(255),
    location VARCHAR(255),
    calibration_data JSON,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (plant_id) REFERENCES plants(id) ON DELETE CASCADE,
    INDEX idx_plant_id (plant_id),
    INDEX idx_sensor_type (sensor_type),
    INDEX idx_active (is_active)
);

-- Create sensor_readings table
CREATE TABLE sensor_readings (
    id VARCHAR(36) PRIMARY KEY,
    sensor_id VARCHAR(36) NOT NULL,
    value DECIMAL(10,4) NOT NULL,
    unit VARCHAR(50) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    quality_score DECIMAL(3,2) DEFAULT 1.00,
    FOREIGN KEY (sensor_id) REFERENCES sensors(id) ON DELETE CASCADE,
    INDEX idx_sensor_id (sensor_id),
    INDEX idx_timestamp (timestamp),
    INDEX idx_sensor_timestamp (sensor_id, timestamp)
);

-- Create weather_data table
CREATE TABLE weather_data (
    id VARCHAR(36) PRIMARY KEY,
    location VARCHAR(255) NOT NULL,
    temperature DECIMAL(5,2) NOT NULL,
    humidity DECIMAL(5,2) NOT NULL,
    rainfall DECIMAL(6,2) DEFAULT 0,
    wind_speed DECIMAL(5,2) DEFAULT 0,
    wind_direction INT DEFAULT 0,
    pressure DECIMAL(7,2),
    uv_index DECIMAL(4,2),
    cloud_cover DECIMAL(5,2),
    visibility DECIMAL(5,2),
    weather_condition VARCHAR(100),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    forecast_date DATE,
    source VARCHAR(100) DEFAULT 'openweathermap',
    INDEX idx_location (location),
    INDEX idx_timestamp (timestamp),
    INDEX idx_forecast_date (forecast_date),
    INDEX idx_location_timestamp (location, timestamp)
);

-- Create irrigation_schedules table
CREATE TABLE irrigation_schedules (
    id VARCHAR(36) PRIMARY KEY,
    plant_id VARCHAR(36) NOT NULL,
    schedule_name VARCHAR(255) NOT NULL,
    frequency_hours INT NOT NULL,
    duration_minutes INT NOT NULL,
    start_time TIME NOT NULL,
    is_active BOOLEAN DEFAULT true,
    conditions JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (plant_id) REFERENCES plants(id) ON DELETE CASCADE,
    INDEX idx_plant_id (plant_id),
    INDEX idx_active (is_active),
    INDEX idx_start_time (start_time)
);

-- Create irrigation_events table
CREATE TABLE irrigation_events (
    id VARCHAR(36) PRIMARY KEY,
    plant_id VARCHAR(36) NOT NULL,
    schedule_id VARCHAR(36),
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    water_amount DECIMAL(8,2),
    trigger_type ENUM('scheduled', 'manual', 'sensor_triggered') NOT NULL,
    status ENUM('pending', 'running', 'completed', 'failed') DEFAULT 'pending',
    notes TEXT,
    FOREIGN KEY (plant_id) REFERENCES plants(id) ON DELETE CASCADE,
    FOREIGN KEY (schedule_id) REFERENCES irrigation_schedules(id) ON DELETE SET NULL,
    INDEX idx_plant_id (plant_id),
    INDEX idx_schedule_id (schedule_id),
    INDEX idx_start_time (start_time),
    INDEX idx_status (status)
);

-- Create alerts table
CREATE TABLE alerts (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    plant_id VARCHAR(36),
    alert_type ENUM('low_moisture', 'high_temperature', 'disease_detected', 'maintenance_due', 'weather_warning') NOT NULL,
    severity ENUM('low', 'medium', 'high', 'critical') DEFAULT 'medium',
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    is_resolved BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (plant_id) REFERENCES plants(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_plant_id (plant_id),
    INDEX idx_alert_type (alert_type),
    INDEX idx_severity (severity),
    INDEX idx_is_read (is_read),
    INDEX idx_created_at (created_at)
);

-- Create plant_photos table
CREATE TABLE plant_photos (
    id VARCHAR(36) PRIMARY KEY,
    plant_id VARCHAR(36) NOT NULL,
    photo_url VARCHAR(500) NOT NULL,
    thumbnail_url VARCHAR(500),
    description TEXT,
    metadata JSON,
    taken_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (plant_id) REFERENCES plants(id) ON DELETE CASCADE,
    INDEX idx_plant_id (plant_id),
    INDEX idx_taken_at (taken_at)
);

-- Create plant_health_assessments table
CREATE TABLE plant_health_assessments (
    id VARCHAR(36) PRIMARY KEY,
    plant_id VARCHAR(36) NOT NULL,
    health_score DECIMAL(4,2) NOT NULL,
    assessment_data JSON NOT NULL,
    recommendations TEXT,
    assessed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (plant_id) REFERENCES plants(id) ON DELETE CASCADE,
    INDEX idx_plant_id (plant_id),
    INDEX idx_assessed_at (assessed_at),
    INDEX idx_health_score (health_score)
);

-- Create equipment table
CREATE TABLE equipment (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    equipment_type ENUM('pump', 'sensor', 'valve', 'controller', 'camera') NOT NULL,
    model VARCHAR(255),
    serial_number VARCHAR(255),
    location VARCHAR(255),
    plant_id VARCHAR(36),
    status ENUM('active', 'inactive', 'maintenance', 'faulty') DEFAULT 'active',
    installation_date DATE,
    last_maintenance DATE,
    next_maintenance DATE,
    specifications JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (plant_id) REFERENCES plants(id) ON DELETE SET NULL,
    INDEX idx_plant_id (plant_id),
    INDEX idx_equipment_type (equipment_type),
    INDEX idx_status (status),
    INDEX idx_next_maintenance (next_maintenance)
);

-- Create maintenance_logs table
CREATE TABLE maintenance_logs (
    id VARCHAR(36) PRIMARY KEY,
    equipment_id VARCHAR(36) NOT NULL,
    maintenance_type ENUM('routine', 'repair', 'replacement', 'calibration') NOT NULL,
    description TEXT NOT NULL,
    performed_by VARCHAR(255),
    cost DECIMAL(10,2),
    parts_used JSON,
    maintenance_date DATE NOT NULL,
    next_due_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (equipment_id) REFERENCES equipment(id) ON DELETE CASCADE,
    INDEX idx_equipment_id (equipment_id),
    INDEX idx_maintenance_type (maintenance_type),
    INDEX idx_maintenance_date (maintenance_date),
    INDEX idx_next_due_date (next_due_date)
);

-- Create system_logs table
CREATE TABLE system_logs (
    id VARCHAR(36) PRIMARY KEY,
    level ENUM('debug', 'info', 'warning', 'error', 'critical') NOT NULL,
    service VARCHAR(100) NOT NULL,
    message TEXT NOT NULL,
    context JSON,
    user_id VARCHAR(36),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_level (level),
    INDEX idx_service (service),
    INDEX idx_timestamp (timestamp),
    INDEX idx_user_id (user_id)
);

-- Insert sample data

-- Sample users
INSERT INTO users (id, email, password_hash, first_name, last_name, role) VALUES
('user-1', 'admin@empowerplant.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewLRL/4lUn5CnSNu', 'Admin', 'User', 'admin'),
('user-2', 'john@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewLRL/4lUn5CnSNu', 'John', 'Doe', 'user'),
('user-3', 'jane@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewLRL/4lUn5CnSNu', 'Jane', 'Smith', 'manager');

-- Sample plants
INSERT INTO plants (id, name, species, location, user_id, planted_date, notes) VALUES
('plant-1', 'Tomato Garden', 'Solanum lycopersicum', 'Greenhouse A', 'user-2', '2024-03-15', 'Heritage variety tomatoes'),
('plant-2', 'Lettuce Patch', 'Lactuca sativa', 'Greenhouse B', 'user-2', '2024-04-01', 'Hydroponic lettuce system'),
('plant-3', 'Pepper Plants', 'Capsicum annuum', 'Outdoor Plot 1', 'user-3', '2024-03-20', 'Bell pepper varieties');

-- Sample sensors
INSERT INTO sensors (id, plant_id, sensor_type, model, location) VALUES
('sensor-1', 'plant-1', 'soil_moisture', 'SM-100', 'Root zone'),
('sensor-2', 'plant-1', 'temperature', 'TEMP-200', 'Canopy level'),
('sensor-3', 'plant-2', 'soil_moisture', 'SM-100', 'Root zone'),
('sensor-4', 'plant-2', 'ph', 'PH-300', 'Nutrient solution'),
('sensor-5', 'plant-3', 'humidity', 'HUM-150', 'Plant environment');

-- Sample sensor readings (recent data)
INSERT INTO sensor_readings (id, sensor_id, value, unit) VALUES
('reading-1', 'sensor-1', 65.5, '%'),
('reading-2', 'sensor-1', 64.2, '%'),
('reading-3', 'sensor-2', 22.5, '°C'),
('reading-4', 'sensor-2', 23.1, '°C'),
('reading-5', 'sensor-3', 71.8, '%'),
('reading-6', 'sensor-4', 6.2, 'pH'),
('reading-7', 'sensor-5', 68.5, '%');

-- Sample weather data
INSERT INTO weather_data (id, location, temperature, humidity, rainfall, wind_speed, weather_condition) VALUES
('weather-1', 'Greenhouse A', 24.5, 72.0, 0.0, 2.1, 'Clear'),
('weather-2', 'Greenhouse B', 23.8, 69.5, 0.0, 1.8, 'Clear'),
('weather-3', 'Outdoor Plot 1', 26.2, 65.3, 2.5, 5.2, 'Light rain');

-- Sample irrigation schedules
INSERT INTO irrigation_schedules (id, plant_id, schedule_name, frequency_hours, duration_minutes, start_time) VALUES
('schedule-1', 'plant-1', 'Morning Watering', 24, 15, '07:00:00'),
('schedule-2', 'plant-2', 'Hydroponic Cycle', 6, 10, '06:00:00'),
('schedule-3', 'plant-3', 'Evening Irrigation', 48, 20, '18:00:00');

-- Sample irrigation events
INSERT INTO irrigation_events (id, plant_id, schedule_id, start_time, end_time, water_amount, trigger_type, status) VALUES
('event-1', 'plant-1', 'schedule-1', '2024-01-15 07:00:00', '2024-01-15 07:15:00', 5.2, 'scheduled', 'completed'),
('event-2', 'plant-2', 'schedule-2', '2024-01-15 06:00:00', '2024-01-15 06:10:00', 2.8, 'scheduled', 'completed'),
('event-3', 'plant-3', 'schedule-3', '2024-01-14 18:00:00', '2024-01-14 18:20:00', 8.5, 'scheduled', 'completed');

-- Sample alerts
INSERT INTO alerts (id, user_id, plant_id, alert_type, severity, title, message) VALUES
('alert-1', 'user-2', 'plant-1', 'low_moisture', 'medium', 'Low Soil Moisture', 'Tomato Garden soil moisture has dropped below 60%'),
('alert-2', 'user-3', 'plant-3', 'high_temperature', 'high', 'High Temperature Warning', 'Pepper Plants experiencing temperatures above 30°C'),
('alert-3', 'user-2', NULL, 'weather_warning', 'low', 'Weather Update', 'Light rain expected in the next 2 hours');

-- Sample equipment
INSERT INTO equipment (id, name, equipment_type, model, location, plant_id, status, installation_date) VALUES
('equipment-1', 'Main Water Pump', 'pump', 'PUMP-500', 'Greenhouse A', 'plant-1', 'active', '2024-01-01'),
('equipment-2', 'pH Sensor Controller', 'controller', 'CTRL-200', 'Greenhouse B', 'plant-2', 'active', '2024-01-01'),
('equipment-3', 'Outdoor Irrigation Valve', 'valve', 'VALVE-100', 'Outdoor Plot 1', 'plant-3', 'active', '2024-01-01');

-- Sample maintenance logs
INSERT INTO maintenance_logs (id, equipment_id, maintenance_type, description, performed_by, maintenance_date) VALUES
('maint-1', 'equipment-1', 'routine', 'Regular pump maintenance and filter cleaning', 'John Doe', '2024-01-10'),
('maint-2', 'equipment-2', 'calibration', 'pH sensor calibration with standard solutions', 'Jane Smith', '2024-01-12'),
('maint-3', 'equipment-3', 'repair', 'Replaced worn valve seal', 'John Doe', '2024-01-08');

-- Sample plant photos
INSERT INTO plant_photos (id, plant_id, photo_url, description) VALUES
('photo-1', 'plant-1', '/photos/tomato-garden-001.jpg', 'Early growth stage of tomato plants'),
('photo-2', 'plant-2', '/photos/lettuce-patch-001.jpg', 'Lettuce in hydroponic system'),
('photo-3', 'plant-3', '/photos/pepper-plants-001.jpg', 'Bell pepper plants flowering stage');

-- Sample health assessments
INSERT INTO plant_health_assessments (id, plant_id, health_score, assessment_data, recommendations) VALUES
('health-1', 'plant-1', 8.5, '{"growth_rate": "good", "leaf_color": "healthy", "pest_presence": false}', 'Continue current care routine'),
('health-2', 'plant-2', 9.2, '{"growth_rate": "excellent", "nutrient_uptake": "optimal", "root_health": "strong"}', 'Maintain nutrient levels'),
('health-3', 'plant-3', 7.8, '{"growth_rate": "fair", "flowering": "active", "fruit_development": "progressing"}', 'Monitor for pest activity');

-- Sample system logs
INSERT INTO system_logs (id, level, service, message, user_id) VALUES
('log-1', 'info', 'weather-data', 'Weather data updated successfully', NULL),
('log-2', 'info', 'plant-monitoring', 'Plant health assessment completed', 'user-2'),
('log-3', 'warning', 'irrigation-system', 'Irrigation event delayed due to sensor timeout', NULL);

-- Create indexes for better query performance
CREATE INDEX idx_sensor_readings_recent ON sensor_readings(sensor_id, timestamp DESC);
CREATE INDEX idx_weather_data_recent ON weather_data(location, timestamp DESC);
CREATE INDEX idx_irrigation_events_recent ON irrigation_events(plant_id, start_time DESC);
CREATE INDEX idx_alerts_unread ON alerts(user_id, is_read, created_at DESC);
CREATE INDEX idx_plant_photos_recent ON plant_photos(plant_id, taken_at DESC);
CREATE INDEX idx_health_assessments_recent ON plant_health_assessments(plant_id, assessed_at DESC);

COMMIT;
