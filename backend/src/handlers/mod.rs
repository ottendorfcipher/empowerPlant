use actix_multipart::Multipart;
use actix_web::{web, HttpResponse, Result as ActixResult};
use chrono::Utc;
use serde::{Deserialize, Serialize};
use sqlx::MySqlPool;
use uuid::Uuid;

mod auth;
mod cameras;
mod irrigation;
mod plants;
mod sensors;
mod users;
mod weather;
mod websocket;

pub use auth::*;
pub use cameras::*;
pub use irrigation::*;
pub use plants::*;
pub use sensors::*;
pub use users::*;
pub use weather::*;
pub use websocket::*;

// Health check endpoint
pub async fn health_check() -> ActixResult<HttpResponse> {
    Ok(HttpResponse::Ok().json(serde_json::json!({
        "status": "healthy",
        "service": "empower-plant-backend",
        "timestamp": Utc::now(),
        "version": env!("CARGO_PKG_VERSION")
    })))
}

// Common response structures
#[derive(Serialize)]
pub struct ApiResponse<T> {
    pub success: bool,
    pub data: Option<T>,
    pub message: String,
}

impl<T> ApiResponse<T> {
    pub fn success(data: T, message: &str) -> Self {
        Self {
            success: true,
            data: Some(data),
            message: message.to_string(),
        }
    }

    pub fn error(message: &str) -> ApiResponse<()> {
        ApiResponse {
            success: false,
            data: None,
            message: message.to_string(),
        }
    }
}
