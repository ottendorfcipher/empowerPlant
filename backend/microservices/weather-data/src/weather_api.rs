use chrono::{DateTime, Utc};
use reqwest::Client;
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use empower_plant_shared::{error::AppError, models::WeatherData};
use std::env;
use std::str::FromStr;
use uuid::Uuid;

use crate::handlers::WeatherAlert;

#[derive(Debug, Deserialize)]
struct OpenWeatherMapResponse {
    coord: Coordinates,
    weather: Vec<WeatherDescription>,
    main: MainWeatherData,
    visibility: Option<f64>,
    wind: Option<WindData>,
    clouds: Option<CloudData>,
    dt: i64,
    sys: Option<SystemData>,
    timezone: i32,
    id: u64,
    name: String,
    cod: u16,
}

#[derive(Debug, Deserialize)]
struct Coordinates {
    lon: f64,
    lat: f64,
}

#[derive(Debug, Deserialize)]
struct WeatherDescription {
    id: u32,
    main: String,
    description: String,
    icon: String,
}

#[derive(Debug, Deserialize)]
struct MainWeatherData {
    temp: f64,
    feels_like: f64,
    temp_min: f64,
    temp_max: f64,
    pressure: f64,
    humidity: f64,
    sea_level: Option<f64>,
    grnd_level: Option<f64>,
}

#[derive(Debug, Deserialize)]
struct WindData {
    speed: f64,
    deg: f64,
    gust: Option<f64>,
}

#[derive(Debug, Deserialize)]
struct CloudData {
    all: f64,
}

#[derive(Debug, Deserialize)]
struct SystemData {
    #[serde(rename = "type")]
    system_type: Option<u32>,
    id: Option<u64>,
    country: Option<String>,
    sunrise: Option<i64>,
    sunset: Option<i64>,
}

#[derive(Debug, Deserialize)]
struct ForecastResponse {
    cod: String,
    message: f64,
    cnt: u32,
    list: Vec<ForecastItem>,
    city: CityInfo,
}

#[derive(Debug, Deserialize)]
struct ForecastItem {
    dt: i64,
    main: MainWeatherData,
    weather: Vec<WeatherDescription>,
    clouds: CloudData,
    wind: WindData,
    visibility: f64,
    pop: f64, // Probability of precipitation
    rain: Option<RainData>,
    snow: Option<SnowData>,
    sys: ForecastSys,
    dt_txt: String,
}

#[derive(Debug, Deserialize)]
struct RainData {
    #[serde(rename = "1h")]
    one_hour: Option<f64>,
    #[serde(rename = "3h")]
    three_hour: Option<f64>,
}

#[derive(Debug, Deserialize)]
struct SnowData {
    #[serde(rename = "1h")]
    one_hour: Option<f64>,
    #[serde(rename = "3h")]
    three_hour: Option<f64>,
}

#[derive(Debug, Deserialize)]
struct ForecastSys {
    pod: String, // Part of day (d/n)
}

#[derive(Debug, Deserialize)]
struct CityInfo {
    id: u64,
    name: String,
    coord: Coordinates,
    country: String,
    population: Option<u64>,
    timezone: i32,
    sunrise: i64,
    sunset: i64,
}

pub struct WeatherApiClient {
    client: Client,
    api_key: String,
    base_url: String,
}

impl WeatherApiClient {
    // Helper function to convert f64 to Decimal with proper precision
    fn f64_to_decimal(&self, value: f64) -> Decimal {
        Decimal::from_str(&format!("{:.2}", value))
            .unwrap_or_else(|_| Decimal::from_str("0.0").unwrap())
    }

    pub fn new() -> Self {
        let api_key = env::var("OPENWEATHER_API_KEY")
            .unwrap_or_else(|_| {
                tracing::warn!("OPENWEATHER_API_KEY not set. Weather API calls will fail.");
                "demo-key".to_string()
            });
        
        Self {
            client: Client::new(),
            api_key,
            base_url: "https://api.openweathermap.org/data/2.5".to_string(),
        }
    }

    pub fn is_api_key_valid(&self) -> bool {
        !self.api_key.is_empty() && self.api_key != "demo-key" && self.api_key != "your_api_key_here"
    }

    pub async fn get_current_weather(&self, location: &str) -> Result<WeatherData, AppError> {
        let url = format!(
            "{}/weather?q={}&appid={}&units=metric",
            self.base_url, location, self.api_key
        );

        tracing::debug!("Fetching weather data from: {}", url);

        let response = self.client
            .get(&url)
            .send()
            .await
            .map_err(|e| AppError::ExternalService(format!("Failed to fetch weather data: {}", e)))?;

        if !response.status().is_success() {
            return Err(AppError::ExternalService(format!(
                "Weather API returned error: {}",
                response.status()
            )));
        }

        let weather_response: OpenWeatherMapResponse = response
            .json()
            .await
            .map_err(|e| AppError::ExternalService(format!("Failed to parse weather response: {}", e)))?;

        Ok(self.convert_to_weather_data(weather_response, location))
    }

