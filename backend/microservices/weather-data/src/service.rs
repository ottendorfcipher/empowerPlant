use chrono::{DateTime, Utc, Duration};
use empower_plant_shared::{error::AppError, models::WeatherData};
use rust_decimal::Decimal;
use sqlx::{MySqlPool, Row};
use std::str::FromStr;
use uuid::Uuid;

use crate::{handlers::WeatherAlert, weather_api::WeatherApiClient};

pub struct WeatherService<'a> {
    pool: &'a MySqlPool,
    api_client: WeatherApiClient,
}

impl<'a> WeatherService<'a> {
    pub fn new(pool: &'a MySqlPool) -> Self {
        Self {
            pool,
            api_client: WeatherApiClient::new(),
        }
    }

    pub async fn get_current_weather(&self, location: &str) -> Result<WeatherData, AppError> {
        // First try to get recent cached data (within last 30 minutes)
        let recent_threshold = Utc::now() - Duration::minutes(30);
        
        if let Ok(cached_data) = self.get_cached_weather(location, recent_threshold).await {
            tracing::info!("Returning cached weather data for location: {}", location);
            return Ok(cached_data);
        }

        // Return an error indicating manual API call is needed
        Err(AppError::ExternalService(
            "No recent cached data available. Use the manual API call endpoint to fetch fresh data.".to_string()
        ))
    }

    pub async fn get_current_weather_manual(&self, location: &str) -> Result<WeatherData, AppError> {
        // Check if API key is configured
        if !self.api_client.is_api_key_valid() {
            return Err(AppError::ExternalService(
                "OpenWeatherMap API key not configured. Please set OPENWEATHER_API_KEY environment variable.".to_string()
            ));
        }

        tracing::info!("Manual API call requested for location: {}", location);
        let weather_data = self.api_client.get_current_weather(location).await?;
        
        // Store in database for caching
        self.store_weather_data(&weather_data).await?;
        
        Ok(weather_data)
    }

    pub async fn get_weather_forecast(&self, location: &str, days: i32) -> Result<Vec<WeatherData>, AppError> {
        // For forecast, always fetch from API as it changes frequently
        let forecast_data = self.api_client.get_weather_forecast(location, days).await?;
        
        // Store forecast data in database
        for weather_data in &forecast_data {
            if let Err(e) = self.store_weather_data(weather_data).await {
                tracing::warn!("Failed to store forecast data: {}", e);
            }
        }
        
        Ok(forecast_data)
    }

    pub async fn get_historical_weather(
        &self,
        location: &str,
        start_date: DateTime<Utc>,
        end_date: DateTime<Utc>,
        page: i32,
        per_page: i32,
    ) -> Result<(Vec<WeatherData>, i64), AppError> {
        let offset = (page - 1) * per_page;
        
        let rows = sqlx::query(
            r#"
            SELECT 
                id,
                location,
                temperature,
                humidity,
                rainfall,
                wind_speed,
                wind_direction,
                pressure,
                uv_index,
                cloud_cover,
                visibility,
                weather_condition,
                timestamp,
                forecast_date,
                source
            FROM weather_data 
            WHERE location = ? 
                AND timestamp BETWEEN ? AND ?
            ORDER BY timestamp DESC
            LIMIT ? OFFSET ?
            "#
        )
        .bind(location)
        .bind(start_date)
        .bind(end_date)
        .bind(per_page)
        .bind(offset)
        .fetch_all(self.pool)
        .await?;

        let weather_data: Vec<WeatherData> = rows.into_iter()
            .map(|row| self.row_to_weather_data(&row))
            .collect::<Result<Vec<_>, _>>()?;

        // Get total count for pagination
        let count_row = sqlx::query(
            "SELECT COUNT(*) as count FROM weather_data WHERE location = ? AND timestamp BETWEEN ? AND ?"
        )
        .bind(location)
        .bind(start_date)
        .bind(end_date)
        .fetch_one(self.pool)
        .await?;

        let total: i64 = count_row.get("count");

        Ok((weather_data, total))
    }

