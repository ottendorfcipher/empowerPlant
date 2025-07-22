mod handlers;
mod repository;
mod service;

use actix_cors::Cors;
use actix_web::{middleware::Logger, web, App, HttpServer};
use empower_plant_shared::{
    create_connection_pool, run_migrations, AppConfig, JwtService, KafkaClient,
    Auth, RequireRole
};
use handlers::{auth_handlers, user_handlers, health_handler};
use repository::UserRepository;
use service::UserService;
use std::sync::Arc;
use tracing::{info, Level};
use tracing_subscriber::FmtSubscriber;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Load environment variables
    dotenvy::dotenv().ok();

    // Initialize configuration
    let config = AppConfig::from_env().expect("Failed to load configuration");

    // Initialize logging
    let subscriber = FmtSubscriber::builder()
        .with_max_level(Level::INFO)
        .with_target(false)
        .with_thread_ids(true)
        .with_file(true)
        .with_line_number(true)
        .finish();
    tracing::subscriber::set_global_default(subscriber).expect("Failed to set subscriber");

    info!("Starting User Management Service");

    // Initialize database connection
    let db_pool = create_connection_pool(&config.database)
        .await
        .expect("Failed to create database pool");

    // Run database migrations
    run_migrations(&db_pool)
        .await
        .expect("Failed to run database migrations");

    // Initialize Kafka client
    let kafka_client = KafkaClient::new(config.kafka.clone())
        .expect("Failed to create Kafka client");

    // Initialize JWT service
    let jwt_service = JwtService::new(config.jwt.clone());

    // Initialize repositories and services
    let user_repository = UserRepository::new(db_pool.clone());
    let user_service = Arc::new(UserService::new(
        user_repository,
        kafka_client,
        jwt_service.clone(),
    ));

    let server_config = config.server.clone();
    info!("Server starting on {}:{}", server_config.host, server_config.port);

    // Start HTTP server
    HttpServer::new(move || {
        let cors = Cors::default()
            .allowed_origin_fn(|origin, _req_head| {
                server_config.cors_origins.iter().any(|allowed| {
                    allowed == "*" || origin.as_bytes() == allowed.as_bytes()
                })
            })
            .allowed_methods(vec!["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"])
            .allowed_headers(vec!["Authorization", "Content-Type", "Accept"])
            .supports_credentials()
            .max_age(3600);

        App::new()
            .app_data(web::Data::new(user_service.clone()))
            .wrap(cors)
            .wrap(Logger::default())
            .wrap(Auth::new(jwt_service.clone()))
            .service(
                web::scope("/api/v1")
                    .service(
                        web::scope("/auth")
                            .service(auth_handlers::register)
                            .service(auth_handlers::login)
                            .service(auth_handlers::refresh_token)
                            .service(auth_handlers::logout)
                    )
                    .service(
                        web::scope("/users")
                            .wrap(RequireRole::new(vec!["admin".to_string()]))
                            .service(user_handlers::get_users)
                            .service(user_handlers::get_user)
                            .service(user_handlers::update_user)
                            .service(user_handlers::delete_user)
                    )
                    .service(
                        web::scope("/profile")
                            .service(user_handlers::get_profile)
                            .service(user_handlers::update_profile)
                    )
            )
            .service(health_handler::health_check)
    })
    .workers(server_config.workers.unwrap_or(4))
    .bind(format!("{}:{}", server_config.host, server_config.port))?
    .run()
    .await
}
