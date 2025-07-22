use actix_web::{HttpResponse, ResponseError};
use serde::{Deserialize, Serialize};
use serde_json::json;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum AppError {
    #[error("Database error: {0}")]
    Database(#[from] sqlx::Error),
    
    #[error("Kafka error: {0}")]
    Kafka(#[from] rdkafka::error::KafkaError),
    
    #[error("Serialization error: {0}")]
    Serialization(#[from] serde_json::Error),
    
    #[error("Authentication error: {0}")]
    Authentication(String),
    
    #[error("Authorization error: {0}")]
    Authorization(String),
    
    #[error("Validation error: {0}")]
    Validation(String),
    
    #[error("Not found: {0}")]
    NotFound(String),
    
    #[error("Conflict: {0}")]
    Conflict(String),
    
    #[error("Internal error: {0}")]
    Internal(String),
    
    #[error("External service error: {0}")]
    ExternalService(String),
    
    #[error("Configuration error: {0}")]
    Config(#[from] config::ConfigError),
}

impl ResponseError for AppError {
    fn error_response(&self) -> HttpResponse {
        let (status, error_message) = match self {
            AppError::Database(_) => (
                actix_web::http::StatusCode::INTERNAL_SERVER_ERROR,
                "Database error occurred",
            ),
            AppError::Kafka(_) => (
                actix_web::http::StatusCode::INTERNAL_SERVER_ERROR,
                "Message queue error occurred",
            ),
            AppError::Serialization(_) => (
                actix_web::http::StatusCode::BAD_REQUEST,
                "Invalid data format",
            ),
            AppError::Authentication(_) => (
                actix_web::http::StatusCode::UNAUTHORIZED,
                "Authentication required",
            ),
            AppError::Authorization(_) => (
                actix_web::http::StatusCode::FORBIDDEN,
                "Insufficient permissions",
            ),
            AppError::Validation(msg) => (
                actix_web::http::StatusCode::BAD_REQUEST,
                msg.as_str(),
            ),
            AppError::NotFound(msg) => (
                actix_web::http::StatusCode::NOT_FOUND,
                msg.as_str(),
            ),
            AppError::Conflict(msg) => (
                actix_web::http::StatusCode::CONFLICT,
                msg.as_str(),
            ),
            AppError::Internal(_) => (
                actix_web::http::StatusCode::INTERNAL_SERVER_ERROR,
                "Internal server error",
            ),
            AppError::ExternalService(_) => (
                actix_web::http::StatusCode::BAD_GATEWAY,
                "External service unavailable",
            ),
            AppError::Config(_) => (
                actix_web::http::StatusCode::INTERNAL_SERVER_ERROR,
                "Configuration error",
            ),
        };

        HttpResponse::build(status).json(json!({
            "error": error_message,
            "details": self.to_string()
        }))
    }
}

pub type AppResult<T> = Result<T, AppError>;