    pub async fn get_weather_alerts(&self, location: &str) -> Result<Vec<WeatherAlert>, AppError> {
        // Get current weather alerts from external API
        let alerts = self.api_client.get_weather_alerts(location).await?;
        
        // Also check for system-generated alerts based on thresholds
        let mut all_alerts = alerts;
        let system_alerts = self.check_weather_thresholds(location).await?;
        all_alerts.extend(system_alerts);
        
        Ok(all_alerts)
    }

    pub async fn process_weather_data_batch(&self, weather_data_batch: Vec<WeatherData>) -> Result<(), AppError> {
        let mut transaction = self.pool.begin().await?;
        
        for weather_data in weather_data_batch {
            sqlx::query(
                r#"
                INSERT INTO weather_data (
                    id, location, temperature, humidity, rainfall, 
                    wind_speed, wind_direction, pressure, uv_index, 
                    cloud_cover, visibility, weather_condition,
                    timestamp, forecast_date, source
                ) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE
                    temperature = VALUES(temperature),
                    humidity = VALUES(humidity),
                    rainfall = VALUES(rainfall),
                    wind_speed = VALUES(wind_speed),
                    wind_direction = VALUES(wind_direction),
                    pressure = VALUES(pressure),
                    uv_index = VALUES(uv_index),
                    cloud_cover = VALUES(cloud_cover),
                    visibility = VALUES(visibility),
                    weather_condition = VALUES(weather_condition)
                "#
            )
            .bind(&weather_data.id)
            .bind(&weather_data.location)
            .bind(weather_data.temperature)
            .bind(weather_data.humidity)
            .bind(weather_data.rainfall)
            .bind(weather_data.wind_speed)
            .bind(weather_data.wind_direction)
            .bind(weather_data.pressure)
            .bind(weather_data.uv_index)
            .bind(weather_data.cloud_cover)
            .bind(weather_data.visibility)
            .bind(&weather_data.weather_condition)
            .bind(weather_data.timestamp)
            .bind(weather_data.forecast_date)
            .bind(&weather_data.source)
            .execute(&mut *transaction)
            .await?;
        }
        
        transaction.commit().await?;
        Ok(())
    }

    async fn get_cached_weather(&self, location: &str, since: DateTime<Utc>) -> Result<WeatherData, AppError> {
        let row = sqlx::query(
            r#"
            SELECT 
                id,
                location,
                temperature,
                humidity,
                rainfall,
                wind_speed,
                wind_direction,
                pressure,
                uv_index,
                cloud_cover,
                visibility,
                weather_condition,
                timestamp,
                forecast_date,
                source
            FROM weather_data 
            WHERE location = ? 
                AND timestamp >= ?
            ORDER BY timestamp DESC
            LIMIT 1
            "#
        )
        .bind(location)
        .bind(since)
        .fetch_one(self.pool)
        .await?;

        let weather_data = self.row_to_weather_data(&row)?;
        Ok(weather_data)
    }

    async fn store_weather_data(&self, weather_data: &WeatherData) -> Result<(), AppError> {
        sqlx::query(
            r#"
            INSERT INTO weather_data (
                id, location, temperature, humidity, rainfall, 
                wind_speed, wind_direction, pressure, uv_index, 
                cloud_cover, visibility, weather_condition,
                timestamp, forecast_date, source
            ) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                temperature = VALUES(temperature),
                humidity = VALUES(humidity),
                rainfall = VALUES(rainfall),
                wind_speed = VALUES(wind_speed),
                wind_direction = VALUES(wind_direction),
                pressure = VALUES(pressure),
                uv_index = VALUES(uv_index),
                cloud_cover = VALUES(cloud_cover),
                visibility = VALUES(visibility),
                weather_condition = VALUES(weather_condition)
            "#
        )
        .bind(&weather_data.id)
        .bind(&weather_data.location)
        .bind(weather_data.temperature)
        .bind(weather_data.humidity)
        .bind(weather_data.rainfall)
        .bind(weather_data.wind_speed)
        .bind(weather_data.wind_direction)
        .bind(weather_data.pressure)
        .bind(weather_data.uv_index)
        .bind(weather_data.cloud_cover)
        .bind(weather_data.visibility)
        .bind(&weather_data.weather_condition)
        .bind(weather_data.timestamp)
        .bind(weather_data.forecast_date)
        .bind(&weather_data.source)
        .execute(self.pool)
        .await?;

        Ok(())
    }

