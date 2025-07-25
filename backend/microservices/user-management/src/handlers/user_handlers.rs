use actix_web::{web, HttpResponse, Result};
use crate::service::UserService;
use empower_plant_shared::CurrentUser;
use std::sync::Arc;
use tracing::{error, info};
use uuid::Uuid;

#[actix_web::get("")]
pub async fn get_users(
    user_service: web::Data<Arc<UserService>>,
    query: web::Query<serde_json::Value>,
) -> Result<HttpResponse> {
    let page = query.get("page").and_then(|v| v.as_i64()).unwrap_or(1) as i32;
    let per_page = query.get("per_page").and_then(|v| v.as_i64()).unwrap_or(20) as i32;
    
    info!("Getting users list, page: {}, per_page: {}", page, per_page);
    
    match user_service.get_users(page, per_page).await {
        Ok(users) => {
            info!("Retrieved {} users", users.len());
            Ok(HttpResponse::Ok().json(users))
        }
        Err(e) => {
            error!("Failed to get users: {}", e);
            Ok(HttpResponse::InternalServerError().json(serde_json::json!({
                "error": e.to_string()
            })))
        }
    }
}

#[actix_web::get("/{id}")]
pub async fn get_user(
    user_service: web::Data<Arc<UserService>>,
    path: web::Path<String>,
) -> Result<HttpResponse> {
    let user_id = match Uuid::parse_str(&path) {
        Ok(id) => id,
        Err(_) => {
            return Ok(HttpResponse::BadRequest().json(serde_json::json!({
                "error": "Invalid user ID format"
            })));
        }
    };
    
    info!("Getting user by ID: {}", user_id);
    
    match user_service.get_user_by_id(&user_id).await {
        Ok(Some(user)) => {
            info!("User found: {}", user.id);
            Ok(HttpResponse::Ok().json(user))
        }
        Ok(None) => {
            info!("User not found: {}", user_id);
            Ok(HttpResponse::NotFound().json(serde_json::json!({
                "error": "User not found"
            })))
        }
        Err(e) => {
            error!("Failed to get user: {}", e);
            Ok(HttpResponse::InternalServerError().json(serde_json::json!({
                "error": e.to_string()
            })))
        }
    }
}

#[actix_web::put("/{id}")]
pub async fn update_user(
    user_service: web::Data<Arc<UserService>>,
    path: web::Path<String>,
    request: web::Json<serde_json::Value>,
) -> Result<HttpResponse> {
    let user_id = match Uuid::parse_str(&path) {
        Ok(id) => id,
        Err(_) => {
            return Ok(HttpResponse::BadRequest().json(serde_json::json!({
                "error": "Invalid user ID format"
            })));
        }
    };
    
    info!("Updating user: {}", user_id);
    
    match user_service.update_user(&user_id, request.into_inner()).await {
        Ok(user) => {
            info!("User updated successfully: {}", user.id);
            Ok(HttpResponse::Ok().json(user))
        }
        Err(e) => {
            error!("Failed to update user: {}", e);
            Ok(HttpResponse::BadRequest().json(serde_json::json!({
                "error": e.to_string()
            })))
        }
    }
}

#[actix_web::delete("/{id}")]
pub async fn delete_user(
    user_service: web::Data<Arc<UserService>>,
    path: web::Path<String>,
) -> Result<HttpResponse> {
    let user_id = match Uuid::parse_str(&path) {
        Ok(id) => id,
        Err(_) => {
            return Ok(HttpResponse::BadRequest().json(serde_json::json!({
                "error": "Invalid user ID format"
            })));
        }
    };
    
    info!("Deactivating user: {}", user_id);
    
    match user_service.deactivate_user(&user_id).await {
        Ok(_) => {
            info!("User deactivated successfully: {}", user_id);
            Ok(HttpResponse::NoContent().finish())
        }
        Err(e) => {
            error!("Failed to deactivate user: {}", e);
            Ok(HttpResponse::BadRequest().json(serde_json::json!({
                "error": e.to_string()
            })))
        }
    }
}

#[actix_web::get("")]
pub async fn get_profile(
    current_user: CurrentUser,
    user_service: web::Data<Arc<UserService>>,
) -> Result<HttpResponse> {
    info!("Getting profile for user: {}", current_user.id);
    
    match user_service.get_user_by_id(&current_user.id).await {
        Ok(Some(user)) => {
            info!("Profile retrieved for user: {}", user.id);
            Ok(HttpResponse::Ok().json(user))
        }
        Ok(None) => {
            error!("Current user not found in database: {}", current_user.id);
            Ok(HttpResponse::NotFound().json(serde_json::json!({
                "error": "User profile not found"
            })))
        }
        Err(e) => {
            error!("Failed to get user profile: {}", e);
            Ok(HttpResponse::InternalServerError().json(serde_json::json!({
                "error": e.to_string()
            })))
        }
    }
}

#[actix_web::put("")]
pub async fn update_profile(
    current_user: CurrentUser,
    user_service: web::Data<Arc<UserService>>,
    request: web::Json<serde_json::Value>,
) -> Result<HttpResponse> {
    info!("Updating profile for user: {}", current_user.id);
    
    match user_service.update_user(&current_user.id, request.into_inner()).await {
        Ok(user) => {
            info!("Profile updated successfully for user: {}", user.id);
            Ok(HttpResponse::Ok().json(user))
        }
        Err(e) => {
            error!("Failed to update user profile: {}", e);
            Ok(HttpResponse::BadRequest().json(serde_json::json!({
                "error": e.to_string()
            })))
        }
    }
}
