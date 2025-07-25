use super::*;
use crate::models::*;

pub async fn get_current_weather(pool: web::Data<MySqlPool>) -> ActixResult<HttpResponse> {
    let weather = WeatherData {
        temperature: 22.5,
        humidity: 65.0,
        pressure: 1013.25,
        wind_speed: 5.2,
        condition: "Sunny".to_string(),
        timestamp: Utc::now(),
    };

    Ok(HttpResponse::Ok().json(ApiResponse::success(weather, "Current weather retrieved successfully")))
}

pub async fn get_weather_forecast(pool: web::Data<MySqlPool>) -> ActixResult<HttpResponse> {
    let forecast = vec![
        WeatherData {
            temperature: 23.0,
            humidity: 60.0,
            pressure: 1015.0,
            wind_speed: 4.8,
            condition: "Partly Cloudy".to_string(),
            timestamp: Utc::now(),
        }
    ];

    Ok(HttpResponse::Ok().json(ApiResponse::success(forecast, "Weather forecast retrieved successfully")))
}
