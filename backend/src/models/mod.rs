use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use validator::Validate;

// Plant models
#[derive(Serialize, Deserialize, Clone)]
pub struct Plant {
    pub id: Uuid,
    pub name: String,
    pub plant_type: String,
    pub location: Option<String>,
    pub created_at: DateTime<Utc>,
}

#[derive(Deserialize, Validate)]
pub struct CreatePlantRequest {
    #[validate(length(min = 1, max = 100))]
    pub name: String,
    #[validate(length(min = 1, max = 50))]
    pub plant_type: String,
    pub location: Option<String>,
}

#[derive(Deserialize)]
pub struct UpdatePlantRequest {
    pub name: Option<String>,
    pub plant_type: Option<String>,
    pub location: Option<String>,
}

#[derive(Serialize)]
pub struct PlantIdentification {
    pub plant_type: String,
    pub scientific_name: String,
    pub confidence: f64,
    pub care_instructions: CareInstructions,
}

#[derive(Serialize)]
pub struct CareInstructions {
    pub water_frequency: String,
    pub light_requirements: String,
    pub soil_type: String,
    pub optimal_temperature: String,
}

// Sensor models
#[derive(Serialize, Deserialize)]
pub struct Sensor {
    pub id: Uuid,
    pub name: String,
    pub sensor_type: String,
    pub location: String,
    pub status: String,
}

#[derive(Deserialize, Validate)]
pub struct CreateSensorRequest {
    #[validate(length(min = 1, max = 100))]
    pub name: String,
    pub sensor_type: String,
    pub location: String,
}

#[derive(Serialize, Deserialize)]
pub struct SensorReading {
    pub id: Uuid,
    pub sensor_id: Uuid,
    pub value: f64,
    pub unit: String,
    pub timestamp: DateTime<Utc>,
}

#[derive(Deserialize)]
pub struct SensorReadingRequest {
    pub value: f64,
    pub unit: String,
}

// Camera models
#[derive(Serialize, Deserialize)]
pub struct Camera {
    pub id: Uuid,
    pub name: String,
    pub location: String,
    pub status: String,
    pub stream_url: Option<String>,
}

#[derive(Deserialize, Validate)]
pub struct CameraSetupRequest {
    #[validate(length(min = 1, max = 100))]
    pub camera_name: String,
    pub network_ssid: String,
    pub network_password: String,
    pub location: String,
}

#[derive(Serialize)]
pub struct CameraStream {
    pub camera_id: Uuid,
    pub stream_url: String,
    pub status: String,
    pub resolution: String,
    pub fps: u32,
}

// User models
#[derive(Serialize, Deserialize)]
pub struct User {
    pub id: Uuid,
    pub email: String,
    pub name: String,
    pub created_at: DateTime<Utc>,
}

#[derive(Deserialize, Validate)]
pub struct LoginRequest {
    #[validate(email)]
    pub email: String,
    #[validate(length(min = 6))]
    pub password: String,
}

#[derive(Deserialize, Validate)]
pub struct RegisterRequest {
    #[validate(email)]
    pub email: String,
    #[validate(length(min = 1, max = 100))]
    pub name: String,
    #[validate(length(min = 6))]
    pub password: String,
}

#[derive(Serialize)]
pub struct LoginResponse {
    pub token: String,
    pub user_id: Uuid,
    pub email: String,
}

#[derive(Deserialize)]
pub struct UpdateUserRequest {
    pub email: Option<String>,
    pub name: Option<String>,
}

// Weather models
#[derive(Serialize, Deserialize)]
pub struct WeatherData {
    pub temperature: f64,
    pub humidity: f64,
    pub pressure: f64,
    pub wind_speed: f64,
    pub condition: String,
    pub timestamp: DateTime<Utc>,
}

// Irrigation models
#[derive(Serialize, Deserialize)]
pub struct IrrigationStatus {
    pub pump_active: bool,
    pub pump_pwm_level: u8, // 0-255 PWM value
    pub solenoid_active: bool,
    pub water_level_ok: bool,
    pub flow_rate: f64, // L/min
    pub voltage: f64, // 12V rail voltage
    pub system_uptime: u64, // seconds
    pub last_command: Option<String>,
    pub error: Option<String>,
    pub timestamp: DateTime<Utc>,
}

#[derive(Serialize, Deserialize)]
pub struct IrrigationSensor {
    pub id: Uuid,
    pub sensor_type: IrrigationSensorType,
    pub location: String,
    pub value: f64,
    pub unit: String,
    pub status: String,
    pub last_reading: DateTime<Utc>,
}

#[derive(Serialize, Deserialize)]
pub enum IrrigationSensorType {
    WaterLevel,
    FlowRate,
    Voltage,
    SoilMoisture,
    Pressure,
}

#[derive(Deserialize, Validate)]
pub struct IrrigationCommand {
    #[validate(length(min = 1))]
    pub command: String, // PUMP:SOFTSTART, PUMP:OFF, SOLENOID:ON, etc.
    pub parameters: Option<serde_json::Value>, // Optional parameters for commands
}

#[derive(Serialize)]
pub struct IrrigationCommandResponse {
    pub success: bool,
    pub command: String,
    pub result: String,
    pub system_status: IrrigationStatus,
}

#[derive(Serialize, Deserialize)]
pub struct IrrigationDiagnostics {
    pub pump_diagnostics: PumpDiagnostics,
    pub solenoid_diagnostics: SolenoidDiagnostics,
    pub sensor_diagnostics: Vec<SensorDiagnostics>,
    pub power_diagnostics: PowerDiagnostics,
    pub timestamp: DateTime<Utc>,
}

#[derive(Serialize, Deserialize)]
pub struct PumpDiagnostics {
    pub motor_current: f64, // Amps
    pub motor_temperature: f64, // Celsius
    pub runtime_hours: f64,
    pub cycles_completed: u32,
    pub soft_start_functioning: bool,
    pub last_maintenance: Option<DateTime<Utc>>,
}

#[derive(Serialize, Deserialize)]
pub struct SolenoidDiagnostics {
    pub coil_resistance: f64, // Ohms
    pub activation_count: u32,
    pub response_time_ms: u32,
    pub leak_detected: bool,
    pub last_maintenance: Option<DateTime<Utc>>,
}

#[derive(Serialize, Deserialize)]
pub struct SensorDiagnostics {
    pub sensor_id: Uuid,
    pub sensor_type: String,
    pub calibration_status: String,
    pub last_calibration: Option<DateTime<Utc>>,
    pub drift_percentage: f64,
    pub readings_count: u32,
    pub error_rate: f64,
}

#[derive(Serialize, Deserialize)]
pub struct PowerDiagnostics {
    pub supply_voltage: f64,
    pub current_draw: f64,
    pub power_consumption: f64, // Watts
    pub efficiency: f64, // Percentage
    pub thermal_status: String,
}
