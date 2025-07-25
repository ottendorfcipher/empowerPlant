use actix_web::{web, HttpResponse, Result};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use empower_plant_shared::{error::AppError, models::WeatherData};
use sqlx::MySqlPool;
use uuid::Uuid;

use crate::service::WeatherService;

#[derive(Deserialize)]
pub struct HistoricalWeatherQuery {
    pub location: String,
    pub start_date: DateTime<Utc>,
    pub end_date: DateTime<Utc>,
    pub page: Option<i32>,
    pub per_page: Option<i32>,
}

#[derive(Serialize)]
pub struct WeatherResponse {
    pub success: bool,
    pub data: WeatherData,
    pub timestamp: DateTime<Utc>,
}

#[derive(Serialize)]
pub struct WeatherListResponse {
    pub success: bool,
    pub data: Vec<WeatherData>,
    pub total: i64,
    pub page: i32,
    pub per_page: i32,
    pub timestamp: DateTime<Utc>,
}

#[derive(Serialize)]
pub struct WeatherAlertResponse {
    pub success: bool,
    pub data: Vec<WeatherAlert>,
    pub timestamp: DateTime<Utc>,
}

#[derive(Serialize)]
pub struct WeatherAlert {
    pub id: Uuid,
    pub alert_type: String,
    pub severity: String,
    pub title: String,
    pub description: String,
    pub location: String,
    pub start_time: DateTime<Utc>,
    pub end_time: Option<DateTime<Utc>>,
}

pub async fn get_current_weather(
    path: web::Path<String>,
    pool: web::Data<MySqlPool>,
) -> Result<HttpResponse, AppError> {
    let location = path.into_inner();
    let service = WeatherService::new(pool.get_ref());
    
    match service.get_current_weather(&location).await {
        Ok(weather_data) => Ok(HttpResponse::Ok().json(WeatherResponse {
            success: true,
            data: weather_data,
            timestamp: Utc::now(),
        })),
        Err(e) => {
            tracing::error!("Failed to get current weather for location {}: {}", location, e);
            Err(e)
        }
    }
}

pub async fn get_weather_forecast(
    path: web::Path<String>,
    pool: web::Data<MySqlPool>,
) -> Result<HttpResponse, AppError> {
    let location = path.into_inner();
    let service = WeatherService::new(pool.get_ref());
    
    match service.get_weather_forecast(&location, 7).await {
        Ok(forecast_data) => Ok(HttpResponse::Ok().json(WeatherListResponse {
            success: true,
            data: forecast_data,
            total: 7,
            page: 1,
            per_page: 7,
            timestamp: Utc::now(),
        })),
        Err(e) => {
            tracing::error!("Failed to get weather forecast for location {}: {}", location, e);
            Err(e)
        }
    }
}

pub async fn get_historical_weather(
    query: web::Query<HistoricalWeatherQuery>,
    pool: web::Data<MySqlPool>,
) -> Result<HttpResponse, AppError> {
    let service = WeatherService::new(pool.get_ref());
    let page = query.page.unwrap_or(1);
    let per_page = query.per_page.unwrap_or(50);
    
    match service.get_historical_weather(
        &query.location,
        query.start_date,
        query.end_date,
        page,
        per_page,
    ).await {
        Ok((weather_data, total)) => Ok(HttpResponse::Ok().json(WeatherListResponse {
            success: true,
            data: weather_data,
            total,
            page,
            per_page,
            timestamp: Utc::now(),
        })),
        Err(e) => {
            tracing::error!(
                "Failed to get historical weather for location {} from {} to {}: {}", 
                query.location, query.start_date, query.end_date, e
            );
            Err(e)
        }
    }
}

pub async fn get_weather_alerts(
    path: web::Path<String>,
    pool: web::Data<MySqlPool>,
) -> Result<HttpResponse, AppError> {
    let location = path.into_inner();
    let service = WeatherService::new(pool.get_ref());
    
    match service.get_weather_alerts(&location).await {
        Ok(alerts) => Ok(HttpResponse::Ok().json(WeatherAlertResponse {
            success: true,
            data: alerts,
            timestamp: Utc::now(),
        })),
        Err(e) => {
            tracing::error!("Failed to get weather alerts for location {}: {}", location, e);
            Err(e)
        }
    }
}

// New manual API call handler
pub async fn get_current_weather_manual(
    path: web::Path<String>,
    pool: web::Data<MySqlPool>,
) -> Result<HttpResponse, AppError> {
    let location = path.into_inner();
    let service = WeatherService::new(pool.get_ref());
    
    match service.get_current_weather_manual(&location).await {
        Ok(weather_data) => {
            tracing::info!("Manual API call successful for location: {}", location);
            Ok(HttpResponse::Ok().json(WeatherResponse {
                success: true,
                data: weather_data,
                timestamp: Utc::now(),
            }))
        },
        Err(e) => {
            tracing::error!("Manual API call failed for location {}: {}", location, e);
            Err(e)
        }
    }
}

// Endpoint specifically for Jackson Township, IN
pub async fn get_jackson_township_weather(
    pool: web::Data<MySqlPool>,
) -> Result<HttpResponse, AppError> {
    let location = "E Crescent Dr, Jackson Township, IN 47274";
    let service = WeatherService::new(pool.get_ref());
    
    // First try to get cached data
    match service.get_current_weather(location).await {
        Ok(weather_data) => {
            Ok(HttpResponse::Ok().json(serde_json::json!({
                "success": true,
                "data": weather_data,
                "cached": true,
                "message": "Returning cached data. Use /manual endpoint to fetch fresh data.",
                "timestamp": Utc::now(),
            })))
        },
        Err(_) => {
            Ok(HttpResponse::Ok().json(serde_json::json!({
                "success": false,
                "cached": false,
                "message": "No cached data available. Use the manual API call endpoint to fetch fresh data.",
                "manual_endpoint": "/api/v1/weather/manual/jackson-township",
                "timestamp": Utc::now(),
            })))
        }
    }
}

// Manual API call specifically for Jackson Township
pub async fn get_jackson_township_weather_manual(
    pool: web::Data<MySqlPool>,
) -> Result<HttpResponse, AppError> {
    let location = "E Crescent Dr, Jackson Township, IN 47274";
    let service = WeatherService::new(pool.get_ref());
    
    match service.get_current_weather_manual(location).await {
        Ok(weather_data) => {
            tracing::info!("Manual API call successful for Jackson Township");
            Ok(HttpResponse::Ok().json(serde_json::json!({
                "success": true,
                "data": weather_data,
                "api_call_made": true,
                "location": location,
                "message": "Fresh weather data retrieved from OpenWeatherMap API",
                "timestamp": Utc::now(),
            })))
        },
        Err(e) => {
            tracing::error!("Manual API call failed for Jackson Township: {}", e);
            Err(e)
        }
    }
}

pub async fn health_check() -> Result<HttpResponse, AppError> {
    Ok(HttpResponse::Ok().json(serde_json::json!({
        "status": "healthy",
        "service": "weather-data",
        "timestamp": Utc::now(),
        "version": env!("CARGO_PKG_VERSION")
    })))
}
