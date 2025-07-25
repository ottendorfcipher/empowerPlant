use std::env;

use axum::{
    routing::{get, post, put, delete},
    Router,
};
use tower::ServiceBuilder;
use tower_http::{cors::CorsLayer, trace::TraceLayer};
use tracing::info;

use empowerplant_shared::{database::get_connection_pool, config::load_config};

mod handlers;
mod service;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::init();

    let config = load_config()?;
    let pool = get_connection_pool(&config.database_url).await?;

    // Run database migrations
    sqlx::migrate!("./migrations").run(&pool).await?;

    let app = Router::new()
        // Camera management routes
        .route("/cameras", post(handlers::create_camera))
        .route("/cameras", get(handlers::list_cameras))
        .route("/cameras/:id", get(handlers::get_camera))
        .route("/cameras/:id", put(handlers::update_camera))
        .route("/cameras/:id", delete(handlers::delete_camera))
        .route("/cameras/:id/status", put(handlers::update_camera_status))
        
        // Camera streaming routes
        .route("/cameras/:id/stream", get(handlers::get_stream))
        .route("/cameras/:id/stream", post(handlers::start_stream))
        .route("/cameras/:id/stream", delete(handlers::stop_stream))
        
        // Camera control routes
        .route("/cameras/:id/control", post(handlers::camera_control))
        .route("/cameras/:id/snapshot", post(handlers::take_snapshot))
        .route("/cameras/:id/record", post(handlers::start_recording))
        .route("/cameras/:id/record/:recording_id", delete(handlers::stop_recording))
        
        // Test connection route
        .route("/cameras/:id/test-connection", post(handlers::test_connection))
        
        // Health check
        .route("/health", get(handlers::health_check))
        .layer(
            ServiceBuilder::new()
                .layer(TraceLayer::new_for_http())
                .layer(CorsLayer::permissive())
        )
        .with_state(pool);

    let port = env::var("PORT").unwrap_or_else(|_| "3003".to_string());
    let addr = format!("0.0.0.0:{}", port);
    
    info!("Camera Management Service listening on {}", addr);
    
    let listener = tokio::net::TcpListener::bind(&addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
