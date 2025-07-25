use actix_web::{web, HttpResponse, Result};
use crate::service::UserService;
use empower_plant_shared::{CreateUserRequest, LoginRequest, RefreshTokenRequest};
use std::sync::Arc;
use tracing::{error, info};

#[actix_web::post("/register")]
pub async fn register(
    user_service: web::Data<Arc<UserService>>,
    request: web::Json<CreateUserRequest>,
) -> Result<HttpResponse> {
    info!("Registration request received for email: {}", request.email);
    
    match user_service.register_user(request.into_inner()).await {
        Ok(user) => {
            info!("User registered successfully: {}", user.id);
            Ok(HttpResponse::Created().json(user))
        }
        Err(e) => {
            error!("Registration failed: {}", e);
            Ok(HttpResponse::BadRequest().json(serde_json::json!({
                "error": e.to_string()
            })))
        }
    }
}

#[actix_web::post("/login")]
pub async fn login(
    user_service: web::Data<Arc<UserService>>,
    request: web::Json<LoginRequest>,
) -> Result<HttpResponse> {
    info!("Login request received for email: {}", request.email);
    
    match user_service.login(request.into_inner()).await {
        Ok(response) => {
            info!("User logged in successfully: {}", response.user.id);
            Ok(HttpResponse::Ok().json(response))
        }
        Err(e) => {
            error!("Login failed: {}", e);
            Ok(HttpResponse::Unauthorized().json(serde_json::json!({
                "error": e.to_string()
            })))
        }
    }
}

#[actix_web::post("/refresh")]
pub async fn refresh_token(
    user_service: web::Data<Arc<UserService>>,
    request: web::Json<RefreshTokenRequest>,
) -> Result<HttpResponse> {
    info!("Token refresh request received");
    
    // This would typically validate the refresh token and generate new tokens
    // For now, return an unimplemented response
    Ok(HttpResponse::NotImplemented().json(serde_json::json!({
        "error": "Token refresh not yet implemented"
    })))
}

#[actix_web::post("/logout")]
pub async fn logout() -> Result<HttpResponse> {
    info!("Logout request received");
    
    // This would typically invalidate the session/token
    // For now, return a simple success response
    Ok(HttpResponse::Ok().json(serde_json::json!({
        "message": "Logged out successfully"
    })))
}
