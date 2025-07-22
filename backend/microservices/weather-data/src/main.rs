use actix_cors::Cors;
use actix_web::{web, App, HttpServer, Result};
use empower_plant_shared::{database, middleware::auth_middleware};
use std::env;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

mod handlers;
mod service;
mod weather_api;

use handlers::*;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Initialize logging
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "weather_data=debug,tower_http=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Load configuration from environment
    dotenvy::dotenv().ok();
    let database_url = env::var("DATABASE_URL")
        .unwrap_or_else(|_| "mysql://root:password@localhost:3306/empowerplant".to_string());
    let host = env::var("HOST").unwrap_or_else(|_| "127.0.0.1".to_string());
    let port = env::var("PORT")
        .unwrap_or_else(|_| "3002".to_string())
        .parse::<u16>()
        .expect("PORT must be a valid number");

    // Initialize database connection
    let db_pool = database::create_pool(&database_url)
        .await
        .expect("Failed to create database pool");

    tracing::info!("Starting Weather Data Service on {}:{}", host, port);

    // Start HTTP server
    HttpServer::new(move || {
        let cors = Cors::default()
            .allow_any_origin()
            .allow_any_method()
            .allow_any_header()
            .supports_credentials();

        App::new()
            .app_data(web::Data::new(db_pool.clone()))
            .wrap(cors)
            .wrap(tracing_actix_web::TracingLogger::default())
            .service(
                web::scope("/api/v1/weather")
                    .wrap(auth_middleware())
                    .route("/current/{location}", web::get().to(get_current_weather))
                    .route("/forecast/{location}", web::get().to(get_weather_forecast))
                    .route("/historical", web::get().to(get_historical_weather))
                    .route("/alerts/{location}", web::get().to(get_weather_alerts))
                    // Manual API call endpoints
                    .route("/manual/{location}", web::post().to(get_current_weather_manual))
                    // Jackson Township specific endpoints
                    .route("/jackson-township", web::get().to(get_jackson_township_weather))
                    .route("/manual/jackson-township", web::post().to(get_jackson_township_weather_manual))
            )
            .route("/health", web::get().to(health_check))
    })
    .bind((host, port))?
    .run()
    .await
}