    pub async fn get_weather_forecast(&self, location: &str, days: i32) -> Result<Vec<WeatherData>, AppError> {
        let cnt = days * 8; // 8 forecasts per day (every 3 hours)
        let url = format!(
            "{}/forecast?q={}&appid={}&units=metric&cnt={}",
            self.base_url, location, self.api_key, cnt
        );

        tracing::debug!("Fetching forecast data from: {}", url);

        let response = self.client
            .get(&url)
            .send()
            .await
            .map_err(|e| AppError::ExternalService(format!("Failed to fetch forecast data: {}", e)))?;

        if !response.status().is_success() {
            return Err(AppError::ExternalService(format!(
                "Forecast API returned error: {}",
                response.status()
            )));
        }

        let forecast_response: ForecastResponse = response
            .json()
            .await
            .map_err(|e| AppError::ExternalService(format!("Failed to parse forecast response: {}", e)))?;

        let weather_data_list: Vec<WeatherData> = forecast_response
            .list
            .into_iter()
            .map(|item| self.convert_forecast_item_to_weather_data(item, location))
            .collect();

        Ok(weather_data_list)
    }

    pub async fn get_weather_alerts(&self, location: &str) -> Result<Vec<WeatherAlert>, AppError> {
        // OpenWeatherMap's alerts are available in the One Call API 3.0
        // For demo purposes, we'll return empty alerts or simulate some based on current conditions
        
        // In a real implementation, you would:
        // 1. Use the One Call API if available
        // 2. Parse government weather alerts
        // 3. Create alerts based on severe weather conditions
        
        let current_weather = self.get_current_weather(location).await?;
        let mut alerts = Vec::new();

        // Generate alerts based on severe conditions
        let temp_threshold = Decimal::from_str("35.0").unwrap();
        let wind_threshold = Decimal::from_str("30.0").unwrap();
        let zero_decimal = Decimal::from_str("0.0").unwrap();
        
        if current_weather.temperature > temp_threshold {
            alerts.push(WeatherAlert {
                id: Uuid::new_v4(),
                alert_type: "extreme_temperature".to_string(),
                severity: "medium".to_string(),
                title: "High Temperature Advisory".to_string(),
                description: format!("Temperature is {}°C. Take precautions for plant protection.", current_weather.temperature),
                location: location.to_string(),
                start_time: Utc::now(),
                end_time: None,
            });
        }

        if current_weather.wind_speed.unwrap_or(zero_decimal) > wind_threshold {
            alerts.push(WeatherAlert {
                id: Uuid::new_v4(),
                alert_type: "weather_alert".to_string(),
                severity: "medium".to_string(),
                title: "Wind Advisory".to_string(),
                description: format!("Wind speed is {} km/h. Secure outdoor equipment.", current_weather.wind_speed.unwrap_or(zero_decimal)),
                location: location.to_string(),
                start_time: Utc::now(),
                end_time: None,
            });
        }

        Ok(alerts)
    }

    fn convert_to_weather_data(&self, response: OpenWeatherMapResponse, location: &str) -> WeatherData {
        let timestamp = DateTime::from_timestamp(response.dt, 0)
            .unwrap_or_else(Utc::now);

        WeatherData {
            id: Uuid::new_v4().to_string(),
            location: location.to_string(),
            temperature: self.f64_to_decimal(response.main.temp),
            humidity: self.f64_to_decimal(response.main.humidity),
            rainfall: Some(self.f64_to_decimal(0.0)), // Current weather doesn't include rainfall data
            wind_speed: response.wind.as_ref().map(|w| self.f64_to_decimal(w.speed * 3.6)),
            wind_direction: response.wind.as_ref().map(|w| w.deg as i32),
            pressure: Some(self.f64_to_decimal(response.main.pressure)),
            uv_index: None, // Not available in basic API
            cloud_cover: response.clouds.map(|c| self.f64_to_decimal(c.all)),
            visibility: response.visibility.map(|v| self.f64_to_decimal(v / 1000.0)), // Convert m to km
            weather_condition: response.weather.first().map(|w| w.main.clone()),
            timestamp: Some(timestamp),
            forecast_date: None, // Not a forecast
            source: Some("openweathermap".to_string()),
        }
    }

    fn convert_forecast_item_to_weather_data(&self, item: ForecastItem, location: &str) -> WeatherData {
        let timestamp = DateTime::from_timestamp(item.dt, 0)
            .unwrap_or_else(Utc::now);

        let rainfall = item.rain
            .and_then(|r| r.three_hour.or(r.one_hour))
            .unwrap_or(0.0);

        WeatherData {
            id: Uuid::new_v4().to_string(),
            location: location.to_string(),
            temperature: self.f64_to_decimal(item.main.temp),
            humidity: self.f64_to_decimal(item.main.humidity),
            rainfall: Some(self.f64_to_decimal(rainfall)),
            wind_speed: Some(self.f64_to_decimal(item.wind.speed * 3.6)), // Convert m/s to km/h
            wind_direction: Some(item.wind.deg as i32),
            pressure: Some(self.f64_to_decimal(item.main.pressure)),
            uv_index: None, // Not available in basic API
            cloud_cover: Some(self.f64_to_decimal(item.clouds.all)),
            visibility: Some(self.f64_to_decimal(item.visibility / 1000.0)), // Convert m to km
            weather_condition: item.weather.first().map(|w| w.main.clone()),
            timestamp: Some(timestamp),
            forecast_date: Some(timestamp.date_naive()),
            source: Some("openweathermap_forecast".to_string()),
        }
    }
}
