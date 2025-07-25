use actix_cors::Cors;
use actix_web::{web, App, HttpServer, Result};
use empower_plant_shared::{database, middleware::auth_middleware};
use std::env;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

mod handlers;
mod service;
mod analytics;
mod models;

use handlers::*;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Initialize logging
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "plant_monitoring=debug,tower_http=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Load configuration from environment
    dotenv::dotenv().ok();
    let database_url = env::var("DATABASE_URL")
        .unwrap_or_else(|_| "mysql://root:password@localhost:3306/empowerplant".to_string());
    let host = env::var("HOST").unwrap_or_else(|_| "127.0.0.1".to_string());
    let port = env::var("PORT")
        .unwrap_or_else(|_| "3003".to_string())
        .parse::<u16>()
        .expect("PORT must be a valid number");

    // Initialize database connection
    let db_pool = database::create_pool(&database_url)
        .await
        .expect("Failed to create database pool");

    tracing::info!("Starting Plant Monitoring Service on {}:{}", host, port);

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
                web::scope("/api/v1/plants")
                    .wrap(auth_middleware())
                    .route("", web::get().to(get_plants))
                    .route("", web::post().to(create_plant))
                    .route("/create", web::post().to(create_plant_with_data))
                    .route("/identify", web::post().to(identify_plant))
                    .route("/{id}", web::get().to(get_plant))
                    .route("/{id}", web::put().to(update_plant))
                    .route("/{id}", web::delete().to(delete_plant))
                    .route("/{id}/photos", web::post().to(upload_plant_photo))
                    .route("/{id}/photos", web::get().to(get_plant_photos))
                    .route("/{id}/health-assessment", web::get().to(get_health_assessment))
                    .route("/{id}/growth-analysis", web::get().to(get_growth_analysis))
                    .route("/{id}/recommendations", web::get().to(get_plant_recommendations))
            )
            .service(
                web::scope("/api/v1/sensors")
                    .wrap(auth_middleware())
                    .route("", web::get().to(get_sensors))
                    .route("", web::post().to(create_sensor))
                    .route("/{id}", web::get().to(get_sensor))
                    .route("/{id}", web::put().to(update_sensor))
                    .route("/{id}", web::delete().to(delete_sensor))
                    .route("/{id}/readings", web::get().to(get_sensor_readings))
                    .route("/{id}/readings", web::post().to(add_sensor_reading))
                    .route("/{id}/calibrate", web::post().to(calibrate_sensor))
                    .route("/readings/batch", web::post().to(batch_sensor_readings))
            )
            .service(
                web::scope("/api/v1/cameras")
                    .wrap(auth_middleware())
                    .route("", web::get().to(get_configured_cameras))
                    .route("/setup", web::post().to(setup_live_camera))
                    .route("/{id}/test", web::get().to(test_camera_connection))
                    .route("/{id}/stream", web::get().to(get_live_camera_stream))
            )
            .route("/health", web::get().to(health_check))
    })
    .bind((host, port))?
    .run()
    .await
}