    async fn check_weather_thresholds(&self, location: &str) -> Result<Vec<WeatherAlert>, AppError> {
        let mut alerts = Vec::new();
        
        // Get recent weather data to check against thresholds
        let recent_data = self.get_cached_weather(
            location, 
            Utc::now() - Duration::hours(1)
        ).await?;

        // Check temperature thresholds
        let temp_high_threshold = Decimal::from_str("40.0").unwrap();
        let temp_low_threshold = Decimal::from_str("-5.0").unwrap();
        
        if recent_data.temperature > temp_high_threshold {
            alerts.push(WeatherAlert {
                id: Uuid::new_v4(),
                alert_type: "extreme_temperature".to_string(),
                severity: "high".to_string(),
                title: "Extreme High Temperature".to_string(),
                description: format!("Temperature has reached {}°C, which may be harmful to plants", recent_data.temperature),
                location: location.to_string(),
                start_time: recent_data.timestamp.unwrap_or(Utc::now()),
                end_time: None,
            });
        } else if recent_data.temperature < temp_low_threshold {
            alerts.push(WeatherAlert {
                id: Uuid::new_v4(),
                alert_type: "extreme_temperature".to_string(),
                severity: "critical".to_string(),
                title: "Freeze Warning".to_string(),
                description: format!("Temperature has dropped to {}°C, immediate protection needed for plants", recent_data.temperature),
                location: location.to_string(),
                start_time: recent_data.timestamp.unwrap_or(Utc::now()),
                end_time: None,
            });
        }

        // Check wind speed thresholds
        if let Some(wind_speed) = recent_data.wind_speed {
            let wind_threshold = Decimal::from_str("50.0").unwrap();
            if wind_speed > wind_threshold {
                alerts.push(WeatherAlert {
                    id: Uuid::new_v4(),
                    alert_type: "weather_alert".to_string(),
                    severity: "medium".to_string(),
                    title: "High Wind Warning".to_string(),
                    description: format!("Wind speed has reached {} km/h, secure loose equipment", wind_speed),
                    location: location.to_string(),
                    start_time: recent_data.timestamp.unwrap_or(Utc::now()),
                    end_time: None,
                });
            }
        }

        Ok(alerts)
    }

    fn row_to_weather_data(&self, row: &sqlx::mysql::MySqlRow) -> Result<WeatherData, AppError> {
        use sqlx::Row;
        
        Ok(WeatherData {
            id: row.try_get("id")?,
            location: row.try_get("location")?,
            temperature: row.try_get("temperature")?,
            humidity: row.try_get("humidity")?,
            rainfall: row.try_get("rainfall")?,
            wind_speed: row.try_get("wind_speed")?,
            wind_direction: row.try_get("wind_direction")?,
            pressure: row.try_get("pressure")?,
            uv_index: row.try_get("uv_index")?,
            cloud_cover: row.try_get("cloud_cover")?,
            visibility: row.try_get("visibility")?,
            weather_condition: row.try_get("weather_condition")?,
            timestamp: row.try_get("timestamp")?,
            forecast_date: row.try_get("forecast_date")?,
            source: row.try_get("source")?,
        })
    }
}
