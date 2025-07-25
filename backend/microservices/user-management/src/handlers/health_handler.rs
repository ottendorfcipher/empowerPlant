use actix_web::{HttpResponse, Result};
use serde_json::json;

#[actix_web::get("/health")]
pub async fn health_check() -> Result<HttpResponse> {
    Ok(HttpResponse::Ok().json(json!({
        "status": "healthy",
        "service": "user-management",
        "timestamp": chrono::Utc::now().to_rfc3339()
    })))
}
