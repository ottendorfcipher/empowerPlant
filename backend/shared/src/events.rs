use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

// Event topics
pub const USER_EVENTS_TOPIC: &str = "user-events";
pub const SENSOR_EVENTS_TOPIC: &str = "sensor-events";
pub const PLANT_EVENTS_TOPIC: &str = "plant-events";
pub const WEATHER_EVENTS_TOPIC: &str = "weather-events";
pub const IRRIGATION_EVENTS_TOPIC: &str = "irrigation-events";
pub const ALERT_EVENTS_TOPIC: &str = "alert-events";

#[derive(Debug, Serialize, Deserialize)]
#[serde(tag = "event_type")]
pub enum Event {
    UserRegistered(UserRegisteredEvent),
    UserLoggedIn(UserLoggedInEvent),
    UserProfileUpdated(UserProfileUpdatedEvent),
    SensorReadingReceived(SensorReadingReceivedEvent),
    SensorStatusChanged(SensorStatusChangedEvent),
    PlantHealthUpdated(PlantHealthUpdatedEvent),
    PlantGrowthStageChanged(PlantGrowthStageChangedEvent),
    WeatherDataReceived(WeatherDataReceivedEvent),
    WeatherAlertTriggered(WeatherAlertTriggeredEvent),
    IrrigationStarted(IrrigationStartedEvent),
    IrrigationCompleted(IrrigationCompletedEvent),
    AlertCreated(AlertCreatedEvent),
    AlertAcknowledged(AlertAcknowledgedEvent),
}

#[derive(Debug, Serialize, Deserialize)]
pub struct EventMetadata {
    pub event_id: Uuid,
    pub timestamp: DateTime<Utc>,
    pub source_service: String,
    pub correlation_id: Option<String>,
}

// User Events
#[derive(Debug, Serialize, Deserialize)]
pub struct UserRegisteredEvent {
    pub metadata: EventMetadata,
    pub user_id: Uuid,
    pub email: String,
    pub first_name: String,
    pub last_name: String,
    pub roles: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UserLoggedInEvent {
    pub metadata: EventMetadata,
    pub user_id: Uuid,
    pub email: String,
    pub login_timestamp: DateTime<Utc>,
    pub ip_address: Option<String>,
    pub user_agent: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UserProfileUpdatedEvent {
    pub metadata: EventMetadata,
    pub user_id: Uuid,
    pub updated_fields: Vec<String>,
}

// Sensor Events
#[derive(Debug, Serialize, Deserialize)]
pub struct SensorReadingReceivedEvent {
    pub metadata: EventMetadata,
    pub sensor_id: Uuid,
    pub reading_id: Uuid,
    pub sensor_type: String,
    pub value: f64,
    pub unit: String,
    pub location: String,
    pub reading_timestamp: DateTime<Utc>,
    pub quality_score: Option<f64>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct SensorStatusChangedEvent {
    pub metadata: EventMetadata,
    pub sensor_id: Uuid,
    pub old_status: String,
    pub new_status: String,
    pub reason: Option<String>,
}

// Plant Events
#[derive(Debug, Serialize, Deserialize)]
pub struct PlantHealthUpdatedEvent {
    pub metadata: EventMetadata,
    pub plant_id: Uuid,
    pub old_health_status: String,
    pub new_health_status: String,
    pub assessment_data: serde_json::Value,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PlantGrowthStageChangedEvent {
    pub metadata: EventMetadata,
    pub plant_id: Uuid,
    pub old_stage: String,
    pub new_stage: String,
    pub measurements: serde_json::Value,
}

// Weather Events
#[derive(Debug, Serialize, Deserialize)]
pub struct WeatherDataReceivedEvent {
    pub metadata: EventMetadata,
    pub location: String,
    pub temperature: f64,
    pub humidity: f64,
    pub rainfall: f64,
    pub wind_speed: f64,
    pub wind_direction: f64,
    pub solar_radiation: Option<f64>,
    pub uv_index: Option<f64>,
    pub data_timestamp: DateTime<Utc>,
    pub source: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct WeatherAlertTriggeredEvent {
    pub metadata: EventMetadata,
    pub alert_type: String,
    pub location: String,
    pub severity: String,
    pub message: String,
    pub conditions: serde_json::Value,
}

// Irrigation Events
#[derive(Debug, Serialize, Deserialize)]
pub struct IrrigationStartedEvent {
    pub metadata: EventMetadata,
    pub irrigation_id: Uuid,
    pub zone_id: Uuid,
    pub trigger_type: String,
    pub planned_duration_minutes: i32,
    pub planned_water_amount_liters: f64,
    pub started_by: Option<Uuid>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct IrrigationCompletedEvent {
    pub metadata: EventMetadata,
    pub irrigation_id: Uuid,
    pub zone_id: Uuid,
    pub actual_duration_minutes: i32,
    pub actual_water_amount_liters: f64,
    pub completed_successfully: bool,
    pub failure_reason: Option<String>,
}

// Alert Events
#[derive(Debug, Serialize, Deserialize)]
pub struct AlertCreatedEvent {
    pub metadata: EventMetadata,
    pub alert_id: Uuid,
    pub alert_type: String,
    pub severity: String,
    pub title: String,
    pub message: String,
    pub source: String,
    pub affected_resources: Vec<Uuid>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AlertAcknowledgedEvent {
    pub metadata: EventMetadata,
    pub alert_id: Uuid,
    pub acknowledged_by: Uuid,
    pub acknowledgment_note: Option<String>,
}

impl Event {
    pub fn metadata(&self) -> &EventMetadata {
        match self {
            Event::UserRegistered(e) => &e.metadata,
            Event::UserLoggedIn(e) => &e.metadata,
            Event::UserProfileUpdated(e) => &e.metadata,
            Event::SensorReadingReceived(e) => &e.metadata,
            Event::SensorStatusChanged(e) => &e.metadata,
            Event::PlantHealthUpdated(e) => &e.metadata,
            Event::PlantGrowthStageChanged(e) => &e.metadata,
            Event::WeatherDataReceived(e) => &e.metadata,
            Event::WeatherAlertTriggered(e) => &e.metadata,
            Event::IrrigationStarted(e) => &e.metadata,
            Event::IrrigationCompleted(e) => &e.metadata,
            Event::AlertCreated(e) => &e.metadata,
            Event::AlertAcknowledged(e) => &e.metadata,
        }
    }

    pub fn event_type(&self) -> &str {
        match self {
            Event::UserRegistered(_) => "user_registered",
            Event::UserLoggedIn(_) => "user_logged_in",
            Event::UserProfileUpdated(_) => "user_profile_updated",
            Event::SensorReadingReceived(_) => "sensor_reading_received",
            Event::SensorStatusChanged(_) => "sensor_status_changed",
            Event::PlantHealthUpdated(_) => "plant_health_updated",
            Event::PlantGrowthStageChanged(_) => "plant_growth_stage_changed",
            Event::WeatherDataReceived(_) => "weather_data_received",
            Event::WeatherAlertTriggered(_) => "weather_alert_triggered",
            Event::IrrigationStarted(_) => "irrigation_started",
            Event::IrrigationCompleted(_) => "irrigation_completed",
            Event::AlertCreated(_) => "alert_created",
            Event::AlertAcknowledged(_) => "alert_acknowledged",
        }
    }
}

pub fn create_event_metadata(source_service: &str, correlation_id: Option<String>) -> EventMetadata {
    EventMetadata {
        event_id: Uuid::new_v4(),
        timestamp: Utc::now(),
        source_service: source_service.to_string(),
        correlation_id,
    }
}
