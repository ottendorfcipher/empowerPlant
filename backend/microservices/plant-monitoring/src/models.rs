// Models specific to plant monitoring service
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use uuid::Uuid;

#[derive(Debug, Serialize, Deserialize)]
pub struct HealthAssessment {
    pub health_score: i32,
    pub status: String,
    pub recommendations: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct GrowthAnalysis {
    pub growth_rate: String,
    pub stage: String,
    pub projected_harvest: Option<DateTime<Utc>>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PlantPhoto {
    pub id: Uuid,
    pub plant_id: Uuid,
    pub image_url: String,
    pub caption: Option<String>,
    pub taken_at: DateTime<Utc>,
}
