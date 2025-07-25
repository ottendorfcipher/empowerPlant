use chrono::{DateTime, Utc};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;
use validator::Validate;

// Weather models
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct WeatherData {
    pub id: String,  // UUID as string in database
    pub location: String,
    pub temperature: Decimal,  // NOT NULL - DECIMAL(5,2)
    pub humidity: Decimal,     // NOT NULL - DECIMAL(5,2)
    pub rainfall: Option<Decimal>,        // NULLABLE with default 0.00 - DECIMAL(6,2)
    pub wind_speed: Option<Decimal>,      // NULLABLE with default 0.00 - DECIMAL(5,2)
    pub wind_direction: Option<i32>,  // NULLABLE with default 0
    pub pressure: Option<Decimal>,        // NULLABLE - DECIMAL(7,2)
    pub uv_index: Option<Decimal>,        // NULLABLE - DECIMAL(4,2)
    pub cloud_cover: Option<Decimal>,     // NULLABLE - DECIMAL(5,2)
    pub visibility: Option<Decimal>,      // NULLABLE - DECIMAL(5,2)
    pub weather_condition: Option<String>,  // NULLABLE
    pub timestamp: Option<DateTime<Utc>>,   // NULLABLE with default CURRENT_TIMESTAMP
    pub forecast_date: Option<chrono::NaiveDate>,  // NULLABLE
    pub source: Option<String>,       // NULLABLE with default 'openweathermap'
}

// User models
#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct User {
    pub id: String,  // Store as string for MySQL compatibility
    pub email: String,
    pub password_hash: String,
    pub first_name: String,
    pub last_name: String,
    pub role: String,  // Single role field to match database schema
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// Additional types for authentication and middleware
#[derive(Debug, Serialize, Deserialize)]
pub struct RefreshTokenRequest {
    pub refresh_token: String,
}

#[derive(Debug, Clone)]
pub struct CurrentUser {
    pub id: uuid::Uuid,
    pub email: String,
    pub roles: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize, Validate)]
pub struct CreateUserRequest {
    #[validate(email)]
    pub email: String,
    #[validate(length(min = 8))]
    pub password: String,
    #[validate(length(min = 1))]
    pub first_name: String,
    #[validate(length(min = 1))]
    pub last_name: String,
    pub roles: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize, Validate)]
