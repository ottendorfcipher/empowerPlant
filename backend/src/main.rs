use actix_cors::Cors;
use actix_web::{web, App, HttpServer};
use sqlx::MySqlPool;
use std::env;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

mod auth;
mod database;
mod handlers;
mod models;
mod services;

use handlers::*;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Initialize logging
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "empower_plant_backend=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Load environment variables
    dotenvy::dotenv().ok();
    
    let database_url = env::var("DATABASE_URL")
        .expect("DATABASE_URL environment variable must be set");
    let host = env::var("HOST").unwrap_or_else(|_| "127.0.0.1".to_string());
    let port = env::var("PORT")
        .unwrap_or_else(|_| "8080".to_string())
        .parse::<u16>()
        .expect("PORT must be a valid number");

    // Initialize database connection
    let db_pool = database::create_pool(&database_url)
        .await
        .expect("Failed to create database pool");

    tracing::info!("Starting EmpowerPlant Backend on {}:{}", host, port);

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
                web::scope("/api/v1")
                    // Authentication
                    .route("/auth/login", web::post().to(auth_login))
                    .route("/auth/register", web::post().to(auth_register))
                    
                    // Plants
                    .route("/plants", web::get().to(get_plants))
                    .route("/plants", web::post().to(create_plant))
                    .route("/plants/identify", web::post().to(identify_plant))
                    .route("/plants/{id}", web::get().to(get_plant))
                    .route("/plants/{id}", web::put().to(update_plant))
                    .route("/plants/{id}", web::delete().to(delete_plant))
                    
                    // Sensors
                    .route("/sensors", web::get().to(get_sensors))
                    .route("/sensors", web::post().to(create_sensor))
                    .route("/sensors/{id}/readings", web::get().to(get_sensor_readings))
                    .route("/sensors/{id}/readings", web::post().to(add_sensor_reading))
                    
                    // Cameras
                    .route("/cameras", web::get().to(get_cameras))
                    .route("/cameras/setup", web::post().to(setup_camera))
                    .route("/cameras/{id}/stream", web::get().to(get_camera_stream))
                    
                    // Weather
                    .route("/weather/current", web::get().to(get_current_weather))
                    .route("/weather/forecast", web::get().to(get_weather_forecast))
                    
                    // Users
                    .route("/users/profile", web::get().to(get_user_profile))
                    .route("/users/profile", web::put().to(update_user_profile))
            )
            .route("/health", web::get().to(health_check))
    })
    .bind((host, port))?
    .run()
    .await
}