pub struct LoginRequest {
    #[validate(email)]
    pub email: String,
    #[validate(length(min = 1))]
    pub password: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct LoginResponse {
    pub access_token: String,
    pub refresh_token: String,
    pub user: UserResponse,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UserResponse {
    pub id: Uuid,
    pub email: String,
    pub first_name: String,
    pub last_name: String,
    pub roles: Vec<String>,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
}

impl From<User> for UserResponse {
    fn from(user: User) -> Self {
        Self {
            id: uuid::Uuid::parse_str(&user.id).unwrap_or_default(),
            email: user.email,
            first_name: user.first_name,
            last_name: user.last_name,
            roles: vec![user.role],  // Convert single role to vector
            is_active: user.is_active,
            created_at: user.created_at,
        }
    }
}

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct Sensor {
    pub id: Uuid,
    pub name: String,
    pub sensor_type: String,
    pub location: String,
    pub status: String,
    pub last_reading_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct SensorReading {
    pub id: Uuid,
    pub sensor_id: Uuid,
    pub value: f64,
    pub unit: String,
    pub timestamp: DateTime<Utc>,
    pub metadata: Option<serde_json::Value>,
}

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct Plant {
    pub id: Uuid,
    pub name: String,
    pub variety: String,
    pub plant_type: String,
    pub planting_date: DateTime<Utc>,
    pub location: String,
    pub growth_stage: String,
    pub health_status: String,
    pub photo_url: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, Validate)]
pub struct CreatePlantRequest {
    #[validate(length(min = 1))]
    pub name: String,
    #[validate(length(min = 1))]
    pub variety: String,
    #[validate(length(min = 1))]
    pub plant_type: String,
    pub location: Option<String>,
    pub photo_url: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PlantIdentificationRequest {
    pub image_base64: String,
    pub metadata: Option<serde_json::Value>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PlantIdentificationResponse {
    pub plant_type: String,
    pub variety: String,
    pub confidence: f64,
    pub care_instructions: PlantCareInstructions,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PlantCareInstructions {
    pub watering_frequency: String,
    pub light_requirements: String,
    pub temperature_range: String,
    pub humidity_level: String,
    pub soil_type: String,
    pub fertilizer_schedule: String,
}


#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct IrrigationEvent {
    pub id: Uuid,
    pub zone_id: Uuid,
    pub duration_minutes: i32,
    pub water_amount_liters: f64,
    pub trigger_type: String, // manual, scheduled, sensor-based
    pub started_at: DateTime<Utc>,
    pub completed_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct Alert {
    pub id: Uuid,
    pub alert_type: String,
    pub severity: String,
    pub title: String,
    pub message: String,
    pub source: String,
    pub acknowledged: bool,
    pub acknowledged_by: Option<Uuid>,
    pub acknowledged_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
}

// Live Camera Models
#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct Camera {
    pub id: Uuid,
    pub name: String,
    pub location: String,
    pub camera_type: String,
    pub stream_url: Option<String>,
    pub status: String, // active, inactive, setup_required
    pub wifi_network: Option<String>,
    pub resolution: Option<String>,
    pub user_id: Uuid,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, Validate)]
pub struct CreateCameraRequest {
    #[validate(length(min = 1))]
    pub name: String,
    #[validate(length(min = 1))]
    pub location: String,
    #[validate(length(min = 1))]
    pub wifi_network: String,
    #[validate(length(min = 8))]
    pub wifi_password: String,
    pub camera_type: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CameraStreamResponse {
    pub stream_url: String,
    pub status: String,
    pub resolution: String,
    pub frame_rate: i32,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CameraControlRequest {
    pub action: String, // record, snapshot, audio_toggle
    pub parameters: Option<serde_json::Value>,
}

// Temperature Unit Preferences
#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct UserPreferences {
    pub id: Uuid,
    pub user_id: Uuid,
    pub temperature_unit: String, // celsius, fahrenheit
    pub measurement_unit: String, // metric, imperial
    pub notification_settings: Option<serde_json::Value>,
    pub dashboard_layout: Option<serde_json::Value>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UpdatePreferencesRequest {
    pub temperature_unit: Option<String>,
    pub measurement_unit: Option<String>,
    pub notification_settings: Option<serde_json::Value>,
    pub dashboard_layout: Option<serde_json::Value>,
}

// Water Management
#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct WaterUsage {
    pub id: Uuid,
    pub date: chrono::NaiveDate,
    pub total_liters: f64,
    pub irrigation_liters: f64,
    pub manual_watering_liters: f64,
    pub location: String,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct DailyWaterSummary {
    pub date: chrono::NaiveDate,
    pub total_liters: f64,
    pub breakdown: Vec<WaterUsageBreakdown>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct WaterUsageBreakdown {
    pub source: String,
    pub liters: f64,
    pub percentage: f64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct HealthCheckResponse {
    pub status: String,
    pub timestamp: DateTime<Utc>,
    pub services: Vec<ServiceStatus>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ServiceStatus {
    pub name: String,
    pub status: String,
    pub last_check: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ApiResponse<T> {
    pub success: bool,
    pub data: Option<T>,
    pub message: Option<String>,
    pub timestamp: DateTime<Utc>,
}

impl<T> ApiResponse<T> {
    pub fn success(data: T) -> Self {
        Self {
            success: true,
            data: Some(data),
            message: None,
            timestamp: Utc::now(),
        }
    }

    pub fn error(message: String) -> Self {
        Self {
            success: false,
            data: None,
            message: Some(message),
            timestamp: Utc::now(),
        }
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PaginatedResponse<T> {
    pub data: Vec<T>,
    pub total: i64,
    pub page: i32,
    pub per_page: i32,
    pub total_pages: i32,
}

impl<T> PaginatedResponse<T> {
    pub fn new(data: Vec<T>, total: i64, page: i32, per_page: i32) -> Self {
        let total_pages = ((total as f64) / (per_page as f64)).ceil() as i32;
        
        Self {
            data,
            total,
            page,
            per_page,
            total_pages,
        }
    }
}
